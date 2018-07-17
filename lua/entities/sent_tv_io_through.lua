AddCSLuaFile()

DEFINE_BASECLASS( "sent_tv_io_base" )

ENT.PrintName		= "IO: Through"
ENT.Author			= "raubana"
ENT.Information		= ""
ENT.Category		= "Tunnel Vision"

ENT.Editable		= true
ENT.Spawnable		= true
ENT.AdminOnly		= true
ENT.RenderGroup		= RENDERGROUP_OPAQUE

ENT.NumInputs 		= 1
ENT.NumOutputs 		= 1

ENT.InstantUpdate = true




list.Add( "TV_IO_ents", "sent_tv_io_through" )




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
		self:StoreCopyOfOutputs()
	
		self:SetOutputX( 1, self:GetInputX( 1 ) )
		
		self:UpdateIOState()
		self:MarkChangedOutputs()
	end
	
end




if CLIENT then
	
	local DEBUGMODE = GetConVar("tv_io_debug")
	
	
	local matSprite = Material( "sprites/tunnelvision/cable_joint" )
	local size = 0.5
	
	function ENT:Draw()
		if DEBUGMODE:GetBool() then
			self:DrawModel()
		end
		
		render.SetMaterial( matSprite )
		render.DrawSprite( self:GetPos(), size, size, color_black )
	end
	
end