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




local WRAP = math.pow(2,7)
local function prng( x )
	return math.mod(x * 6581 + 7883, WRAP) / WRAP
end


local function smooth_noise( x )
	//expects a float
	return prng(x)/2 + prng(x-1)/4  +  prng(x+1)/4
end


local function interpolate_noise( x )
	//expects a float
	local frac_x = math.mod(x,1)
	local int_x = x-frac_x
	local v1 = smooth_noise(int_x)
	local v2 = smooth_noise(int_x + 1)
	return Lerp((1-math.cos(frac_x*math.pi))/2,v1,v2)
end


function util.PerlinNoise( x, speed, persistence, octaves )
	//expects a float
	local total = 0
	local den = 0
	for i = 0, octaves - 1 do
		local frequency = math.pow(2,i)
		local amplitude = math.pow(persistence,i)
		den = den + amplitude
		total = total + interpolate_noise(x*speed*frequency)*amplitude
	end
	total = total / den
	return total
end