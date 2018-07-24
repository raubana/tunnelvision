local DEBUG_SOUND = CreateConVar("twg_debug_sound", "0", bit.bor( FCVAR_SERVER_CAN_EXECUTE, FCVAR_NOTIFY, FCVAR_CHEAT, FCVAR_ARCHIVE ) )



function ENT:SoundInit()
	self.sound_current = {}
	self.sound_paused = false
end




function ENT:SoundEmit( soundname, volume, pitch, level, loops )
	if DEBUG_SOUND:GetBool() then
		print( self, "SoundEmit", soundname, volume, pitch, level, loops )
	end

	local sound = self.sound_current[soundname]
	
	if sound == nil then
		if DEBUG_SOUND:GetBool() then
			print( self, "creating new sound instance for", soundname )
		end
	
		filter = RecipientFilter()
		filter:AddAllPlayers()
		sound = CreateSound(
			self,
			soundname,
			filter
		)
		
		sound:SetSoundLevel( level )
		
		local sound_data = {}
		sound_data.sound = sound
		sound_data.volume = volume
		
		if loops then
			sound_data.ends_at = -1
		else
			sound_data.ends_at = CurTime() + SoundDuration( soundname )
		end
		
		if DEBUG_SOUND:GetBool() then
			print( self, "sound ends at", sound_data.ends_at )
		end
		
		self.sound_current[soundname] = sound_data
		
		sound:PlayEx(volume, pitch)
		sound:SetSoundLevel( level )
	end
end




function ENT:SoundStop( soundname )
	if DEBUG_SOUND:GetBool() then
		print( self, "SoundStop", soundname )
	end

	local sound_data = self.sound_current[ soundname ] 
	if sound_data != nil then
		self.sound_current[soundname] = nil
		sound_data.sound:Stop()
		sound_data.sound = nil
		
		if DEBUG_SOUND:GetBool() then
			print( self, "Stopped sound", soundname )
		end
	end
end




function ENT:SoundStopAll( )
	if DEBUG_SOUND:GetBool() then
		print( self, "SoundStopAll" )
	end
	
	for key, sound_data in pairs( self.sound_current ) do
		self:SoundStop( key )
	end
end




function ENT:SoundUpdate()
	if self.sound_paused != (self.frozen or self.pausing) then
		self.sound_paused = (self.frozen or self.pausing)
		
		-- We can't actually pause sounds, soooo...
		
		if self.sound_paused then
			for key, sound_data in pairs( self.sound_current ) do
				sound_data.sound:ChangeVolume( 0, 0.0 )
			end
		else
			for key, sound_data in pairs( self.sound_current ) do
				sound_data.sound:ChangeVolume( sound_data.volume, 0.0 )
			end
		end
		
	else
		for key, sound_data in pairs( self.sound_current ) do
			if sound_data.ends_at > 0 and CurTime() >= sound_data.ends_at then
				if DEBUG_SOUND:GetBool() then
					print( self, "ending sound instance", key )
				end
				
				self:SoundStop( key )
			end
		end
	end
end