print( "cl_sound_precacher" )




local DEBUG_PRECACHE_SOUNDS = false -- TODO: Make convar for this.

local legal_extensions = {
	mp3 = true,
	wav = true
}


function findAndPrecacheSounds(name)
	if DEBUG_PRECACHE_SOUNDS then print("- sound/"..name) end
	local L1,L2 = file.Find("sound/"..name,"GAME")
	for key,f in pairs(L1) do
		local new_f = string.Replace("sound/"..name,"*",f)
		if legal_extensions[string.GetExtensionFromFilename(new_f)] then
			if DEBUG_PRECACHE_SOUNDS then print("-- precaching "..new_f) end
			util.PrecacheSound(new_f)
		else
			if DEBUG_PRECACHE_SOUNDS then print("-- skipping "..new_f) end
		end
	end
	for key,dir in pairs(L2) do
		local new_dir = string.Replace(name,"*",dir).."/*"
		findAndPrecacheSounds(new_dir)
	end
end




hook.Add( "InitPostEntity", "TV_ClSoundPrecacher_InitPostEntity", function()
	-- AMBIENT
	findAndPrecacheSounds("ambient/*")

	-- PLAYER
	findAndPrecacheSounds("player/*") -- Doesn't seem necessary.
	
	-- PHYSICS
	findAndPrecacheSounds("physics/*") -- Only sometimes causes a spike.
	
	-- DOORS
	findAndPrecacheSounds("doors/*") -- Doesn't seem necessary.
end )




--[[
local threshold = 1/60

hook.Add( "Think", "TV_ClSoundPrecacher_Think", function()
	local frametime = RealFrameTime()
	
	if frametime >= threshold then
		print( "THRESHOLD PASSED:", frametime, "/", threshold, RealTime() )
	end
end )
]]