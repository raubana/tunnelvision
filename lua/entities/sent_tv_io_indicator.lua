AddCSLuaFile()

DEFINE_BASECLASS( "sent_tv_io_base" )

ENT.PrintName		= "IO: Indicator"
ENT.Author			= "raubana"
ENT.Information		= ""
ENT.Category		= "Tunnel Vision"

ENT.Editable		= true
ENT.Spawnable		= true
ENT.AdminOnly		= true
ENT.RenderGroup		= RENDERGROUP_OPAQUE

ENT.NumInputs 		= 1
ENT.NumOutputs 		= 0

-- ENT.InstantUpdate	= true




list.Add( "TV_IO_ents", "sent_tv_io_indicator" )




function ENT:Initialize()
	self:SetModel( "models/tunnelvision/io_models/io_default.mdl" )
	
	if SERVER then
		if engine.ActiveGamemode() == "sandbox" then
			self:PhysicsInit(SOLID_VPHYSICS)
			self:GetPhysicsObject():EnableMotion(false)
		end
		
		self:IOInit()
		
		if self.start_state then
			self:SetState( self.start_state )
			self:DeriveIOFromState()
			self.start_state = nil
		end
	end
end




function ENT:GetConnectionPos( a )
	return self:GetPos()
end




if SERVER then

	function ENT:KeyValue(key, value)
		if key == "state" then
			self.start_state = tonumber( value )
		end
	end
	
	
	
	
	function ENT:Update()
		self:UpdateInputs()
		self:UpdateIOState()
	end
	
end




if CLIENT then
	
	local matSprite = Material( "sprites/glow04_noz" )
	matSprite:SetString( "$additive", "1" )
	local sprite_size = 5

	function ENT:Draw()
		self:DrawModel()
		
		if self:GetState() > 0 then
			render.SetMaterial(matSprite)
			render.DrawSprite( self:GetPos() + (self:GetForward() * 1.0), sprite_size, sprite_size, color_white )
		end
	end
	
end