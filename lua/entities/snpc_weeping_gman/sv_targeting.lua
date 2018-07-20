local DEBUG_TARGETING = CreateConVar("twg_debug_targeting", "0", bit.bor( FCVAR_SERVER_CAN_EXECUTE, FCVAR_NOTIFY, FCVAR_CHEAT, FCVAR_ARCHIVE ) )
local SIGHT_DISABLED = CreateConVar("twg_sight_disabled", "0", bit.bor( FCVAR_SERVER_CAN_EXECUTE, FCVAR_NOTIFY, FCVAR_CHEAT, FCVAR_ARCHIVE ) )
local DISABLE_SENSES_AND_STUFF = GetConVar( "twg_disable_senses_and_stuff" )




function ENT:TargetingInit()
	self.have_target = false
	self.have_old_target = false
	self.target = nil
	self.old_target = nil
	self.target_last_known_position = nil
	self.target_last_seen = 0
	
	self.target_interval = 0.25
	self.target_giveup_duration = 120
	self.target_next = 0
end




function ENT:GetDurationWithoutSeeingTarget()
	return CurTime() - self.target_last_seen
end




function ENT:FindTarget()
	local ply_list = player.GetAll()
	
	for i, ply in ipairs(ply_list) do
		if IsValid(ply) and ply:Alive() then
			if self:CanSeeEnt( ply ) then
				self:SetNewTarget( ply )
				return
			end
		end
	end
end




function ENT:OnNewTarget( old, new )
	-- self:SoundEmit( "npc/snpc_weeping_gman/wgm_startle"..tostring(math.random(7))..".wav", 1.0, 100, 65)
	if DEBUG_TARGETING:GetBool() then
		print( self, "OnNewTarget", old, new )
	end
	self.interrupt = true
	self.interrupt_reason = "found target"
end




function ENT:OnFoundOldTarget( new )
	if DEBUG_TARGETING:GetBool() then
		print( self, "OnFoundOldTarget", new )
	end
	self.interrupt = true
	self.interrupt_reason = "found old target"
end




function ENT:OnLostTarget( old )
	if DEBUG_TARGETING:GetBool() then
		print( self, "OnLostTarget", old )
	end
	
	self:IncrementInstability()
end




function ENT:OnLostOldTarget( old )
	if DEBUG_TARGETING:GetBool() then
		print( self, "OnLostOldTarget", old )
	end
end




function ENT:LoseTarget()
	if not self.have_target then return end
	
	local old = self.target

	self.have_target = false
	self.target = nil
	self.old_target = old
	self.have_old_target = true
	
	self:OnLostTarget( old )
end




function ENT:ResetTargetting()
	if DEBUG_TARGETING:GetBool() then
		print( self, "ResetTargetting" )
	end
	self:LoseTarget()
	self.old_target = nil
	self.have_old_target = false
	self.target_last_known_position = nil
end





function ENT:SetNewTarget( ent )
	if self.target == ent then return end

	local had_old = self.have_target
	local old = self.target
	
	self:SetEntityToLookAt( ent )

	self.have_target = true
	self.target = ent
	self.target_last_known_position = ent:GetPos()
	self.target_last_seen = CurTime()
	
	if self.have_old_target and ent == self.old_target then
		self.old_target = nil
		self.have_old_target = false
		self:OnFoundOldTarget( ent )
		if self.target_last_seen > 0 then
			local dif = CurTime() - self.target_last_seen
			dif = math.ceil(dif/5.0)
			if self.unstable_counter + dif > self.unstable_lower_hint_limit then
				dif = self.unstable_lower_hint_limit - self.unstable_counter
			end
			for i = 1, dif do
				self:IncrementInstability()
			end
		end
	else
		if had_old then
			self.old_target = old
			self.have_old_target = true
		end
		self:OnNewTarget( old, ent )
	end
end




function ENT:CheckStillHasTarget()
	
	if not (self.have_target or self.have_old_target) then return false end
	
	if CurTime() - self.target_last_seen > self.target_giveup_duration then
		self:ResetTargetting()
		self:LoseTarget()
		if self.have_old_target then
			self:OnLostOldTarget( self.old_target )
			self.interrupt = true
			self.interrupt_reason = "lost old target"
		end
	else
		if isvector(self.target_last_known_position) and self:GetPos():Distance(self.target_last_known_position) < 50 and CurTime() - self.target_last_seen > 1.0 then
			self.target_last_known_position = nil
			self:LoseTarget()
		end
	end
	
	return self.have_target or self.have_old_target
end




local LAST_KNOWN_POSITION_COLOR = Color(0,255,255)




function ENT:TargetingUpdate()
	-- if self.frozen then return end
	
	if CurTime() < self.target_next then return end
	self.target_next = CurTime() + self.target_interval
	
	if not self.have_target and not self.have_old_target then
		self:FindTarget()
	else
		self:CheckStillHasTarget()
		if DEBUG_TARGETING:GetBool() and isvector(self.target_last_known_position) then
			debugoverlay.Line( self.target_last_known_position+Vector(0,0,15), self.target_last_known_position+Vector(0,0,25), self.target_interval, LAST_KNOWN_POSITION_COLOR, true )
		end
		
		if not (SIGHT_DISABLED:GetBool() or DISABLE_SENSES_AND_STUFF:GetBool()) and ((self.have_target and IsValid( self.target )) or (self.have_old_target and IsValid(self.old_target))) then
			local target
			if IsValid( self.target ) then target = self.target
			else target = self.old_target end
		
			local can_see = target:Alive() and self:CanSeeEnt( target )
			
			if not can_see and target:FlashlightIsOn() then
				local ang = target:EyeAngles()
				ang:RotateAroundAxis( ang:Forward(), math.random()*360 )
				ang:RotateAroundAxis( ang:Right(), math.random()*45 )
				
				local start = target:GetShootPos()
				local endpos = start + ang:Forward() * 800
				
				local tr = util.TraceLine({
					start = start,
					endpos = endpos,
					filter = target,
					mask = bit.bor( MASK_OPAQUE, CONTENTS_IGNORE_NODRAW_OPAQUE, CONTENTS_MONSTER )
				})
				
				if tr.Hit then
					can_see = self:CanSeeVector( tr.HitPos +  tr.HitNormal )
					if DEBUG_TARGETING:GetBool() and can_see then
						print( "I can see their flashlight..." )
					end
				end
			end
		
			if can_see then
				if not self.have_target then
					self:SetNewTarget( self.old_target )
				else
					self.target_last_known_position = target:GetPos()
					self.target_last_seen = CurTime()
				end
			end
		end
	end
end