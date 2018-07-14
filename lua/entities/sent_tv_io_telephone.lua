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




ENT.DIALRADIUS = 3.57
ENT.DIALHOLERADIUS = 2.85
ENT.HOLERADIUS = 0.6
ENT.DIALPOS_2D = Vector(-0.025,0.85,0)
ENT.FACEHEIGHT = 4.05
ENT.DIALANG = -12




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
	pos = pos + (self:GetForward() * 1) + (self:GetRight()*2)
	return pos
end




function ENT:GetOutputPos( x )
	local pos = self:GetPos()
	pos = pos + (self:GetForward() * 1) - (self:GetRight()*2)
	return pos
end




function ENT:IsOnFace( pos )
	local dif = pos - self:GetPos()
	local ang = self:GetAngles()
	
	local forward = (ang:Forward()):Dot( dif )
	
	return math.abs( forward - self.FACEHEIGHT ) <= 0.1
end




function ENT:Calc2DCursorPos( pos )
	local dif = pos - self:GetPos()
	local ang = self:GetAngles()
	
	local right = ang:Right():Dot( dif )
	local down = (-ang:Up()):Dot( dif )
	
	local cursor_pos_2d = Vector( -right, -down, 0 )
	
	return cursor_pos_2d
end



function ENT:Calc3DCursorPosAndAng( pos_2d )
	local my_ang = self:GetAngles()
	
	local cursor_pos = Vector( 0, pos_2d.x, pos_2d.y )
	cursor_pos = cursor_pos + Vector( self.FACEHEIGHT, 0, 0 )
	cursor_pos:Rotate( my_ang )
	cursor_pos = cursor_pos + self:GetPos()
	
	return cursor_pos, my_ang
end




function ENT:IsOnDial( pos_2d )
	return self.DIALPOS_2D:Distance( pos_2d ) <= self.DIALRADIUS
end




function ENT:CalcDialSection( pos_2d )
	local dif = pos_2d - self.DIALPOS_2D
	local ang = ( math.deg( math.atan2(dif.y, dif.x) ) + self.DIALANG ) % 360.0
	
	local section = math.floor( ang/30 )
	
	if section >= 1 and section <= 10 then return section end
	
	return -1
end




function ENT:Calc2DHolePos( section )
	local ang = math.rad( (( section + 0.5 ) * 30 - self.DIALANG ) % 360.0 )
	
	local hole_pos = self.DIALPOS_2D
	hole_pos = hole_pos + ( Vector( math.cos(ang), math.sin(ang), 0 ) * self.DIALHOLERADIUS )
	
	return hole_pos
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
		
		local is_on_dial = false
		
		if self:IsOnFace( tr.HitPos ) then
			local cursor_pos_2d = self:Calc2DCursorPos( tr.HitPos )
			
			if self:IsOnDial( cursor_pos_2d ) then
				is_on_dial = true
			
				local section = self:CalcDialSection( cursor_pos_2d )
				
				if section > 0 then
					local hole_pos_2d = self:Calc2DHolePos( section )
					local hole_dist = hole_pos_2d:Distance( cursor_pos_2d )
					
					if hole_dist <= self.HOLERADIUS then
						self.unwinding = true
						self.wind_distance = section
						self.next_unwind = CurTime() + 0.1
					end
				end
			end
		end
		
		if not is_on_dial then
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




if CLIENT then

	local COLOR_INDICATOR = Color( 128,0,0 )
	local CURSOR_ENABLE_DIST = 50
	local CURSOR_ENABLE_DIST_SQR = CURSOR_ENABLE_DIST * CURSOR_ENABLE_DIST
	
	local matRing = Material( "indicator/tunnelvision/select_ring" )
	local matDot = Material( "indicator/tunnelvision/select_dot" )
	
	local matSprite = Material( "sprites/glow04_noz" )
	matSprite:SetString( "$additive", "1" )
	local SPRITE_SIZE = 5


	function ENT:Draw()
		self:DrawModel()
		
		-- To indicate when the phone has power and is outputting a high signal.
		if self:GetState() == 3 then
			local pos, ang = self:Calc3DCursorPosAndAng( Vector(3,5,0) )
			pos = pos + ( ang:Forward() * 0.5 )
			render.SetMaterial( matSprite )
			render.DrawSprite( pos, SPRITE_SIZE, SPRITE_SIZE, color_white )
		end
		
		
		local localplayer = LocalPlayer()
		if not IsValid( localplayer ) then return end
		
		local start = localplayer:GetShootPos()
		local dist_sqr = start:DistToSqr( self:GetPos() ) - self:BoundingRadius()
		
		if dist_sqr < CURSOR_ENABLE_DIST_SQR then
			local tr = util.TraceLine( util.GetPlayerTrace( localplayer ) )
			if not tr.Hit or tr.Entity != self then return end
			
			if self:IsOnFace( tr.HitPos ) then
				local cursor_pos_2d = self:Calc2DCursorPos( tr.HitPos )
				
				if self:IsOnDial( cursor_pos_2d ) then
					local section = self:CalcDialSection( cursor_pos_2d )
					
					if section > 0 then
						local hole_pos_2d = self:Calc2DHolePos( section )
						local hole_dist = hole_pos_2d:Distance( cursor_pos_2d )
						
						if hole_dist <= self.HOLERADIUS then
							local cursor_pos, cursor_ang = self:Calc3DCursorPosAndAng( hole_pos_2d )
							
							--debugoverlay.Cross( cursor_pos, 2, 0.1, color_white, true )
							
							render.SetMaterial( matRing )
							render.DrawQuadEasy( cursor_pos, cursor_ang:Forward(), self.HOLERADIUS*2.5, self.HOLERADIUS*2.5, COLOR_INDICATOR, cursor_ang.roll )
						end
					end
				end
				
			end
		end
	end
	
end