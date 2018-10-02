AddCSLuaFile()

DEFINE_BASECLASS( "base_anim" )

ENT.PrintName		= "Tunnel Vision: Fly"
ENT.Author			= "raubana"
ENT.Information		= "buzz"
ENT.Category		= "Tunnel Vision"

ENT.Editable		= false
ENT.Spawnable		= true
ENT.AdminOnly		= true
ENT.RenderGroup		= RENDERGROUP_OPAQUE




local COUNTER = 1
local TOTAL = 5


local STAGE_STANDING = 0
local STAGE_FLYING_GIVING_SPACE = 1
local STAGE_FLYING = 2
local STAGE_FLYING_WANTS_TO_LAND = 3

local SPACE = 50

local FORCE_FLY = false
local FORCE_HOVER = false
local DEBUG_MODE = false -- hehe, de-bug.




function ENT:Initialize()
	self:SetModel("models/props_junk/watermelon01.mdl")
	self:SetModelScale( 0.1 )
	self:DrawShadow( false )
	
	self:SetMoveType( MOVETYPE_NONE )
	
	if SERVER then
		self.prev_pos = self:GetPos()
		self.vel = Vector(0,0,0)
	
		self.sound_pitch = 100 + Lerp( math.random(), -9, 9 ) + Lerp( math.random(), -7, 7 ) + Lerp( math.random(), -5, 5 ) + Lerp( math.random(), -3, 3 ) + Lerp( math.random(), -1, 1 )
		
		self.lowCPUmode = false
		self.lowCPUmode_interval = 0.75
		
		self.stage = STAGE_STANDING
		self.next_stage_change = CurTime() + Lerp(  math.random(), 1, 5 )
		
		self.spooked = false
		self.spook_radius = 75
		
		self.tired = false
		self.tired_end = 0
		
		self.target_next_update = 0
		self.target_update_interval_standing = 0.33
		self.target_update_interval = 1.5
		self.target_update_interval_lowcpu = 3.0
		self.target = nil
		
		self.target_trace_dist = 250
		self.target_gain_dist = 75
		self.target_lose_dist = 85
		
		self.flight_target_pos = self:GetPos() + Vector(0,0,10)
		self.flight_force = Vector(0,0,0)
		self.flight_update_interval = 0.33
		self.flight_update_interval_lowcpu = 0.75
		self.flight_next_update = 0
		
		self.dead = false
	
	elseif CLIENT then
		
		for i = 1, TOTAL do util.PrecacheSound( "npc/sent_tv_fly/fly_loop"..tostring(i)..".wav" ) end
		
	end
end




