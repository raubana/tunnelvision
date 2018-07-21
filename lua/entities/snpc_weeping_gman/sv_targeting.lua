local DEBUG_TARGETING = CreateConVar("twg_debug_targeting", "0", bit.bor( FCVAR_SERVER_CAN_EXECUTE, FCVAR_NOTIFY, FCVAR_CHEAT, FCVAR_ARCHIVE ) )
local SIGHT_DISABLED = CreateConVar("twg_sight_disabled", "0", bit.bor( FCVAR_SERVER_CAN_EXECUTE, FCVAR_NOTIFY, FCVAR_CHEAT, FCVAR_ARCHIVE ) )
local DISABLE_SENSES_AND_STUFF = GetConVar( "twg_disable_senses_and_stuff" )




function ENT:TargetingInit()
	self.have_target = false
	self.target = nil
	self.target_last_known_position = nil
	
	self.target_last_seen = 0
	self.target_last_heard = 0
	self.target_last_saw_me = 0
	
	self.target_interval = 0.25
	self.target_giveup_duration = 120
	self.target_next = 0
end




function ENT:CanSeeFlashlight( ply )
	if SIGHT_DISABLED:GetBool() or DISABLE_SENSES_AND_STUFF:GetBool() then return false end

	if not ply:FlashlightIsOn() then return false end

	local ang = ply:EyeAngles()
	ang:RotateAroundAxis( ang:Forward(), math.random()*360 )
	ang:RotateAroundAxis( ang:Right(), math.random()*45 )
	
	local start = ply:GetShootPos()
	local endpos = start + ang:Forward() * 800
	
	local tr = util.TraceLine({
		start = start,
		endpos = endpos,
		filter = ply,
		mask = bit.bor( MASK_OPAQUE, CONTENTS_IGNORE_NODRAW_OPAQUE, CONTENTS_MONSTER )
	})
	
	if tr.Hit then
		can_see = self:CanSeeVector( tr.HitPos +  tr.HitNormal )
		if DEBUG_TARGETING:GetBool() and can_see then
			print( "I can see their flashlight..." )
			return true
		end
	end
	
	return false
end




function ENT:FindTarget()
	if SIGHT_DISABLED:GetBool() or DISABLE_SENSES_AND_STUFF:GetBool() then return end

	local ply_list = player.GetAll()
	
	for i, ply in ipairs(ply_list) do
		if IsValid(ply) and ply:Alive() then
			if self:CanSeeEnt( ply ) or self:CanSeeFlashlight( ply ) then
				self:SetTarget( ply )
				return
			end
		end
	end
end




function ENT:OnNewTarget( old, new )
	if DEBUG_TARGETING:GetBool() then
		print( self, "OnNewTarget", old, new )
	end
	self.interrupt = true
	self.interrupt_reason = "found target"
end




function ENT:OnLostTarget( old )
	if DEBUG_TARGETING:GetBool() then
		print( self, "OnLostTarget", old )
	end
	
	self:IncrementInstability()
end




function ENT:LoseTarget()
	if not self.have_target then return end
	
	local old = self.target

	self.have_target = false
	self.target = nil
	
	self:OnLostTarget( old )
end




function ENT:ResetTargetting()
	if DEBUG_TARGETING:GetBool() then
		print( self, "ResetTargetting" )
	end
	self:LoseTarget()
	self.target_last_known_position = nil
end





function ENT:SetTarget( ent )
	if self.target == ent then return end
	
	local old = self.target
	
	self:SetEntityToLookAt( ent )

	self.have_target = true
	self.target = ent
	
	self:OnNewTarget( old, ent )
	
	self.target_last_known_position = ent:GetPos()
	self.target_last_seen = CurTime()
end




function ENT:CheckStillHasTarget()
	
	if not self.have_target then return false end
	
	if CurTime() - self.target_last_seen > self.target_giveup_duration and CurTime() - self.target_last_heard > self.target_giveup_duration then
		self:ResetTargetting()
		self:LoseTarget()
	else
		if isvector(self.target_last_known_position) and self:GetPos():Distance(self.target_last_known_position) < 50 and CurTime() - self.target_last_seen > 1.0 then
			self.target_last_known_position = nil
		end
	end
	
	return self.have_target
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
		if DEBUG_TARGETING:GetBool() and isvector(self.target_last_known_position) then
			debugoverlay.Line( self.target_last_known_position+Vector(0,0,15), self.target_last_known_position+Vector(0,0,25), self.target_interval, LAST_KNOWN_POSITION_COLOR, true )
		end
		
		if not (SIGHT_DISABLED:GetBool() or DISABLE_SENSES_AND_STUFF:GetBool()) and (self.have_target and IsValid( self.target )) then
			
			local can_see = self.target:Alive() and ( self:CanSeeEnt( self.target ) or self:CanSeeFlashlight( self.target ) )
		
			if can_see then
				if CurTime() - math.max( self.target_last_seen, self.target_last_heard ) > 30.0 then
					self:IncrementInstability()
				end
			
				self.target_last_known_position = self.target:GetPos()
				self.target_last_seen = CurTime()
			end
		end
	end
end