AddCSLuaFile()

DEFINE_BASECLASS( "sent_tv_io_base" )

ENT.PrintName		= "IO: Telephone"
ENT.Author			= "raubana"
ENT.Information		= ""
ENT.Category		= "Tunnel Vision"

ENT.Editable		= false
ENT.Spawnable		= true
ENT.AdminOnly		= true
ENT.RenderGroup		= RENDERGROUP_OPAQUE

ENT.NumInputs 		= 1
ENT.NumOutputs 		= 1




list.Add( "TV_IO_ents", "sent_tv_io_telephone" )




function ENT:Initialize()
	self:SetModel( "models/tunnelvision/io_models/io_telephone.mdl" )
	
	if SERVER then
		self:PhysicsInit(SOLID_VPHYSICS)
		self:GetPhysicsObject():EnableMotion(false)
		
		self:SetUseType( SIMPLE_USE )
		
		self:IOInit()
		
		self.is_on = false
		
		self.wind_distance = 0
		self.unwinding = false
		self.next_unwind = 0
		
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
	pos = pos + (self:GetForward() * 0.5) + (self:GetRight()*1.75)
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
		if not silent then self:EmitSound( "buttons/lightswitch2.wav", 75, 75 ) end
	end
	
	
	
	
	function ENT:SetOff( silent )
		self.is_on = false
		if not silent then self:EmitSound( "buttons/lightswitch2.wav", 75, 50 ) end
	end
	
	
	
	
	function ENT:Use( activator, caller, useType, value )
		if not caller:IsPlayer() then return end
		
		local tr = util.TraceLine( util.GetPlayerTrace( caller ) )
		if not tr.Hit or tr.Entity != self then return end
		
		local hitpos = tr.HitPos
		local dif = hitpos - self:GetPos()
		local ang = self:GetAngles()
		
		local right = ang:Right():Dot( dif )
		local down = (-ang:Up()):Dot( dif )
		
		local cursor_pos = Vector( -right, -down, 0 )
		
		local dial_pos = Vector(0,1,0)
		local dial_radius = 3.57
		local dial_radius_deadzone = 1.4
		local dial_dif = cursor_pos - dial_pos
		local dial_dist = dial_dif:Length()
		
		if dial_dist <= dial_radius then
			if dial_dist > dial_radius_deadzone then
				local dial_ang = ( math.deg( math.atan2(dial_dif.y, dial_dif.x) ) - 10 ) % 360.0
				
				local section = math.floor( dial_ang/30 )
				
				if section >= 1 and section <= 10 then
					self.unwinding = true
					self.wind_distance = section
					self.next_unwind = CurTime() + 0.25
				end
			end
		else
			self.is_on = not self.is_on
		
			if self.is_on then
				self:SetOn()
			else
				self:SetOff()
			end
		end
	end

	
	
	
	function ENT:KeyValue(key, value)
		if key == "state" then
			self.start_state = tonumber( value )
		elseif key == "is_on" then
			self.start_is_on = tobool( value )
		end
	end

	
	
	
	function ENT:Update()
		local out = false
		
		if self.is_on then
			out = self:GetInputX( 1 )
		end
	
		if self.unwinding then
			if CurTime() >= self.next_unwind then
				self.next_unwind = CurTime() + 0.1
				self:EmitSound( "buttons/lightswitch2.wav", 75, 135 )
				self.wind_distance = self.wind_distance - 1
				out = false
				if self.wind_distance <= 0 then
					self.unwinding = false
				end
			end
		end
		
		self:SetOutputX( 1, out )
		
		self:UpdateIOState()
		
		self:SetInputX( 1, false )
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