local DEBUG_TARGETING = CreateConVar("twg_debug_targeting", "0", FCVAR_SERVER_CAN_EXECUTE+FCVAR_NOTIFY+FCVAR_CHEAT)




function ENT:TargetingInit()
	self.have_target = false
	self.have_old_target = false
	self.target = nil
	self.old_target = nil
	self.target_last_known_position = nil
	self.target_last_seen = 0
	
	self.target_interval = 0.25
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
end




function ENT:OnFoundOldTarget( new )
	if DEBUG_TARGETING:GetBool() then
		print( self, "OnFoundOldTarget", new )
	end
	self.interrupt = true
end




function ENT:OnLostTarget( old )
	if DEBUG_TARGETING:GetBool() then
		print( self, "OnLostTarget", old )
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
end





function ENT:SetNewTarget( ent )
	if self.target == ent then return end

	local had_old = self.have_target
	local old = self.target
	
	self:SetEntityToLookAt( ent )
	self:PlayGesture( "gesture_shoot_rpg" )

	self.have_target = true
	self.target = ent
	self.target_last_known_position = ent:GetPos()
	self.target_last_seen = CurTime()
	
	if self.have_old_target and ent == self.old_target then
		self.old_target = nil
		self.have_old_target = false
		self:OnFoundOldTarget( ent )
	else
		if had_old then
			self.old_target = old
			self.have_old_target = true
		end
		self:OnNewTarget( old, ent )
	end
end




function ENT:CheckStillHasTarget()
	local lost_target = true

	if self.have_target and IsValid(self.target) and isvector(self.target_last_known_position) and self:GetPos():Distance(self.target_last_known_position) > 15 then
		lost_target = false
	end
	
	if lost_target then
		self:LoseTarget()
	end
	
	return not lost_target
end




local LAST_KNOWN_POSITION_COLOR = Color(0,255,255)




function ENT:TargetingUpdate()
	-- if self.frozen then return end
	
	if CurTime() < self.target_next then return end
	self.target_next = CurTime() + self.target_interval
	
	if not self.have_target then
		self:FindTarget()
	else
		self:CheckStillHasTarget()
		if self.have_target then
			if DEBUG_TARGETING:GetBool() then
				debugoverlay.Line( self.target_last_known_position+Vector(0,0,15), self.target_last_known_position+Vector(0,0,25), self.target_interval, LAST_KNOWN_POSITION_COLOR, true )
			end
		
			if self:CanSeeEnt( self.target ) then
				self.target_last_known_position = self.target:GetPos()
				self.target_last_seen = CurTime()
			end
		end
	end
end