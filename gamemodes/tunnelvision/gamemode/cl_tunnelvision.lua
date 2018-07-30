print( "cl_tunnelvision" )



include( "sh_tunnelvision.lua" )



local RADIUS = 20
local CLIP_RADIUS = 20.1

local p = 0.0
local hearing_muffled = false




hook.Add( "RenderScreenspaceEffects", "TV_ClTunnelVision_RenderScreenspaceEffects", function()
	local localplayer = LocalPlayer()
	if not IsValid( localplayer ) then return end
	
	local new_p = localplayer:GetTunnelVision()
	p = Lerp( 1-math.pow( 0.5, RealFrameTime()), p, new_p )
	
	if not hearing_muffled and p > 0.5 then
		hearing_muffled = true
		GAMEMODE:SendMessage( "You feel faint." )
		--localplayer:SetDSP( 31 )
	elseif hearing_muffled and p < 0.1 then
		hearing_muffled = false
		GAMEMODE:SendMessage( "You feel better now." )
		--localplayer:SetDSP( 1 )
	end
	
	local new_p = math.invlerp(p, 0.4, 1.0)
	local new_p2 = math.invlerp(p, 0.0, 0.5)
	
	cam.Start3D()
		cam.IgnoreZ( true )
		
		local pos = EyePos()
		local ang = EyeAngles()
		
		local normal = -ang:Forward()
		local dot = normal:Dot( pos + ( - normal * Lerp( math.sin( p * math.pi * 0.5 ), 0, CLIP_RADIUS )  ) )

		render.EnableClipping( true )
		
		render.PushCustomClipPlane( normal, dot )
		
		render.SetColorMaterial()
		local c = Color(0,0,0,255*new_p2)
		render.DrawSphere( pos, -RADIUS, 50, 50, c )
		
		render.PopCustomClipPlane()
		
		render.EnableClipping( false )
		
		cam.IgnoreZ( false )
	cam.End3D()
	
	if new_p > 0.0 then
		local new_p = new_p * new_p
		
		render.CheapBlur( Lerp( new_p, 0.0, 0.1) * ScrH() * 0.5 )
		
		local color_mod = {}
		color_mod["$pp_colour_addr"] = 0
		color_mod["$pp_colour_addg"] = 0
		color_mod["$pp_colour_addb"] = 0
		color_mod["$pp_colour_brightness"] = 0
		color_mod["$pp_colour_contrast"] = Lerp(new_p, 1, 0.1)
		color_mod["$pp_colour_colour"] = 1
		color_mod["$pp_colour_mulr"] = 0
		color_mod["$pp_colour_mulg"] = 0
		color_mod["$pp_colour_mulb"] = 0
		
		DrawColorModify( color_mod )
	end
end )




hook.Add( "PostGamemodeCalcView", "TV_ClTunnelVision_PostGamemodeCalcView", function( ply, data )
	local p = math.invlerp( p, 0.4, 1.0 )
	if p > 0 then
		data.fov = data.fov * Lerp( p, 1.0, 0.25 )
	end
end )