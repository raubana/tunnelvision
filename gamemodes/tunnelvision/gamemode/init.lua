AddCSLuaFile( "cl_init.lua" )

include( "shared.lua" )
include( "sv_mapgen.lua" )




function GM:Initialize()
	util.AddNetworkString("TV_Message")
	util.AddNetworkString("TV_OnDeath")
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




function GM:SpawnHim( pos )
	print( "HE LIVES" )

	local ent = ents.Create("snpc_weeping_gman")
	ent:SetPos( pos )
	ent:SetAngles( Angle(0, math.random()*360, 0) )
	ent:Spawn()
	ent:Activate()
end




function GM:SpawnFlies()
	navs = navmesh.GetAllNavAreas()
	
	for x = 1, math.ceil(#navs*0.025) do
		local nav = navs[math.random(#navs)]
	
		if nav and IsValid(nav) then
			local ent = ents.Create( "sent_tv_fly" )
			ent:SetPos( nav:GetCenter() )
			ent:SetAngles( Angle(0, math.random()*360, 0) )
			ent:Spawn()
			ent:Activate()
		end
	end
end




function GM:SpawnKey( pos, door_name, index )
	local color = DOOR_CONNECTION_TABLE[door_name][3]

	local ent_list = ents.FindByName( door_name )
	local door = ent_list[1]
	door:SetColor( color )
	
	local ent = ents.Create( "sent_tv_key" )
	ent:SetPos( pos )
	ent:SetAngles( AngleRand() )
	ent:SetColor( color )
	ent:Spawn()
	ent:Activate()
	
	ent.door = door
end




function GM:PlayerInitialSpawn( ply )
	if not game.SinglePlayer() then
		ply:Kick( "this is a singleplayer gamemode, dummy" )
	end
	
	local result = GAMEMODE:GenerateMap()
	
	self.player_spawn = nil
	
	for i, data in ipairs( result.spawns ) do
		if isstring( data ) then
			if data == "player" then
				self.player_spawn = SPAWN_LOCATION_TABLE[i][2]
			elseif data == "gman" then
				GAMEMODE:SpawnHim( SPAWN_LOCATION_TABLE[i][2] )
			end
		elseif istable( data ) then
			self:SpawnKey( SPAWN_LOCATION_TABLE[i][2], data[2], data[1] )
		end
	end
	
	self:SpawnFlies()
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
	
	ply:SetPos( self.player_spawn )
	ply:SetAngles( Angle(0, math.random()*360, 0) )
	
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