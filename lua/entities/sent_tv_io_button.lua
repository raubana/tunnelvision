AddCSLuaFile()

DEFINE_BASECLASS( "sent_tv_io_base" )

ENT.PrintName		= "IO: Button"
ENT.Author			= "raubana"
ENT.Information		= ""
ENT.Category		= "Tunnel Vision"

ENT.Editable		= true
ENT.Spawnable		= true
ENT.AdminOnly		= true
ENT.RenderGroup		= RENDERGROUP_OPAQUE

ENT.NumInputs 		= 1
ENT.NumOutputs 		= 2




list.Add( "TV_IO_ents", "sent_tv_io_button" )




function ENT:Initialize()
	self:SetModel( "models/props_junk/garbage_metalcan001a.mdl" )
	
	if SERVER then
		self:PhysicsInit(SOLID_VPHYSICS)
		self:GetPhysicsObject():EnableMotion(false)
		
		self:SetUseType( CONTINUOUS_USE )
		
		self:IOInit()
		
		self.is_on = false
		
		self:SetSkin( 0 )
		
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
		end
		
		-- don't worry about is_on; it's going to be false by default in any case.
	end
	
	
	

	function ENT:Use( activator, caller, useType, value )
		self.is_on = true
		
		-- self:EmitSound( "buttons/lightswitch2.wav", 75 )
		
		if self.is_on then
			self:SetSkin( 1 )
		else
			self:SetSkin( 0 )
		end
	end
	
	
	
	
	function ENT:Update()
		if not self.is_on then
			self:SetOutputX( 1, false )
			self:SetOutputX( 2, self:GetInputX( 1 ) )
		else
			self:SetOutputX( 1, self:GetInputX( 1 ) )
			self:SetOutputX( 2, false )
		end
		
		self.is_on = false
		
		self:UpdateIOState()
		
		self:SetInputX( 1, false )
	end
	
end