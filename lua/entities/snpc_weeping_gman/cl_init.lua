include("shared.lua")
include("cl_frozen_lighting_awareness.lua")




function ENT:Initialize()
	self:SetIK( false )
	self:DrawShadow( false )
	
	util.PrecacheSound( "npc/fast_zombie/fz_scream1.wav" )
	util.PrecacheSound( "npc/zombie_poison/pz_breathe_loop2.wav" )
	util.PrecacheSound( "npc/fast_zombie/breathe_loop1.wav" )
	
	self:FrozenLightingAwarenessInit()
end



function ENT:Think()
	self:FrozenLightingAwarenessUpdate()
	
	self:SetNextClientThink( CurTime() )
	return true -- is this needed for the client think?
end