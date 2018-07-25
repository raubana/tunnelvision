print( "cl_init" )




include( "shared.lua" )
include( "tv_anim_track.lua" )
include( "cl_intro.lua" )
include( "cl_dof.lua" )
include( "cl_tunnelvision.lua" )




local SHOW_SCALELINES = CreateConVar("tv_show_scalelines", "0", bit.bor( FCVAR_CHEAT ))




local has_died = has_died or false
local death_start = death_start or 0




local rt = GetRenderTarget( "tv_death_frame", ScrW(), ScrH() )
local mat_data = {}
local mat = CreateMaterial("tv_death_frame", "UnlitGeneric", mat_data)
local next_deathframe_update = 0
local next_deathframe_grab = 0




hook.Add( "InitPostEntity", "TV_ClInit_InitPostEntity", function()
	timer.Simple( 10.0, function()
		net.Start( "TV_PlayerSpawnedOnClient" )
		net.SendToServer()
	end )
end )




function GM:RenderScreenspaceEffects()
	if has_died then
			
		mat:SetTexture( "$basetexture", rt )
		render.SetMaterial( mat )
		render.DrawScreenQuad()
		
		if RealTime() - death_start < 0.2 then
			
			local p = ((math.sin(RealTime()*math.pi*20))+1)/2
		
			local color_mod = {}
			color_mod["$pp_colour_addr"] = 0
			color_mod["$pp_colour_addg"] = 0
			color_mod["$pp_colour_addb"] = 0
			color_mod["$pp_colour_brightness"] = Lerp( p, -1, 0 )
			color_mod["$pp_colour_contrast"] = Lerp( p, -3, 3 )
			color_mod["$pp_colour_colour"] = Lerp( p, -3, 3 )
			color_mod["$pp_colour_mulr"] = 1
			color_mod["$pp_colour_mulg"] = 1
			color_mod["$pp_colour_mulb"] = 1
			
			DrawColorModify( color_mod )
			
		else
			
			if RealTime() > next_deathframe_update then
				render.BlurRenderTarget( rt, math.random(3), math.random(3), 1 )
				next_deathframe_update = RealTime() + (1/30)
			end
			
		end
	
	else
		
		if RealTime() > next_deathframe_grab then
		
			render.CopyTexture( render.GetRenderTarget(), rt )
				
			render.PushRenderTarget( rt )
			
			local color_mod = {}
			color_mod["$pp_colour_addr"] = 0
			color_mod["$pp_colour_addg"] = 0
			color_mod["$pp_colour_addb"] = 0
			color_mod["$pp_colour_brightness"] = 0
			color_mod["$pp_colour_contrast"] = 2.5
			color_mod["$pp_colour_colour"] = 1.5
			color_mod["$pp_colour_mulr"] = 1
			color_mod["$pp_colour_mulg"] = 1
			color_mod["$pp_colour_mulb"] = 1
			
			DrawColorModify( color_mod )
			
			render.PopRenderTarget()
			
			next_deathframe_grab = RealTime() + (1/12)
			
		end
	
	end
end




function GM:CalcView( ply, origin, angles, fov, znear, zfar )
	local data = {}
	data.origin = origin
	data.angles = angles
	data.fov = fov
	data.znear = znear
	data.zfar = zfar
	
	data.drawviewer = true
	data.fov = GAMEMODE.FOV
	
	local t = RealTime()
	
	data.origin = origin + Vector(
		Lerp( util.PerlinNoise( t+11, 0.6, 0.1, 2 ), -1, 1 ) * 0.05,
		Lerp( util.PerlinNoise( t+63, 0.5, 0.1, 2 ), -1, 1 ) * 0.05,
		Lerp( util.PerlinNoise( t+92, 0.4, 0.1, 2 ), -1, 1 ) * 0.01
	)
	
	data.angles = angles + Angle(
		Lerp( util.PerlinNoise( t+5, 0.4, 0.1, 2 ), -1, 1 ) * 0.25,
		Lerp( util.PerlinNoise( t+29, 0.5, 0.1, 2 ), -1, 1 ) * 0.25,
		Lerp( util.PerlinNoise( t+45, 0.6, 0.1, 2 ), -1, 1 ) * 0.05
	)
	
	data.origin = data.origin + ( data.angles:Forward() * 10 ) + ( data.angles:Up() * 10 ) - Vector(0,0,10)
	
	if IsValid(ply) then
		ply:DrawShadow( false )
		
		local boneid = ply:LookupBone( "ValveBiped.Bip01_Spine4" )
		ply:ManipulateBoneScale( boneid, vector_origin )
		boneid = ply:LookupBone( "ValveBiped.Bip01_Spine2" ) -- middle
		ply:ManipulateBoneScale( boneid, vector_origin )
	
		boneid = ply:LookupBone( "ValveBiped.Bip01_Head1" )
		ply:ManipulateBoneScale( boneid, vector_origin )
	
		local headpos = ply:GetBonePosition( boneid )
		local dif = headpos - data.origin
		local dist = dif:Length()
		
		if dist > 10 then
			local normal = dif:GetNormalized()
			data.origin = headpos - normal * 10
		end
		
		ply:SetRenderClipPlaneEnabled( false )
		local normal = data.angles:Forward()
		local position = data.origin + ( normal * 5 )
		local dot = normal:Dot( position )
		ply:SetRenderClipPlane( normal, dot )
	end
	
	
	hook.Call( "PostGamemodeCalcView", nil, ply, data )
	
	-- selfie mode lol
	--data.origin = data.origin + data.angles:Forward() * 20
	--data.angles = data.angles + Angle(0,180,0)
	
	return data
