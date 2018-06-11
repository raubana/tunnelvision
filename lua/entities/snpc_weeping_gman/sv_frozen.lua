include( "sv_frozen_lighting_awareness.lua" )




local DEBUG_FROZEN = CreateConVar("twg_debug_frozen", "0", FCVAR_SERVER_CAN_EXECUTE+FCVAR_NOTIFY+FCVAR_CHEAT)
local FROZEN_DISABLE = CreateConVar("twg_frozen_disable", "0", FCVAR_SERVER_CAN_EXECUTE+FCVAR_NOTIFY+FCVAR_CHEAT)




function ENT:FrozenInit()
	self.frozen = false
	self.frozen_last_freezer = nil
	self.frozen_last_freezer_bone = nil
	
	self:FrozenLightingAwarenessInit()
end



function ENT:GetIsBlockedByOpaqueObjects( start, filter, offset )
	local offset = offset or vector_origin
	local bone_list = table.Copy( self.TraceBones )
	if table.HasValue( bone_list, self.frozen_last_freezer_bone ) then
		if bone_list[1] != self.frozen_last_freezer_bone then
			table.RemoveByValue( bone_list, self.frozen_last_freezer_bone )
			table.insert( bone_list, self.frozen_last_freezer_bone, 1 )
		end
	end
	
	for i, bone_id in ipairs(bone_list) do
		local bone_pos = self:GetBonePosition( bone_id ) + offset
		
		-- debugoverlay.Cross( bone_pos, 10, engine.TickInterval()*2, color_white, true )
	
		local tr = util.TraceLine({
			start = start,
			endpos = bone_pos,
			filter = filter,
			mask = MASK_OPAQUE
		})
		
		if not tr.Hit then
			self.frozen_last_freezer_bone = bone_id
			return false
		end
	end
	
	return true
end



function ENT:CheckShouldBeFrozen()
	if FROZEN_DISABLE:GetBool() then
		return false
	end
	
	local ply_list = player.GetAll()
	
	if table.HasValue( ply_list, self.frozen_last_freezer ) then
		if ply_list[1] != self.frozen_last_freezer then
			table.RemoveByValue( ply_list, self.frozen_last_freezer )
			table.insert( ply_list, self.frozen_last_freezer, 1 )
		end
	end
	
	for i, ply in ipairs(ply_list) do
		if ply:Alive() then
			local view_ang_dif = (self:GetHeadPos() - ply:GetShootPos()):Angle() - ply:EyeAngles()
			view_ang_dif:Normalize()
			
			if math.abs( view_ang_dif.yaw ) < 90 and math.abs( view_ang_dif.pitch ) < 90 and ply:TestPVS(self) and not self:GetIsBlockedByOpaqueObjects( ply:GetShootPos(), {self, ply}) then
				if self:FrozenLightingAwarenessGetPlayerCanSeeMe( ply ) then
					self.frozen_last_freezer = ply
					return true
				elseif ply:FlashlightIsOn() and math.abs( view_ang_dif.yaw ) < 45 and math.abs( view_ang_dif.pitch ) < 45 then
					if self:GetPos():Distance(ply:GetPos()) < 800 then
						self.frozen_last_freezer = ply
						return true
					end
				end
			else
				-- check ahead on the path
				if self.path then
					local current_dist = self.path:GetCursorPosition()
					local test_pos = self.path:GetPositionOnPath(current_dist+50)
					
					local view_ang_dif = (test_pos - ply:GetShootPos()):Angle() - ply:EyeAngles()
					view_ang_dif:Normalize()
					
					if math.abs( view_ang_dif.yaw ) < 90 and math.abs( view_ang_dif.pitch ) < 90 then
						if ply:TestPVS(test_pos) and not self:GetIsBlockedByOpaqueObjects( ply:GetShootPos(), {self, ply}, test_pos - self:GetPos()) then
							if self:FrozenLightingAwarenessGetPlayerCanSeeMe( ply ) then
								return true
							else
								if ply:FlashlightIsOn() and math.abs( view_ang_dif.yaw ) < 45 and math.abs( view_ang_dif.pitch ) < 45 then
									if self:GetPos():Distance(ply:GetPos()) < 800 then
										self.frozen_last_freezer = ply
										return true
									end
								end
							end
						end
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
		if DEBUG_FROZEN:GetBool() then
			print( self, "NEW FROZEN STATE:", new_state )
		end
	end
	
	if self.frozen then
		self.loco:SetVelocity( vector_origin )
	end
end