if SERVER then

	function ENT:StartFlyingSound()
		if not self.sound then
			local filter = RecipientFilter()
			filter:AddAllPlayers()
			self.sound = CreateSound(self, "npc/sent_tv_fly/fly_loop"..tostring(COUNTER)..".wav", filter)
			self.sound:SetSoundLevel( 40 )
			
			COUNTER = COUNTER + 1
			if COUNTER > TOTAL then
				COUNTER = 1
			end
			
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
		self.dead = true
		self:StopFlyingSound()
	end
	
	
	
	
	function ENT:OnTakeDamage( dmg )
		SafeRemoveEntity( self )
	end
	
	
	
	
	function ENT:IsMaterialTypeILike( matType )
		return matType == MAT_ALIENFLESH or matType == MAT_BLOODYFLESH or matType == MAT_FLESH
	end
	
	
	
	
	function ENT:UpdateLowCPUmode()
		local old_state = self.lowCPUmode
		
		local ply_list = player.GetAll()
		for i, ply in ipairs(ply_list) do
			local dist_sqr = ply:GetPos():DistToSqr( self:GetPos() )
			if dist_sqr < 5000000 then
				self.lowCPUmode = false
				if DEBUG_MODE and old_state == true then
					print( self, "I am no longer in low CPU mode." )
				end
				return
			end
		end
		
		self.lowCPUmode = true
		if DEBUG_MODE and old_state == false then
			print( self, "I am now in low CPU mode." )
		end
	end
	
	
	
	
	function ENT:Think()
		if self.dead then return end
		
		if DEBUG_MODE then
			print( self, self.stage )
		end
		
		if not self:IsInWorld() or bit.band( util.PointContents( self:GetPos() ), CONTENTS_WATER) > 0 then
			SafeRemoveEntity( self )
			return
		end
	
		if self.lowCPUmode then
			self:UpdateLowCPUmode()
		end
		
		if self.stage == STAGE_STANDING and self.tired and CurTime() >= self.tired_end then
			self.tired = false
		end
		
		if not FORCE_FLY then
			if CurTime() >= self.next_stage_change then
				if self.stage == STAGE_STANDING then
					self.stage = STAGE_FLYING_GIVING_SPACE
					self:SetParent( nil )
					self.prev_pos = self:GetPos()
					self.vel = Vector( 0, 0, 0 )
					self:StartFlyingSound()
					if self.lowCPUmode then
						self.next_stage_change = CurTime() + Lerp(math.random(), 2, 10)
					else
						self.next_stage_change = CurTime() + Lerp(math.random(), 0.25, 0.5)
					end
					self.target_next_update = 0
					self.flight_next_update = 0
				elseif self.stage == STAGE_FLYING_GIVING_SPACE then
					self.stage = STAGE_FLYING
					if not self.tired then
						self.next_stage_change = CurTime() + Lerp(math.random(), 5, 7)
					else
						self.next_stage_change = CurTime() + Lerp(math.random(), 0.5, 1.0)
					end
				elseif self.stage == STAGE_FLYING then
					self.stage = STAGE_FLYING_WANTS_TO_LAND
					if not self.tired then
						self.next_stage_change = CurTime() + Lerp(math.random(), 10, 15)
					else
						self.next_stage_change = CurTime() + Lerp(math.random(), 3, 6 )
					end
					self.tired = true
				elseif self.stage == STAGE_FLYING_WANTS_TO_LAND then
					-- falling like flies!
					self.stage = STAGE_STANDING
					self.spooked = false
					self:StopFlyingSound()
					
					if not self.lowCPUmode then
						self:UpdateLowCPUmode()
					end
					
					self.tired_end = CurTime() + Lerp(math.random(), 1, 3)
					self.next_stage_change = math.max( self.tired_end+1, CurTime() + Lerp( math.pow(math.random(), 2), 2, 10 ) )
				end
			end
		end
		
		if FORCE_FLY then
			self.stage = STAGE_FLYING
		end
		
		
		-- Targetting
		if CurTime() >= self.target_next_update then
			--print( "targetting" )
			
			local interval
			if self.lowCPUmode then
				interval = self.target_update_interval_lowcpu
			elseif self.stage == STAGE_STANDING then
				interval = self.target_update_interval_standing
			else
				interval = self.target_update_interval
			end
			self.target_next_update = CurTime() + interval
			
			if FORCE_HOVER then
				self.flight_target_pos = self:GetPos()
			else
				if self.stage == STAGE_STANDING  then
					
					if not self.lowCPUmode then
						local ent_list = ents.FindInSphere(self:GetPos(), self.spook_radius)
						
						for i, ent in ipairs( ent_list ) do
							if IsValid(ent) and ent != self then
								local class = ent:GetClass()
								
								if class != "sent_tv_fly" then
									local relative_vel = ent:GetVelocity() - self:GetVelocity()
									local magn_sqr = relative_vel:LengthSqr()
									
									if magn_sqr > 5000 then
										if self:Visible(ent) then
											self.spooked = true
											self.next_stage_change = CurTime()
											break
										end
									end
								end
							end
						end
					end
					
				elseif self.stage == STAGE_FLYING_GIVING_SPACE then
				
					local shortest_dir = nil
					local shortest_dir_dist = 0
					local start = self:GetPos()
					
					for z = -1,0 do
						for y = -1,1 do
							for x = -1,1 do
								if not ( x == 0 and y == 0 and z == 0 ) and not ( z == 0 and ( ( x > 0 ) or ( x == 0 and y == 1 ) ) ) then
									local dir = Vector(x,y,z)
									dir:Normalize()
									
									local endpos1 = start + (dir * SPACE)
									local endpos2 = start - (dir * SPACE)
								
									local tr1 = util.TraceLine({
										start = start,
										endpos = endpos1,
										filter = self,
										mask = MASK_SOLID
									})
									
									local tr2 = util.TraceLine({
										start = start,
										endpos = endpos2,
										filter = self,
										mask = MASK_SOLID
									})
									
									local dist1 = tr1.Fraction * SPACE
									local dist2 = tr2.Fraction * SPACE
									
									local total_dist = math.max( dist1, dist2 ) - math.min( dist1, dist2 )
									
									if DEBUG_MODE then
										debugoverlay.Line( start, start + tr1.Normal*SPACE*tr1.Fraction, interval, color_white, true )
										debugoverlay.Line( start, start + tr2.Normal*SPACE*tr2.Fraction, interval, color_black, true )
									end
									
									if shortest_dir_dist == nil or total_dist > shortest_dir_dist then
										if dist1 <= dist2 then
											shortest_dir = dir
										else
											shortest_dir = -dir
										end
										shortest_dir_dist = total_dist
									end
								end
							end
						end
					end
					
					if shortest_dir == nil then
						self.next_stage_change = CurTime()
					else
						self.flight_target_pos = start - (shortest_dir*1)
					end

				elseif self.stage == STAGE_FLYING or self.stage == STAGE_FLYING_WANTS_TO_LAND then
				
					local change_target
					
					if self.target == nil or not IsValid(self.target) or self.target:GetPos():Distance( self:GetPos() ) > self.target_lose_dist then
						self.target = nil
						change_target = math.random() > 0.25
					else
						change_target = math.random() > 0.75
					end
					
					if change_target then
						self.target = nil
						
						local ent_list = ents.FindInSphere(self:GetPos(), 200)
						
						util.ShuffleTable( ent_list )
						
						for i, ent in ipairs( ent_list ) do
							if IsValid(ent) and ent != self then
								local class = ent:GetClass()
								
								if class != "sent_tv_fly" then
									if self:IsMaterialTypeILike( ent:GetMaterialType() ) and self:Visible(ent) then
										self.target = ent
										break
									end
								end
							end
						end
						
						if self.target == nil then
							local tr = util.TraceLine({
								start = self:GetPos(),
								endpos = self:GetPos() + ( VectorRand() * self.target_trace_dist ),
								filter = self,
								mask = MASK_SOLID
							})
							
							if DEBUG_MODE then
								debugoverlay.Cross( tr.HitPos, 1, self.target_update_interval, color_white, true )
							end
							
							if self.stage == 2 then
								self.flight_target_pos = tr.HitPos
							else
								self.flight_target_pos = LerpVector( math.random(), tr.HitPos, tr.StartPos )
							end
						else
							if self.target:IsPlayer() then
								self.flight_target_pos = self.target:GetShootPos()
							else
								local pos = self.target:GetPos()
								local mins = self.target:OBBMins() + pos
								local maxs = self.target:OBBMaxs() + pos
							
								self.flight_target_pos = Vector(
									Lerp( math.random(), mins.x, maxs.x),
									Lerp( math.random(), mins.y, maxs.y),
									Lerp( math.random(), mins.z, maxs.z)
								)
							end
						end
					end
					
				end
			end
		end
		
		
		-- Flight
		if self.stage != STAGE_STANDING and CurTime() >= self.flight_next_update then
			local interval
		
			if not self.lowCPUmode then
				interval = self.flight_update_interval
			else
				interval = self.flight_update_interval_lowcpu
			end
			
			self.flight_next_update = CurTime() + interval
			
			if DEBUG_MODE then
				debugoverlay.Cross( self.flight_target_pos, 10, interval, color_white, true )
			end
			
			local gravity_comp = -physenv.GetGravity() * Lerp(math.random(), 0.95, 1.05 )
			
			local vel_comp
			if self.spooked then
				vel_comp = vector_origin
			else
				vel_comp = -self.vel * Lerp(math.random(), 0.75, 1.25 )
			end
			
			local scale = 10
			if self.spooked then
				scale = 1000
			end
			
			local offset_comp = (self.flight_target_pos - self.prev_pos) * scale
			local offset_comp_magn = offset_comp:Length()
			
			local max_speed = 75/interval
			
			if offset_comp_magn > max_speed then
				offset_comp = max_speed*offset_comp/offset_comp_magn
			end
			
			local force = gravity_comp + vel_comp + offset_comp
			local force_magn = force:Length()
			force = force + ( (VectorRand() * force_magn * 0.01) / interval)
			
			self.flight_force = force
		end
		
		
		-- Physics
		if not IsValid( self:GetParent() ) and not self:GetParent():IsWorld() then
			local interval
			if not self.lowCPUmode then
				interval = engine.TickInterval()
			else
				interval = self.lowCPUmode_interval
			end
			
			local old_vel = 1.0 * self.vel
			self.vel = self.vel + ( (self.flight_force + physenv.GetGravity()) * interval )
			
			self.vel = self.vel * math.pow( 0.5, interval ) -- air resistance
			
			local half_vel = LerpVector( 0.5, old_vel, self.vel )
			
			local new_pos = self.prev_pos + half_vel * interval
			
			local tr = util.TraceLine({
				start = self.prev_pos,
				endpos = new_pos,
				mask = MASK_SOLID
			})
			
			if tr.Hit then
				new_pos = tr.HitPos + tr.HitNormal * 0.1
			
				if self.stage == STAGE_FLYING_WANTS_TO_LAND and isvector( tr.HitPos ) then
					if tr.Entity and IsValid(tr.Entity) and (tr.Entity:IsPlayer() or tr.Entity:IsNPC()) then
						-- do not stick to it.
					else
						local bone = -1
						
						if not tr.Entity:IsWorld() then
							if tr.Entity.GetModelPhysBoneCount != nil then
								local num_physbones = tr.Entity:GetModelPhysBoneCount()
								
								for i = 0, num_physbones-1 do
									if tr.Entity:PhysicsObjectNum( i ) == tr.PhysicsBone then
										bone = tr.Entity:TranslatePhysBoneToBone( i )
										break
									end
								end
							end
						end
					
						self.stage = STAGE_STANDING
						self.spooked = false
						self:StopFlyingSound()
						self:SetPos( new_pos )
						self:SetParent( tr.Entity, bone )
						
						-- TODO: Find out why the fly becomes invisible when parented.
						
						if not self.lowCPUmode then
							self:UpdateLowCPUmode()
						end
						
						self.tired_end = CurTime() + Lerp(math.random(), 1, 3)
						self.next_stage_change = math.max( self.tired_end+1, CurTime() + Lerp( math.pow(math.random(), 2), 2, 10 ) )
					end
				end
				
				if not IsValid( self:GetParent() ) then
					self.vel = half_vel - 2*tr.HitNormal*half_vel:Dot(tr.HitNormal)
					self.vel = self.vel * 0.75
					
				end
			else
				self:SetPos( new_pos )
			end
		end
		
		if DEBUG_MODE then
			debugoverlay.Cross( self:GetPos(), 10, 0.1, color_black, true )
		end
		
		self.prev_pos = self:GetPos()
		
		
		if self.lowCPUmode then
			self:NextThink( CurTime() + self.lowCPUmode_interval )
		else
			self:NextThink( CurTime() )
		end
		return true
	end
	
	
	
	
	hook.Add( "EntityEmitSound", "sent_tv_fly_EntityEmitSound", function( data )
		if data.Entity != nil and IsValid( data.Entity ) and data.Entity:GetClass() == "sent_tv_fly" then
			if string.StartWith( data.SoundName, "physics/" ) then
				return false
			end
		end
	end )
	
end




if CLIENT then

	local matFlySprite = Material( "sprites/tunnelvision/fly" )
	local SIZE = 1

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