AddCSLuaFile()

DEFINE_BASECLASS( "sent_tv_io_base" )

ENT.PrintName		= "IO: Power"
ENT.Author			= "raubana"
ENT.Information		= ""
ENT.Category		= "Tunnel Vision"

ENT.Editable		= true
ENT.Spawnable		= true
ENT.AdminOnly		= true
ENT.RenderGroup		= RENDERGROUP_OPAQUE

ENT.NumInputs 		= 0
ENT.NumOutputs 		= 1




list.Add( "TV_IO_ents", "sent_tv_io_power" )




function ENT:Initialize()
	self:SetModel( "models/tunnelvision/io_models/io_default.mdl" )
	
	if SERVER then
		self:PhysicsInit(SOLID_VPHYSICS)
		self:GetPhysicsObject():EnableMotion(false)
		
		self:IOInit()
		
		self.enabled = true
		
		if self.start_disabled then
			self.enabled = false
			self.start_disabled = nil
		end
		
		if self.start_state then
			self:SetState( self.start_state )
			self:DeriveIOFromState()
			self.start_state = nil
		end
	end
end




if SERVER then

	function ENT:KeyValue(key, value)
		if key == "state" then
			self.start_state = tonumber( value )
		elseif key == "StartDisabled" then
			self.start_disabled = tobool( value )
		end
	end
	
	
	
	
	function ENT:AcceptInput( name, activator, caller, data )
		if name == "Enable" then
			self.enabled = true
		elseif name == "Disable" then
			self.enabled = false
		end
	end
	
	
	
	
	function ENT:Update()
		self:SetOutputX( 1, self.enabled )
		self:UpdateIOState()
	end
	
end




if CLIENT then
	
	function ENT:GetConnectionPos( a )
		return self:GetPos()
	end
	
end