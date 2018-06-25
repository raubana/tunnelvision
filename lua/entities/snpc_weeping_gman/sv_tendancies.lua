



function ENT:TendanciesInit()
	self.home = self:GetPos()
	self.home_angle = self:GetAngles()

	self.returns_to_home = true
	self.hides_that_he_is_looking = true
	self.tries_to_be_quiet = true
	self.stalks_slowly = true
end