AddCSLuaFile()

DEFINE_BASECLASS( "sent_tv_io_base" )

ENT.PrintName		= "IO: Switch"
ENT.Author			= "raubana"
ENT.Information		= ""
ENT.Category		= "Tunnel Vision"

ENT.Editable		= true
ENT.Spawnable		= true
ENT.AdminOnly		= true
ENT.RenderGroup		= RENDERGROUP_OPAQUE

ENT.NumInputs 		= 1
ENT.NumOutputs 		= 2




list.Add( "TV_IO_ents", "sent_tv_io_switch" )




function ENT:Initialize()
	self:SetModel( "models/tunnelvision/io_models/io_switch.mdl" )
	
	if SERVER then
		self:PhysicsInit(SOLID_VPHYSICS)
		self:GetPhysicsObject():EnableMotion(false)
		
		self:SetUseType( SIMPLE_USE )
		
		self:IOInit()
		
		self.is_on = false
		
		self:SetSkin( 0 )
	end
end




function ENT:Use( activator, caller, useType, value )
	self.is_on = not self.is_on
	
	self:EmitSound( "buttons/lightswitch2.wav", 75 )
	
	if self.is_on then
		self:SetSkin( 1 )
	else
		self:SetSkin( 0 )
	end
end




function ENT:GetInputPos( x )
	local pos = self:GetPos()
	pos = pos + (self:GetForward() * 0.5) + (self:GetRight()*1.75)
	return pos
end




function ENT:GetOutputPos( x )
	local pos = self:GetPos()
	if x == 1 then
		pos = pos + (self:GetForward() * 0.5) - (self:GetRight()*1.75) + (self:GetUp() * 1.75)
	else
		pos = pos + (self:GetForward() * 0.5) - (self:GetRight()*1.75) - (self:GetUp() * 1.75)
	end
	return pos
end




if SERVER then
	
	function ENT:Update()
		if not self.is_on then
			self:SetOutputX( 1, false )
			self:SetOutputX( 2, self:GetInputX( 1 ) )
		else
			self:SetOutputX( 1, self:GetInputX( 1 ) )
			self:SetOutputX( 2, false )
		end
		
		self:UpdateIOState()
		
		self:SetInputX( 1, false )
		self:SetInputX( 2, false )
	end
	
end