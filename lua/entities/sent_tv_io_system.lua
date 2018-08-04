AddCSLuaFile()

DEFINE_BASECLASS( "sent_tv_io_base" )

ENT.PrintName		= "IO: System"
ENT.Author			= "raubana"
ENT.Information		= ""
ENT.Category		= "Tunnel Vision"

ENT.Editable		= true
ENT.Spawnable		= true
ENT.AdminOnly		= true
ENT.RenderGroup		= RENDERGROUP_OPAQUE

ENT.NumInputs 		= 1
ENT.NumOutputs 		= 0

ENT.InstantUpdate = true


list.Add( "TV_IO_ents", "sent_tv_io_system" )




function ENT:Initialize()
	self:SetModel( "models/tunnelvision/io_models/io_default.mdl" )
	self:DrawShadow( false )
	
	if SERVER then
		if engine.ActiveGamemode() == "sandbox" then
			self:PhysicsInit(SOLID_VPHYSICS)
			self:GetPhysicsObject():EnableMotion(false)
		end
		
		self:IOInit()
		
		self.is_on = false
		
		if self.start_state then
			self:SetState( self.start_state )
			self:DeriveIOFromState()
			self.start_state = nil
		end
		
		if self.start_is_on then
			self.is_on = start_is_on
			self.start_is_on = nil
		end
	end
end




function ENT:GetConnectionPos( a )
	return self:GetPos()
end




if SERVER then

	function ENT:KeyValue(key, value)
		if key == "OnLowToHigh" or key == "OnHighToLow" then
			self:StoreOutput(key, value)
		elseif key == "state" then
			self.start_state = tonumber( value )
		elseif key == "is_on" then
			self.start_is_on = tobool( value )
		end
	end
	
	
	
	
	function ENT:Update()
		self:UpdateInputs()
		
		local new_input = self:GetInputX( 1 )
		
		if self.is_on != new_input then
			if not new_input then
				self:TriggerOutput("OnHighToLow", self)
			else
				self:TriggerOutput("OnLowToHigh", self)
			end
		end
		
		self.is_on = new_input
		
		self:UpdateIOState()
	end
	
	
	
	
	function ENT:Pickle( ent_list, cable_list )
		local data = {}
		
		data.is_on = self.is_on
		
		data.class = self:GetClass()
		data.pos = self:GetPos()
		data.angles = self:GetAngles()
		data.state = self:GetState()
		
		return util.TableToJSON( data )
	end
	
	
	
	
	function ENT:UnPickle( data, ent_list )
		self:SetPos( data.pos )
		self:SetAngles( data.angles )
		self:SetState( data.state )
		self:DeriveIOFromState()
		
		self.is_on = data.is_on
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