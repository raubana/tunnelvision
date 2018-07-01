AddCSLuaFile( "cl_init.lua" )

include( "shared.lua" )
include( "sv_mapgen.lua" )




function GM:Initialize()
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
	
	for x = 1, math.ceil(#navs*0.1) do
		local nav = navs[math.random(#navs)]
	
		if nav and IsValid(nav) then
			local ent = ents.Create("sent_tv_fly")
			ent:SetPos( nav:GetCenter() )
			ent:SetAngles( Angle(0, math.random()*360, 0) )
			ent:Spawn()
			ent:Activate()
		end
	end
end




function GM:SpawnKey( pos, door_name, index )
	local color = HSVToColor( Lerp(index/#table.GetKeys(DOOR_CONNECTION_TABLE), 0, 360), (index%2)/2+0.5, (index%2)/2+0.5 )

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
end




function GM:PlayerSpawn(ply)
	print(ply:GetName(),"has spawned.")

	ply:SetDSP( 1 )

	ply:SetModel("models/player/leet.mdl")
	ply:Give("swep_tv_voltage_tester")
	
	ply:SetRunSpeed(310)
	ply:SetWalkSpeed(100)
	ply:SetCrouchedWalkSpeed(0.5)
	ply:AllowFlashlight(true)

	local result = GAMEMODE:GenerateMap()
	
	for i, data in ipairs( result.spawns ) do
		if isstring( data ) then
			if data == "player" then
				ply:SetPos( SPAWN_LOCATION_TABLE[i][2] )
				ply:SetAngles( Angle(0, math.random()*360, 0) )
			elseif data == "gman" then
				GAMEMODE:SpawnHim( SPAWN_LOCATION_TABLE[i][2] )
			end
		elseif istable( data ) then
			self:SpawnKey( SPAWN_LOCATION_TABLE[i][2], data[2], data[1] )
		end
	end
	
	self:SpawnFlies()
end