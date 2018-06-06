include("shared.lua")

include("sv_movement.lua")
include("sv_animation.lua")
include("sv_targeting.lua")
include("sv_search.lua")
include("sv_hearing.lua")
include("sv_frozen.lua")

AddCSLuaFile("cl_init.lua")



function ENT:Initialize()
	self:SetModel( "models/gman_high.mdl" )
	self:SetMaterial( "models/props_wasteland/rockcliff02c" )
	
	self:RSNBInit()
	self:TargetingInit()
	self:SearchInit()
	self:FrozenInit()
	
	self.use_bodymoveyaw = true
	
	self.walk_speed = 50
	self.run_speed = 300
	
	self.walk_accel = 400
	self.walk_decel = 1000000000
	
	self.run_accel = 1000
	self.run_decel = 10000000000
	
	self.walk_turn_speed = 720
	self.run_turn_speed = 720
	
	self.run_tolerance = 1000
	
	self.motionless_speed_limit = 0.25
	
	self.loco:SetStepHeight( 24 )
	
	self:SetMaxHealth(1000000)
	self:SetHealth(1000000)
end




function ENT:GetHeadAngles()
	local pos, ang = self:GetBonePosition( self:LookupBone( "ValveBiped.Bip01_Head1" ) )
	ang:RotateAroundAxis(ang:Up(), -90)
	ang:RotateAroundAxis(ang:Forward(), -90)
	--debugoverlay.Axis( pos, ang, 10, engine.TickInterval()*2, true )
	return ang
end




function ENT:CanSeeEnt( ent )
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
	
	if math.abs( view_ang_dif.yaw ) < 70 and math.abs( view_ang_dif.pitch ) < 70 then
		if not self:Visible( ent ) then return false end
		return true
	end
	
	return false
end




function ENT:CanSeeVector( vector )
	local view_ang_dif = (vector - self:GetHeadPos()):Angle() - self:GetHeadAngles()
	view_ang_dif:Normalize()
	
	if math.abs( view_ang_dif.yaw ) < 70 and math.abs( view_ang_dif.pitch ) < 70 then
		if self:VisibleVec( vector ) then
			return true
		end
	end
	
	return false
end




function ENT:OnInjured( info )
	info:ScaleDamage(0)
end




local COLOR_ME = Color(255,0,0)

function ENT:Think()
	self:FrozenUpdate()
	
	if not self.frozen then
		self:TargetingUpdate()
		self:SearchUpdate()
		self:RSNBUpdate()
		
		debugoverlay.Line( self:GetPos(), self:GetPos()+Vector(0,0,30), engine.TickInterval()*2, COLOR_ME, true )
	end

	self:NextThink( CurTime() )
	return true
end




function ENT:UpdateLook()
	local target = self.target
	local target_pos = nil
	
	if target != nil and IsValid( target ) then
		if isfunction(target.GetShootPos) then
			target_pos = target:GetShootPos()
		elseif isfunction(target.GetHeadPos) then
			target_pos = target:GetHeadPos()
		else
			target_pos = target:GetPos()
		end
	else
		target_pos = self.target_last_known_position
	end
	
	if target_pos == nil then
		if self.alt_path != nil then
			-- We're following an alt path, so we should be looking at that if
			-- we're not looking at something else.
			target_pos = self.alt_path[ math.min( self.alt_path_index+2, #self.alt_path ) ]
		elseif self.path != nil then
			-- We're following a path, so we should be looking at that if we're
			-- not looking at something else.
			local cursor_dist = self.path:GetCursorPosition()
			target_pos = self.path:GetPositionOnPath( cursor_dist + 300 )
		else
			-- Just look forward blankly
			target_pos = self:GetHeadPos() + self:GetAngles():Forward() * 1000
		end
	end
	
	local target_angle = ( target_pos - self:GetHeadPos() ):Angle()
	local target_head_angle = target_angle - self:GetAngles()
	target_head_angle:Normalize()
	
	target_head_angle.yaw = math.Clamp( target_head_angle.yaw, -80, 80 )
	
	local p = math.pow( 0.1, (engine.TickInterval() * game.GetTimeScale())/0.2 )
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
end




function ENT:WaitForAnimToEnd( duration )
	local anim_end = CurTime() + duration
	
	while CurTime() < anim_end do
		if self.frozen then
			anim_end = anim_end + engine.TickInterval()
		end
		
		coroutine.yield()
	end
end




function ENT:FidgetWithTie()
	self:PushActivity( ACT_IDLE )
	self:PlaySequence( "idle_subtle" )
	self:PlayGesture( "G_tiefidget" )
	
	self:WaitForAnimToEnd( 3 )
	
	self:PopActivity()
end




function ENT:KillTarget()
	print( self, "KillTarget" )
	
	self:PlaySequence( "swing" )
	
	self:WaitForAnimToEnd( 0.5 )
	
	if self.have_target and self.target:GetPos():Distance( self:GetPos() ) <= 50 then
		self.target:Kill()
		self:ResetTargetting()
		
		coroutine.wait( 1 )
		
		self:FidgetWithTie()
		
		return "ok"
	end
	
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
	
		if self.have_target then
			local dist = self.target_last_known_position:Distance( self:GetPos() )
			if CurTime() - self.target_last_seen > 1.0 then
				
				self:LoseTarget()
			
				if dist < 100 then
					coroutine.wait( 1 )
					
					self:FidgetWithTie()
				
					result = self:Search()
					if not self.have_target then
						self:ResetTargetting()
					end
				else
					result = self:MoveToPos( self.target_last_known_position )
				end
			else
				print( dist )
				if dist <= 50 then
					result = self:KillTarget()
				else
					result = self:ChaseTarget( )
				end
			end
		else
			result = self:Wander( )
		end
		
		print( "RESULT:", result )
		
		if self.interrupt then
			self.interrupt = false
		end
	
		coroutine.yield()
	end
end

