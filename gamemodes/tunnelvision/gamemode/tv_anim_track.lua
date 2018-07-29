TV_ANIM_TRACK = TV_ANIM_TRACK or {}

TV_ANIM_TRACK.INTERP_LINEAR = 0
TV_ANIM_TRACK.INTERP_SINE = 1
TV_ANIM_TRACK.INTERP_HOLD = 2
TV_ANIM_TRACK.INTERP_EASEIN = 3
TV_ANIM_TRACK.INTERP_EASEIN_SINE = 4
TV_ANIM_TRACK.INTERP_EASEOUT = 5
TV_ANIM_TRACK.INTERP_EASEOUT_SINE = 6

-- EASEIN and EASEOUT (exponential) might not be working right.

TV_ANIM_TRACK.OUTPUT_TYPE_NUMBER = 0
TV_ANIM_TRACK.OUTPUT_TYPE_VECTOR = 1
TV_ANIM_TRACK.OUTPUT_TYPE_ANGLE = 2




function TV_ANIM_TRACK:create( anim_data, output_type )
	local instance = {}
	setmetatable(instance,self)
	self.__index = self
	
	instance.anim_data = anim_data
	instance.output_type = output_type
	
	instance.i = 1
	instance.start_t = 0
	instance.done = false
	instance.output = nil
	
	return instance
end




function TV_ANIM_TRACK:Restart( t )
	self.i = 1
	self.last_t = 0
	self.start_t = t
	self.done = false
end




function TV_ANIM_TRACK:SetStartTime( t )
	self.start_t = t
end




function TV_ANIM_TRACK:Update( t )
	if self.done then return end
	
	local t2 = t - self.start_t
	
	while self.i < #self.anim_data do
		local next_data = self.anim_data[self.i+1]
		
		if next_data.t <= t2 then
			self.i = self.i + 1
		else
			local current_data = self.anim_data[self.i]
			
			local dur = next_data.t - current_data.t
			local p = (t2-current_data.t)/dur
			
			local interp = current_data.i
			
			if interp == TV_ANIM_TRACK.INTERP_SINE then
				p = ( math.sin( math.rad( Lerp( p, -90, 90) ) ) + 1 ) / 2
			elseif interp == TV_ANIM_TRACK.INTERP_HOLD then
				p = 0
			elseif interp == TV_ANIM_TRACK.INTERP_EASEIN then
				p = math.pow( p, 1/current_data.x )
			elseif interp == TV_ANIM_TRACK.INTERP_EASEIN_SINE then
				p = 1 - math.sin( math.rad( Lerp( p, 90, 180) ) )
			elseif interp == TV_ANIM_TRACK.INTERP_EASEOUT then
				p = math.pow( p, current_data.x )
			elseif interp == TV_ANIM_TRACK.INTERP_EASEOUT_SINE then
				p = math.sin( math.rad( Lerp( p, 0, 90) ) )
			end
			
			if self.output_type == TV_ANIM_TRACK.OUTPUT_TYPE_NUMBER then
				self.output = Lerp( p, current_data.v, next_data.v )
			elseif self.output_type == TV_ANIM_TRACK.OUTPUT_TYPE_VECTOR then
				self.output = LerpVector( p, current_data.v, next_data.v )
			elseif self.output_type == TV_ANIM_TRACK.OUTPUT_TYPE_ANGLE then
				self.output = LerpAngle( p, current_data.v, next_data.v )
			else
				print( self, "Warning: received unknown type." )
			end
			
			break
		end
	end
	
	if self.i >= #self.anim_data then
		self.done = true
	end
end




function TV_ANIM_TRACK:GetOutput()
	return self.output
end




function TV_ANIM_TRACK:IsDone()
	return self.done
end
