print( "cl_intro" )




local doing_anim = false
local anim_prev_t = 0
local anim_start = 0

local ANIM_LOGO_VISIBLE_DURATION = 32
local ANIM_HALF_DURATION = 55
local ANIM_DURATION = 65




local CAM_POS_ANIM = TV_ANIM_TRACK:create( {
	{	t = 0.0,		v = Vector(10322,15371,12417),		i = TV_ANIM_TRACK.INTERP_LINEAR },
	{	t = 20.15,		v = Vector(11131,15371,12417),		i = TV_ANIM_TRACK.INTERP_EASEOUT_SINE },
	{	t = 24.0,		v = Vector(11231,15371,12417),		i = TV_ANIM_TRACK.INTERP_EASEIN_SINE },
	{	t = 32.0,		v = Vector(11232,12290,12417),		i = TV_ANIM_TRACK.INTERP_EASEOUT_SINE },
	{	t = 46.0,		v = Vector(11524,7500,12229),		i = TV_ANIM_TRACK.INTERP_EASEIN_SINE },
	{	t = 55.0,		v = Vector(11524,9000,12229) },
	
}, TV_ANIM_TRACK.OUTPUT_TYPE_VECTOR )

local CAM_ANG_ANIM = TV_ANIM_TRACK:create( {
	{	t = 0.0,		v = Angle(0,-90,90),					i = TV_ANIM_TRACK.INTERP_HOLD },
	{	t = 24.0,		v = Angle(0,-90,90),					i = TV_ANIM_TRACK.INTERP_SINE },
	{	t = 30.0,		v = Angle(0,-90,0),						i = TV_ANIM_TRACK.INTERP_EASEIN_SINE },
	{	t = 32.0,		v = Angle(0,-190,0),					i = TV_ANIM_TRACK.INTERP_EASEOUT_SINE },
	{	t = 40.0,		v = Angle(0,-270,0),					i = TV_ANIM_TRACK.INTERP_HOLD },
	{	t = 55.0,		v = Angle(0,-270,0) },
}, TV_ANIM_TRACK.OUTPUT_TYPE_ANGLE )

local CAM_FOV_ANIM = TV_ANIM_TRACK:create( {
	{	t = 0.0,		v = 10,									i = TV_ANIM_TRACK.INTERP_HOLD },
	{	t = 24.0,		v = 10,									i = TV_ANIM_TRACK.INTERP_EASEIN_SINE },
	{	t = 32.0,		v = 45,									i = TV_ANIM_TRACK.INTERP_HOLD },
	{	t = 32.0,		v = 45 },
}, TV_ANIM_TRACK.OUTPUT_TYPE_NUMBER )

local CAM_CONTRAST_ANIM
if GetConVar("mat_hdr_level"):GetInt() > 0 then
	CAM_CONTRAST_ANIM = TV_ANIM_TRACK:create( {
		{	t = 0.0,		v = 200,								i = TV_ANIM_TRACK.INTERP_HOLD },
		{	t = 32.0,		v = 800,								i = TV_ANIM_TRACK.INTERP_HOLD },
		{	t = 42.0,		v = 800,								i = TV_ANIM_TRACK.INTERP_EASEIN_SINE },
		{	t = 55.0,		v = 0,									i = TV_ANIM_TRACK.INTERP_LINEAR },
		{	t = 65.0,		v = 100 },
	}, TV_ANIM_TRACK.OUTPUT_TYPE_NUMBER )
else
	CAM_CONTRAST_ANIM = TV_ANIM_TRACK:create( {
		{	t = 0.0,		v = 100,								i = TV_ANIM_TRACK.INTERP_HOLD },
		{	t = 32.0,		v = 400,								i = TV_ANIM_TRACK.INTERP_HOLD },
		{	t = 42.0,		v = 400,								i = TV_ANIM_TRACK.INTERP_EASEIN_SINE },
		{	t = 55.0,		v = 0,									i = TV_ANIM_TRACK.INTERP_LINEAR },
		{	t = 65.0,		v = 100 },
	}, TV_ANIM_TRACK.OUTPUT_TYPE_NUMBER )
end


