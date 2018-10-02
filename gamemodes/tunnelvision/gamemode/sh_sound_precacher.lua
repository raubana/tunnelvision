print( "sh_sound_precacher" )




--[[
local sound_list = sound_list or {}

hook.Add( "EntityEmitSound", "TV_ShSoundPrecacher_EntityEmitSound", function( data )
	if not sound_list[ data.SoundName ] then
		print( "NEW:", data.SoundName, RealTime() )
		sound_list[data.SoundName] = true
	end
end )
]]