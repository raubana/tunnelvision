function ENT:BodyUpdate()
	if self.frozen then return end

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