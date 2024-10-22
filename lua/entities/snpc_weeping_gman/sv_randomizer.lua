local DEBUG_RANDOMIZER = CreateConVar("twg_debug_randomizer", "0", bit.bor( FCVAR_SERVER_CAN_EXECUTE, FCVAR_NOTIFY, FCVAR_CHEAT, FCVAR_ARCHIVE ) )




function ENT:RandomizerResetTimer()
	self.randomizer_next = math.max( self.randomizer_next, CurTime() + Lerp(math.random(), 5, 15) )
end




function ENT:Randomize()
	if DEBUG_RANDOMIZER:GetBool() then
		print( self, "Randomize" )
	end

	if math.random() > 0.5 then
		self.walk_speed_mult = Lerp(math.random(), 0.75, 1.0)
	end
	
	if math.random() > 0.5 then
		self.run_speed_mult = Lerp(math.random(), 0.75, 1.0)
	end
	
	if math.random() > 0.5 then
		self.force_run = math.random() < ( self.unstable_percent or 0 )
	end
	
	--if math.random() > 0.5 then
	--	self.pausing_enabled = math.random() > 0.75
	--end
	
	self:RandomizerResetTimer()
	
	if DEBUG_RANDOMIZER:GetBool() then
		print( self, self.walk_speed_mult, self.run_speed_mult, self.force_run, self.pausing_enabled )
	end
end




function ENT:RandomizerInit()
	self.randomizer_next = 0
	
	self.walk_speed_mult = 1.0
	self.run_speed_mult = 1.0
	self.force_run = false
	self.pausing_enabled = true --false
	
	self:Randomize()
end




function ENT:RandomizerUpdate()
	if CurTime() >= self.randomizer_next then
		self:Randomize()
	end
end