local CAM_BLUR_ANIM = TV_ANIM_TRACK:create( {
	{	t = 0.0,		v = 1,									i = TV_ANIM_TRACK.INTERP_HOLD },
	{	t = 44.0,		v = 1,									i = TV_ANIM_TRACK.INTERP_EASEIN_SINE },
	{	t = 55.0,		v = 100,								i = TV_ANIM_TRACK.INTERP_HOLD },
	{	t = 55.0,		v = 10,									i = TV_ANIM_TRACK.INTERP_LINEAR },
	{	t = 65.0,		v = 0 },
}, TV_ANIM_TRACK.OUTPUT_TYPE_NUMBER )




net.Receive( "TV_IntroAnim_Run", function( len )
	doing_anim = true
	anim_start = RealTime()
	anim_prev_time = -1
	
	CAM_POS_ANIM:Restart( anim_start )
	CAM_ANG_ANIM:Restart( anim_start )
	CAM_FOV_ANIM:Restart( anim_start )
	CAM_CONTRAST_ANIM:Restart( anim_start )
	CAM_BLUR_ANIM:Restart( anim_start )
end )




net.Receive( "TV_IntroAnim_Skip", function( len )
	anim_start = RealTime() - ANIM_HALF_DURATION
	CAM_POS_ANIM:SetStartTime( anim_start )
	CAM_ANG_ANIM:SetStartTime( anim_start )
	CAM_FOV_ANIM:SetStartTime( anim_start )
	CAM_CONTRAST_ANIM:SetStartTime( anim_start )
	CAM_BLUR_ANIM:SetStartTime( anim_start )
end )




hook.Add( "RenderScreenspaceEffects", "TV_ClIntroAnim_RenderScreenspaceEffects", function()
	if doing_anim then
		local t = RealTime() - anim_start
	
		if t > ANIM_DURATION then
			net.Start( "TV_IntroAnim_Over" )
			net.SendToServer()
			
			doing_anim = false
		end
		
		local contrast_amount = CAM_CONTRAST_ANIM:GetOutput()/100
		if contrast_amount != 1 then
			local color_mod = {}
			color_mod["$pp_colour_addr"] = 0
			color_mod["$pp_colour_addg"] = 0
			color_mod["$pp_colour_addb"] = 0
			color_mod["$pp_colour_brightness"] = 0
			color_mod["$pp_colour_contrast"] = contrast_amount
			color_mod["$pp_colour_colour"] = 1
			color_mod["$pp_colour_mulr"] = 0
			color_mod["$pp_colour_mulg"] = 0
			color_mod["$pp_colour_mulb"] = 0
			
			DrawColorModify( color_mod )
		end
		
		local blur_amount = CAM_BLUR_ANIM:GetOutput()/100
		if blur_amount > 0 then
			render.CheapBlur( blur_amount*ScrH()*0.1 )
		end
		
		if anim_prev_t < ANIM_HALF_DURATION and t >= ANIM_HALF_DURATION then
			net.Start( "TV_IntroAnim_HalfOver" )
			net.SendToServer()
		end
		
		anim_prev_t = t
	end
end )




hook.Add( "PostGamemodeCalcView", "TV_ClIntroAnim_PostGamemodeCalcView", function( ply, data )
	if doing_anim then
		local t = RealTime()
		
		CAM_BLUR_ANIM:Update( t )
		CAM_CONTRAST_ANIM:Update( t )
		
		if t < anim_start + ANIM_HALF_DURATION then
		
			CAM_POS_ANIM:Update( t )
			CAM_ANG_ANIM:Update( t )
			CAM_FOV_ANIM:Update( t )
			
			data.origin = CAM_POS_ANIM:GetOutput()
			data.angles = CAM_ANG_ANIM:GetOutput()
			data.fov = CAM_FOV_ANIM:GetOutput()
			
		else
		
			local p = ( t - anim_start - ANIM_HALF_DURATION ) / ( ANIM_DURATION - ANIM_HALF_DURATION )
			p = math.sin( math.rad( Lerp( p, 0, 90) ) )
			
			data.origin = LerpVector( p, data.origin + data.angles:Forward() * 15, data.origin )
			data.fov = Lerp( p, 45, GAMEMODE.FOV )
		end
	end
end )