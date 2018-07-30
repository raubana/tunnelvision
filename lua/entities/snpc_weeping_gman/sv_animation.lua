local DEBUG_ANIMATION = GetConVar("rsnb_debug_animation")




function ENT:BodyUpdate()
	if self.frozen or self.pausing then return end

	local act = self:GetActivity()
	
	if act == ACT_RUN_STIMULATED or act == ACT_RUN or act == ACT_WALK or act == ACT_WALK_STEALTH then
		self:BodyMoveXY()
		if self.use_bodymoveyaw then
			self:BodyMoveYaw()
		end
		return
	end
	
	self:FrameAdvance()
end




function ENT:PushActivity( act, duration )
	if DEBUG_ANIMATION:GetBool() then
		print( self, "PushActivity", act, duration )
	end
	
	while self.pausing or self.frozen do
		coroutine.wait(0.25)
	end
	
	local duration = duration or -1
	local endtime = -1
	if duration > 0 then
		endtime = CurTime() + duration
	end
	
	if self.activity_stack:Size() == 0 or act != self.activity_stack:Top()[1] then
		self:StartActivity( act )
		if act == ACT_RUN_STIMULATED then
			self:PlaySequence( "run_all_panicked" )
		elseif act == ACT_RUN then
			-- use default
		elseif act == ACT_WALK then
			self:PlaySequence("walk_all_Moderate")
		elseif act == ACT_WALK_STEALTH then
			self:PlaySequence("idle_subtle")
		end
	end
	
	self.activity_stack:Push( {act, endtime} )
end




function ENT:PopActivity()
	if DEBUG_ANIMATION:GetBool() then
		print( self, "PopActivity" )
	end
	
	while self.pausing or self.frozen do
		coroutine.wait(0.25)
	end
	
	if self.activity_stack:Size() > 0 then
		self.activity_stack:Pop()
		if self.activity_stack:Size() == 0 or act != self.activity_stack:Top()[1] then
			self:StartActivity( self.activity_stack:Top()[1] )
		end
	end
end