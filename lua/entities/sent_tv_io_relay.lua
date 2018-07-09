AddCSLuaFile()

DEFINE_BASECLASS( "sent_tv_io_base" )

ENT.PrintName		= "IO: Relay"
ENT.Author			= "raubana"
ENT.Information		= ""
ENT.Category		= "Tunnel Vision"

ENT.Editable		= true
ENT.Spawnable		= true
ENT.AdminOnly		= true
ENT.RenderGroup		= RENDERGROUP_OPAQUE

ENT.NumInputs 		= 2
ENT.NumOutputs 		= 2




list.Add( "TV_IO_ents", "sent_tv_io_relay" )




function ENT:Initialize()
	self:SetModel( "models/tunnelvision/io_models/io_relay.mdl" )
	
	if SERVER then
		self:PhysicsInit(SOLID_VPHYSICS)
		self:GetPhysicsObject():EnableMotion(false)
		
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
	if x == 1 then
		pos = pos + (self:GetForward() * 0.5) + (self:GetRight()*1.75) + (self:GetUp() * 1.75)
	else
		pos = pos + (self:GetForward() * 0.5) + (self:GetRight()*1.75) - (self:GetUp() * 1.75)
	end
	return pos
end




function ENT:GetOutputPos( x )
	local pos = self:GetPos()
	if x == 1 then
		pos = pos + (self:GetForward() * 0.5) - (self:GetRight()*1.75) + (self:GetUp() * 1.75)
	else
		pos = pos + (self:GetForward() * 0.5) - (self:GetRight()*1.75) - (self:GetUp() * 1.75)
	end
	return pos
end




if SERVER then
	
	function ENT:SetOn( silent )
		self.is_on = true
		
		if not silent then self:EmitSound( "buttons/lightswitch2.wav", 75, 175 ) end
		filter = RecipientFilter()
		filter:AddAllPlayers()
		self.sound_loop = CreateSound(
			self,
			"ambient/atmosphere/laundry_amb.wav",
			filter
		)
		self.sound_loop:SetSoundLevel( 65 )
		self.sound_loop:PlayEx(0.1, 255)
		
		self:SetSkin( 1 )
	end
	
	
	
	
	function ENT:SetOff( silent )
		self.is_on = false
	
		if not silent then self:EmitSound( "buttons/lightswitch2.wav", 75, 125 ) end
		if self.sound_loop then
			self.sound_loop:Stop()
		end
		
		self:SetSkin( 0 )
	end
	
	
	
	
	function ENT:KeyValue(key, value)
		if key == "state" then
			self.start_state = tonumber( value )
		elseif key == "is_on" then
			self.start_is_on = tobool( value )
		end
	end
	
	
	
	
	function ENT:Update()
		local old_is_on = self.is_on
		local new_is_on = self:GetInputX(2)
		
		if old_is_on != new_is_on then
			self.is_on = new_is_on
			
			if new_is_on then
				self:SetOn()
			else
				self:SetOff()
			end
		end
	
		if not self:GetInputX( 2 ) then
			self:SetOutputX( 1, false )
			self:SetOutputX( 2, self:GetInputX( 1 ) )
		else
			self:SetOutputX( 1, self:GetInputX( 1 ) )
			self:SetOutputX( 2, false )
		end
		
		self:UpdateIOState()
		
		self:SetInputX( 1, false )
		self:SetInputX( 2, false )
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
	
end