AddCSLuaFile()

DEFINE_BASECLASS( "base_anim" )

ENT.PrintName		= "Tunnel Vision: Fly"
ENT.Author			= "raubana"
ENT.Information		= "Hello, my name is..."
ENT.Category		= "Tunnel Vision"

ENT.Editable		= false
ENT.Spawnable		= true
ENT.AdminOnly		= true
ENT.RenderGroup		= RENDERGROUP_OPAQUE



function ENT:Initialize()
	self:SetModel("models/props_junk/watermelon01.mdl")
	self:SetModelScale( 0.1 )
	self:DrawShadow( false )
	
	if SERVER then
		self.sound_pitch = Lerp( math.random(), 75, 125 )
	
		self:PhysicsInitSphere( 0.25, "antlion" )
		self:SetCollisionGroup( COLLISION_GROUP_DEBRIS )
		
		self:GetPhysicsObject():SetMass( 1 )
		
		-- states:
		-- 0 = Standing on a surface.
		-- 1 = Flying.
		-- 2 = Flying but wants to land.
		
		self.stage = 0
		self.next_stage_change = 0
		
		self.target_next_update = 0
		self.target_update_freq = 0.5
		
		self.flight_target_pos = self:GetPos() + Vector(0,0,10)
		self.flight_force = Vector(0,0,0)
		self.flight_update_freq = 0.5
		self.flight_next_update = 0
		
		self.parent_offset = Vector(0,0,0)
	end
end




if SERVER then
	function ENT:StartFlyingSound()
		if not self.sound then
			local filter = RecipientFilter()
			filter:AddAllPlayers()
			self.sound = CreateSound(self, "npc/sent_tv_fly/fly_loop.wav", filter)
			self.sound:SetSoundLevel( 60 )
			
			self.sound:PlayEx(1.0, self.sound_pitch)
		end
	end
	
	
	
	function ENT:StopFlyingSound()
		if self.sound then
			self.sound:Stop()
			self.sound = nil
		end
	end
	
	
	
	
	function ENT:OnRemove()
		self:StopFlyingSound()
	end
	
	
	
	
	function ENT:OnTakeDamage( dmg )
		SafeRemoveEntity( self )
	end
	
	
	
	
	function ENT:Think()
		if CurTime() >= self.next_stage_change then
			if self.stage == 0 then
				self.stage = 1
				self:SetParent( nil )
				self:StartFlyingSound()
				self.next_stage_change = CurTime() + Lerp(math.random(), 1, 5)
			elseif self.stage == 1 then
				self.stage = 2
			end
		end
		
		if self.stage == 1 or self.stage == 2 then
			local phys_obj = self:GetPhysicsObject()
			
			if CurTime() >= self.target_next_update then
				self.target_next_update = CurTime() + self.target_update_freq
				
				local tr = util.TraceLine({
					start = self:GetPos(),
					endpos = self:GetPos() + (VectorRand() * 500),
					filter = self,
					mask = MASK_OPAQUE
				})
				
				local change_target = math.random() > 0.75
				
				if not change_target then
					if tr.Hit and tr.Entity and IsValid(tr.Entity) then
						if not tr.Entity:IsWorld() then
							self.flight_target_pos = tr.HitPos
						end
					end
				else
					if self.stage == 2 then
						self.flight_target_pos = tr.HitPos
					else
						self.flight_target_pos = LerpVector( math.random(), tr.HitPos, tr.StartPos )
					end
				end
			end
		
			if CurTime() >= self.flight_next_update then
				-- debugoverlay.Cross( self.flight_target_pos, 1, self.flight_update_freq, color_white, true )
			
				self.flight_next_update = CurTime() + self.flight_update_freq
				
				local gravity_comp = -physenv.GetGravity()
				
				local vel_comp =(-self:GetVelocity() / self.flight_update_freq) * math.pow( Lerp(math.random(), 0.75, 1.22 ), 2 )
				
				local offset_comp = (self.flight_target_pos - self:GetPos()) * 10
				local offset_comp_magn = offset_comp:Length()
				
				if offset_comp_magn > 500 then
					offset_comp = 500*offset_comp/offset_comp_magn
				end
				
				local force = gravity_comp + vel_comp + offset_comp
				local force_magn = force:Length()
				force = force + ( (VectorRand() * force_magn * 0.025) / self.flight_update_freq)
				
				self.flight_force = force * phys_obj:GetMass() * engine.TickInterval()
			end
			
			phys_obj:ApplyForceCenter( self.flight_force )
			
			self:NextThink( CurTime())
			return true
		end
	end
	
	
	
	function ENT:PhysicsCollide( colData, collider )
		if self.stage == 2 and isvector( colData.HitPos ) then
			local dist = colData.HitPos:Distance(self:GetPos())
			
			if dist < 1 then
				self.stage = 0
				self.next_stage_change = CurTime() + Lerp(math.random(), 5, 10)
				self:StopFlyingSound()
				self:SetParent( collider )
			end
		end
	end
end




if CLIENT then
	local matFlySprite = Material( "sprites/tunnelvision/fly" )
	local SIZE = 2

	function ENT:Draw()
		local light = render.GetLightColor( self:GetPos() ) * 255 * 2
		
		local color = Color(
								math.min( light.x, 255),
								math.min( light.y, 255),
								math.min( light.z, 255)
							)
	
		render.SetMaterial( matFlySprite )
		render.DrawSprite( self:GetPos(), SIZE, SIZE, color )
	end
end