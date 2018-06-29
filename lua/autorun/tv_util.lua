AddCSLuaFile()




local util = util




function util.DBToRadius( db, volume )
	return volume * (-(0.0003*math.pow(db, 4)) + (0.0766*math.pow(db, 3)) - (4.5372*math.pow(db, 2)) + (109.05*db) - 902.64)
end