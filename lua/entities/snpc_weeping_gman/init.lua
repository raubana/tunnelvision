include("shared.lua")

include("sv_movement.lua")
include("sv_animation.lua")
include("sv_randomizer.lua")
include("sv_unstable.lua")
include("sv_tendancies.lua")
include("sv_targeting.lua")
include("sv_search.lua")
include("sv_hearing.lua")
include("sv_frozen.lua")
include("sv_sound.lua")
include("sv_wind.lua")

AddCSLuaFile("cl_init.lua")
AddCSLuaFile("cl_frozen_lighting_awareness.lua")




local DEBUG_MODE = CreateConVar("twg_debug", "0", FCVAR_SERVER_CAN_EXECUTE+FCVAR_NOTIFY+FCVAR_CHEAT)
local KILLING_DISABLED = CreateConVar("twg_killing_disabled", "0", FCVAR_SERVER_CAN_EXECUTE+FCVAR_NOTIFY+FCVAR_CHEAT)
local SIGHT_DISABLED = GetConVar("twg_sight_disabled")




include("sv_behaviour_curious.lua")




function ENT:Initialize()
	self:SetModel( "models/gman_high.mdl" )
	self:SetMaterial( "models/props_wasteland/rockcliff02c" )
	
	self:RSNBInit()
	self:RandomizerInit()
	self:UnstableInit()
	self:TendanciesInit()
	self:TargetingInit()
	self:SearchInit()
	self:FrozenInit()
	self:SoundInit()
	self:WindInit()
	
	self.use_bodymoveyaw = true
	self.fov = 80
	self.player_fov = 80
	self.player_fov_flashlight = 45
	
	self.listening = false
	self.interrupt_reason = nil
	
	self:SetMaxHealth(1000000)
	self:SetHealth(1000000)
end



--[[
function ENT:BehaveStart()

	self.BehaveThread = coroutine.create( function() self:RunBehaviourCurious() end )

end
]]




function ENT:OnRemove()
	self:SoundStopAll()
end




function ENT:UpdateTransmitState()
	return TRANSMIT_ALWAYS
end




function ENT:OnInjured( info )
	info:ScaleDamage(0)
	self:IncrementInstability()
end




function ENT:GetHeadAngles()
	local pos, ang = self:GetBonePosition( self:LookupBone( "ValveBiped.Bip01_Head1" ) )
	ang:RotateAroundAxis(ang:Up(), -90)
	ang:RotateAroundAxis(ang:Forward(), -90)
	--debugoverlay.Axis( pos, ang, 10, engine.TickInterval()*2, true )
	return ang
end




function ENT:CanSeeEnt( ent )
	if SIGHT_DISABLED:GetBool() then return false end

	local pos
	if isfunction( ent.GetShootPos ) then
		pos = ent:GetShootPos()
	elseif isfunction( ent.GetHeadPos) then
		pos = ent:GetHeadPos()
	else
		pos = ent:GetPos()
	end

	local view_ang_dif = (pos - self:GetHeadPos()):Angle() - self:GetHeadAngles()
	view_ang_dif:Normalize()
	
	if math.abs( view_ang_dif.yaw ) < self.fov and math.abs( view_ang_dif.pitch ) < self.fov then
		if not self:Visible( ent ) then return false end
		return true
	end
	
	return false
end




function ENT:CanSeeVector( vector )
	local view_ang_dif = (vector - self:GetHeadPos()):Angle() - self:GetHeadAngles()
	view_ang_dif:Normalize()
	
	if math.abs( view_ang_dif.yaw ) < self.fov and math.abs( view_ang_dif.pitch ) < self.fov then
		if self:VisibleVec( vector ) then
			return true
		end
	end
	
	return false
end




local COLOR_ME = Color(255,0,0)

function ENT:Think()
	self:FrozenUpdate()
	self:SoundUpdate()
	self:WindUpdate()
	self:RandomizerUpdate()
	self:UnstableUpdate()
	
	if not self.frozen then
		self:TargetingUpdate()
		self:SearchUpdate()
		
		if not self.pausing then
			self:RSNBUpdate()
		end
	end
	
	if DEBUG_MODE:GetBool() then
		debugoverlay.Line( self:GetPos(), self:GetPos()+Vector(0,0,30), engine.TickInterval()*2, COLOR_ME, true )
	end

	self:NextThink( CurTime() )
	return true
end



function ENT:IsAtHome()
	local dist = self:GetPos():Distance( self.home_pos )
	if dist > 3 then return false end
	
	-- TODO: Also check the angles.
	
	return true
end



