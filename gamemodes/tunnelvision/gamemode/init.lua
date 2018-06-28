AddCSLuaFile( "cl_init.lua" )

include( "shared.lua" )




function GM:Initialize()
	self.spawned_him =  false
end




function GM:PlayerSpawn(ply)
	ply:SetModel("models/player/leet.mdl")
	ply:Give("swep_tv_voltage_tester")
	
	ply:SetRunSpeed(275)
	ply:SetWalkSpeed(100)
	ply:SetCrouchedWalkSpeed(0.5)
	ply:AllowFlashlight(true)
	
	print(ply:GetName(),"has spawned.")
	
	if not self.spawned_him then
		navs = navmesh.GetAllNavAreas()
		nav = navs[math.random(#navs)]
		
		if nav and IsValid(nav) then
			print( "HE LIVES" )
		
			local ent = ents.Create("snpc_weeping_gman")
			ent:SetPos( nav:GetCenter() )
			ent:SetAngles( Angle(0, math.random()*360, 0) )
			ent:Spawn()
			ent:Activate()
			
			self.spawned_him = true
		end
	end
end