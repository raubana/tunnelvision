include( "sv_movement_inaccessable.lua" )
include( "sv_movement_obstacle_interaction.lua" )




local DEBUG_MOVEMENT = GetConVar("rsnb_debug_movement")
local DEBUG_MOVEMENT_FORCE_DRAW_PATH = CreateConVar("twg_debug_movement_force_draw_path", "0", FCVAR_SERVER_CAN_EXECUTE+FCVAR_NOTIFY+FCVAR_CHEAT)




function ENT:RSNBInitMovement()
	self.path = nil
	self.alt_path = nil -- reserved for dynamically generated paths
	self.alt_path_index = 1
	
	self.walk_speed = 50
	self.run_speed = 300
	
	self.walk_accel = self.walk_speed * 1
	self.walk_decel = self.walk_speed * 4
	
	self.run_accel = self.run_speed * 32
	self.run_decel = self.run_speed * 32
	
	self.walk_turn_speed = 360
	self.run_turn_speed = 180
	
	self.move_ang = Angle()
	
	self.run_tolerance = 1000
	
	self.loco:SetDeathDropHeight( 400 )
	self.loco:SetStepHeight( 24 )
	self.loco:SetJumpHeight( 24 )
	
	self.interrupt = false
	
	self:RSNBInitMovementMotionless()
	self:MovementInaccessableInit()
	
	self.motionless_speed_limit = 0.25
	
	-- I'm being lazy AF here...
	
	self.previous_cnav = nil
	self.current_cnav = nil
end




function ENT:OnNavAreaChanged( old, new )
	self.previous_cnav = old
	self.current_cnav = new
end




local function doValidationHullTrace( start, endpos, mins, maxs, filter, drawit )
	local tr = util.TraceHull({
		start = start,
		endpos = endpos,
		mins = mins,
		maxs = maxs,
		filter = filter,
		mask = MASK_SOLID,
	})
	
	return tr
end




function ENT:TestIsSafeSpot( pos )
	local output = {can_stand_here=false}
	if not util.IsInWorld( pos ) then return output end
	
	hull_stand_height = 74
	hull_halfthick = 15
	
	local height = hull_stand_height

	local tr_up = doValidationHullTrace( pos, pos + Vector(0,0,hull_stand_height), Vector(-hull_halfthick, -hull_halfthick, 0), Vector(hull_halfthick, hull_halfthick, 0), self.ent )
	if tr_up.Hit or tr_up.StartSolid then return output end
	
	local tr_down = doValidationHullTrace( pos + Vector(0,0,height), pos, Vector(-hull_halfthick, -hull_halfthick, 0), Vector(hull_halfthick, hull_halfthick, 0), self.ent )
	if tr_down.Hit or tr_down.StartSolid then return output end
	
	local tr_right = doValidationHullTrace( pos - Vector(0,hull_halfthick,0), pos + Vector(0,hull_halfthick,0), Vector(-hull_halfthick, 0, 0), Vector(hull_halfthick, 0, height), self.ent )
	if tr_right.Hit or tr_right.StartSolid then return output end
	
	local tr_left = doValidationHullTrace( pos + Vector(0,hull_halfthick,0), pos - Vector(0,hull_halfthick,0), Vector(-hull_halfthick, 0, 0), Vector(hull_halfthick, 0, height), self.ent )
	if tr_left.Hit or tr_left.StartSolid then return output end
	
	local tr_forward = doValidationHullTrace( pos - Vector(hull_halfthick,0,0), pos + Vector(hull_halfthick,0,0), Vector(0, -hull_halfthick, 0), Vector(0, hull_halfthick, height), self.ent )
	if tr_forward.Hit or tr_forward.StartSolid then return output end
	
	local tr_backward = doValidationHullTrace( pos + Vector(hull_halfthick,0,0), pos - Vector(hull_halfthick,0,0), Vector(0, -hull_halfthick, 0), Vector(0, hull_halfthick, height), self.ent )
	if tr_backward.Hit or tr_backward.StartSolid then return output end
	
	output.can_stand_here = true
	
	return output
end