function ENT:FindSomethingToLookAt()
	if self.have_target and CurTime() - self.target_last_seen <= 1.0 then
		self:SetEntityToLookAt( self.target )
	else
		self:SetEntityToLookAt( nil )
	end
end




function ENT:UpdateLook()
	local target = self.look_entity
	local target_pos = nil
	
	if self.current_behaviour == self.BEHAVIOUR_CURIOUS then
		-- Just look forward blankly
		target_pos = self:GetHeadPos() + self:GetAngles():Forward() * 1000
	else
		if self.have_target and target != nil and IsValid( target ) then
			if isfunction(target.GetShootPos) then
				target_pos = target:GetShootPos()
			elseif isfunction(target.GetHeadPos) then
				target_pos = target:GetHeadPos()
			else
				target_pos = target:GetPos()
			end
		end
	
	
		if target_pos == nil then
			if self.listening then
				-- Keep moving the head back and forth.
				local ang = self:GetAngles()
				ang:RotateAroundAxis( ang:Up(), math.cos(math.rad((CurTime()*15) + self.target_last_seen))*45 )
				target_pos = self:GetHeadPos() + ang:Forward() * 1000
			elseif self.alt_path != nil then
				-- We're following an alt path, so we should be looking at that if
				-- we're not looking at something else.
				target_pos = self.alt_path[ math.min( self.alt_path_index+2, #self.alt_path ) ]
			elseif self.path != nil then
				-- We're following a path, so we should be looking at that if we're
				-- not looking at something else.
				local cursor_dist = self.path:GetCursorPosition()
				target_pos = self.path:GetPositionOnPath( cursor_dist + 200 ) + Vector( 0, 0, 45 )
			else
				-- Just look forward blankly
				target_pos = self:GetHeadPos() + self:GetAngles():Forward() * 1000
			end
		end
	end
	
	-- debugoverlay.Cross( target_pos, 10, 1, color_white, true )
	
	local target_angle = ( target_pos - self:GetHeadPos() ):Angle()
	local target_head_angle = target_angle - self:GetAngles()
	target_head_angle:Normalize()
	
	target_head_angle.yaw = math.Clamp( target_head_angle.yaw, -80, 80 )
	
	local p = math.pow( 0.2, (engine.TickInterval() * game.GetTimeScale())/0.2 )
	self.look_head_angle = LerpAngle( p, target_head_angle, self.look_head_angle )
	
	if math.max(math.abs(self.look_head_angle.pitch), math.abs(self.look_head_angle.yaw)) > 1 then
		self:SetPoseParameter( "head_pitch", self.look_head_angle.pitch * self.look_head_turn_bias )
		self:SetPoseParameter( "head_yaw", self.look_head_angle.yaw * 0.33 )
		self:SetPoseParameter( "spine_yaw", self.look_head_angle.yaw * 0.33 )
		self:SetPoseParameter( "body_yaw", self.look_head_angle.yaw * 0.33 )
	end
	
	if CurTime() > self.look_sightstray_next_time then
		self.look_sightstray_offset = VectorRand() * 3
		self.look_sightstray_next_time = CurTime() + Lerp(math.random(), self.look_sightstray_min_delay, self.look_sightstray_max_delay)
		
		self:SetEyeTarget( target_pos + self.look_sightstray_offset )
	end
	
	if not self.look_keep_focus and CurTime() >= self.look_endtime then
		self:FindSomethingToLookAt()
		self.look_endtime = CurTime() + 1
		self.look_sightstray_next_time = CurTime()
	end
end




function ENT:WaitForAnimToEnd( duration )
	local old_frozen = self.frozen
	local last_frozen = CurTime()
	local anim_elapsed = 0
	
	while anim_elapsed < duration do
		if self.frozen != old_frozen then
			if self.frozen then
				anim_elapsed = anim_elapsed + (CurTime() - last_frozen)
			else
				last_frozen = CurTime()
			end
		end
		
		if not self.frozen and CurTime() - last_frozen + anim_elapsed >= duration then
			break
		end
		
		old_frozen = self.frozen
		coroutine.yield()
	end
end




function ENT:Listen()
	if DEBUG_MODE:GetBool() then
		print( " - Listening..." )
	end

	self.listening = true

	self:PushActivity( ACT_IDLE )
	
	local listening_end = CurTime() + Lerp( math.random(), 3, 6 )
	while not self.interrupt and CurTime() < listening_end do
		coroutine.yield()
	end
	
	self:PopActivity()
	
	self.listening = false
	
	if DEBUG_MODE:GetBool() then
		print( " - Stopped listening." )
	end
end




function ENT:FidgetWithTie()
	self:PushActivity( ACT_IDLE )
	self:PlaySequence( "idle_subtle" )
	self:PlayGesture( "G_tiefidget" )
	
	-- self:SoundEmit( "npc/snpc_weeping_gman/wgm_sigh"..tostring(math.random(3))..".wav", 1.0, 100, 65)
	
	self:WaitForAnimToEnd( 3 )
	
	self:PopActivity()
end




function ENT:CanKillTarget( )
	if self.have_target and IsValid( self.target ) and CurTime() - self.target_last_seen <= 0.25 then
		local dist = self.target:GetPos():Distance( self:GetPos() )
		
		if dist < 100 then
			return true
		end
	end

	return false
end




function ENT:KillTarget()
	if DEBUG_MODE:GetBool() then
		print( self, "KillTarget" )
	end
	
	if not self.target then return "failed" end
	
	self:SoundEmit( "npc/fast_zombie/fz_scream1.wav", 1.0, 100.0, 95 )
	
	self:PushActivity( ACT_IDLE )
	self:PlaySequence( "swing" )
	
	self:WaitForAnimToEnd( 0.4 )
	
	if self.have_target and IsValid( self.target ) and self.target:Alive() and self.target:GetPos():Distance( self:GetPos() ) <= 120 then
		self.target:EmitSound( "physics/body/body_medium_impact_hard"..tostring(math.random(6))..".wav", 95, Lerp(math.random(), 90, 110), 1.0 )
		self.target:EmitSound( "physics/body/body_medium_break"..tostring(math.random(2,4))..".wav", 95, Lerp(math.random(), 90, 110), 1.0 )
	
		self.target:Kill()
		self:ResetTargetting()
		self.unstable_counter = math.floor( self.unstable_counter / 2 )
		self:UpdateUnstablePercent()
		
		coroutine.wait( 1 )
		
		self:FidgetWithTie()
		
		return "ok"
	end
	
	self:WaitForAnimToEnd( 1.0 )
	
	self:PopActivity()
	
	self:RandomizerResetTimer()
	
	return "failed"
end




function ENT:RunBehaviour()
	self:PushActivity( ACT_IDLE )
	
	coroutine.wait( 1 )
	
	while true do
		while self.frozen do
			coroutine.yield()
		end
		
		local result
	
		if self.have_target or self.have_old_target then
			if not self.have_target and self.have_old_target then
				
				if not isvector(self.target_last_known_position)  then
				
					if DEBUG_MODE:GetBool() then
						print(self, "I might have lost them... I'm going to look around.")
					end
					
					-- self:SoundEmit( "npc/snpc_weeping_gman/wgm_searching"..tostring(math.random(4))..".wav", 1.0, 100, 65)
					if self.is_unstable then
						self:SoundEmit( "npc/fast_zombie/breathe_loop1.wav", 1.0, 25.0, 55, true )
					end
					coroutine.wait(1.0)
					result = self:Search()
					self:SoundStop( "npc/fast_zombie/breathe_loop1.wav" )
					
				else
				
					if DEBUG_MODE:GetBool() then
						print(self, "I might have lost them... I'm going to look where I last think they were.")
					end
					coroutine.wait(1.0)
					result = self:MoveToPos( self.target_last_known_position )
					
				end
				
			else
			
				if self:CanKillTarget() then
				
					if not KILLING_DISABLED:GetBool() then
						result = self:KillTarget()
					else
						result = "ok"
					end
					
					if result == "failed" then
						self:IncrementInstability()
					end
					
				else
				
					if self.is_unstable then
						self:SoundEmit( "npc/zombie_poison/pz_breathe_loop2.wav", 1.0, 100.0, 65, true )
					end
					result = self:ChaseTarget( )
					self:SoundStop( "npc/zombie_poison/pz_breathe_loop2.wav" )
					
				end
				
			end
		else
		
			coroutine.wait(1.0)
			result = self:Wander( )
			
		end
		
		if DEBUG_MODE:GetBool() then
			print( "RESULT:", result )
		end
		
		if self.interrupt then
			self.interrupt = false
			local reason = self.interrupt_reason
			self.interrupt_reason = nil
			
			if reason == "heard something" then
				self:Listen()
			elseif reason == "found target" then
				coroutine.wait(1)
			elseif reason == "found old target" then
				coroutine.wait(1)
			elseif reason == "lost old target" then
				self:FidgetWithTie()
			elseif reason == "became unstable" then
				coroutine.wait(1)
			end
		end
	
		coroutine.yield()
	end
end

