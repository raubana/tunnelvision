include( "sv_frozen_lighting_awareness.lua" )




function ENT:FrozenInit()
	self.frozen = false
	
	self:FrozenLightingAwarenessInit()
end



function ENT:CheckShouldBeFrozen()
	local ply_list = player.GetAll()
	
	for i, ply in ipairs(ply_list) do
		if ply:Alive() then
			if self:Visible( ply ) then
				local view_ang_dif = (self:GetHeadPos() - ply:GetShootPos()):Angle() - ply:EyeAngles()
				view_ang_dif:Normalize()
				
				if math.abs( view_ang_dif.yaw ) < 80 and math.abs( view_ang_dif.pitch ) < 80 then
					if self:FrozenLightingAwarenessGetPlayerCanSeeMe( ply ) then
						return true
					elseif ply:FlashlightIsOn() and math.abs( view_ang_dif.yaw ) < 45 and math.abs( view_ang_dif.pitch ) < 45 then
						return true
					end
				end
			else
				-- check ahead on the path
				if self.path then
					local current_dist = self.path:GetCursorPosition()
					local test_pos = self.path:GetPositionOnPath(current_dist+100) + Vector(0,0,25)
					
					local view_ang_dif = (test_pos - ply:GetShootPos()):Angle() - ply:EyeAngles()
					view_ang_dif:Normalize()
					
					if math.abs( view_ang_dif.yaw ) < 80 and math.abs( view_ang_dif.pitch ) < 80 then
						return true
					end
				end
			end
		end
	end
	
	return false
end




function ENT:FrozenUpdate()
	local old_state = self.frozen
	local new_state = self:CheckShouldBeFrozen()
	
	if old_state != new_state then
		self.frozen = new_state -- TODO: Hook stuff
		print( self, "NEW FROZEN STATE:", new_state )
	end
	
	if self.frozen then
		self.loco:SetVelocity( vector_origin )
	end
end