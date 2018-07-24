AddCSLuaFile()

DEFINE_BASECLASS( "base_anim" )

ENT.PrintName		= "TV: Message"
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




if SERVER then
	
	function ENT:AcceptInput( name, activator, caller, data )
		if name == "ShowMessage" then
			if engine.ActiveGamemode() == "tunnelvision" then
				GAMEMODE:SendMessage( data )
			end
		end
	end
	
end