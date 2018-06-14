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

ENT.LOW_COLOR = Color(0,0,64)
ENT.HIGH_COLOR = Color(255,255,0)




function ENT:SetupDataTables()
	self:NetworkVar( "Int", 0, "State" )
end




function ENT:GetConnectionPos( a )
	local pos = self:GetPos()
	local ang = self:GetAngles()
	
	ang:RotateAroundAxis( ang:Forward(), a )
	pos = pos + ang:Right() * 10
	
	return pos
end




function ENT:GetInputPos( x )
	return self:GetConnectionPos( -60 + (x * 15) )
end




function ENT:GetOutputPos( x )
	return self:GetConnectionPos( 240 - (x * 15) )
end