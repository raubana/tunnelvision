local DEBUG_UNSTABLE = CreateConVar("twg_debug_unstable", "0", bit.bor( FCVAR_SERVER_CAN_EXECUTE, FCVAR_NOTIFY, FCVAR_CHEAT, FCVAR_ARCHIVE ) )
local FORCE_UNSTABLE = CreateConVar("twg_force_unstable", "0", bit.bor( FCVAR_SERVER_CAN_EXECUTE, FCVAR_NOTIFY, FCVAR_CHEAT, FCVAR_ARCHIVE ) )




function ENT:UnstableInit()
	self.is_unstable = false

	self.unstable_counter = 0
	self.unstable_lower_hint_limit = 7
	self.unstable_upper_hint_limit = 14
	self.unstable_max_limit = 16
	
	self.unstable_percent = 0
	
	self.unstable_next = 0
	
	self.unstable_hint_stage = 0
	self.unstable_hinting_next = 0
	self.unstable_hint_bone = 0
	
	self.unstable_hint_bones = {6,6,6,11,16,9,14,10,15}
end




function ENT:UpdateUnstablePercent()
	self.unstable_percent = math.Clamp( (self.unstable_counter - self.unstable_lower_hint_limit)/(self.unstable_upper_hint_limit - self.unstable_lower_hint_limit), 0, 1 )
end




function ENT:BecomeUnstable()
	while self.unstable_counter < self.unstable_max_limit do
		self:IncrementInstability()
	end
end




function ENT:DecrementInstability()
	self.unstable_counter = math.max( self.unstable_counter - 1, 0 )
	self:UpdateUnstablePercent()
	
	if DEBUG_UNSTABLE:GetBool() then
		print( self, "UNSTABLE:", self.unstable_counter, "/", self.unstable_max_limit )
	end
	
	if self.is_unstable and self.unstable_counter <= self.unstable_lower_hint_limit then
		if DEBUG_UNSTABLE:GetBool() then
			print( self, "I am no longer unstable." )
			self:SoundStopAll()
		end
		self.is_unstable = false
	end
end




function ENT:IncrementInstability()
	self.unstable_counter = math.min( self.unstable_counter + 1, self.unstable_max_limit )
	self:UpdateUnstablePercent()
	
	if DEBUG_UNSTABLE:GetBool() then
		print( self, "UNSTABLE:", self.unstable_counter, "/", self.unstable_max_limit )
	end
	
	if not self.is_unstable and self.unstable_counter > self.unstable_upper_hint_limit then
		if DEBUG_UNSTABLE:GetBool() then
			print( self, "I am now unstable!" )
		end
		self.unstable_counter = self.unstable_max_limit
		self.interrupt = true
		self.interrupt_reason = "became unstable"
		self.is_unstable = true
	end
	
	self.unstable_hinting_next = 0
end




function ENT:UnstableUpdate()
	if FORCE_UNSTABLE:GetBool() then
		self.is_unstable = true
		self.unstable_percent = 1.0
		self.unstable_counter = self.unstable_max_limit
	end

	if CurTime() >= self.unstable_next then
		if DEBUG_UNSTABLE:GetBool() then
			print( self, "Instability timer tick!" )
		end
		if not self.frozen then
			if not self.have_target then
				self:DecrementInstability()
			end
			
			self.unstable_next = CurTime() + Lerp(math.random(), 8, 16)
		else
			self:IncrementInstability()
			
			self.unstable_next = CurTime() + Lerp(math.random(), 8, 16)
		end
	end

	if self.frozen then
		if not self.is_unstable and self.unstable_counter >= self.unstable_lower_hint_limit and self.unstable_counter <= self.unstable_upper_hint_limit then
			if CurTime() >= self.unstable_hinting_next then
				if DEBUG_UNSTABLE:GetBool() then
					print( self, "Instability hinted." )
				end
				
				if self.unstable_hint_stage == 0 then
					
					self.unstable_hint_bone = self.unstable_hint_bones[ math.random(#self.unstable_hint_bones) ]
					self.unstable_hinting_next = CurTime() + 0.01
					
					self:ManipulateBoneAngles( 
						self.unstable_hint_bone, 
						Angle(
							Lerp(math.random(), -3, 3),
							Lerp(math.random(), -3, 3),
							Lerp(math.random(), -3, 3)
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
					
					self.unstable_hinting_next = CurTime() + Lerp( 1-math.pow(1-self.unstable_percent, 2), Lerp( math.random(), 5, 10 ), Lerp( math.random(), 0.0, 0.1 ) )
					self.unstable_hint_stage = 0
				end
			end
		end
	end
end