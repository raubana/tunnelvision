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
	self:SetModel( "models/props_borealis/door_wheel001a.mdl" )
	
	if SERVER then
		self:PhysicsInit(SOLID_VPHYSICS)
		self:GetPhysicsObject():EnableMotion(false)
		
		self:IOInit()
	end
end




if SERVER then
	
	function ENT:Update()
		self:SetOutputX( 1, true )
		self:UpdateIOState()
	end
	
end




if CLIENT then
	
	function ENT:GetConnectionPos( a )
		return self:GetPos()
	end
	
end