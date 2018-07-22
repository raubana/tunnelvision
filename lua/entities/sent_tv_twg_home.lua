AddCSLuaFile()

DEFINE_BASECLASS( "base_anim" )

ENT.PrintName		= "The Weeping Gman Home"
ENT.Author			= "Raubana"
ENT.Information		= ""
ENT.Category		= "Other"

ENT.Editable		= false
ENT.Spawnable		= false
ENT.AdminOnly		= false
ENT.RenderGroup		= RENDERGROUP_OTHER







function ENT:Initialize()
	self:SetNoDraw(true)
	self:DrawShadow(false)
	self:SetSolid(SOLID_NONE)
	self:SetMoveType(MOVETYPE_NONE)
end