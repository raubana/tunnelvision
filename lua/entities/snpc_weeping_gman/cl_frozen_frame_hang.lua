local rt = GetRenderTarget( "tv_hang_frame", ScrW(), ScrH() )
local mat_data = {}
local mat = CreateMaterial("tv_hang_frame", "UnlitGeneric", mat_data)
local hanging = false
local hang_end = 0




net.Receive( "HangFrame", function( len, ply )
	hanging = true
	grabbed_frame = false
	hang_end = CurTime() + (engine.TickInterval()*8)
end )



hook.Add( "PostRenderVGUI", "snpc_weeping_gman_PostRenderVGUI", function()
	if not hanging then
		render.CopyTexture( render.GetRenderTarget(), rt )
	else
		if CurTime() >= hang_end then
			hanging = false
		else
			mat:SetTexture( "$basetexture", rt )
			render.SetMaterial( mat )
			render.DrawScreenQuad()
			return true
		end
	end
end )