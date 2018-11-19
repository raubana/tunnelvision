AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "cl_sound_precacher.lua" )
AddCSLuaFile( "sh_sound_precacher.lua" )
AddCSLuaFile( "cl_intro.lua" )
AddCSLuaFile( "cl_dof.lua" )
AddCSLuaFile( "tv_anim_track.lua" )




local LAST_PLAYED = CreateConVar("tv_lastplayed", "0", bit.bor( FCVAR_ARCHIVE ))
local DEATH_COUNT = CreateConVar("tv_deathcount", "0", bit.bor( FCVAR_ARCHIVE ))




include( "shared.lua" )
include( "sv_intro.lua" )




function GM:Initialize()
	util.AddNetworkString("TV_Message")
	util.AddNetworkString("TV_OnPain")
	util.AddNetworkString("TV_PlayerSpawnedOnClient")
	
	self.next_playtime_update = CurTime() + 120
	
	if os.time() - LAST_PLAYED:GetFloat() > 60*60 then
		DEATH_COUNT:SetInt( 0 )
	end
end




function GM:Tick()
	if CurTime() >= self.next_playtime_update then
		print( "set last played" )
		LAST_PLAYED:SetFloat( os.time() )
		self.next_playtime_update = CurTime() + 60
	end
end




net.Receive( "TV_PlayerSpawnedOnClient", function( len, ply )
	-- We turn the player's flashlight on and off really quick because a
	-- spike occurs the first time the player uses their flashlight.
	-- Think of this as precaching.
	timer.Simple( 0.1, function() if IsValid( ply ) then ply:Flashlight( true ) end end )
	timer.Simple( 0.2, function() if IsValid( ply ) then ply:Flashlight( false ) end end )

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
	
	ply:AllowFlashlight(false)
	
	ply:SetRunSpeed(220)
	ply:SetWalkSpeed(100)
	ply:SetCrouchedWalkSpeed(30/ply:GetWalkSpeed())
	ply:SetJumpPower( 200 )
	
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




-- We don't want the player to be able to pick up physics entities.
function GM:AllowPlayerPickup( ply, ent )
	return
end




function GM:GetFallDamage(ply, speed)
	return math.max( 0, GAMEMODE:calcFallDamage( ply, speed ) )
end




-- We don't want the player to be able to commit suicide.
function GM:CanPlayerSuicide( ply )
	self:SendMessage( ply, "You don't have much to live for, do you." )
	return false
end




-- We don't want the heart monitor sound to play when the player dies.
function GM:PlayerDeathSound()
	return true
end




function GM:DoPlayerDeath( ply, attacker, dmg )
	ply.has_died = true
	ply.died_at = CurTime()
	net.Start( "TV_OnPain" )
	net.WriteInt( dmg:GetDamageType(), 32 )
	net.WriteBool( true )
	net.Send( ply )
end




function GM:PostPlayerDeath( ply )
	timer.Simple( 0.01, function()
		ply:SetPos( Vector( 32768-100, 32768-100, 32768-100 ) )
	end )
	
	DEATH_COUNT:SetInt( DEATH_COUNT:GetInt() + 1 )
end