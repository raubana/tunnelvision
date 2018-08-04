AddCSLuaFile()

DEFINE_BASECLASS( "sent_tv_io_base" )

ENT.PrintName		= "IO: Switch"
ENT.Author			= "raubana"
ENT.Information		= ""
ENT.Category		= "Tunnel Vision"

ENT.Editable		= true
ENT.Spawnable		= true
ENT.AdminOnly		= true
ENT.RenderGroup		= RENDERGROUP_OPAQUE

ENT.NumInputs 		= 1
ENT.NumOutputs 		= 2

ENT.InstantUpdate	= true




list.Add( "TV_IO_ents", "sent_tv_io_switch" )




function ENT:Initialize()
	self:SetModel( "models/tunnelvision/io_models/io_switch.mdl" )
	self:DrawShadow( false )
	
	if SERVER then
		self:PhysicsInit(SOLID_VPHYSICS)
		self:GetPhysicsObject():EnableMotion(false)
		
		self:SetUseType( SIMPLE_USE )
		
		self:IOInit()
		
		self.is_on = false
		self:SetSkin( 0 )
		
		if self.start_state then
			self:SetState( self.start_state )
			self:DeriveIOFromState()
			self.start_state = nil
		end
		
		if self.start_is_on then
			self:SetOn( true )
			self.start_is_on = nil
		end
	end
end




function ENT:GetInputPos( x )
	local pos = self:GetPos()
	pos = pos + (self:GetForward() * 0.5) + (self:GetRight()*2)
	return pos
end




function ENT:GetOutputPos( x )
	local pos = self:GetPos()
	if x == 1 then
		pos = pos + (self:GetForward() * 0.5) - (self:GetRight()*2) + (self:GetUp() * 1.75)
	else
		pos = pos + (self:GetForward() * 0.5) - (self:GetRight()*2) - (self:GetUp() * 1.75)
	end
	return pos
end




if SERVER then
	
	function ENT:SetOn( silent )
		self.is_on = true
		if not silent then self:EmitSound( "buttons/lightswitch2.wav", 75 ) end
		self:SetSkin( 1 )
	end
	
	
	
	
	function ENT:SetOff( silent )
		self.is_on = false
		if not silent then self:EmitSound( "buttons/lightswitch2.wav", 75 ) end
		self:SetSkin( 0 )
	end
	
	
	
	
	function ENT:Use( activator, caller, useType, value )
		self.is_on = not self.is_on
		
		if self.is_on then
			self:SetOn()
			self:TriggerOutput("OnSwitchedOn", self)
			if self:GetInputX(1) == true then
				self:TriggerOutput("OnSwitchedOnHasPower", self)
			else
				self:TriggerOutput("OnSwitchedOnHasNoPower", self)
			end
		else
			self:SetOff()
			self:TriggerOutput("OnSwitchedOff", self)
			if self:GetInputX(1) == true then
				self:TriggerOutput("OnSwitchedOffHasPower", self)
			else
				self:TriggerOutput("OnSwitchedOffHasNoPower", self)
			end
		end
		
		self:TriggerOutput("OnSwitchChange", self)
		
		hook.Call( "TV_IO_MarkEntityToBeUpdated", nil, self )
	end

	
	
	
	function ENT:KeyValue(key, value)
		if key == "OnSwitchedOn" or key == "OnSwitchedOff" or key == "OnSwitchChange" or
		key == "OnSwitchedOnHasPower" or key == "OnSwitchedOnHasNoPower" or 
		key =="OnSwitchedOffHasPower" or key =="OnSwitchedOffHasNoPower" or key =="OnChange" then
			self:StoreOutput(key, value)
		elseif key == "state" then
			self.start_state = tonumber( value )
		elseif key == "is_on" then
			self.start_is_on = tobool( value )
		end
	end

	
	
	
	function ENT:Update()
		self:UpdateInputs()
		self:StoreCopyOfOutputs()
	
		if not self.is_on then
			self:SetOutputX( 1, false )
			self:SetOutputX( 2, self:GetInputX( 1 ) )
		else
			self:SetOutputX( 1, self:GetInputX( 1 ) )
			self:SetOutputX( 2, false )
		end
		
		local old_state = self:GetState()
		self:UpdateIOState()
		local new_state = self:GetState()
		
		if old_state != new_state then
			self:TriggerOutput("OnChange", self)
		end
		
		self:MarkChangedOutputs()
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