AddCSLuaFile()




local util = util




function util.ShuffleTable( tbl )
	for i1 = 1, #tbl do
		local i2 = math.random(#tbl)
		
		if i1 != i2 then
			local temp = tbl[i1]
			tbl[i1] = tbl[i2]
			tbl[i2] = temp
		end
	end
end




function util.DBToRadius( db, volume )
	return volume * (-(0.0003*math.pow(db, 4)) + (0.0766*math.pow(db, 3)) - (4.5372*math.pow(db, 2)) + (109.05*db) - 902.64)
end




local WRAP = math.pow( 2, 9 )
local function prng( x )
	return math.mod( x * 104723 + 68771, WRAP ) / WRAP
end


local function interpolate_noise( x )
	local frac = math.mod( x, 1 )
	local int = x - frac
	
	local p1 = prng( int )
	local p2 = prng( int + 1)
	
	return Lerp( frac, p1, p2 )
end


function util.PerlinNoise( x, speed, persistence, octaves )
	local total = 0
	local maxamp = 0
	for i = 0, octaves - 1 do
		local freq = math.pow( 2, i )
		local amp = math.pow( persistence, i )
		maxamp = maxamp + amp
		total = total + interpolate_noise( x * speed * freq ) * amp
	end
	total = total / maxamp
	return total
end