print( "sv_intro_anim" )

AddCSLuaFile( "cl_intro_anim.lua" )



hook.Add( "Initialize", "TV_SvIntroAnim_Initialize", function()
	util.AddNetworkString("TV_IntroAnim_Run")
	util.AddNetworkString("TV_IntroAnim_HalfOver")
	util.AddNetworkString("TV_IntroAnim_Over")
end )




function GM:RunIntroAnim()
	net.Start( "TV_IntroAnim_Run" )
	net.Broadcast()
	
	for i, ply in ipairs( player.GetAll() ) do
		ply:Freeze( true )
		
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
end )




net.Receive( "TV_IntroAnim_Over", function( len, ply )
	ply:Freeze( false )
end )




concommand.Add( "tv_run_intro_anim", function( ply, cmd, args, argStr )
	GAMEMODE:RunIntroAnim()
end, nil, nil, FCVAR_CHEAT+FCVAR_SERVER_CAN_EXECUTE )