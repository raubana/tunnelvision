AddCSLuaFile( "cl_init.lua" )

include( "shared.lua" )




function GM:Initialize()
	self.spawned_creatures =  false
end




function GM:SpawnHim()
	navs = navmesh.GetAllNavAreas()
	nav = navs[math.random(#navs)]
	
	if nav and IsValid(nav) then
		print( "HE LIVES" )
	
		local ent = ents.Create("snpc_weeping_gman")
		ent:SetPos( nav:GetCenter() )
		ent:SetAngles( Angle(0, math.random()*360, 0) )
		ent:Spawn()
		ent:Activate()
	end
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




function GM:PlayerInitialSpawn( ply )
	if not game.SinglePlayer() then
		ply:Kick( "this is a singleplayer gamemode, dummy" )
	end
end




function GM:PlayerSpawn(ply)
	ply:SetModel("models/player/leet.mdl")
	ply:Give("swep_tv_voltage_tester")
	
	ply:SetRunSpeed(275)
	ply:SetWalkSpeed(100)
	ply:SetCrouchedWalkSpeed(0.5)
	ply:AllowFlashlight(true)
	
	print(ply:GetName(),"has spawned.")
	
	if not self.spawned_creatures then
		self:SpawnHim()
		self:SpawnFlies()
		
		self.spawned_creatures = true
	end
end