function ENT:FrozenLightingAwarenessInit()
	self.frozen_lighting_can_see = true
end



function ENT:FrozenLightingAwarenessSetCanSee( state )
	if state != self.frozen_lighting_can_see then
		print( self, "CAN SEE:", state )
	
		self.frozen_lighting_can_see = state
		
		net.Start("PlayerStateCanSeeWeepingGman")
		net.WriteBool( state )
		net.WriteEntity( self )
		net.SendToServer()
	end
end



local LIGHT_THRESHOLD = 0.0001



function ENT:FrozenLightingAwarenessUpdate()
	local localplayer = LocalPlayer()
	
	local can_see = false
	
	-- check how illuminated I am.
	local my_pos = self:GetPos() + Vector(0,0,40)
	
	local light_at_me = render.GetLightColor(my_pos)
	local max = math.max(light_at_me.x, light_at_me.y, light_at_me.z)
	
	if max >= LIGHT_THRESHOLD then
		can_see = true
	else
		-- check how illuminated the area behind me is.
		local start = localplayer:EyePos()
		local norm = my_pos - start
		norm:Normalize()
		local endpos = start + (norm * 100000)
		
		local tr = util.TraceLine({
			start = localplayer:EyePos(),
			endpos = endpos,
			mask = MASK_OPAQUE,
			filter = {self, localplayer}
		})
		
		local light_at_hit = render.GetLightColor(tr.HitPos + (tr.Normal * 1))
		local max2 = math.max(light_at_hit.x, light_at_hit.y, light_at_hit.z)
		
		if max2 >= LIGHT_THRESHOLD then
			can_see = true
		end
	end
	
	self:FrozenLightingAwarenessSetCanSee( can_see )
end
