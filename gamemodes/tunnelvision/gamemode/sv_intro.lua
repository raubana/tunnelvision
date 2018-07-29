print( "sv_intro_anim" )

AddCSLuaFile( "cl_intro.lua" )




local DISABLE_INTRO = CreateConVar("tv_disable_intro", "0", bit.bor( FCVAR_SERVER_CAN_EXECUTE, FCVAR_NOTIFY, FCVAR_CHEAT, FCVAR_ARCHIVE ) )
local LAST_PLAYED = GetConVar("tv_lastplayed")




hook.Add( "Initialize", "TV_SvIntroAnim_Initialize", function()
	util.AddNetworkString("TV_IntroAnim_Run")
	util.AddNetworkString("TV_IntroAnim_HalfOver")
	util.AddNetworkString("TV_IntroAnim_Over")
	util.AddNetworkString("TV_IntroAnim_Skip")
end )




hook.Add( "PlayerSpawn", "TV_ClIntro_PlayerSpawn", function( ply )
	if DISABLE_INTRO:GetBool() then return end
	
	ply:Freeze( true )
end )




function GM:RunIntroAnim()
	if DISABLE_INTRO:GetBool() then return end
	if (os.time() - LAST_PLAYED:GetFloat()) < 60*60 then
		for i, ply in ipairs( player.GetAll() ) do
			ply:Freeze( false )
		end
		return
	end

	local target = ents.FindByName("player_start")[1]
	
	net.Start( "TV_IntroAnim_Run" )
	net.Broadcast()
	
	for i, ply in ipairs( player.GetAll() ) do
		ply.is_doing_intro = true
		ply:Freeze( false )
		
		ply:SetPos( target:GetPos() )
		ply:SetAngles( target:GetAngles() )
		
		if ply:HasWeapon( "swep_tv_cassetteplayer" ) then
			local wep = ply:GetWeapon( "swep_tv_cassetteplayer" )
			wep:TogglePlaybackSilent()
			wep:SetVolumeLoud()
		end
	end
end




net.Receive( "TV_IntroAnim_HalfOver", function( len, ply )
	if ply:HasWeapon( "swep_tv_cassetteplayer" ) then
		local wep = ply:GetWeapon( "swep_tv_cassetteplayer" )
		wep:SetVolumeQuiet()
	end
	
	local target = ents.FindByClass("info_player_start")[1]
	ply:SetPos( target:GetPos() )
	ply:SetAngles( target:GetAngles() )
	
	ply:Freeze( true )
	ply.is_doing_intro = nil
end )




net.Receive( "TV_IntroAnim_Over", function( len, ply )
	ply:Freeze( false )
end )




hook.Add( "StartCommand", "TV_SvIntroAnim_StartCommand", function( ply, ucmd )
	if ply.is_doing_intro then
		local btn = ucmd:GetButtons()
		if btn > 0 then
			ucmd:ClearButtons()
			net.Start( "TV_IntroAnim_Skip" )
			net.Broadcast()
		end
	end
end )




concommand.Add( "tv_run_intro_anim", function( ply, cmd, args, argStr )
	GAMEMODE:RunIntroAnim()
end, nil, nil, FCVAR_CHEAT+FCVAR_SERVER_CAN_EXECUTE )