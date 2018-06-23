local DEBUG_MOVEMENT = GetConVar("rsnb_debug_movement")




function ENT:RSNBInitMovement()
	self.path = nil
	self.alt_path = nil -- reserved for dynamically generated paths
	self.alt_path_index = 1
	
	self.walk_speed = 75
	self.run_speed = 200
	
	self.walk_accel = 50
	self.walk_decel = 50
	
	self.run_accel = 300
	self.run_decel = 100
	
	self.walk_turn_speed = 180
	self.run_turn_speed = 90
	
	self.move_ang = Angle()
	
	self.run_tolerance = 500
	
	self.interrupt = false
	
	self:RSNBInitMovementMotionless()
	
	
	-- I'm being lazy AF here...
	
	self.previous_cnav = nil
	self.current_cnav = nil
	
	self.inaccessable_data = {}
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

	local my_pos = self:GetPos()

	for x = -2,2 do
		for y = -2,2 do
			for z = -2,2 do
				local offset = Vector(x,y,z) * 20
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




function ENT:GetCnavInaccessableData( cnav )
	local data = self.inaccessable_data[tostring(cnav:GetID())]
	return data
end




function ENT:MarkCnavInaccessable( cnav, reason, obstruction )
	if DEBUG_MOVEMENT:GetBool() then
		print( "MarkCnavInaccessable", cnav, reason, obstruction )
	end
	
	-- Updates existing data.
	local existing_data = self:GetCnavInaccessableData( cnav )
	
	if existing_data then
		if not table.HasValue( existing_data.obstructions, obstruction ) then
			table.insert( existing_data.obstructions, obstruction )
		end
		existing_data.time = CurTime()
		existing_data.repeats = existing_data.repeats + 1
		
		return
	end
	
	-- Creates new data.
	local data = {
		time = CurTime(),
		repeats = 0,
		obstructions = {obstruction}
	}
	
	self.inaccessable_data[tostring(cnav:GetID())] = data
end




function ENT:ClearCnavInaccessableData( cnav )
	if DEBUG_MOVEMENT:GetBool() then
		print( "ClearCnavInaccessableData", cnav )
	end
	self.inaccessable_data[tostring(cnav:GetID())] = nil
end




local ENT_DATA = {}
ENT_DATA["env_soundscape"] = {ignore = true}
ENT_DATA["func_lod"] = {ignore = true}
ENT_DATA["info_player_spawn"] = {ignore = true}
ENT_DATA["info_player_terrorist"] = {ignore = true}
ENT_DATA["info_player_counterterrorist"] = {ignore = true}
ENT_DATA["keyframe_rope"] = {ignore = true}
ENT_DATA["manipulate_flex"] = {ignore = true}
ENT_DATA["move_rope"] = {ignore = true}
ENT_DATA["player"] = {ignore = true}
ENT_DATA["predicted_viewmodel"] = {ignore = true}
ENT_DATA["prop_dynamic"] = {ignore = true}
ENT_DATA["trigger_multiple"] = {ignore = true}
ENT_DATA["trigger_soundscape"] = {ignore = true}

ENT_DATA["prop_physics"] = {is_physical = true}
ENT_DATA["prop_physics_multiplayer"] = {is_physical = true}

ENT_DATA["func_brush"] = {impassable = true}
ENT_DATA["entity_blocker"] = {impassable = true}

ENT_DATA["func_breakable"] = {breakable = true}
ENT_DATA["func_breakable_surf"] = {
	breakable = true,
	will_not_despawn = true,
	use_bullets = true,
	obb_is_not_local = true,
	ignore_dist = true
}

ENT_DATA["prop_door_rotating"] = {
	is_door = true
}
ENT_DATA["func_door_rotating"] = {
	is_door = true
}
ENT_DATA["func_door"] = {
	is_door = true
}




function ENT:DealWithPhysicsProp( cnav, ent, data )
	if DEBUG_MOVEMENT:GetBool() then
		print( self, "DealWithPhysicsProp" )
	end

	if not IsValid( ent ) then return "ok" end

	self:PushActivity( ACT_IDLE )
	
	self:PlaySequence( "swing" )
	
	self:WaitForAnimToEnd( 0.33 )
	
	local start_pos = nil
	local start_angle = nil
	if IsValid( ent ) then
		start_pos = ent:GetPos()
		start_angle = ent:GetAngles()
		
		local dif = ent:GetPos() - self:GetHeadPos()
		dif:Normalize()
		
		ent:GetPhysicsObject():ApplyForceCenter(dif*100000)
	end
	
	self:WaitForAnimToEnd( 2.0 )
	
	local end_pos = nil
	local end_angle = nil
	if IsValid( ent ) then
		end_pos = ent:GetPos()
		end_angle = ent:GetAngles()
	end
	
	self:PopActivity()
	
	if isvector(start_pos) and isvector(end_pos) then
		local dist = start_pos:Distance( end_pos )
		local ang_dif = (end_angle - start_angle)
		ang_dif:Normalize()
		local ang_dist = math.sqrt( math.pow(ang_dif.pitch,2) + math.pow(ang_dif.yaw,2) + math.pow(ang_dif.roll,2) )
		
		if dist > 5 or ang_dist > 20 then
			self:ClearCnavInaccessableData( cnav )
			return "ok"
		end
	end
	
	-- if we've reached this point, then the prop probably didn't move.
	self:MarkCnavInaccessable( cnav, "unmovable", ent )
	return "failed"
