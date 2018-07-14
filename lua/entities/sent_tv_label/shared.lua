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
	self:NetworkVar( "Bool", 0, "Editable", { KeyName = "editable", Edit = { type = "Boolean" } } )
	self:NetworkVar( "Bool", 1, "Pickupable", { KeyName = "pickupable", Edit = { type = "Boolean" } } )
	self:NetworkVar( "String", 0, "Message", { KeyName = "message", Edit = { type = "String" } } )
end