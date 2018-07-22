AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "cl_intro_anim.lua" )
AddCSLuaFile( "cl_dof.lua" )
AddCSLuaFile( "tv_anim_track.lua" )

include( "shared.lua" )
include( "sv_intro_anim.lua" )




function GM:Initialize()
	util.AddNetworkString("TV_Message")
	util.AddNetworkString("TV_OnDeath")
	util.AddNetworkString("TV_PlayerSpawnedOnClient")
	
	self.presim = false
end




function GM:InitPostEntity()
	local ply_list = player.GetAll()
	for i, ply in ipairs( ply_list ) do ply:Freeze( true ) end

	game.SetTimeScale( 10.0 )
	timer.Simple( 60, function()
		game.SetTimeScale( 1.0 )
		
		local ply_list = player.GetAll()
		for i, ply in ipairs( ply_list ) do
			ply:Freeze( false )
			self:SendMessage( ply, "Ready." )
		end
		
		GAMEMODE.presim = true
	end )
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
end




function GM:PlayerSpawn(ply)
	if not game.SinglePlayer() then
		timer.Simple( 1, function()
			ply:ConCommand( "disconnect" )
		end )
		return
	end

	if ply.has_died then
		game.ConsoleCommand( "restart\n" )
	end

	print(ply:GetName(),"has spawned.")

	ply:SetModel("models/player/leet.mdl")
	ply:Give("swep_tv_cassetteplayer")
	ply:Give("swep_tv_voltagetester")
	ply:Give("swep_tv_map")
	
	ply:SetRunSpeed(220)
	ply:SetWalkSpeed(100)
	--ply:SetWalkSpeed(60)
	ply:SetCrouchedWalkSpeed(30/ply:GetWalkSpeed())
	ply:AllowFlashlight(true)
	
	ply:SetDuckSpeed( 0.5 )
	ply:SetUnDuckSpeed( 0.5 )
	
	ply:SetViewOffsetDucked( Vector( 0, 0, 50 ) )
	
	if not self.presim then
		ply:Freeze( true )
		self:SendMessage( ply, "One moment please..." )
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
	net.Send( ply )
end




function GM:PostPlayerDeath( ply )
	timer.Simple( 0.01, function()
		ply:SetPos( Vector( 32768, 32768, 32768 ) )
	end )
end