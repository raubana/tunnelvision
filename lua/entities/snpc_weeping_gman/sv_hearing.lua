local DEBUG_HEARING = CreateConVar("twg_debug_hearing", "0", FCVAR_SERVER_CAN_EXECUTE+FCVAR_NOTIFY+FCVAR_CHEAT)
local HEARING_DISABLED = CreateConVar("twg_hearing_disabled", "0", FCVAR_SERVER_CAN_EXECUTE+FCVAR_NOTIFY+FCVAR_CHEAT)




function ENT:HearingInit()
	
end




local function DBToRadius( db, volume )
	return volume * (-(0.0003*math.pow(db, 4)) + (0.0766*math.pow(db, 3)) - (4.5372*math.pow(db, 2)) + (109.05*db) - 902.64)
end




function ENT:HearSound( data )
	if self.frozen or HEARING_DISABLED:GetBool() then return end

	if (self.have_target and data.Entity == self.target) or (self.have_old_target and data.Entity == self.old_target) then
		if CurTime() - self.target_last_seen > 1.0 then
			local pos = data.Pos
			if not isvector(pos) then
				pos = data.Entity:GetPos()
			end
			
			local dist = pos:Distance(self:GetPos())
			local sound_radius = DBToRadius(data.SoundLevel, data.Volume)
			local chance = math.Clamp( 1-(dist/sound_radius), 0, 1)
			local guaranteed = math.pow( chance, 2 )
			local radius = Lerp(chance, 0.5, 0.1) * dist
			
			if DEBUG_HEARING:GetBool() then
				print( chance, data.Volume, dist, radius )
			end
			
			local r = math.random()
			
			if r < guaranteed or ( self.listening and r < chance ) then
				if DEBUG_HEARING:GetBool() then
					print( self, "I heard that!" )
				end
				
				if not self.have_target then
					self:SetNewTarget(self.old_target)
					self.interrupt = true
					self.interrupt_reason = "heard target"
				end
				
				self.target_last_known_position = self:FindSpot("near", {
					pos = pos,
					radius = radius
				})
				
				if not isvector(self.target_last_known_position) then
					self.target_last_known_position = pos
				end
			elseif not self.have_target and not self.listening and r < chance then
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
			ent:HearSound( data )
		end
	end
end )