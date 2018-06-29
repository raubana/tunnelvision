print( "shared" )

AddCSLuaFile()

GM.Name				= "Tunnel Vision"
GM.Author			= "raubana"




function GM:SetupMove( ply, mv, ucmd )
	if mv:GetForwardSpeed() < 0 then
		mv:SetMaxClientSpeed( mv:GetMaxClientSpeed() *0.5 )
	end
end
