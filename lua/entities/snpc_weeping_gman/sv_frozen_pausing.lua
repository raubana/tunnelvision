local DEBUG_PAUSING = CreateConVar("twg_debug_pausing", "0", FCVAR_SERVER_CAN_EXECUTE+FCVAR_NOTIFY+FCVAR_CHEAT)
local PAUSING_DISABLE = CreateConVar("twg_pausing_disable", "0", FCVAR_SERVER_CAN_EXECUTE+FCVAR_NOTIFY+FCVAR_CHEAT) -- doesn't do anything right now.




function ENT:FrozenPausingInit()
	self.pausing = false
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
		self.pausing_end = CurTime() + Lerp( math.pow(self.unstable_percent, 0.5), Lerp( math.random(), 15, 30 ), Lerp(math.random(), 0.5, 3) )
	else
		self.pausing_end = math.max( self.pausing_end, CurTime() + Lerp( math.pow(self.unstable_percent, 0.5), Lerp( math.random(), 1, 3 ), Lerp(math.random(), 0.25, 0.75) ) )
	end
end




function ENT:FrozenPausingUpdate()
	if (self.pausing and ( CurTime() >= self.pausing_end or (not self.pausing_enabled or PAUSING_DISABLE:GetBool()) or self.is_unstable )) then
		if DEBUG_PAUSING:GetBool() then
			print( self, "Pausing end." )
		end
		self.pausing = false
	end	
end