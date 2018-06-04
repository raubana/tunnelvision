-- Helper function. Automatically decides weather to run or walk based on
-- how close to the end the NextBot is, and how steep the path is.
function ENT:UpdateRunOrWalk( len, no_pop )
	local cur_act = self.activity_stack:Top()
	
	local cursor_dist = self.path:GetCursorPosition()
	local future_pos = self.path:GetPositionOnPath( cursor_dist + 150 )
	
	local ang = (future_pos - self:GetPos()):Angle()
	ang = ang - Angle(0,self:GetAngles().yaw,0)
	ang:Normalize()
	
	local should_run = self.have_target
	local should_walk = not (self.have_target or self.have_old_target) or math.abs(ang.pitch) > 10 or math.abs(ang.yaw) > 90
	
	if (not should_run) and (len <= self.run_tolerance or should_walk) then
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
	print( self, "MoveToPos" )

	local options = options or {}

	self.path = Path( "Follow" )
	self.path:SetMinLookAheadDistance( options.lookahead or 300 )
	self.path:SetGoalTolerance( options.tolerance or 20 )
	self.path:Compute( self, pos )
	
	if not self.path:IsValid() then
		print( "I FAIL YOU" )
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
	print( self, "Wander" )

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
	print( self, "ChaseTarget" )

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