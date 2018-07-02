print( "shared" )

AddCSLuaFile()

GM.Name				= "Tunnel Vision"
GM.Author			= "raubana"




function GM:StartCommand( ply, ucmd )
	ucmd:RemoveKey(IN_WALK)
	ucmd:RemoveKey(IN_ZOOM)
end





function GM:SetupMove( ply, mv, ucmd )
	if mv:GetForwardSpeed() < 0 then
		mv:SetMaxClientSpeed( mv:GetMaxClientSpeed() *0.5 )
	end
end




function GM:EntityEmitSound( data )
	if data.SoundName == "items/flashlight1.wav" then
		return false
	end
end