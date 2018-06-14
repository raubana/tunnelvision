include("shared.lua")

AddCSLuaFile("cl_init.lua")




function ENT:SpawnFunction( ply, tr, classname )
	if not tr.Hit then return end
	
	local pos = tr.HitPos + tr.HitNormal * 2
	local ang = tr.HitNormal:Angle()

	local ent = ents.Create( ClassName )
	ent:SetPos( pos )
	ent:SetAngles( ang )
	ent:Spawn()
	ent:Activate()

	return ent
end




function ENT:IOInit()
	self.inputs = {}
	self.outputs = {}
	
	for x = 1, self.NumInputs do table.insert( self.inputs, false ) end
	for x = 1, self.NumOutputs do table.insert( self.outputs, false ) end
end




function ENT:GetInputX( x )
	if x >= 1 and x <= self.NumInputs then
		return self.inputs[x] == true
	end
	return false
end




function ENT:GetOutputX( x )
	if x >= 1 and x <= self.NumOutputs then
		return self.outputs[x] == true
	end
	return false
end




function ENT:SetInputX( x, val )
	if x >= 1 and x <= self.NumInputs then
		self.inputs[x] = val
	end
end




function ENT:SetOutputX( x, val )
	if x >= 1 and x <= self.NumOutputs then
		self.outputs[x] = val
	end
end




function ENT:UpdateIOState()
	local state = 0
	
	for x = 1, self.NumInputs do
		if self:GetInputX( x ) then
			state = state + math.pow( 2, x )
		end
	end
	
	for x = 1, self.NumOutputs do
		if self:GetOutputX( x ) then
			state = state + math.pow( 2, self.NumInputs + x )
		end
	end
	
	self:SetState( state )
end



function ENT:Update()

end