AddCSLuaFile()

DEFINE_BASECLASS( "base_anim" )

ENT.PrintName		= "TV: Death Counter"
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
	
	function ENT:KeyValue(key, value)
		if key == "TotalOut" then
			self:StoreOutput(key, value)
		end
	end
	
	
	
	
	function ENT:AcceptInput( name, activator, caller, data )
		if name == "OutputDeathCount" then
			local convar = GetConVar("tv_deathcount")
			local count
			if not convar then
				count = 0
			else
				count = convar:GetInt()
			end
		
			self:TriggerOutput( "TotalOut", self, count )
		end
	end
	
end