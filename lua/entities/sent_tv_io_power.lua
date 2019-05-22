AddCSLuaFile()

DEFINE_BASECLASS( "sent_tv_io_base" )

ENT.PrintName		= "IO: Power"
ENT.Author			= "raubana"
ENT.Information		= ""
ENT.Category		= "Tunnel Vision"

ENT.Editable		= true
ENT.Spawnable		= true
ENT.AdminOnly		= true
ENT.RenderGroup		= RENDERGROUP_OPAQUE

ENT.NumInputs 		= 0
ENT.NumOutputs 		= 1

ENT.InstantUpdate = true




list.Add( "TV_IO_ents", "sent_tv_io_power" )




function ENT:Initialize()
	self:SetModel( "models/tunnelvision/io_models/io_default.mdl" )
	self:DrawShadow( false )
	
	if SERVER then
		if engine.ActiveGamemode() == "sandbox" then
			self:PhysicsInit(SOLID_VPHYSICS)
			self:GetPhysicsObject():EnableMotion(false)
		end
		
		self:IOInit()
		
		if self.start_disabled then
			self:SetEnabled( false )
			self.start_disabled = nil
		else
			self:SetEnabled( true )
		end
		
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




function ENT:SetupDataTables()
	self:NetworkVar( "Int", 0, "State" )
	self:NetworkVar( "Bool", 0, "Enabled", { KeyName = "enabled", Edit = { type = "Boolean"} } )
end




if SERVER then

	function ENT:KeyValue(key, value)
		if key == "state" then
			self.start_state = tonumber( value )
		elseif key == "StartDisabled" then
			self.start_disabled = tobool( value )
		end
	end
	
	
	
	
	function ENT:AcceptInput( name, activator, caller, data )
		if name == "Enable" then
			self:SetEnabled( true )
			hook.Call( "TV_IO_MarkEntityToBeUpdated", nil, self )
		elseif name == "Disable" then
			self:SetEnabled( false )
			hook.Call( "TV_IO_MarkEntityToBeUpdated", nil, self )
		end
	end
	
	
	
	
	function ENT:Update()
		self:StoreCopyOfOutputs()
	
		self:SetOutputX( 1, self:GetEnabled() )
		
		self:UpdateIOState()
		self:MarkChangedOutputs()
	end
	
end




if CLIENT then
	
	local DEBUGMODE = GetConVar("tv_io_debug")
	
	function ENT:Draw()
		if DEBUGMODE and DEBUGMODE:GetBool() then
			self:DrawModel()
		end
	end
	
end