end




local DO_NOT_DRAW = {}
DO_NOT_DRAW["CHudAmmo"] = true
DO_NOT_DRAW["CHudChat"] = true
DO_NOT_DRAW["CHudBattery"] = true
DO_NOT_DRAW["CHudHealth"] = true
DO_NOT_DRAW["CHudWeaponSelection"] = true

function GM:HUDShouldDraw( name )
	return not DO_NOT_DRAW[name]
end




function GM:AddDeathNotice( attacker, attackerTeam, inflictor, victim, victimTeam )
	return
end



local expected_weapon = nil
function GM:PlayerBindPress( ply, bind, pressed )
	if bind == "invprev" or bind == "invnext" then
		local all_weps = ply:GetWeapons()
		
		if #all_weps <= 1 then return end
		
		local selected = ply:GetActiveWeapon()
		local index
		for i, wep in ipairs( all_weps ) do
			if wep == selected then
				index = i
				break
			end
		end
		
		if bind == "invprev" then
			index = index - 1
			if index <= 0 then index = #all_weps end
		else
			index = index + 1
			if index > #all_weps then index = 1 end
		end
		
		expected_weapon = all_weps[index]
		
		if expected_weapon.PrintName then
			self:SendMessage( "You switch to your "..expected_weapon.PrintName.."." )
		else
			self:SendMessage( "You switch to something...?" )
		end
	end
end




function GM:CreateMove( cmd )
	if expected_weapon != nil and LocalPlayer():GetActiveWeapon() != expected_weapon and IsValid( expected_weapon ) then
		cmd:SelectWeapon( expected_weapon )
	end
end





local messages = message or {}
local MSG_FADEIN_TIME = 0.2
local MSG_FADEOUT_TIME = 2
local FONT_NAME = "TV_MessageFont"
local FONT_DATA = {
	font = "Times New Roman",
	size = 24,
	antialias = false,
	outline = true
}
surface.CreateFont( FONT_NAME, FONT_DATA )


function GM:SendMessage( msg )
	local msg_data = {}
	msg_data.message = msg
	msg_data.start_time = RealTime()
	msg_data.end_time = RealTime() + 7
	
	table.insert( messages, msg_data )
end




function GM:ClearMessages()
	messages = {}
end




net.Receive( "TV_Message", function( len )
	local msg = net.ReadString()
	
	GAMEMODE:SendMessage( msg )
end )




net.Receive( "TV_OnDeath", function( len )
	death_start = RealTime()
	timer.Simple( 0.3, function()
		RunConsoleCommand( "stopsound" )
		RunConsoleCommand( "stopsoundscape" )
	end )
	has_died = true
	GAMEMODE:ClearMessages()
end )





local COLOR_RED = Color( 255, 0, 0 )

function GM:HUDPaint()
	if has_died then return end

	if #messages > 0 then

		local t = RealTime()

		surface.SetFont( FONT_NAME )

		local y = ScrH() - 10 - draw.GetFontHeight( FONT_NAME )
		local i = #messages
		while i > 0 do
			local msg_data = messages[i]
			
			if t >= msg_data.end_time then
				table.remove( messages, i )
			else
				local text_width, text_height = surface.GetTextSize( msg_data.message )
				
				local a = 1.0
				if t < msg_data.start_time + MSG_FADEIN_TIME then
					a = (t - msg_data.start_time)/MSG_FADEIN_TIME
				elseif t > msg_data.end_time - MSG_FADEOUT_TIME then
					a = (msg_data.end_time - t)/MSG_FADEOUT_TIME
				end
				
				local c = 255 * a
				surface.SetTextColor( Color(0,0,0,c*0.9) )
				surface.SetTextPos( (ScrW()-text_width)/2+3, y+3 )
				surface.DrawText( msg_data.message )
				
				surface.SetTextColor( Color(255,255,255,c) )
				surface.SetTextPos( (ScrW()-text_width)/2, y )
				surface.DrawText( msg_data.message )
				
				y = y - (text_height * a)
			end
			
			i = i - 1
		end
		
	end
	
	if SHOW_SCALELINES:GetBool() then
		local w = ScrW()
		local h = ScrH()
		
		surface.SetDrawColor( COLOR_RED )
		for x = 1,3 do
			local p = x/4
			surface.DrawLine( w*p, 0, w*p, h )
		end
		for y = 1,3 do
			local p = y/4
			surface.DrawLine( 0, h*p, w, h*p )
		end
	end
end