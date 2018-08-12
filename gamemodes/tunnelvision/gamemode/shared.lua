print( "shared" )

AddCSLuaFile()

GM.Name				= "Tunnel Vision"
GM.Author			= "raubana"
GM.FOV				= 70




function GM:StartCommand( ply, ucmd )
	ucmd:RemoveKey(IN_ZOOM)
	ucmd:RemoveKey(IN_WALK)
	
	if ucmd:GetForwardMove() < 0 then
		ucmd:RemoveKey(IN_SPEED)
	end
end




local listening_ents = {}
if SERVER then
	hook.Add( "PreventEntityEmitSoundHookForHearingEntity", "TV_PreventEntityEmitSoundHookForHearingEntity", function( ent )
		table.insert( listening_ents, ent )
		return true
	end )
end




function GM:EntityEmitSound( data )
	if data.SoundName == "items/flashlight1.wav" then
		return false
	end
	
	if SERVER then
		for i, ent in ipairs(listening_ents) do
			ent:HearSound( data )
		end
		
		listening_ents = {}
		
		return true
	end
end