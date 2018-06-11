local DEBUG_MOVEMENT = GetConVar("rsnb_debug_movement")




function ENT:FollowAltPath( options )
	if DEBUG_MOVEMENT:GetBool() then
		print( self, "FollowAltPath" )
	end
	
	self:ResetMotionless()
	
	self:SetupToWalk( true )
	
	local timeout = CurTime() + ( options.timeout or 60 )
	
	while self.alt_path_index <= #self.alt_path do
		if not self.frozen then
			if self.interrupt then
				self:PopActivity()
				return "interrupt"
			end
		
			self:CheckIsMotionless()
		
			if CurTime() >= timeout then
				self:PopActivity()
				return "timeout"
			end
			
			if self.motionless then
				local result = self:GiveMovingSpace( options )
				if result != "ok" then
					self:PopActivity()
					return result
				end
			end
		
			if options.draw then
				for i = 1, #self.alt_path - 1 do
					debugoverlay.Line( self.alt_path [i], self.alt_path [i+1], 0.1, color_white, true )
				end
			end
			
			self.loco:Approach( self.alt_path[self.alt_path_index], 1 )
			self.loco:FaceTowards( self.alt_path[ self.alt_path_index ] )
			if self:GetPos():Distance( self.alt_path[ self.alt_path_index ] ) < 25 then -- TODO: replace magic number
				self.alt_path_index = self.alt_path_index + 1
			end
		end
		coroutine.yield()
	end
	
	self.loco:ClearStuck()
	
	self:PopActivity()
	return "ok"
end




-- Helper function. Automatically decides weather to run or walk based on
-- how close to the end the NextBot is, and how steep the path is.
function ENT:UpdateRunOrWalk( len, no_pop )
	local cur_act = self.activity_stack:Top()
	
	local cursor_dist = self.path:GetCursorPosition()
	local future_pos = self.path:GetPositionOnPath( cursor_dist + 150 )
	
	local ang = (future_pos - self:GetPos()):Angle()
	ang = ang - Angle(0,self:GetAngles().yaw,0)
	ang:Normalize()
	
	local should_run = self.have_target or len > self.run_tolerance
	local should_walk = not (self.have_target or self.have_old_target) or math.abs(ang.pitch) > 10 or math.abs(ang.yaw) > 90
	
	if (not should_run) and should_walk then
		if cur_act[1] != ACT_WALK then
			if not no_pop then
				self:PopActivity()
			end
			self:SetupToWalk( true )
			cur_act = self.activity_stack:Top()
		end
	else
		if cur_act[1] != ACT_RUN then
			if not no_pop then
				self:PopActivity()
			end
			self:SetupToRun( true )
			cur_act = self.activity_stack:Top()
		end
	end
	
	return cur_act
end




function ENT:MoveToPos( pos, options )
	if DEBUG_MOVEMENT:GetBool() then
		print( self, "MoveToPos" )
	end

	local options = options or {}

	self.path = Path( "Follow" )
	self.path:SetMinLookAheadDistance( options.lookahead or 300 )
	self.path:SetGoalTolerance( options.tolerance or 20 )
	self.path:Compute( self, pos )
	
	if not self.path:IsValid() then
		if DEBUG_MOVEMENT:GetBool() then
			print( self, "I FAIL YOU" )
		end
		return "failed"
	end
	
	-- set the initial animation and speed.
	local len = self.path:GetLength()
	self:UpdateRunOrWalk( len, true )
	
	self:ResetMotionless()
	
	while self.path:IsValid() do
		if not self.frozen then
			if self.interrupt then
				self:PopActivity()
				return "interrupt"
			end
		
			self:CheckIsMotionless()
		
			local cur_act = self.activity_stack:Top()
		
			if self.path:GetAge() > ( options.repath or 2.0 ) then
				self.path:Compute( self, pos )
				
				-- update the animation and speed as needed.
				local len = self.path:GetLength()
			end
			
			if cur_act[2] <= 0 and self:OnGround() then
				local len = self.path:GetLength()
				cur_act = self:UpdateRunOrWalk( len )
			end
			
			-- only move when the animation is a movement type.
			if cur_act[1] == ACT_WALK or cur_act[1] == ACT_RUN then
				self.path:Update( self )
			else
				self:ResetMotionless()
			end

			if options.draw then self.path:Draw() end
			
			if self.loco:IsStuck() or self.motionless then
				
				-- TODO: Try to open doors or break things here
			
				self:PopActivity()
				
				local result = self:HandleStuck( options )
				if result != "ok" then return ( result or "stuck" ) end
				self.path:Compute( self, pos )
				
				self:PushActivity( ACT_IDLE )
			end
		end
		coroutine.yield()
	end
	
	self:PopActivity()
	return "ok"
end




function ENT:Wander( options )
	if DEBUG_MOVEMENT:GetBool() then
		print( self, "Wander" )
	end

	local pos = self:FindSpot(
				"random",
				{
					type = "hiding",
					pos = self:GetPos(),
					radius = 100000
				}
			)
	
	return self:MoveToPos( pos )
end




function ENT:ChaseTarget( options )
	if DEBUG_MOVEMENT:GetBool() then
		print( self, "ChaseTarget" )
	end

	local options = options or {}
	options.tolerance = options.tolerance or 35

	self.path = Path( "Chase" )
	self.path:SetMinLookAheadDistance( options.lookahead or 300 )
	self.path:SetGoalTolerance( options.tolerance )
	
	self.path:Compute( self, self.target_last_known_position )
	
	if ( !self.path:IsValid() ) then return "failed" end
	
	-- set the initial animation and speed.
	self:SetupToRun( true )
	
	while self.path:IsValid() and self.have_target and self.target_last_known_position:Distance(self:GetPos()) > options.tolerance do
		if not self.frozen then
			if self.interrupt then
				self:PopActivity()
				return "interrupt"
			end
			
			self:CheckIsMotionless()
		
			local cur_act = self.activity_stack:Top()
			
			if self.path:GetAge() > 0.25 then
				self.path:Compute( self, self.target_last_known_position )
			end
			
			-- only move when the animation is a movement type.
			if cur_act[1] == ACT_WALK or cur_act[1] == ACT_RUN then
				if CurTime() - self.target_last_seen > 1.0 or self.target_last_known_position:Distance(self:GetPos()) > 50 then
					self.path:Update( self )
				else
					self.path:Chase( self, self.target )
				end
			else
				self:ResetMotionless()
			end

			if ( options.draw ) then self.path:Draw() end
			
			if self.loco:IsStuck() or self.motionless then
				self:PopActivity()
				
				local result = self:HandleStuck( options )
				if result != "ok" then return ( result or "stuck" ) end
				--self.path:Chase( self, self.target )
				--self.path:Compute( self, self.target_last_known_position )
				
				self:SetupToRun( true )
			end
		end

		coroutine.yield()
	end
	
	self:PopActivity()
	return "ok"
end