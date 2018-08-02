local DEBUG_HEARING = CreateConVar("twg_debug_hearing", "0", bit.bor( FCVAR_SERVER_CAN_EXECUTE, FCVAR_NOTIFY, FCVAR_CHEAT, FCVAR_ARCHIVE ) )
local HEARING_DISABLED = CreateConVar("twg_hearing_disabled", "0", bit.bor( FCVAR_SERVER_CAN_EXECUTE, FCVAR_NOTIFY, FCVAR_CHEAT, FCVAR_ARCHIVE ) )
local DISABLE_SENSES_AND_STUFF = GetConVar( "twg_disable_senses_and_stuff" )




function ENT:HearingInit()
	
end




function ENT:HearSound( data )
	if self.frozen or HEARING_DISABLED:GetBool() or DISABLE_SENSES_AND_STUFF:GetBool() then return end

	if self.have_target and data.Entity == self.target then
		if CurTime() - self.target_last_seen > 1.0 and CurTime() - self.target_last_heard > 3.0 then
			local pos = data.Pos
			if not isvector(pos) then
				pos = data.Entity:GetPos()
			end
			
			local dist = pos:Distance(self:GetPos())
			local sound_radius = util.DBToRadius(data.SoundLevel, data.Volume) * 1.75
			local chance = math.pow( math.Clamp( 1-(dist/sound_radius), 0, 1), 2 )
			local guaranteed = math.max( Lerp( math.pow( chance, 2 ), -0.5, 1.5), 0 )
			local radius = dist * 0.3
			
			if DEBUG_HEARING:GetBool() then
				print( chance, guaranteed, data.Volume, dist, radius )
			end
			
			local r = math.random()
			
			if r < guaranteed or ( r < chance and (self.listening or self.pausing or self.frozen) ) then
				if DEBUG_HEARING:GetBool() then
					print( self, "I heard that!" )
				end
				
				self.target_last_known_position = self:FindSpot("near", {
					pos = pos,
					radius = radius
				})
				
				if not isvector(self.target_last_known_position) then
					self.target_last_known_position = pos
				end
				
				self.target_last_heard = CurTime()
			elseif r < chance then
				if DEBUG_HEARING:GetBool() then
					print( self, "I think I heard something..." )
				end
				
				self.interrupt = true
				self.interrupt_reason = "heard something"
			end
		end
	end
end




hook.Add( "EntityEmitSound", "snpc_weeping_gman_EntityEmitSound", function( data )
	local ent_list = ents.FindByClass( "snpc_weeping_gman" )
	for i, ent in ipairs( ent_list ) do
		if IsValid(ent) then
			local result = hook.Call( "PreventEntityEmitSoundHookForHearingEntity", nil, ent)
			
			if result == true then
				-- surpress the event. this allows the gamemode to handle the sound first.
			else
				ent:HearSound( data )
			end
		end
	end
end )