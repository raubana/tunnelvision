print( "sv_drowning" )




hook.Add( "SetupMove", "TV_SvDrowning_SetupMove", function( ply, mv, cmd )
	if not IsValid( ply ) then return end

	local tunnelvision = ply:GetTunnelVision()
	local waterlevel = ply:WaterLevel()
	
	if waterlevel >= 1 then
		local p = Lerp( tunnelvision, 1, 0 )
	
		local forwardspeed = mv:GetForwardSpeed()
		local sidespeed = mv:GetSideSpeed()
		local forwardmove = cmd:GetForwardMove()
		local sidemove = cmd:GetSideMove()
		
		mv:SetForwardSpeed(math.floor(forwardspeed * p))
		mv:SetSideSpeed(math.floor(sidespeed * p))
		cmd:SetForwardMove(math.floor(forwardmove * p))
		cmd:SetSideMove(math.floor(sidemove * p))
		
		if tunnelvision >= 0.75 then
			if mv:KeyDown( IN_JUMP ) then
				mv:SetButtons( mv:GetButtons()-IN_JUMP )
			end
			cmd:RemoveKey(IN_JUMP)
		end
	end
	
	if FrameTime() > 0 then
		if waterlevel >= 3 then
			ply.drowned_percent = math.min( ( ply.drowned_percent or 0 ) + ( 0.1 * engine.TickInterval()), 1 )
		else
			ply.drowned_percent = math.max( ( ply.drowned_percent or 0 ) - ( 0.5 * engine.TickInterval()), 0 )
		end
		
		if ply.drowned_percent >= 1 then
			if CurTime() > ( ply.next_drown_pain or 0 ) then
				local dmg = DamageInfo()
				dmg:SetDamage( 10 )
				dmg:SetAttacker( game.GetWorld() )
				dmg:SetInflictor( game.GetWorld() )
				dmg:SetDamageType( DMG_DROWN )
				ply:TakeDamageInfo( dmg )
				
				ply.next_drown_pain = CurTime() + 2
			end
		end
	end
end )