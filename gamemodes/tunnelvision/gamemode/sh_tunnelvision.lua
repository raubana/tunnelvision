print( "sh_tunnelvision" )




local plymeta = FindMetaTable( "Player" )
if not plymeta then Error("FAILED TO FIND PLAYER TABLE") return end




function plymeta:GetTunnelVision()
	return self:GetNWFloat( "TunnelVision" )
end