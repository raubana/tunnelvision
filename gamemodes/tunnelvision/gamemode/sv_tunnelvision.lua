print( "sv_tunnelvision" )

AddCSLuaFile( "cl_tunnelvision.lua" )
AddCSLuaFile( "sh_tunnelvision.lua" )

include( "sh_tunnelvision.lua" )




local plymeta = FindMetaTable( "Player" )
if not plymeta then Error("FAILED TO FIND PLAYER TABLE") return end




function plymeta:SetTunnelVision( percent )
	self:SetNWFloat( "TunnelVision", percent )
end




hook.Add( "PlayerTick", "TV_SvTunnelVision_PlayerTick", function( ply, mv )
	if FrameTime() > 0 then

		if IsValid( ply ) and ply:Alive() then
			local p = ply:GetTunnelVision()
			
			local waterlevel = ply:WaterLevel()
			local onground = ply:IsOnGround()
			
			if ( onground and waterlevel < 3 ) or waterlevel <= 0 then
				p = p - ( 0.05 * engine.TickInterval() )
			end
			
			if onground and waterlevel < 3 then
				local speed = ply:GetGroundSpeedVelocity():Length()
				local effect = math.max( speed - 50, 0 ) / 150
				
				p = p + effect * 0.1 * engine.TickInterval()
				
				if mv:KeyPressed(IN_JUMP) then
					p = p + 0.1 + (effect * 0.01)
				end
			else
				if waterlevel > 0 then
					p = p + 0.01 * engine.TickInterval()
				
					local speed = ply:GetGroundSpeedVelocity():Length()
					local effect = speed / 100
					
					p = p + effect * 0.01 * engine.TickInterval()
					
					if mv:KeyPressed(IN_JUMP) then
						p = p + 0.075
					end
				end
			end
			
			p = math.Clamp( p, 0, 1 )
			
			-- print( p )
			
			ply:SetTunnelVision( p )
		end
		
	end
end )
