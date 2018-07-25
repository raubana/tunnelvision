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
			
			if ply:IsOnGround() then
				local speed = ply:GetGroundSpeedVelocity():Length()
				local effect = math.max( speed - 50, 0 ) / 150
				
				p = p + effect * 0.075 * engine.TickInterval()
				
				if mv:KeyPressed(IN_JUMP) then
					p = p + 0.075 + (effect * 0.0075)
				end
			end
			
			p = p - ( 0.025 * engine.TickInterval() )
			
			p = math.Clamp( p, 0, 1 )
			
			-- print( p )
			
			ply:SetTunnelVision( p )
		end
		
	end
end )
