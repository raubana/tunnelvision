print( "sv_tunnelvision" )

AddCSLuaFile( "cl_tunnelvision.lua" )
AddCSLuaFile( "sh_tunnelvision.lua" )

include( "sh_tunnelvision.lua" )




local plymeta = FindMetaTable( "Player" )
if not plymeta then Error("FAILED TO FIND PLAYER TABLE") return end




function plymeta:SetTunnelVision( percent )
	self:SetNWFloat( "TunnelVision", percent )
end




local prev_curtime = CurTime()
hook.Add( "Tick", "TV_SvTunnelVision_Tick", function()
	local curtime = CurTime()
	timer.Simple( engine.TickInterval() * 2, function() 
		prev_curtime = curtime
	end )
end )




hook.Add( "PlayerTick", "TV_SvTunnelVision_PlayerTick", function( ply, mv )
	if CurTime() != prev_curtime then

		if IsValid( ply ) and ply:Alive() then
			local p = ply:GetTunnelVision()
			
			if ply:IsOnGround() then
				local speed = ply:GetGroundSpeedVelocity():Length()
				local effect = math.max( speed - 100, 0 ) / 100
				
				p = p + effect * 0.075 * engine.TickInterval()
				
				if mv:KeyPressed(IN_JUMP) then
					p = p + 0.075 + (effect * 0.0075)
				end
			end
			
			p = p - ( 0.025 * engine.TickInterval() )
			
			p = math.Clamp( p, 0, 1 )
			
			print( p )
			
			ply:SetTunnelVision( p )
		end
		
	end
end )
