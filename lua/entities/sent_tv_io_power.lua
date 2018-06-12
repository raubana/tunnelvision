AddCSLuaFile()

DEFINE_BASECLASS( "base_anim" )

ENT.PrintName		= "IO: Power"
ENT.Author			= "raubana"
ENT.Information		= ""
ENT.Category		= "Tunnel Vision"

ENT.Editable		= true
ENT.Spawnable		= true
ENT.AdminOnly		= true
ENT.RenderGroup		= RENDERGROUP_OPAQUE




list.Add( "Tunnel Vision: IO Entities", "sent_tv_io_power" )




function ENT:Initialize()
	self:SetModel( "models/props_c17/streetsign001c.mdl" )
	
	if SERVER then
		self:PhysicsInit(SOLID_VPHYSICS)
		self:GetPhysicsObject():EnableMotion(false)
		
		self.outputs = {true}
	end
end




function ENT:SetupDataTables()
	self:NetworkVar("Bool", 0, "Active", { KeyName = "active", Edit = { type = "Boolean" } })
	
	self:SetActive( true )
end




if SERVER then
	
	function ENT:UpdateI()
		
	end
	
	
	
	
	function ENT:UpdateO() 
		self.outputs[1] = self:GetActive()
	end
	
end





if CLIENT then
	local low_color = Color(0,0,255)
	local high_color = Color(255,0,0)

	function ENT:Draw()
		local c = low_color
		if self:GetActive() then
			c = high_color
		end
		
		self:SetColor( c )
		self:DrawModel()
	end
end