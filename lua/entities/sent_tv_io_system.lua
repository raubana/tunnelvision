AddCSLuaFile()

DEFINE_BASECLASS( "base_anim" )

ENT.PrintName		= "IO: System"
ENT.Author			= "raubana"
ENT.Information		= ""
ENT.Category		= "Tunnel Vision"

ENT.Editable		= true
ENT.Spawnable		= true
ENT.AdminOnly		= true
ENT.RenderGroup		= RENDERGROUP_OPAQUE




list.Add( "Tunnel Vision: IO Entities", "sent_tv_io_system" )




function ENT:Initialize()
	self:SetModel( "models/props_c17/streetsign003b.mdl" )
	
	if SERVER then
		self:PhysicsInit(SOLID_VPHYSICS)
		self:GetPhysicsObject():EnableMotion(false)
		
		self.inputs = {false}
	end
end




function ENT:SetupDataTables()
	self:NetworkVar("Bool", 0, "High")
end




if SERVER then

	function ENT:UpdateI()
		self.inputs[1] = false
	end
	
	
	
	
	function ENT:UpdateO() 
		self:SetHigh( self.inputs[1] )
	end
	
end




if CLIENT then
	local low_color = Color(0,0,255)
	local high_color = Color(255,0,0)

	function ENT:Draw()
		local c = low_color
		if self:GetHigh() then
			c = high_color
		end
		
		self:SetColor( c )
		self:DrawModel()
	end
end