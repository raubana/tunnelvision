AddCSLuaFile()

DEFINE_BASECLASS( "sent_tv_io_base" )

ENT.PrintName		= "IO: Indicator"
ENT.Author			= "raubana"
ENT.Information		= ""
ENT.Category		= "Tunnel Vision"

ENT.Editable		= true
ENT.Spawnable		= true
ENT.AdminOnly		= true
ENT.RenderGroup		= RENDERGROUP_BOTH

ENT.NumInputs 		= 1
ENT.NumOutputs 		= 1

ENT.InstantUpdate	= true




list.Add( "TV_IO_ents", "sent_tv_io_indicator" )




function ENT:Initialize()
	self:SetModel( "models/tunnelvision/io_models/io_indicator.mdl" )
	self:DrawShadow( false )
	
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
		
		self:UpdateSkin()
	end
	
	if CLIENT then
		self.pixvishook = util.GetPixelVisibleHandle()
	end
end




function ENT:GetInputPos( x )
	local pos = self:GetPos()
	pos = pos + (self:GetForward() * 0.5) + (self:GetRight()*1)
	return pos
end




function ENT:GetOutputPos( x )
	local pos = self:GetPos()
	pos = pos + (self:GetForward() * 0.5) - (self:GetRight()*1)
	return pos
end




if SERVER then

	function ENT:KeyValue(key, value)
		if key == "state" then
			self.start_state = tonumber( value )
		end
	end
	
	
	
	
	function ENT:UpdateSkin()
		if self:GetInputX( 1 ) then
			self:SetSkin( 1 )
		else
			self:SetSkin( 0 )
		end
	end
	
	
	
	
	function ENT:Update()
		self:UpdateInputs()
		self:StoreCopyOfOutputs()
		
		self:SetOutputX( 1, self:GetInputX( 1 ) )
		self:UpdateSkin()
		
		self:UpdateIOState()
		self:MarkChangedOutputs()
	end
	
end




local INDICATOR_COLOR = Color(255,0,0)

if CLIENT then
	
	local matSprite = Material( "sprites/glow04_noz" )
	matSprite:SetString( "$additive", "1" )
	local sprite_size = 8
	
	function ENT:DrawTranslucent()
		if self:GetState() > 0 then
			local pos = self:GetPos() + (self:GetForward() * 1.5)
			local p = util.PixelVisible( pos, 1, self.pixvishook )
			
			if p > 0 then
				local c = Color( INDICATOR_COLOR.r * p, INDICATOR_COLOR.g * p, INDICATOR_COLOR.b * p )
			
				cam.IgnoreZ( true )
				render.SetMaterial( matSprite )
				render.DrawSprite( pos, sprite_size, sprite_size, c )
				cam.IgnoreZ( false )
			end
		end
	end
	
end