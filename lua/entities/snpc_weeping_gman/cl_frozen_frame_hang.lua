local hanging = false
local hang_end = 0




net.Receive( "HangFrame", function( len, ply )
	hanging = true
	hang_end = CurTime() + (engine.TickInterval()*8)
end )




hook.Add( "RenderScene", "snpc_weeping_gman_RenderScene", function()
	if hanging then
		if CurTime() >= hang_end then
			hanging = false
		else
			return true
		end
	end
end )