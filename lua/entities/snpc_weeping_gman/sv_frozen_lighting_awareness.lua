AddCSLuaFile("cl_frozen_lighting_awareness.lua")




local DEBUG_FROZEN_LIGHTING_AWARENESS = CreateConVar("twg_debug_frozen_lighting_awareness", "0", FCVAR_SERVER_CAN_EXECUTE+FCVAR_NOTIFY+FCVAR_REPLICATED+FCVAR_CHEAT)




function ENT:FrozenLightingAwarenessInit()
	self.players_who_can_not_see_me = {}
end




function ENT:FrozenLightingAwarenessGetPlayerCanSeeMe( ply )
	return not table.HasValue( self.players_who_can_not_see_me, ply )
end




function ENT:FrozenLightingAwarenessSetPlayerCanSee( ply, can_see )
	if DEBUG_FROZEN_LIGHTING_AWARENESS:GetBool() then
		print("updated can see", ply, can_see)
	end

	if not can_see then
		if self:FrozenLightingAwarenessGetPlayerCanSeeMe( ply ) then
			table.insert( self.players_who_can_not_see_me, ply ) -- the player is noted as not being able to see me
		end
	else
		table.RemoveByValue( self.players_who_can_not_see_me, ply ) -- the player is noted as being able to see me
	end
end




hook.Add( "Initialize", "snpc_weeping_gman_frozen_lighting_awareness_Initialize", function()
	util.AddNetworkString( "PlayerStateCanSeeWeepingGman" )
end )




net.Receive( "PlayerStateCanSeeWeepingGman", function( len, ply )
	local can_see = net.ReadBool()
	local ent = net.ReadEntity()
	
	if IsValid( ent ) and ent:GetClass() == "snpc_weeping_gman" then
		ent:FrozenLightingAwarenessSetPlayerCanSee( ply, can_see )
	end
end )





