include("shared.lua")
include("cl_frozen_lighting_awareness.lua")




function ENT:Initialize()
	self:SetIK( false )
	
	self:FrozenLightingAwarenessInit()
end



function ENT:Think()
	self:FrozenLightingAwarenessUpdate()
	
	self:SetNextClientThink( CurTime() )
	return true -- is this needed for the client think?
end