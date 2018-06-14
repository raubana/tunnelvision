AddCSLuaFile()

DEFINE_BASECLASS( "sent_tv_io_base" )

ENT.PrintName		= "IO: Relay"
ENT.Author			= "raubana"
ENT.Information		= ""
ENT.Category		= "Tunnel Vision"

ENT.Editable		= true
ENT.Spawnable		= true
ENT.AdminOnly		= true
ENT.RenderGroup		= RENDERGROUP_OPAQUE

ENT.NumInputs 		= 2
ENT.NumOutputs 		= 2




list.Add( "TV_IO_ents", "sent_tv_io_relay" )




function ENT:Initialize()
	self:SetModel( "models/props_combine/breenglobe.mdl" )
	
	if SERVER then
		self:PhysicsInit(SOLID_VPHYSICS)
		self:GetPhysicsObject():EnableMotion(false)
		
		self:IOInit()
	end
end




if SERVER then
	
	function ENT:Update()
		if not self:GetInputX( 2 ) then
			self:SetOutputX( 1, false )
			self:SetOutputX( 2, self:GetInputX( 1 ) )
			self:SetColor( self.LOW_COLOR )
		else
			self:SetOutputX( 1, self:GetInputX( 1 ) )
			self:SetOutputX( 2, false )
			self:SetColor( self.HIGH_COLOR )
		end
		
		self:UpdateIOState()
		
		self:SetInputX( 1, false )
		self:SetInputX( 2, false )
	end
	
end