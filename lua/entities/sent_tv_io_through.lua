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




list.Add( "TV_IO_ents", "sent_tv_io_through" )




function ENT:Initialize()
	self:SetModel( "models/tunnelvision/io_models/io_default.mdl" )
	
	if SERVER then
		self:PhysicsInit(SOLID_VPHYSICS)
		self:GetPhysicsObject():EnableMotion(false)
		
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
		self:SetOutputX( 1, self:GetInputX( 1 ) )
		self:UpdateIOState()
		self:SetInputX( 1, false )
	end
	
end




if CLIENT then
	
	local DEBUGMODE = GetConVar("tv_io_debug")

	function ENT:Draw()
		if DEBUGMODE:GetBool() then
			self:DrawModel()
		end
	end
	
end