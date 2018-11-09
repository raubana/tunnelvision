TV_SMOOTHER = TV_SMOOTHER or {}

TV_SMOOTHER.INTERP_LINEAR = 0




function TV_SMOOTHER:create( smoothingduration, samples_per_duration, startamount )
	startamount = startamount or 0.0

	local instance = {}
	setmetatable(instance,self)
	self.__index = self
	
	instance.smoothingduration = smoothingduration
	instance.samples_per_duration = samples_per_duration
	
	instance.prev_average = startamount
	instance.next_average = startamount
	
	instance.time_of_next_sample = RealTime() + smoothingduration/samples_per_duration
	instance.new_sample_flag = false
	
	instance.samples = {}
	instance.sample_index_offset = 0
	for i = 0, samples_per_duration do
		table.insert( instance.samples, startamount )
	end
	
	return instance
end




function TV_SMOOTHER:Update( val )
	--print( self, "update" )
	
	--PrintTable( self.samples )

	local t = RealTime()
	
	if t >= self.time_of_next_sample then
		--print( self, "SAMPLE" )
		
		self.new_sample_flag = true
		
		self.time_of_next_sample = t + self.smoothingduration/self.samples_per_duration
		
		self.sample_index_offset = (self.sample_index_offset + 1) % #self.samples
		
		self.samples[self.sample_index_offset+1] = val
		
		self.prev_average = 1.0*self.next_average
		self.next_average = 0.0
		
		for i = 1, #self.samples do
			self.next_average = self.next_average + self.samples[i]
		end
		self.next_average = self.next_average / #self.samples
	end
end




function TV_SMOOTHER:GetValue()
	local t = RealTime()
	
	local time_before_next_sample = self.time_of_next_sample - t
	local p = 1 - (time_before_next_sample*self.samples_per_duration/self.smoothingduration)
	
	--[[
	local buffer = {}
	for i = 1, #self.samples do
		buffer[i] = self.samples[(i-self.sample_index_offset)%#self.samples+1]
	end
	
	for i = #buffer, 1, -1 do
		for j = 1, i-1 do
			buffer[j] = Lerp(p, buffer[j], buffer[j+1])
		end
	end
	
	return buffer[1]
	]]
	
	return Lerp( p, self.prev_average, self.next_average )
end


