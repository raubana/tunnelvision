local DEBUG_PAUSING = CreateConVar("twg_debug_pausing", "0", bit.bor( FCVAR_SERVER_CAN_EXECUTE, FCVAR_NOTIFY, FCVAR_CHEAT, FCVAR_ARCHIVE ) )
local PAUSING_DISABLE = CreateConVar("twg_pausing_disable", "0", bit.bor( FCVAR_SERVER_CAN_EXECUTE, FCVAR_NOTIFY, FCVAR_CHEAT, FCVAR_ARCHIVE ) )
local DISABLE_SENSES_AND_STUFF = GetConVar( "twg_disable_senses_and_stuff" )




function ENT:FrozenPausingInit()
	self.pausing = false
	self.pausing_wants_to_stop = false
	self.pausing_end = 0
end




function ENT:BeginPausing()
	if DEBUG_PAUSING:GetBool() then
		print( self, "BeginPausing" )
	end

	if PAUSING_DISABLE:GetBool() or DISABLE_SENSES_AND_STUFF:GetBool() or (not self.pausing_enabled) then return end

	if not self.pausing then
		if DEBUG_PAUSING:GetBool() then
			print( self, "Pausing start." )
		end
		self.pausing = true
		self.pausing_wants_to_stop = false
		self.pausing_end = CurTime() + Lerp( self.unstable_counter/Lerp(0.5, self.unstable_lower_hint_limit, self.unstable_upper_hint_limit), Lerp( math.random(), 15, 30 ), Lerp(math.random(), 0.5, 1) )
	elseif not self.pausing_wants_to_stop then
		self.pausing_end = math.max( self.pausing_end, CurTime() + Lerp( self.unstable_percent, Lerp( math.random(), 5, 10 ), Lerp(math.random(), 0.5, 1) ) )
	end
end




function ENT:FrozenPausingUpdate()
	if self.pausing then
		if ( CurTime() >= self.pausing_end ) or self.is_unstable or PAUSING_DISABLE:GetBool() or DISABLE_SENSES_AND_STUFF:GetBool() or (not self.pausing_enabled) or
		( self.have_target and ( ( CurTime() - self.target_last_seen > 5.0 and CurTime() - self.target_last_heard > 10.0 ) or ( isvector(self.target_last_known_position) and self.target_last_known_position:Distance( self:GetPos() ) > 1000 ) ) ) then
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
				self.pausing_wants_to_stop = false
			end
		end
	end	
end