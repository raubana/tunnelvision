function ENT:HearingInit()
	
end




function ENT:HearSound( data )
	if self.frozen then return end

	if (self.have_target and CurTime()-self.target_last_seen > 1.0) or self.have_old_target then
		if (self.have_target and data.Entity == self.target) or (self.have_old_target and data.Entity == self.old_target) then
			local pos = data.Pos
			if not isvector(pos) then
				pos = data.Entity:GetPos()
			end
			
			local dist = pos:Distance(self:GetPos())
			local chance = 1/(math.pow(dist/400, 2)+1)
			local radius = dist/2
			
			if math.random() < chance then
				print( "I heard that!" )
				
				if not self.have_target then
					self:SetNewTarget(self.old_target)
					self.interrupt = true
				end
				
				self.target_last_known_position = self:FindSpot("near", {
					pos = pos,
					radius = radius
				})
				
				if not isvector(self.target_last_known_position) then
					self.target_last_known_position = pos
				end
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