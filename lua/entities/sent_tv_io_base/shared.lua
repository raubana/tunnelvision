AddCSLuaFile()




DEFINE_BASECLASS( "base_anim" )

ENT.PrintName		= "IO: BASE"
ENT.Author			= "raubana"
ENT.Information		= ""
ENT.Category		= "Tunnel Vision"

ENT.Editable		= true
ENT.Spawnable		= false
ENT.AdminOnly		= true
ENT.RenderGroup		= RENDERGROUP_OPAQUE

ENT.NumInputs 		= 0
ENT.NumOutputs 		= 0

ENT.LOW_COLOR = Color(0,0,255)
ENT.HIGH_COLOR = Color(255,0,0)




function ENT:SetupDataTables()
	self:NetworkVar( "Int", 0, "State" )
end