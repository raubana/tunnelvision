function ENT:SoundInit()
	self.sound_current = {}
	self.sound_paused = false
end




function ENT:SoundEmit( soundname, volume, pitch, level )
	local sound = self.sound_current[soundname]
	if sound == nil then
		filter = RecipientFilter()
		filter:AddAllPlayers()
		sound = CreateSound(
			self,
			soundname,
			filter
		)
		
		sound:SetSoundLevel( level )
		
		self.sound_current[soundname] = sound
		
		sound:PlayEx(volume, pitch)
	end
end




function ENT:SoundStop( soundname )
	local sound = self.sound_current[ soundname ] 
	if sound != nil then
		self.sound_current[soundname] = nil
		sound:Stop()
		sound = nil
	end
end




function ENT:SoundStopAll( )
	for i, key in ipairs( self.sound_current ) do
		self:SoundStop( key )
	end
end




function ENT:SoundUpdate()
	if self.sound_paused != (self.frozen or self.pausing) then
		local sounds_to_remove = {}
	
		for key, sound in pairs(self.sound_current) do
			if not self.sound_paused then
				self:StopSound(key)
			else
				sound:Play()
			end
		end
		
		for i, key in ipairs( sounds_to_remove ) do
			self:SoundStop( key )
		end
	
		self.sound_paused = self.frozen
	else
		for i, key in ipairs( self.sound_current ) do
			if not self.sound_current[ key ]:IsPlaying() then
				self:SoundStop( key )
			end
		end
	end
end