print( "cl_init" )




function GM:CalcView( ply, origin, angles, fov, znear, zfar )
	local data = {}
	data.origin = origin
	data.angles = angles
	data.fov = fov
	data.znear = znear
	data.zfar = zfar
	
	data.fov = 55
	
	return data
end