local DEBUG_ANIMATION = GetConVar("rsnb_debug_animation")




function ENT:RSNBInitAnimation()
	self.activity_stack = util.Stack()
	
	self.next_activity = nil
	self.next_sequence = nil
	
	self.use_bodymoveyaw = false

	self:RSNBInitAnimationBlink()
end




function ENT:UpdateAnimation()
	self:UpdateBlink()
	
	local top = self.activity_stack:Top()
	if istable(top) then
		if top[2] > 0 and CurTime() >= top[2] then
			self:PopActivity()
		end
	end
	
	if not self.frozen and not self.pausing then
		if self.next_activity != nil then
			if DEBUG_ANIMATION:GetBool() then
				print( self, "Set activity", self.next_activity )
			end
			self:StartActivity( self.next_activity )
			self.next_activity = nil
		end
		
		if self.next_sequence != nil then
			if DEBUG_ANIMATION:GetBool() then
				print( self, "Set sequence", self.next_sequence )
			end
			self:PlaySequence( self.next_sequence )
			self.next_sequence = nil
		end
	end
end




function ENT:BodyUpdate()
	if self.frozen or self.pausing then return end

	local act = self:GetActivity()
	
	if act == ACT_RUN or act == ACT_WALK or act == ACT_WALK_STEALTH or act == ACT_RUN_STEALTH then
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
	
	self.next_activity = act
	
	if act == ACT_RUN then
		self.next_sequence = "run_all_panicked"
	elseif act == ACT_WALK then
		self.next_sequence = "walk_all_Moderate"
	elseif act == ACT_WALK_STEALTH or act == ACT_RUN_STEALTH then
		self.next_sequence = "idle_subtle"
	end
	
	self.activity_stack:Push( {act, endtime} )
end




function ENT:PopActivity()
	if DEBUG_ANIMATION:GetBool() then
		print( self, "PopActivity" )
	end
	
	if self.activity_stack:Size() > 0 then
		self.next_activity = self.activity_stack:Pop()
	end
end