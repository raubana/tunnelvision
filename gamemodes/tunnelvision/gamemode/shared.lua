print( "shared" )

AddCSLuaFile()

GM.Name				= "Tunnel Vision"
GM.Author			= "raubana"




function GM:SetupMove( ply, mv, ucmd )
	if mv:GetForwardSpeed() < 0 then
		mv:SetMaxClientSpeed( mv:GetMaxClientSpeed() *0.5 )
	end
end




hook.Add( "Tick", "tv_dsp_tick", function()
	for i, ply in ipairs( player.GetAll() ) do
		ply:SetDSP( 115 )
	end
end )