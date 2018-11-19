AddCSLuaFile()

DEFINE_BASECLASS( "base_anim" )

ENT.PrintName		= "Florescent Light"
ENT.Author			= "Raubana"
ENT.Information		= ""
ENT.Category		= "Other"

ENT.Editable		= true
ENT.Spawnable		= true
ENT.AdminOnly		= false
ENT.RenderGroup		= RENDERGROUP_OPAQUE



local RADIUS = math.pow( 2, 7.5 )
local R = 254
local G = 216
local B = 146
local HUM_SOUNDLEVEL = 55
local TINK_SOUNDLEVEL = 60
local HUM_VOLUME = 0.25
local TINK_VOLUME = 0.66




function ENT:Initialize()
	self:DrawShadow( false )
	
	if SERVER then
		self:SetModel( "models/props_interiors/lights_florescent01a.mdl" )
		self:PhysicsInit( SOLID_VPHYSICS )
		self:GetPhysicsObject():EnableMotion( false )
		
		if self.start_disabled then
			self:SetEnabled( false )
			self.start_disabled = nil
		else
			self:SetEnabled( true )
		end
	end
	
	if CLIENT then
		self:SetRenderBounds(Vector(-RADIUS,-RADIUS,-RADIUS),Vector(RADIUS,RADIUS,RADIUS))
		self.LastThink = CurTime()
		
		self.is_on = false
		self.next_toggle = CurTime() + Lerp( math.random(), 0, 2 )
		
		self.flickering = false
		self.flickering_next_toggle = 0
		self.flickering_end = 0
		
		for i = 1, 3 do util.PrecacheSound( "ambient/florescent_light_hum_loop_"..tostring(i)..".wav" ) end
		for i = 1, 4 do util.PrecacheSound( "ambient/florescent_light_on_"..tostring(i)..".wav" ) end
		for i = 1, 7 do util.PrecacheSound( "ambient/florescent_light_off_"..tostring(i)..".wav" ) end
		
		self.sound = CreateSound(self, "ambient/florescent_light_hum_loop_"..tostring(math.random(3))..".wav")
		self.sound:SetSoundLevel( HUM_SOUNDLEVEL )
		self.sound:ChangeVolume( HUM_VOLUME )
	end
end




function ENT:SetupDataTables()
	self:NetworkVar( "Bool", 0, "Enabled" )
end




if SERVER then
	
	function ENT:KeyValue(key, value)
		if key == "StartDisabled" then
			self.start_disabled = tobool( value )
		end
	end
	
	
	
	
	function ENT:AcceptInput( name, activator, caller, data )
		if name == "Enable" then
			self:SetEnabled( true )
		elseif name == "Disable" then
			self:SetEnabled( false )
		end
	end
	
end




function ENT:OnRemove()
	if CLIENT then
		self.sound:Stop()
	end
end




function ENT:UpdateTransmiteState()
	return TRANSMIT_ALWAYS
end




if CLIENT then
	
	function ENT:TurnOn()
		if self.is_on then return end
		self.is_on = true
		
		self:SetSkin( 1 )
		self.sound:Play()
		self.sound:ChangeVolume( HUM_VOLUME )
		
		self:EmitSound( "ambient/florescent_light_on_"..tostring(math.random(4))..".wav", TINK_SOUNDLEVEL, 100, TINK_VOLUME )
	end
	
	
	
	
	function ENT:TurnOff()
		if not self.is_on then return end
		self.is_on = false
		
		self:SetSkin( 0 )
		self.sound:Stop()
		
		self:EmitSound( "ambient/florescent_light_off_"..tostring(math.random(7))..".wav", TINK_SOUNDLEVEL, 100, TINK_VOLUME  )
	end
	
	
	

	function ENT:Think()
		local enabled = self:GetEnabled()
		
		if not enabled then
			
			if self.is_on then
				self:TurnOff()
				self.next_toggle = CurTime()
			end
		
		else
		
			if self.flickering then
				if CurTime() > self.flickering_end then
					self.flickering = false
					self:TurnOn()
				elseif CurTime() > self.flickering_next_toggle then
					if self.is_on then
						self:TurnOff()
						self.flickering_next_toggle = CurTime() + Lerp( math.random(), 0.05, 0.3)
					else
						self:TurnOn()
						self.flickering_next_toggle = CurTime() + Lerp( math.random(), 0.05, 0.1)
					end
				end
			elseif CurTime() >= self.next_toggle then
				if not self.is_on then
					self:TurnOn()
					self.next_toggle = CurTime() + Lerp( math.pow(math.random(),2), 10.0, 0.25 )
					
					if math.random() > 0.5 then
						self.flickering = true
						self.flickering_end = CurTime() + Lerp( math.pow(math.random(),2), 0.25, 1.25 )
					end
				else
					self:TurnOff()
					self.next_toggle = CurTime() + Lerp( math.pow(math.random(),2), 0.5, 3.0 )
				end
			end
			
			local localplayer = LocalPlayer()
			if localplayer and IsValid( localplayer ) and not self:IsDormant() then
				if self.is_on then
					local dlight = DynamicLight( self:EntIndex() )
					if dlight then
						local p = 1
					
						dlight.pos = self:GetPos()-(self:GetUp()*40)
						dlight.r = R*p
						dlight.g = G*p
						dlight.b = B*p
						dlight.brightness = 1
						dlight.Decay = 100
						dlight.Size = RADIUS
						dlight.DieTime = CurTime() + 0.1
					end
				end
			end
		
		end
		
		self:SetNextClientThink(CurTime() + 1/60)
		return true
	end
end