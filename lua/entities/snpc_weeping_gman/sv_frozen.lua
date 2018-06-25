include( "sv_frozen_lighting_awareness.lua" )




local DEBUG_FROZEN = CreateConVar("twg_debug_frozen", "0", FCVAR_SERVER_CAN_EXECUTE+FCVAR_NOTIFY+FCVAR_CHEAT)
local FROZEN_DISABLE = CreateConVar("twg_frozen_disable", "0", FCVAR_SERVER_CAN_EXECUTE+FCVAR_NOTIFY+FCVAR_CHEAT)




hook.Add( "Initialize", "snpc_weeping_gman_frozen_Initialize", function()
	util.AddNetworkString( "HangFrame" )
end )




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
		local actual_bone_pos = self:GetBonePosition( bone_id )
		local bone_pos = actual_bone_pos + offset
		
		if DEBUG_FROZEN:GetBool() then
			debugoverlay.Cross( bone_pos, 10, engine.TickInterval()*2, color_white, true )
		end
		
		local skip = false
		if offset and not offset:IsZero() then
			if DEBUG_FROZEN:GetBool() then
				debugoverlay.Line( actual_bone_pos, bone_pos, engine.TickInterval()*2, color_white, true )
			end
		
			local tr = util.TraceLine({
				start = actual_bone_pos,
				endpos = bone_pos,
				filter = filter,
				mask = MASK_SOLID
			})
			
			if tr.Hit then
				skip = true
			end
		end
		
		if not skip then
			local tr = util.TraceLine({
				start = start,
				endpos = bone_pos,
				filter = filter,
				mask = MASK_OPAQUE + CONTENTS_IGNORE_NODRAW_OPAQUE + CONTENTS_MONSTER
			})
			
			if not tr.Hit then
				self.frozen_last_freezer_bone = bone_id
				return false
			end
		end
	end
	
	self.frozen_last_freezer_bone = nil
	return true
end



function ENT:CheckShouldBeFrozen()
	if FROZEN_DISABLE:GetBool() then
		return false, nil
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
			
			if math.abs( view_ang_dif.yaw ) < self.player_fov and math.abs( view_ang_dif.pitch ) < self.player_fov then
				if ply:TestPVS(self) and not self:GetIsBlockedByOpaqueObjects( ply:GetShootPos(), {self, ply}) then
					if self:FrozenLightingAwarenessGetPlayerCanSeeMe( ply ) then
						self.frozen_last_freezer = ply
						return true, ply
					elseif ply:FlashlightIsOn() and math.abs( view_ang_dif.yaw ) < self.player_fov_flashlight and math.abs( view_ang_dif.pitch ) < self.player_fov_flashlight then
						if self:GetPos():Distance(ply:GetPos()) < 800 then
							self.frozen_last_freezer = ply
							return true, ply
						end
					end
				end
			end
			
			-- check ahead on the path
			if self.path then
				local current_dist = self.path:GetCursorPosition()
				local test_pos = self.path:GetPositionOnPath(current_dist+50)
				
				local view_ang_dif = (test_pos - ply:GetShootPos()):Angle() - ply:EyeAngles()
				view_ang_dif:Normalize()
				
				if math.abs( view_ang_dif.yaw ) < self.player_fov and math.abs( view_ang_dif.pitch ) < self.player_fov then
					if ply:TestPVS(test_pos) and not self:GetIsBlockedByOpaqueObjects( ply:GetShootPos(), {self, ply}, test_pos - self:GetPos()) then
						if self:FrozenLightingAwarenessGetPlayerCanSeeMe( ply ) then
							self.frozen_last_freezer = ply
							return true, nil
						else
							if ply:FlashlightIsOn() and math.abs( view_ang_dif.yaw ) < self.player_fov_flashlight and math.abs( view_ang_dif.pitch ) < self.player_fov_flashlight then
								if self:GetPos():Distance(ply:GetPos()) < 800 then
									self.frozen_last_freezer = ply
									return true, nil
								end
							end
						end
					end
				end
			end
		end
	end
	
	self.frozen_last_freezer = nil
	return false
end




function ENT:FrozenUpdate()
	local old_state = self.frozen
	local new_state, freezer = self:CheckShouldBeFrozen()
	
	if old_state != new_state then
		self.frozen = new_state -- TODO: Hook stuff
		if DEBUG_FROZEN:GetBool() then
			print( self, "NEW FROZEN STATE:", new_state )
		end
		
		if new_state and freezer != nil then
			--net.Start( "HangFrame" )
			--net.Send( freezer )
		end
	end
	
	if self.frozen then
		self.loco:SetVelocity( vector_origin )
	end
end