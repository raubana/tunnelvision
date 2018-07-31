AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "cl_intro.lua" )
AddCSLuaFile( "cl_dof.lua" )
AddCSLuaFile( "tv_anim_track.lua" )




local LAST_PLAYED = CreateConVar("tv_lastplayed", "0", bit.bor( FCVAR_ARCHIVE ))




include( "shared.lua" )
include( "sv_intro.lua" )
include( "sv_tunnelvision.lua" )
include( "sv_drowning.lua" )




function GM:Initialize()
	util.AddNetworkString("TV_Message")
	util.AddNetworkString("TV_OnDeath")
	util.AddNetworkString("TV_PlayerSpawnedOnClient")
	
	self.next_playtime_update = CurTime() + 120
end




function GM:Tick()
	if CurTime() >= self.next_playtime_update then
		print( "set last played" )
		LAST_PLAYED:SetFloat( os.time() )
		self.next_playtime_update = CurTime() + 60
	end
end




net.Receive( "TV_PlayerSpawnedOnClient", function( len, ply )
	GAMEMODE:RunIntroAnim()
end )




function GM:SendMessage( ply, msg )
	local ply = ply
	local msg = msg

	if isstring( ply ) then
		msg = ply
		ply = nil
	end

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
end




function GM:PlayerSpawn(ply)
	if not game.SinglePlayer() then
		timer.Simple( 1, function()
			ply:ConCommand( "disconnect" )
		end )
		return
	end

	if ply.has_died then
		ply:ConCommand( "restart" )
	end

	print(ply:GetName(),"has spawned.")

	ply:SetModel("models/player/leet.mdl")
	ply:Give("swep_tv_cassetteplayer")
	ply:Give("swep_tv_voltagetester")
	--ply:Give("swep_tv_map")
	
	ply:SetRunSpeed(220)
	ply:SetWalkSpeed(100)
	--ply:SetWalkSpeed(60)
	ply:SetCrouchedWalkSpeed(30/ply:GetWalkSpeed())
	ply:AllowFlashlight(true)
	
	ply:SetDuckSpeed( 0.25 )
	ply:SetUnDuckSpeed( 0.5 )
	
	ply:SetViewOffsetDucked( Vector( 0, 0, 50 ) )
	ply:SetHullDuck( Vector( -16, -16, 0 ), Vector( 16, 16, 52 ) )
end




function GM:PlayerUse( ply, ent )
	local tr = util.TraceLine( util.GetPlayerTrace( ply ) )
	
	if ( tr.Entity != ent ) or ( tr.Hit and tr.HitPos:Distance( ply:GetShootPos() ) > 70 ) then
		return false
	end
	
	return true
end




function GM:AllowPlayerPickup( ply, ent )
	return
end




function GM:GetFallDamage(ply, speed)
	return 1
end




function GM:OnPlayerHitGround( ply, inWater, onFloater, speed)
	local dmg_amount = 0
	if not inWater then
		dmg_amount = math.max( 0, math.ceil( 0.23*speed - 120 ) )
	end
	
	if dmg_amount > 0 then
		local dmg = DamageInfo()
		dmg:SetDamageType(DMG_FALL)
		dmg:SetDamage(dmg_amount)
		dmg:SetInflictor(game.GetWorld())
		dmg:SetAttacker(game.GetWorld())
		ply:TakeDamageInfo(dmg)
	end
	return true
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
	net.WriteInt( dmg:GetDamageType(), 32 )
	net.Send( ply )
end




function GM:PostPlayerDeath( ply )
	timer.Simple( 0.01, function()
		ply:SetPos( Vector( 32768, 32768, 32768 ) )
	end )
end