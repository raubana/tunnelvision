function ENT:WindInit()
	self.wind_distance = 16
end




function ENT:WindUpdate()
	local my_pos = LerpVector( 0.5, self:GetPos(), self:GetHeadPos() )

	local my_vel = self:GetVelocity()
	local speed = my_vel:Length()
	
	if speed > 0 then
		local mins = self:GetPos() + self:OBBMins()
		local maxs = self:GetPos() + self:OBBMaxs()
		
		local my_vel_norm = my_vel / speed
	
		local ent_list = ents.FindInSphere( my_pos, self.wind_distance+64 )
		for i, ent in ipairs( ent_list ) do
			if IsValid(ent) and isfunction(ent.GetPhysicsObject) then
				local phys = ent:GetPhysicsObject()
				
				if IsValid( phys ) then
					local ent_pos = ent:GetPos()
					local ent_radius = ent:BoundingRadius()
					local ent_vel = phys:GetVelocity()
					
					local my_nearest_pos = Vector(
						math.Clamp( ent_pos.x, mins.x, maxs.x ),
						math.Clamp( ent_pos.y, mins.y, maxs.y ),
						math.Clamp( ent_pos.z, mins.z, maxs.z )
					)
					
					local nearest_pos = my_nearest_pos
					
					local dif = nearest_pos - ent_pos
					local dist = nearest_pos:Distance( ent_pos )
					if dist > ent_radius then
						local norm = dif/dist
						nearest_pos = ent_pos + ( norm * ent_radius )
					end
			
					dist = my_nearest_pos:Distance( nearest_pos )
					
					local p = math.Clamp( 1-(dist/self.wind_distance), 0, 1 )
					
					if p > 0 then
						local exp = 0.1*phys:GetMass()
					
						if exp < 1 then
							p = p * (1 - math.pow( exp, engine.TickInterval() ))
							
							local new_vel = LerpVector( p, ent_vel, my_vel * 0.9 )
							
							local dif_norm = ent_pos - my_pos
							dif_norm:Normalize()
							local dot = math.abs( dif_norm:Dot( my_vel_norm ) )
							
							local vortex_pos = my_pos + dif_norm * (self.wind_distance / 2)
							local vortex_dif = ( ent_pos - vortex_pos ):GetNormalized()
							local vortex_dif_norm = vortex_dif:GetNormalized()
							local vortex_axis = my_vel_norm:Cross(vortex_dif_norm)
							local vortex_flow = vortex_axis:Cross(vortex_dif_norm) * speed * 0.25
							
							new_vel = LerpVector( dot, vortex_flow, new_vel )
							
							local force = (new_vel - ent_vel) * phys:GetMass()
							phys:ApplyForceOffset( force, LerpVector( 0.01, ent_pos, nearest_pos ) )
							-- phys:ApplyForceCenter( force )
							
							--debugoverlay.Line( my_pos, vortex_pos, engine.TickInterval()*2, color_white, true )
							--debugoverlay.Line( vortex_pos, vortex_pos + vortex_axis*10, engine.TickInterval()*2, color_white, true )
							--debugoverlay.Line( ent_pos, ent_pos + vortex_flow, engine.TickInterval()*2, color_white, true )
							
						end
					end
				end
			end
		end
	end
end