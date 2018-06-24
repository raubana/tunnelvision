local DEBUG_MOVEMENT = GetConVar("rsnb_debug_movement")




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