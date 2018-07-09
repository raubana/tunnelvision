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
	
	for x = 0, self.NumInputs-1 do table.insert( self.inputs, false ) end
	for x = 0, self.NumOutputs-1 do table.insert( self.outputs, false ) end
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
	
	for x = 0, self.NumInputs-1 do
		if self:GetInputX( x + 1 ) then
			state = state + math.pow( 2, x )
		end
	end
	
	for x = 0, self.NumOutputs-1 do
		if self:GetOutputX( x + 1 ) then
			state = state + math.pow( 2, self.NumInputs + x )
		end
	end
	
	self:SetState( state )
end



function ENT:DeriveIOFromState()
	local level = 0
	local state = self:GetState()
	
	for x = 0, self.NumInputs-1 do
		self:SetInputX( x, tobool( bit.band( state, math.pow( 2, level ) ) ) )
	
		level = level * 2
	end
	
	for x = 0, self.NumOutputs-1 do
		self:SetOutputX( x, tobool( bit.band( state, math.pow( 2, level ) ) ) )
	
		level = level * 2
	end
end




function ENT:Update()

end




-- This is for saving circuits.
function ENT:Pickle( ent_list, cable_list )
	local data = {}
	
	data.class = self:GetClass()
	data.pos = self:GetPos()
	data.angles = self:GetAngles()
	data.state = self:GetState()
	
	return util.TableToJSON( data )
end