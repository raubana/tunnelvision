local DEBUG_PAUSING = CreateConVar("twg_debug_pausing", "0", FCVAR_SERVER_CAN_EXECUTE+FCVAR_NOTIFY+FCVAR_CHEAT)
local PAUSING_DISABLE = CreateConVar("twg_pausing_disable", "0", FCVAR_SERVER_CAN_EXECUTE+FCVAR_NOTIFY+FCVAR_CHEAT) -- doesn't do anything right now.




function ENT:FrozenPausingInit()
	self.pausing = false
	self.pausing_wants_to_stop = false
	self.pausing_end = 0
end




function ENT:BeginPausing()
	if DEBUG_PAUSING:GetBool() then
		print( self, "BeginPausing" )
	end

	if PAUSING_DISABLE:GetBool() or not self.pausing_enabled then return end

	if not self.pausing then
		if DEBUG_PAUSING:GetBool() then
			print( self, "Pausing start." )
		end
		self.pausing = true
		self.pausing_wants_to_stop = false
		self.pausing_end = CurTime() + Lerp( 1-math.pow(1-self.unstable_percent, 3), Lerp( math.random(), 0, 10 ), Lerp(math.random(), 0, 1) )
	elseif not self.pausing_wants_to_stop then
		self.pausing_end = math.max( self.pausing_end, CurTime() + Lerp( 1-math.pow(1-self.unstable_percent, 3), Lerp( math.random(), 0, 3 ), Lerp(math.random(), 0, 1) ) )
	end
end




function ENT:FrozenPausingUpdate()
	if self.pausing then
		if CurTime() >= self.pausing_end or (not self.pausing_enabled or PAUSING_DISABLE:GetBool() or self.is_unstable ) then
			if self.frozen then
				if DEBUG_PAUSING:GetBool() and not self.pausing_wants_to_stop then
					print( self, "I want to unpause but I can't." )
				end
				self.pausing_wants_to_stop = true
			else
				if DEBUG_PAUSING:GetBool() then
					print( self, "Pausing end." )
				end
				self.pausing = false
			end
		end
	end	
end