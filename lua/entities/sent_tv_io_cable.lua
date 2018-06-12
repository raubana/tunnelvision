AddCSLuaFile()

DEFINE_BASECLASS( "base_anim" )

ENT.PrintName		= "IO: Cable"
ENT.Author			= "raubana"
ENT.Information		= ""
ENT.Category		= "Tunnel Vision"

ENT.Editable		= true
ENT.Spawnable		= true
ENT.AdminOnly		= true
ENT.RenderGroup		= RENDERGROUP_OPAQUE




list.Add( "Tunnel Vision: IO Entities", "sent_tv_io_cable" )




function ENT:Initialize()
	self:SetModel( "models/props_c17/streetsign004f.mdl" )
	
	if SERVER then
		self:PhysicsInit(SOLID_VPHYSICS)
		self:GetPhysicsObject():EnableMotion(false)
	end
end




function ENT:SetupDataTables()
	self:NetworkVar("Entity", 0, "InputEnt")
	self:NetworkVar("Int", 0, "InputID", { KeyName = "i_id", Edit = { type = "Int", min = 1, max = 32 } })
	self:NetworkVar("Entity", 1, "OutputEnt")
	self:NetworkVar("Int", 1, "OutputID", { KeyName = "o_id", Edit = { type = "Int", min = 1, max = 32 } })
	self:NetworkVar("Bool", 0, "High")
	
	self:SetInputID( 1 )
	self:SetOutputID( 1 )
end




if SERVER then
	
	function ENT:UpdateI()
		local is_high = false
		
		local start_ent = self:GetInputEnt()
		if start_ent and IsValid( start_ent ) then
			is_high = start_ent.outputs[self:GetInputID()] == true
		end
		
		self:SetHigh(is_high)
	end
	
	
	
	
	function ENT:UpdateO()
		if self:GetHigh() then
			local end_ent = self:GetOutputEnt()
			if end_ent and IsValid( end_ent ) then
				end_ent.inputs[self:GetOutputID()] = true
			end
		end
	end
	
end




if CLIENT then
	local beam_mat = Material( "cable/rope" )
	local low_color = Color(0,0,255)
	local high_color = Color(255,0,0)

	function ENT:Draw()
		local c = low_color
		if self:GetHigh() then
			c = high_color
		end
		
		self:SetColor( c )
		self:DrawModel()
		
		local start_ent = self:GetInputEnt()
		if start_ent and IsValid( start_ent ) then
			render.SetMaterial(beam_mat)
			render.DrawBeam(start_ent:GetPos(), self:GetPos(), 1, 0, 1, c)
		end
		
		local end_ent = self:GetOutputEnt()
		if end_ent and IsValid( end_ent ) then
			render.SetMaterial(beam_mat)
			render.DrawBeam(self:GetPos(), end_ent:GetPos(), 1, 0, 1, c)
		end
	end
end