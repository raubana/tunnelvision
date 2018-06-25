local DEBUG_ANIMATION = GetConVar("rsnb_debug_animation")




function ENT:BodyUpdate()
	if self.frozen or self.pausing then return end

	local act = self:GetActivity()
	
	if act == ACT_WALK or act == ACT_RUN then
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
	
	local duration = duration or -1
	local endtime = -1
	if duration > 0 then
		endtime = CurTime() + duration
	end
	
	if self.activity_stack:Size() == 0 or act != self.activity_stack:Top()[1] then
		self:StartActivity( act )
		if not self.is_unstable then --self.have_target then --or self.have_old_target then
			if act == ACT_RUN then
				self:PlaySequence("idle_subtle")--"run_all_panicked")
			elseif act == ACT_WALK then
				self:PlaySequence("idle_subtle")--"luggage_walk_all")
			elseif act == ACT_IDLE then
				self:PlaySequence("idle_subtle")
			end
		else
			if act == ACT_RUN then
				self:PlaySequence("run_all_panicked")
			elseif act == ACT_WALK then
				self:PlaySequence("walk_all_Moderate")
			end
		end
	end
	self.activity_stack:Push( {act, endtime} )
end