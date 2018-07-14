AddCSLuaFile()




DEFINE_BASECLASS( "base_anim" )

ENT.PrintName		= "TV: Label"
ENT.Author			= "raubana"
ENT.Information		= ""
ENT.Category		= "Tunnel Vision"

ENT.Editable		= true
ENT.Spawnable		= true
ENT.AdminOnly		= true
ENT.RenderGroup		= RENDERGROUP_OPAQUE




function ENT:SetupDataTables()
	self:NetworkVar( "Bool", 0, "editable", { KeyName = "editable", Edit = { type = "Boolean" } } )
	self:NetworkVar( "Bool", 1, "pickupable", { KeyName = "pickupable", Edit = { type = "Boolean" } } )
	self:NetworkVar( "String", 0, "message", { KeyName = "message", Edit = { type = "String" } } )
end