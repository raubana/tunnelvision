include("shared.lua")

AddCSLuaFile("cl_init.lua")




ENT.AlwaysUpdate = false
ENT.InstantUpdate = false




function ENT:SpawnFunction( ply, tr, classname )
	if not tr.Hit then return end
	
	local pos = tr.HitPos + tr.HitNormal * 0.25
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
	self.old_outputs = {}
	self.outputs = {}
	
	self.input_cables = {}
	self.output_cables = {}
	
	for x = 0, self.NumInputs-1 do 
		table.insert( self.inputs, false )
		table.insert( self.input_cables, {} )
	end
	for x = 0, self.NumOutputs-1 do
		table.insert( self.old_outputs, false )
		table.insert( self.outputs, false )
		table.insert( self.output_cables, {} )
	end
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
		self:SetInputX( x+1, tobool( bit.band( state, math.pow( 2, level ) ) ) )
		level = level + 1
	end
	
	for x = 0, self.NumOutputs-1 do
		self:SetOutputX( x+1, tobool( bit.band( state, math.pow( 2, level ) ) ) )
		level = level + 1
	end
end




function ENT:StoreCopyOfOutputs()
	self.old_outputs = table.Copy( self.outputs )
end




function ENT:MarkChangedOutputs()
	for i = 1, self.NumOutputs do
		if self.old_outputs[i] != self.outputs[i] then
			for j, ent in ipairs( self.output_cables[i] ) do
				hook.Call( "TV_IO_MarkEntityToBeUpdated", nil, ent )
			end
		end
	end
end




function ENT:UpdateInputs()
	for i = 1, self.NumInputs do
		local is_high = false
		
		for j, cable in ipairs( self.input_cables[i] ) do
			if IsValid( cable ) then
				if cable:GetHigh() then
					is_high = true
					break
				end
			end
		end
		
		self:SetInputX( i, is_high )
	end
end




function ENT:Update()

end




function ENT:DisconnectInputs( self_is_removed )
	for i = 1, self.NumInputs do
		for j, cable in ipairs( self.input_cables[i] ) do
			if IsValid( cable ) then
				cable:DisconnectOutput( self_is_removed, false )
			end
		end
	end
end




function ENT:DisconnectOutputs( self_is_removed )
	for i = 1, self.NumOutputs do
		for j, cable in ipairs( self.output_cables[i] ) do
			if IsValid( cable ) then
				cable:DisconnectInput( self_is_removed, false )
			end
		end
	end
end




function ENT:DisconnectAll( self_is_removed )
	self:DisconnectInputs( self_is_removed )
	self:DisconnectOutputs( self_is_removed )
end




function ENT:OnRemove()
	self:DisconnectAll( true )
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




-- This is for loading circuits.
function ENT:UnPickle( data, ent_list )
	self:SetPos( data.pos )
	self:SetAngles( data.angles )
	self:SetState( data.state )
	self:DeriveIOFromState()
end