function ENT:TeleportToNearestSafeSpot()
	if DEBUG_MOVEMENT:GetBool() then
		print( self, "TeleportToNearestSafeSpot" )
	end
	
	while self.frozen do
		coroutine.yield()
	end

	local my_pos = self:GetPos()

	for x = -2,2 do
		for y = -2,2 do
			for z = -2,2 do
				local offset = Vector(x,y,z) * 15
				if not offset:IsZero() then
					local test_pos = my_pos + offset
					
					if self:TestIsSafeSpot( test_pos ).can_stand_here then
						self:SetPos( test_pos )
						self.loco:ClearStuck()
						self:ResetMotionless()
						return "ok"
					end
				end
			end
		end
	end
	
	return "stuck"
end




-- Used example from here:
-- https://wiki.garrysmod.com/page/PathFollower/Compute

local COLOR_RED = Color( 255, 0, 0 )
local temp_self = nil

local function PathGenMethod( area, fromArea, ladder, elevator, length )

	if not IsValid( fromArea ) then
		return 0
	else
		if not temp_self.loco:IsAreaTraversable( area ) or area:HasAttributes( NAV_MESH_JUMP + NAV_MESH_CROUCH )then
			return -1
		else
			if IsValid( area ) then
				local cnav_data = temp_self:GetCnavInaccessableData( area )
				if cnav_data != nil then
					local retry = cnav_data.time + ( 15 * math.pow( 1.5, cnav_data.repeats ) )
					local expires = cnav_data.time + (3*60) + (retry - cnav_data.time)
					
					if CurTime() > retry then
						-- do nothing. let the NextBot try again.
						if CurTime() > expires then
							temp_self:ClearCnavInaccessableData( area )
						end
					else
						if DEBUG_MOVEMENT:GetBool() then
							debugoverlay.Text( area:GetCenter(), "inaccessable" )
						end
						return -1
					end
				end
			end
		end

		local dist = 0

		if IsValid( ladder ) then
			dist = ladder:GetLength()
		elseif length > 0 then
			dist = length
		else
			dist = ( area:GetCenter() - fromArea:GetCenter() ):Length()
		end
		
		if area:IsUnderwater() or area:HasAttributes( NAV_MESH_AVOID ) then
			dist = dist * 10
		end
		
		if temp_self.have_target and IsValid( temp_self.target ) then
			if isvector( temp_self.target_last_known_position ) then
				local dist_from_target = area:GetCenter():Distance( temp_self.target_last_known_position )
				--[[
				if dist_from_target < 500 then
					local can_see = area:IsVisible( temp_self.target_last_known_position + Vector(0,0,50) )
					
					if can_see then
						dist = dist * 5
					else
						dist = dist / (1+#area:GetHidingSpots())
					end
				end
				]]
			end
		end
		
		if not temp_self.is_unstable then
			dist = dist * Lerp( math.random(), 0.5,1.5 )
		end

		local cost = dist + fromArea:GetCostSoFar()
		
		if cost >= 2000 then return -1 end

		// check height change
		local deltaZ = fromArea:ComputeAdjacentConnectionHeightChange( area )
		
		if deltaZ >= temp_self.loco:GetStepHeight() then
			if deltaZ >= temp_self.loco:GetMaxJumpHeight() then
				return -1
			end

			local jumpPenalty = 5
			cost = cost + jumpPenalty * dist
		elseif deltaZ < -temp_self.loco:GetDeathDropHeight() then
			return -1
		end

		return cost
	end
end




function ENT:SetupToRun( push )
	if push then self:PushActivity( ACT_RUN ) end
	self.loco:SetDesiredSpeed( self.run_speed*self.run_speed_mult )
	self.loco:SetMaxYawRate( self.run_turn_speed )
	self.loco:SetAcceleration( self.run_accel )
	self.loco:SetDeceleration( self.run_decel )
end




function ENT:SetupToWalk( push )
	if push then self:PushActivity( ACT_WALK ) end
	self.loco:SetDesiredSpeed( self.run_speed*self.walk_speed_mult )
	self.loco:SetMaxYawRate( self.walk_turn_speed )
	self.loco:SetAcceleration( self.walk_accel )
	self.loco:SetDeceleration( self.walk_decel )
end




function ENT:UpdateRunOrWalk( len, no_pop )
	local cur_act = self.activity_stack:Top()
	
	local cursor_dist = self.path:GetCursorPosition()
	local future_pos = self.path:GetPositionOnPath( cursor_dist + 150 )
	
	local ang = (future_pos - self:GetPos()):Angle()
	ang = ang - Angle(0,self:GetAngles().yaw,0)
	ang:Normalize()
	
	local should_walk = math.abs(ang.pitch) > 25 or math.abs(ang.yaw) > 25
	local should_run = len > self.run_tolerance or self.force_run or (self.is_unstable and self.have_target) 
	
	if should_walk or not should_run then
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




function ENT:GiveMovingSpace( options )
	if DEBUG_MOVEMENT:GetBool() then
		print( self, "GiveMovingSpace" )
	end
	
	self:SetupToWalk( true )

	local timeout = CurTime() + ( options.maxage or 5 )

	while CurTime() <= timeout do
		if not self.frozen and not self.pausing then
			if self.interrupt then
				self:PopActivity()
				return "interrupt"
			end
		
			local closest_ang = nil
			local closest_dist = nil
			local trace_length = 45 -- TODO
			local start = self:GetPos() + Vector(0,0,10) -- TODO
			local mins = Vector(-2,-2,0)
			local maxs = Vector(2,2,60)
			
			local offset = (CurTime()%45)*8
			
			for ang = 0, 360, 30 do
				local ang2 = ang + offset
			
				local normal = Angle(0,ang2,0):Forward()
				local endpos = start + (normal * trace_length)
				
				local tr = util.TraceHull({ -- TODO: TraceEntity wasn't working for some cases??
						start = start,
						endpos = endpos,
						mins = mins,
						maxs = maxs,
						filter = self,
						mask = MASK_SOLID
					}
				)
				
				if DEBUG_MOVEMENT:GetBool() then
					debugoverlay.SweptBox( start, tr.HitPos, mins, maxs, angle_zero, engine.TickInterval()*2, color_white )
				end
				
				if tr.Hit and (closest_dist == nil or tr.Fraction*trace_length < closest_dist) then
					closest_ang = ang2
					closest_dist = tr.Fraction*trace_length
				end
			end
			
			if closest_dist == nil or closest_dist > 20 then
				self:PopActivity()
				return "ok"
			else
				self.loco:Approach( self:GetPos() - (Angle( 0, (CurTime()*90)%360, 0 ):Forward()*1000), 1 )
			end
		end
		
		coroutine.yield()
	end
	
	self:PopActivity()
	return "timeout"
end




function ENT:FollowAltPath( options )
	if DEBUG_MOVEMENT:GetBool() then
		print( self, "FollowAltPath" )
	end
	
	self:ResetMotionless()
	
	self:SetupToWalk( true )
	
	local timeout = CurTime() + ( options.timeout or 60 )
	
	while self.alt_path_index <= #self.alt_path do
		if not self.frozen and not self.pausing then
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




function ENT:MoveToPos( pos, options )
	if DEBUG_MOVEMENT:GetBool() then
		print( self, "MoveToPos" )
	end

	local options = options or {}
	
	if DEBUG_MOVEMENT_FORCE_DRAW_PATH:GetBool() then
		options.draw = true
	end
	
	if not isvector( pos ) then return "failed" end
	
	local cnav = navmesh.GetNearestNavArea( pos )
	if IsValid( cnav ) then
		local data = self:GetCnavInaccessableData( cnav )
		if data then
			return "failed"
		end
	end

	self.path = Path( "Follow" )
	self.path:SetMinLookAheadDistance( options.lookahead or 300 )
	self.path:SetGoalTolerance( options.tolerance or 20 )
	temp_self = self
	self.path:Compute( self, pos, PathGenMethod )
	temp_self = nil
	
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
		if not self.frozen and not self.pausing then
			if self.interrupt then
				self:PopActivity()
				return "interrupt"
			end
			
			self:CheckIsMotionless()
			
			local cur_act = self.activity_stack:Top()
			
			if self.path:GetAge() > ( options.repath or 2.0 ) then
				temp_self = self
				self.path:Compute( self, pos, PathGenMethod )
				temp_self = nil
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
				if DEBUG_MOVEMENT:GetBool() then
					print( self, "Became stuck or motionless." )
				end
			
				self:PopActivity()
				
				local result = self:EvaluateAndDealWithObstruction()
				
				if result == "impassable" then
					self.loco:ClearStuck()
					self:ResetMotionless()
				else
					if result == "ok" then
						self:MarkCnavInaccessable( self.current_cnav, "unknown", nil )
					end
					
					local result = self:HandleStuck( options )
					self.alt_path = nil
					
					if result != "ok" then
						result = self:TeleportToNearestSafeSpot()
					end
					
					if result != "ok" then return ( result or "stuck" ) end
				end
				
				self.path = Path( "Follow" )
				self.path:SetMinLookAheadDistance( options.lookahead or 300 )
				self.path:SetGoalTolerance( options.tolerance or 20 )
				temp_self = self
				self.path:Compute( self, pos, PathGenMethod )
				temp_self = nil
				
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
	
	if DEBUG_MOVEMENT:GetBool() then
		print( self, "Wander to", pos )
	end
	
	return self:MoveToPos( pos )
end




function ENT:ChaseTarget( options )
	if DEBUG_MOVEMENT:GetBool() then
		print( self, "ChaseTarget" )
	end

	local options = options or {}
	options.tolerance = options.tolerance or 30
	
	if DEBUG_MOVEMENT_FORCE_DRAW_PATH:GetBool() then
		options.draw = true
	end
	
	if not isvector( self.target_last_known_position ) then
		return "failed"
	end
	
	local cnav = navmesh.GetNearestNavArea( self.target_last_known_position )
	if IsValid( cnav ) then
		local data = self:GetCnavInaccessableData( cnav )
		if data then
			return "failed"
		end
	end

	self.path = Path( "Follow" ) -- Chase is broken as fuck (?)
	self.path:SetMinLookAheadDistance( options.lookahead or 300 )
	self.path:SetGoalTolerance( options.tolerance )
	temp_self = self
	self.path:Compute( self, self.target_last_known_position, PathGenMethod )
	temp_self = nil
	
	if not self.path:IsValid() then return "failed" end
	
	-- set the initial animation and speed.
	local len = self.path:GetLength()
	self:UpdateRunOrWalk( len, true )
	
	local dist_from_target = self.target_last_known_position:Distance(self:GetPos())
	
	while self.path:IsValid() and self.have_target and dist_from_target > options.tolerance do
		if not self.frozen and not self.pausing then
			if self.interrupt then
				self:PopActivity()
				return "interrupt"
			end
			
			self:CheckIsMotionless()
		
			local cur_act = self.activity_stack:Top()
			
			local dist_from_target = self.target_last_known_position:Distance(self:GetPos())
			local recalc_threshold = 0.1
			if dist_from_target > 1000 then
				recalc_threshold = 2.0
			elseif dist_from_target > 500 or CurTime() - self.target_last_seen > 1.0 then
				recalc_threshold = 1.0
			end
			
			if self.path:GetAge() > recalc_threshold then
				temp_self = self
				self.path:Compute( self, self.target_last_known_position, PathGenMethod )
				temp_self = nil
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

			if ( options.draw ) then self.path:Draw() end
			
			if self.loco:IsStuck() or self.motionless then
				if DEBUG_MOVEMENT:GetBool() then
					print( self, "Became stuck or motionless." )
				end
			
				self:PopActivity()
				
				local result = self:EvaluateAndDealWithObstruction()
				
				if result == "impassable" then
					self.loco:ClearStuck()
					self:ResetMotionless()
				else
					if result == "ok" then
						self:MarkCnavInaccessable( self.current_cnav, "unknown", nil )
					end
					
					local result = self:HandleStuck( options )
					self.alt_path = nil
					
					if result != "ok" then
						result = self:TeleportToNearestSafeSpot()
					end
					
					if result != "ok" then return ( result or "stuck" ) end
				end
				
				if not isvector( self.target_last_known_position ) then return "ok" end
				
				self.path = Path( "Follow" )
				self.path:SetMinLookAheadDistance( options.lookahead or 300 )
				self.path:SetGoalTolerance( options.tolerance )
				temp_self = self
				self.path:Compute( self, self.target_last_known_position, PathGenMethod )
				temp_self = nil
				
				self:PushActivity( ACT_IDLE )
			end
		end

		coroutine.yield()
	end
	
	self:PopActivity()
	return "ok"
end