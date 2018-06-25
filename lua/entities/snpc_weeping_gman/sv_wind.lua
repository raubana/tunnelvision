function ENT:WindInit()
	self.wind_radius = 25
end




function ENT:WindUpdate()
	local my_pos = LerpVector( 0.5, self:GetPos(), self:GetHeadPos() )

	local vel = self:GetVelocity()
	local speed = vel:Length()
	local norm_vel = vel/speed
	
	local mins = self:OBBMins()
	local maxs = self:OBBMaxs()
	
	if speed > 0 then
		local ent_list = ents.FindInSphere( my_pos, self.wind_radius )
		for i, ent in ipairs( ent_list ) do
			if IsValid(ent) and isfunction(ent.GetPhysicsObject) then
				local phys = ent:GetPhysicsObject()
				
				if IsValid( phys ) then
					local ent_pos = ent:GetPos()
					local nearest_point = Vector(
						math.Clamp( ent_pos.x, mins.x, maxs.x ),
						math.Clamp( ent_pos.y, mins.y, maxs.y ),
						math.Clamp( ent_pos.z, mins.z, maxs.z )
					)
			
					local dif = nearest_point - my_pos
					local dist = dif:Length() - ent:BoundingRadius()
					local norm = dif/dist
					
					phys:ApplyForceOffset( 
						((norm*0.25) + (VectorRand()*0.25) + (norm_vel*0.5)) * math.pow(1-(dist/self.wind_radius), 1) * (speed/10),
						ent:GetPos() - (norm * ent:BoundingRadius() * 0.5 )
					)
				end
			end
		end
	end
end