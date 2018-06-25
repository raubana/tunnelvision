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

	if not self.pausing_enabled then return end

	if not self.pausing then
		if DEBUG_PAUSING:GetBool() then
			print( self, "Pausing start." )
		end
		self.pausing = true
		self.pausing_end = CurTime() + Lerp( math.random(), 5, 15 )
	else
		self.pausing_end = math.max( self.pausing_end, CurTime() + Lerp( math.random(), 1, 5 ) )
	end
end




function ENT:FrozenPausingUpdate()
	if self.pausing and ( CurTime() >= self.pausing_end or not self.pausing_enabled ) then
		if DEBUG_PAUSING:GetBool() then
			print( self, "Pausing end." )
		end
		self.pausing = false
	end	
end