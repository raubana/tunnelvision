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




function ENT:Draw()
	render.SuppressEngineLighting( true )
	
	local top_light = vector_origin
	local bottom_light = vector_origin
	local front_light = vector_origin
	local back_light = vector_origin
	local left_light = vector_origin
	local right_light = vector_origin
	
	local samples = 0
	
	for y = 10,70,25 do
		local pos = self:GetPos() + Vector(0,0,y)
	
		top_light = top_light + render.ComputeLighting(pos, Vector(0,0,1))
		bottom_light = bottom_light + render.ComputeLighting(pos, Vector(0,0,-1))
		front_light = front_light + render.ComputeLighting(pos, Vector(1,0,0))
		back_light = back_light + render.ComputeLighting(pos, Vector(-1,0,0))
		left_light = left_light + render.ComputeLighting(pos, Vector(0,-1,0))
		right_light = right_light + render.ComputeLighting(pos, Vector(0,1,0))
		
		samples = samples + 1
	end
	
	top_light = top_light/samples
	bottom_light = bottom_light/samples
	front_light = front_light/samples
	back_light = back_light/samples
	left_light = left_light/samples
	right_light = right_light/samples
	
	render.SetModelLighting(BOX_TOP, top_light.x, top_light.y, top_light.z)
	render.SetModelLighting(BOX_BOTTOM, bottom_light.x, bottom_light.y, bottom_light.z)
	render.SetModelLighting(BOX_FRONT, front_light.x, front_light.y, front_light.z)
	render.SetModelLighting(BOX_BACK, back_light.x, back_light.y, back_light.z)
	render.SetModelLighting(BOX_LEFT, left_light.x, left_light.y, left_light.z)
	render.SetModelLighting(BOX_RIGHT, right_light.x, right_light.y, right_light.z)
	
	self:DrawModel()
	
	render.SuppressEngineLighting( false )
end