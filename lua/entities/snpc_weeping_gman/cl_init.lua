include("shared.lua")
include("cl_frozen_lighting_awareness.lua")




function ENT:Initialize()
	self:SetIK( false )
	
	self:FrozenLightingAwarenessInit()
end



function ENT:Think()
	self:FrozenLightingAwarenessUpdate()
end