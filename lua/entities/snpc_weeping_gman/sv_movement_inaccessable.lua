local DEBUG_MOVEMENT = GetConVar("rsnb_debug_movement")




function ENT:MovementInaccessableInit()
	self.inaccessable_data = {}
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