end




function ENT:DealWithBreakable( cnav, ent, data )
	if DEBUG_MOVEMENT:GetBool() then
		print( self, "DealWithBreakable" )
	end

	if not IsValid( ent ) then return "ok" end
	
	self:PushActivity( ACT_IDLE )
	
	self:PlaySequence( "swing" )
	
	self:WaitForAnimToEnd( 0.33 )
	
	if IsValid( ent ) then
		if data.use_bullets then
			local mins = ent:OBBMins()
			local maxs = ent:OBBMaxs()
			local center
			
			if data.obb_is_not_local then
				center = LerpVector( 0.5, mins, maxs )
			else
				local dif = maxs - mins
				center = ent:GetPos() + dif
			end
		
			local bullet_data = {
					Attacker = self,
					Distance = 100,
					Tracer = 0,
					Dir = (center - self:GetHeadPos()):GetNormalized(),
					Src = self:GetHeadPos(),
					IgnoreEntity = self
			}
			
			if DEBUG_MOVEMENT:GetBool() then
				debugoverlay.Line( bullet_data.Src, bullet_data.Src + (bullet_data.Dir * bullet_data.Distance), 2, color_white, true )
			end
			
			self:FireBullets(
				bullet_data
			)
		else
			ent:TakeDamage( 100, self, self )
		end
	end
	
	self:WaitForAnimToEnd( 1.0 )
	
	self:PopActivity()
	
	if data.will_not_despawn or not IsValid( ent ) then
		self:ClearCnavInaccessableData( cnav )
		return "success"
	end
	
	self:MarkCnavInaccessable( cnav, "unbroken", ent )
	return "failed"
end




function ENT:DealWithDoor( cnav, ent, data )
	if DEBUG_MOVEMENT:GetBool() then
		print( self, "DealWithDoor" )
	end

	if not IsValid( ent ) then return "ok" end

	self:PushActivity( ACT_IDLE )
	
	self:PlayGesture( "G_lefthand_punct" )
	
	self:WaitForAnimToEnd( 0.5 )
	
	local start_pos = nil
	local start_angle = nil
	if IsValid( ent ) then
		start_pos = ent:GetPos()
		start_angle = ent:GetAngles()
		ent:Use( self, self, USE_TOGGLE, 1 )
	end
	
	self:WaitForAnimToEnd( 1.0 )
	
	local end_pos = nil
	local end_angle = nil
	if IsValid( ent ) then
		end_pos = ent:GetPos()
		end_angle = ent:GetAngles()
	end
	
	self:PopActivity()
	
	if isvector(start_pos) and isvector(end_pos) then
		local dist = start_pos:Distance( end_pos )
		local ang_dif = (end_angle - start_angle)
		ang_dif:Normalize()
		local ang_dist = math.sqrt( math.pow(ang_dif.pitch,2) + math.pow(ang_dif.yaw,2) + math.pow(ang_dif.roll,2) )
		
		if dist > 5 or ang_dist > 20 then
			self:ClearCnavInaccessableData( cnav )
			return "ok"
		end
	end
	
	-- if we've reached this point, then the door probably didn't move.
	
	return self:DealWithBreakable( cnav, ent, data )
end




function ENT:DealWithObstruction( cnav, ent, data )
	if data.impassable then
		self:MarkCnavInaccessable( cnav, "impassable", ent )
		return "impassable"
	end
	
	if data.is_door then
		local result = self:DealWithDoor( cnav, ent, data )
		if result == "failed" then
			self:MarkCnavInaccessable( cnav, "locked", ent )
		end
		return result
	end
	
	if data.is_physical == true then
		local result = self:DealWithPhysicsProp( cnav, ent, data )
		return result
	end
	
	if data.breakable == true then
		local result = self:DealWithBreakable( cnav, ent, data )
		return result
	end
end




