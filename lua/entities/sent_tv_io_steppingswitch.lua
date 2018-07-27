AddCSLuaFile()

DEFINE_BASECLASS( "sent_tv_io_base" )

ENT.PrintName		= "IO: Stepping Switch"
ENT.Author			= "raubana"
ENT.Information		= ""
ENT.Category		= "Tunnel Vision"

ENT.Editable		= true
ENT.Spawnable		= true
ENT.AdminOnly		= true
ENT.RenderGroup		= RENDERGROUP_OPAQUE

ENT.NumInputs 		= 1
ENT.NumOutputs 		= 10




list.Add( "TV_IO_ents", "sent_tv_io_steppingswitch" )




function ENT:Initialize()
	self:SetModel( "models/tunnelvision/io_models/io_steppingswitch.mdl" )
	
	if SERVER then
		self:PhysicsInit(SOLID_VPHYSICS)
		self:GetPhysicsObject():EnableMotion(false)
		
		self:IOInit()
		
		self.last_in = false
		self.locked = false
		self.charge_end = 0
		self.charged = false
		self.changing_charge = false
		self.step_pos = 0
		
		if self.start_state then
			self:SetState( self.start_state )
			self:DeriveIOFromState()
			self.start_state = nil
		end
		
		if self.start_step_pos then
			self.step_pos = self.start_step_pos
			self.start_step_pos = nil
		end
		
		if self.start_charged then
			self.charged = self.start_charged
			self.last_in = self.start_charged
			self.start_charged = nil
		end
		
		if self.start_locked then
			self.locked = self.start_locked
			self.start_locked = nil
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
	if x <= 2 then
		pos = pos + (self:GetForward() * 0.5) - (self:GetRight()*( x - 0.5 ) ) + (self:GetUp() * 3.5)
	elseif x <= 8 then
		pos = pos + (self:GetForward() * 0.5) - (self:GetRight()*2 ) + (self:GetUp() * (-x*1.175 + 6.45 ))
	else
		pos = pos + (self:GetForward() * 0.5) - (self:GetRight()*( -x + 10.5 ) ) + (self:GetUp() * -3.5)
	end
	return pos
end




if SERVER then

	function ENT:KeyValue(key, value)
		if key == "state" then
			self.start_state = tonumber( value )
		elseif key == "step_pos" then
			self.start_step_pos = tonumber( value )
		elseif key == "charged" then
			self.start_charged = tobool( value )
		elseif key == "locked" then
			self.start_locked = tobool( value )
		end
	end
	
	
	
	
	function ENT:UpdateSkin()
		self:SetSkin( self.step_pos )
	end
	
	
	
	
	function ENT:Update()
		self:UpdateInputs()
		self:StoreCopyOfOutputs()
	
		local in1 = self:GetInputX( 1 )
		
		if self.last_in != in1 then
			self.changing_charge = true
			
			if in1 and not self.locked and self.charged and self.step_pos < 11 then
				self.step_pos = self.step_pos + 1
				self:EmitSound( "buttons/lightswitch2.wav", 75, 200 )
				self:UpdateSkin()
			end
		
			if in1 then
				self.charge_end = CurTime() + 0.15
			else
				self.charge_end = CurTime() + 0.25
			end
			
			self.last_in = in1
		elseif self.changing_charge then
			if CurTime() >= self.charge_end then
				self.changing_charge = false
				if in1 then
					self.charged = true
					if self.step_pos > 0 then
						self.locked = true
					end
				else
					self.charged = false
					self.locked = false
					if self.step_pos != 0 then
						self.step_pos = 0
						self:EmitSound( "buttons/lightswitch2.wav", 75, 150 )
						self:UpdateSkin()
					end
				end
			end
		end
		
		if in1 and self.charged and self.locked then
			for x = 1, 10 do
				self:SetOutputX( x, self.step_pos == x )
			end
		else
			for x = 1, 10 do
				self:SetOutputX( x, false )
			end
		end
		
		local is_stable = not self.changing_charge
		if not is_stable then
			hook.Call( "TV_IO_MarkEntityToBeUpdated", nil, self )
		end
		
		self:UpdateIOState()
		self:MarkChangedOutputs()
	end
	
	
	
	
	function ENT:Pickle( ent_list, cable_list )
		local data = {}
		
		data.step_pos = self.step_pos
		data.charged = self.charged
		data.locked = self.locked
		
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
		
		self.step_pos = data.step_pos
		self.charged = data.charged
		self.locked = data.locked
		
		self:UpdateSkin()
	end
	
end