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



local RADIUS = Lerp(0.25,128,512)
local R = 254
local G = 216
local B = 146

function ENT:Initialize()
	if SERVER then
		self:SetModel( "models/props_interiors/lights_florescent01a.mdl" )
		self:PhysicsInitSphere( 2, "metal_bouncy" )
	end
	
	if CLIENT then
		self:SetRenderBounds(Vector(-RADIUS,-RADIUS,-RADIUS),Vector(RADIUS,RADIUS,RADIUS))
		self.LastThink = CurTime()
		
		self.is_on = false
		self.start_on_time = 0
		self.next_toggle = CurTime()
		
		self.sound = CreateSound(self, "ambient/florescent_light_hum_loop.wav")
		self.sound:SetSoundLevel( 60 )
	end
end




function ENT:OnRemove()
	if CLIENT then
		self.sound:Stop()
	end
end




function ENT:Think()
	if CLIENT then
		if CurTime() >= self.next_toggle then
			self.is_on = not self.is_on
			
			if self.is_on then
				self:SetSkin( 1 )
				self.sound:Play()
				self.start_on_time = RealTime()
				self.next_toggle = CurTime() + Lerp( math.pow(math.random(),2), 10.0, 0.25 )
			else
				self:SetSkin( 0 )
				self.sound:Stop()
				self.next_toggle = CurTime() + Lerp( math.pow(math.random(),2), 0.5, 3.0 )
			end
		end
	
		if self.is_on then
			local dlight = DynamicLight( self:EntIndex() )
			if dlight then
				local p = 1
			
				dlight.pos = self:GetPos()-(self:GetUp()*20)
				dlight.r = R*p
				dlight.g = G*p
				dlight.b = B*p
				dlight.brightness = 1
				dlight.Decay = 250
				dlight.Size = RADIUS
				dlight.DieTime = CurTime() + 1
			end
		end
		
		self:SetNextClientThink(CurTime() + 1/25)
		return true
	end
end