function ENT:EvaluateAndDealWithObstruction()
	-- This method looks a short distance ahead of the Weeping Gman to determine
	-- why they can't move forward.
	
	-- First we figure out which CNav the NextBot is trying to get into.
	local next_cnav = nil
	local current_dist = self.path:GetCursorPosition()

	local next_pos = self.path:GetPositionOnPath( current_dist + 10 )
	local next_cnav = navmesh.GetNearestNavArea( next_pos )
	
	if next_cnav == nil then
		next_cnav = self.current_cnav
	end
	
	local left = nil
	local right = nil
	local back = nil
	local front = nil
	local bottom = nil
	local top = nil
	
	for i = 0,3 do
		local pos = next_cnav:GetCorner( i )
		
		if DEBUG_MOVEMENT:GetBool() then
			print( self, next_cnav, i, pos )
		end
		
		if left == nil or pos.y < left then left = pos.y end
		if right == nil or pos.y > right then right = pos.y end
		
		if back == nil or pos.x < back then back = pos.x end
		if front == nil or pos.x > front then front = pos.x end
		
		if bottom == nil or pos.z < bottom then bottom = pos.z end
		if top == nil or pos.z > top then top = pos.z end
	end
	
	local mins = Vector(back, left, bottom)
	local maxs = Vector(front, right, top+70)
	
	if DEBUG_MOVEMENT:GetBool() then
		debugoverlay.SweptBox( vector_origin, vector_origin, mins, maxs, angle_zero, 2, color_white )
	end
	
	local ent_list = ents.FindInBox( mins, maxs )
	
	local candidates = {}
	
	for i, ent in ipairs( ent_list ) do
		if ent != self and IsValid( ent ) then
			local data = ENT_DATA[ent:GetClass()]
			if data then
				if not data.ignore then
					local dist = nil
					
					if not data.ignore_dist then
						dist = self:GetPos():Distance(ent:GetPos()) - 25 - ent:BoundingRadius()
					end
					
					if dist == nil or dist < 25 then
						table.insert( candidates, {ent, data} )
					end
				end
			else
				print( "WARNING: Found obstruction of unknown class:", ent:GetClass() )
			end
		end
	end
	
	if DEBUG_MOVEMENT:GetBool() then
		PrintTable( candidates )
	end
	
	if #candidates > 0 then
		local pick = candidates[math.random(#candidates)]
		local result = self:DealWithObstruction( next_cnav, pick[1], pick[2] )
		
		if result == "impassable" or result == "failed" then return result end
	end
	
	return "ok"
end




-- Used example from here:
-- https://wiki.garrysmod.com/page/PathFollower/Compute

local COLOR_RED = Color( 255, 0, 0 )
local temp_self = nil

local function PathGenMethod( area, fromArea, ladder, elevator, length )

	if not IsValid( fromArea ) then
		return 0
	else
		if not temp_self.loco:IsAreaTraversable( area ) or area:HasAttributes(NAV_MESH_JUMP) then
			return -1
		else
			if IsValid( area ) then
				local cnav_data = temp_self:GetCnavInaccessableData( area )
				if cnav_data != nil then
					local retry = cnav_data.time + ( 15 * math.pow( 1.5, cnav_data.repeats ) )
					local expires = cnav_data.time + 60 + 2*(retry - cnav_data.time)
					
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
			dist = ( area:GetCenter() - fromArea:GetCenter() ):GetLength()
		end

		local cost = dist + fromArea:GetCostSoFar()

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




function ENT:GiveMovingSpace( options )
	if DEBUG_MOVEMENT:GetBool() then
		print( self, "GiveMovingSpace" )
	end
	
	self:SetupToWalk( true )

	local timeout = CurTime() + ( options.maxage or 5 )

	while CurTime() <= timeout do
		if not self.frozen then
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
	
	local should_run = (self.have_target) or len > self.run_tolerance
	local should_walk = not (self.have_target or self.have_old_target) or math.abs(ang.pitch) > 25 or math.abs(ang.yaw) > 10
	
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
		if not self.frozen then
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
				
				local result = self:EvaluateAndDealWithObstruction()
				
				if result == "impassable" then
					self.loco:ClearStuck()
					self:ResetMotionless()
				else
					if result != "ok" then
						self:MarkCnavInaccessable( self.current_cnav, "unknown", nil )
					end
				
					local result = self:HandleStuck( options )
					
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
	options.tolerance = options.tolerance or 50
	
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
				temp_self = self
				self.path:Compute( self, self.target_last_known_position, PathGenMethod )
				temp_self = nil
			end
			
			-- only move when the animation is a movement type.
			if cur_act[1] == ACT_WALK or cur_act[1] == ACT_RUN then
				self.path:Update( self )
			else
				self:ResetMotionless()
			end

			if ( options.draw ) then self.path:Draw() end
			
			if self.loco:IsStuck() or self.motionless then
				self:PopActivity()
				
				local result = self:EvaluateAndDealWithObstruction()
				
				if result == "impassable" then
					self.loco:ClearStuck()
					self:ResetMotionless()
				else
					if result != "ok" then
						self:MarkCnavInaccessable( self.current_cnav, "unknown", nil )
					end
					
					local result = self:HandleStuck( options )
					
					if result != "ok" then
						result = self:TeleportToNearestSafeSpot()
					end
					
					if result != "ok" then return ( result or "stuck" ) end
				end
				
				self.path = Path( "Follow" ) -- Chase is broken as fuck (?)
				self.path:SetMinLookAheadDistance( options.lookahead or 300 )
				self.path:SetGoalTolerance( options.tolerance )
				temp_self = self
				self.path:Compute( self, self.target_last_known_position, PathGenMethod )
				temp_self = nil
				
				self:SetupToRun( true )
			end
		end

		coroutine.yield()
	end
	
	self:PopActivity()
	return "ok"
end