print( "sv_intro_anim" )

AddCSLuaFile( "cl_intro_anim.lua" )



hook.Add( "Initialize", "TV_SvIntroAnim_Initialize", function()
	util.AddNetworkString("TV_IntroAnim_Run")
	util.AddNetworkString("TV_IntroAnim_HalfOver")
	util.AddNetworkString("TV_IntroAnim_Over")
	util.AddNetworkString("TV_IntroAnim_Skip")
end )




function GM:RunIntroAnim()
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
	
	ply:Freeze( true )
	ply.is_doing_intro = nil
	
	local target = ents.FindByClass("info_player_start")[1]
	ply:SetPos( target:GetPos() )
	ply:SetAngles( target:GetAngles() )
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