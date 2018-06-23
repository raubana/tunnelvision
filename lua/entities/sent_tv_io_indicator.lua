AddCSLuaFile()

DEFINE_BASECLASS( "sent_tv_io_base" )

ENT.PrintName		= "IO: Indicator"
ENT.Author			= "raubana"
ENT.Information		= ""
ENT.Category		= "Tunnel Vision"

ENT.Editable		= true
ENT.Spawnable		= true
ENT.AdminOnly		= true
ENT.RenderGroup		= RENDERGROUP_OPAQUE

ENT.NumInputs 		= 1
ENT.NumOutputs 		= 0




list.Add( "TV_IO_ents", "sent_tv_io_indicator" )




function ENT:Initialize()
	self:SetModel( "models/props_junk/PopCan01a.mdl" )
	
	if SERVER then
		self:PhysicsInit(SOLID_VPHYSICS)
		self:GetPhysicsObject():EnableMotion(false)
		
		self:IOInit()
	end
end




function ENT:GetConnectionPos( a )
	return self:GetPos()
end




if SERVER then
	
	function ENT:Update() 
		self:UpdateIOState()
		self:SetInputX( 1, false )
	end
	
end




if CLIENT then
	local matSprite = Material( "sprites/glow04_noz" )
	matSprite:SetString( "$additive", "1" )
	local sprite_size = 25

	function ENT:Draw()
		self:DrawModel()
		
		if self:GetState() > 0 then
			render.SetMaterial(matSprite)
			render.DrawSprite( self:GetPos() + (self:GetForward() * 3), sprite_size, sprite_size, color_white )
		end
	end
	
end