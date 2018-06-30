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