local DEBUG_UNSTABLE = CreateConVar("twg_debug_unstable", "0", bit.bor( FCVAR_SERVER_CAN_EXECUTE, FCVAR_NOTIFY, FCVAR_CHEAT, FCVAR_ARCHIVE ) )
local FORCE_UNSTABLE = CreateConVar("twg_force_unstable", "0", bit.bor( FCVAR_SERVER_CAN_EXECUTE, FCVAR_NOTIFY, FCVAR_CHEAT, FCVAR_ARCHIVE ) )




function ENT:UnstableInit()
	self.is_unstable = false

	self.unstable_counter = 20
	self.unstable_lower_hint_limit = 5
	self.unstable_upper_hint_limit = 15
	self.unstable_min_limit = 10
	self.unstable_max_limit = 20
	
	self.unstable_scale = 1.0
	self.unstable_lower_hint_limit = math.floor(self.unstable_lower_hint_limit * self.unstable_scale)
	self.unstable_upper_hint_limit = math.floor(self.unstable_upper_hint_limit * self.unstable_scale)
	self.unstable_max_limit = math.floor(self.unstable_max_limit * self.unstable_scale)
	
	self.unstable_percent = 1
	
	self.unstable_last = 0
	self.unstable_next = 0
	self.unstable_min_interval = 0.75
	
	self.unstable_hint_stage = 0
	self.unstable_hinting_next = 0
	self.unstable_hint_bone = 0
	
	self.unstable_hint_bones = {6,11,16,9,14,10,15}
end




function ENT:UpdateUnstablePercent()
	self.unstable_percent = math.Clamp( (self.unstable_counter - self.unstable_lower_hint_limit)/(self.unstable_upper_hint_limit - self.unstable_lower_hint_limit), 0, 1 )
end




function ENT:BecomeUnstable()
	while self.unstable_counter < self.unstable_max_limit do
		self:IncrementInstability()
	end
	
	if DEBUG_UNSTABLE:GetBool() then
		print( self, "I am now unstable!" )
		
		if self.have_target and IsValid( self.target ) then
			self:SetEntityToLookAt( self.target )
		end
	end
	self.interrupt = true
	self.interrupt_reason = "became unstable"
	self.is_unstable = true
end




function ENT:DecrementInstability()
	self.unstable_counter = math.max( self.unstable_counter - 1, 0 )
	self:UpdateUnstablePercent()
	
	if DEBUG_UNSTABLE:GetBool() then
		print( self, "UNSTABLE:", self.unstable_counter, "/", self.unstable_max_limit )
	end
end




function ENT:IncrementInstability()
	self.unstable_counter = math.min( self.unstable_counter + 1, self.unstable_max_limit )
	
	if DEBUG_UNSTABLE:GetBool() then
		print( self, "UNSTABLE:", self.unstable_counter, "/", self.unstable_max_limit )
	end
	
	self:UpdateUnstablePercent()
	
	self.unstable_hinting_next = 0
end




function ENT:UnstableUpdate()
	if FORCE_UNSTABLE:GetBool() then
		self.is_unstable = true
		self.unstable_percent = 1.0
		self.unstable_counter = self.unstable_max_limit
	end
	
	local curtime = CurTime()

	if curtime >= self.unstable_next then
		if DEBUG_UNSTABLE:GetBool() then
			print( self, "Instability timer tick!" )
		end
		
		if not self.frozen then
			if not self.have_target then
				self:DecrementInstability()
			end
			
			if self.unstable_percent >= 1 then
				self.unstable_next = curtime + Lerp(math.random(), 3, 6)
			elseif self.unstable_percent > 0 then
				self.unstable_next = curtime + Lerp(math.random(), 4, 8)
			else
				self.unstable_next = curtime + Lerp(math.random(), 8, 16)
			end
		else	
			if self.have_target and curtime - self.target_last_seen < 1.0 then
				if self:CanKillTarget() then
					self:IncrementInstability()
					self.unstable_next = curtime + Lerp(math.random(), 0.5, 1.5)
				else
					self.unstable_next = curtime + Lerp(math.random(), 4, 8)
				end
			else
				self.unstable_next = curtime + Lerp(math.random(), 4, 8)
			end
		end
		
	end
	
	if not self.is_unstable then
		if self.have_target and self.unstable_counter >= self.unstable_max_limit and self:CanKillTarget() then
			self:BecomeUnstable()
		end
	else
		if self.unstable_counter <= self.unstable_min_limit then
			if DEBUG_UNSTABLE:GetBool() then
				print( self, "I am no longer unstable." )
				self:SoundStopAll()
			end
			self.is_unstable = false
		end
	end
	
	if self.frozen then
		if not self.is_unstable and self.unstable_counter >= self.unstable_lower_hint_limit and self.unstable_counter <= self.unstable_upper_hint_limit then
			if curtime >= self.unstable_hinting_next then
				if DEBUG_UNSTABLE:GetBool() then
					print( self, "Instability hinted." )
				end
				
				if self.unstable_hint_stage == 0 then
					
					self.unstable_hint_bone = self.unstable_hint_bones[ math.random(#self.unstable_hint_bones) ]
					self.unstable_hinting_next = CurTime() + 0.01
					
					local strength = self.unstable_percent * 3
					
					self:ManipulateBoneAngles( 
						self.unstable_hint_bone, 
						Angle(
							Lerp(math.random(), -1, 1)*strength,
							Lerp(math.random(), -1, 1)*strength,
							Lerp(math.random(), -1, 1)*strength
						)
					)
					
					self.unstable_hint_stage = 1
				
				else
				
					self:ManipulateBoneAngles( 
						self.unstable_hint_bone, 
						Angle(
							0,
							0,
							0
						)
					)
					
					self.unstable_hinting_next = curtime + ( Lerp( math.random(), 0.5, 1.0 ) * Lerp( self.unstable_percent, 2, 1 ) )
					self.unstable_hint_stage = 0
				end
			end
		end
	end
end