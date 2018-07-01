local DEBUG_UNSTABLE = CreateConVar("twg_debug_unstable", "0", FCVAR_SERVER_CAN_EXECUTE+FCVAR_NOTIFY+FCVAR_CHEAT)




function ENT:UnstableInit()
	self.is_unstable = false

	self.unstable_counter = 0
	self.unstable_lower_hint_limit = 50
	self.unstable_upper_hint_limit = 75
	self.unstable_max_limit = 100
	
	self.unstable_percent = 0
	
	self.unstable_next = 0
	
	self.unstable_hinting_next = 0
	self.unstable_hint_bone = 0
	
	self.unstable_hint_bones = {6,6,6,11,16,9,14,10,15}
end




function ENT:UpdateUnstablePercent()
	self.unstable_percent = math.Clamp( (self.unstable_counter - self.unstable_lower_hint_limit)/(self.unstable_upper_hint_limit - self.unstable_lower_hint_limit), 0, 1 )
end




function ENT:DecrementInstability()
	self.unstable_counter = math.max( self.unstable_counter - 1, 0 )
	self:UpdateUnstablePercent()
	
	if DEBUG_UNSTABLE:GetBool() then
		print( self, "UNSTABLE:", self.unstable_counter, "/", self.unstable_max_limit )
	end
	
	if self.is_unstable and self.unstable_counter < self.unstable_upper_hint_limit then
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
	if CurTime() >= self.unstable_next then
		if DEBUG_UNSTABLE:GetBool() then
			print( self, "Instability timer tick!" )
		end
		if not self.frozen then
			self:DecrementInstability()
		else
			self:IncrementInstability()
		end
		self.unstable_next = CurTime() + Lerp(math.random(), 10, 15)
	end

	if self.frozen then
		if not self.is_unstable and self.unstable_counter >= self.unstable_lower_hint_limit and self.unstable_counter <= self.unstable_upper_hint_limit then
			if CurTime() >= self.unstable_hinting_next then
				if DEBUG_UNSTABLE:GetBool() then
					print( self, "Instability hinted." )
				end
				
				self.unstable_hint_bone = self.unstable_hint_bones[ math.random(#self.unstable_hint_bones) ]
				self.unstable_hinting_next = CurTime() + Lerp( self.unstable_percent, Lerp( math.random(), 5, 10 ), Lerp( math.random(), 0.0, 0.1 ) )
				
				self:ManipulateBoneAngles( 
					self.unstable_hint_bone, 
					Angle(
						Lerp(math.random(), -1, 1),
						Lerp(math.random(), -1, 1),
						Lerp(math.random(), -1, 1)
					)
				)
			end
		end
	end
end