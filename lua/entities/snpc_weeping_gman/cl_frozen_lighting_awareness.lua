local DEBUG_FROZEN_LIGHTING_AWARENESS = GetConVar("twg_debug_frozen_lighting_awareness")




function ENT:FrozenLightingAwarenessInit()
	self.frozen_lighting_can_see = true
	self.frozen_last_freezer_bone = nil
end



function ENT:FrozenLightingAwarenessSetCanSee( state )
	if state != self.frozen_lighting_can_see then
		if DEBUG_FROZEN_LIGHTING_AWARENESS:GetBool() then
			print( self, "CAN SEE:", state )
		end
	
		self.frozen_lighting_can_see = state
		
		net.Start("PlayerStateCanSeeWeepingGman")
		net.WriteBool( state )
		net.WriteEntity( self )
		net.SendToServer()
	end
end



local LIGHT_THRESHOLD = 0.005



local TEST_DIRECTIONS = {
	vector_up,
	Vector(1,0,0),
	Vector(-1,0,0),
	Vector(0,1,0),
	Vector(0,-1,0),
	-vector_up
}

local function GetMaxLightingAt( pos )
	local max = 0
	
	for i, dir in ipairs(TEST_DIRECTIONS) do
		local light = render.ComputeLighting(pos, dir)
		max = math.max( max, light.x, light.y, light.z )
	end
	
	return max
end



function ENT:FrozenLightingAwarenessUpdate()
	local localplayer = LocalPlayer()
	local can_see = false
	
	if not self:IsDormant() and localplayer:Alive() then
		-- check how illuminated I am.
		local my_pos = self:GetPos() + Vector(0,0,60)
		
		local max = GetMaxLightingAt(my_pos)
		
		if max >= LIGHT_THRESHOLD then
			can_see = true
		else
			local bone_list = table.Copy( self.TraceBones )
			if table.HasValue( bone_list, self.frozen_last_freezer_bone ) then
				if bone_list[1] != self.frozen_last_freezer_bone then
					table.RemoveByValue( bone_list, self.frozen_last_freezer_bone )
					table.insert( bone_list, self.frozen_last_freezer_bone, 1 )
				end
			end
		
			-- check how illuminated the area behind me is.
			for i, bone_id in ipairs(self.TraceBones) do
				local bone_pos = self:GetBonePosition(bone_id)
			
				local start = localplayer:EyePos()
				local dif = bone_pos - start
				local norm = dif:GetNormalized()
				local endpos = start + (norm * 100000)
				
				local dif_length = dif:Length()
				local trace_length = endpos:Distance(start)
				
				local tr = util.TraceLine({
					start = localplayer:EyePos(),
					endpos = endpos,
					mask = MASK_OPAQUE,
					filter = {self, localplayer}
				})
				
				if tr.Fraction > dif_length / trace_length then
					local max2 = GetMaxLightingAt(tr.HitPos + (tr.HitNormal * 1))
					
					if max2 >= LIGHT_THRESHOLD then
						can_see = true
						self.frozen_last_freezer_bone = bone_id
						break
					end
				end
			end
		end
	end
	
	self:FrozenLightingAwarenessSetCanSee( can_see )
end
