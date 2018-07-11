AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "tv_anim_track.lua" )

include( "shared.lua" )
include( "sv_intro_anim.lua" )




function GM:Initialize()
	util.AddNetworkString("TV_Message")
	util.AddNetworkString("TV_OnDeath")
	util.AddNetworkString("TV_PlayerSpawnedOnClient")
end




function GM:SendMessage( ply, msg )
	net.Start( "TV_Message" )
	net.WriteString( msg )
	if ply then
		net.Send( ply )
	else
		net.Broadcast()
	end
end




function GM:PlayerNoClip( ply, desiredState )
	return not desiredState or GetConVar( "sv_cheats" ):GetBool()
end




function GM:PlayerInitialSpawn( ply )
	if not game.SinglePlayer() then
		ply:Kick( "this is a singleplayer gamemode, dummy" )
	end
end




function GM:PlayerSpawn(ply)
	if ply.has_died then
		game.ConsoleCommand( "restart\n" )
	end

	print(ply:GetName(),"has spawned.")

	ply:SetModel("models/player/leet.mdl")
	ply:Give("swep_tv_voltagetester")
	ply:Give("swep_tv_map")
	ply:Give("swep_tv_cassetteplayer")
	
	ply:SetRunSpeed(310)
	ply:SetWalkSpeed(125)
	ply:SetCrouchedWalkSpeed(0.5)
	ply:AllowFlashlight(true)
	
	if isvector( self.player_spawn ) then
		ply:SetPos( self.player_spawn )
		ply:SetAngles( Angle(0, math.random()*360, 0) )
	end
	
	timer.Simple( 2.0, function()
		if ply and IsValid( ply ) then
			ply:SetDSP( 0 )
		end
	end )
	
	timer.Simple( 3.0, function()
		if ply and IsValid( ply ) then
			ply:SetDSP( 1 )
		end
	end )
end




function GM:CanPlayerSuicide( ply )
	self:SendMessage( ply, "You don't have much to live for, do you." )
	return false
end




function GM:PlayerDeathSound()
	return true
end




function GM:DoPlayerDeath( ply, attacker, dmg )
	ply.has_died = true
	ply.died_at = CurTime()
	net.Start( "TV_OnDeath" )
	net.Send( ply )
end




function GM:PostPlayerDeath( ply )
	timer.Simple( 0.01, function()
		ply:SetPos( Vector( 32768, 32768, 32768 ) )
	end )
end