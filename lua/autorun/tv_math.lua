AddCSLuaFile()




local math = math




function math.invlerp( c, a, b )
	return ( math.Clamp( c, a, b )-a ) / ( b-a )
end