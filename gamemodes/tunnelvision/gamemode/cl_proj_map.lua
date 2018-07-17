print( "cl_proj_map" )




local MESH_DETAIL = 20 -- how many pixels between verticies.




local function rect_to_stereographic( w, h, fov, x, y )
	local fov = math.rad( fov )

	local vert = {}
	
	local X = x-(w/2)
	local Y = y-(h/2)
	
	local phi1 = 0
	local lambda0 = 0
	
	local R = 500
	local p = math.sqrt( math.pow( X, 2 ) + math.pow( Y, 2 ) )
	local c = 2 * math.atan(p/(2*R))
	
	local lambda = lambda0 + math.atan( (X*math.sin(c)) / (p*math.cos(c) - y*math.sin(phi1)*math.sin(c)) )
	local phi = math.sinh( math.cos(c)*math.sin(phi1) + (Y * math.sin(c) ) / p )
	
	lambda = (lambda + math.pi) % (math.pi*2)
	phi = (phi + math.pi) % (math.pi*2)
	
	vert["pos"] = Vector(0,x,y)
	vert["u"] = 1-(lambda/(math.pi*2))
	vert["v"] = 1-(phi/(math.pi*2))
	return vert
end




local function rect_to_fisheye( w, h, fov, x, y )
	local vert = {}
	
	local ratio = w/h
	
	local X = (x-(w/2))
	local Y = (y-(h/2))*ratio
	
	local dist = math.sqrt( X*X + Y*Y )
	local r = math.atan2( dist, h*2 ) / math.rad(fov)
	local phi = math.atan2( Y, X )
	
	local u = r * math.cos( phi ) + 0.5
	local v = r * math.sin( phi ) + 0.5
	
	vert["pos"] = Vector(0,x,y)
	vert["u"] = 1-u
	vert["v"] = 1-v
	return vert
end




local function gen_proj_mesh( w, h, fov )
	local mesh_obj = Mesh()
	
	local verts = {}
	
	local num_x = math.ceil(w/MESH_DETAIL)
	local num_y = math.ceil(h/MESH_DETAIL)
	
	for y = 0, num_y do
		local row = {}
	
		for x = 0, num_x do
			table.insert( row, rect_to_fisheye( w, h, fov, x*w/(num_x-1), y*h/(num_y-1) ) )
		end
		
		table.insert( verts, row )
	end
	
	local new_verts = {}
	
	for y = 1, num_y-1 do
		for x = 1, num_x-1 do
			-- Bottom-Left triangle
			table.insert( new_verts, verts[y][x] )
			table.insert( new_verts, verts[y+1][x+1] )
			table.insert( new_verts, verts[y+1][x] )
			
			-- Top-Right triangle
			table.insert( new_verts, verts[y][x] )
			table.insert( new_verts, verts[y][x+1] )
			table.insert( new_verts, verts[y+1][x+1] )
		end
	end
	
	mesh_obj:BuildFromTriangles( new_verts )
	
	return mesh_obj
end


local rt = GetRenderTarget( "tv_proj_map", ScrW(), ScrH() )
local mat_data = {}
local rt_mat = CreateMaterial("tv_proj_map", "UnlitGeneric", mat_data)
rt_mat:SetTexture( "$basetexture", rt )

local wireframeMat = Material( "editor/wireframe" )

local MESH = nil
local MESH_READY = false

MESH = gen_proj_mesh( ScrW(), ScrH(), 90 )
MESH_READY = true




hook.Add( "PreDrawEffects", "TV_ProjMap_PreDrawEffects", function()
	if MESH_READY then
		-- print( "draw" )
		
		local scrw = ScrW()
		local scrh = ScrH()
		local aspect = scrw/scrh
		
		render.CopyRenderTargetToTexture(rt)
		
		-- render.Clear( 100, 0, 0, 1.0, true, true )
		
		cam.Start(
			{
				x = 0,
				y = 0,
				w = scrw,
				h = scrh,
				origin = Vector(-100,scrw,scrh),
				angles = angle_zero,
				fov = 5,
				aspect = aspect,
				zfar = 10000,
				znear = 3,
				ortho = {
					left = 0,
					right = aspect*scrh,
					bottom = 0,
					top = -scrh
				}
			}
		)
			render.SetColorModulation(1,1,1)
			render.SetMaterial( rt_mat )
			MESH:Draw()
			
			--render.SetMaterial( wireframeMat )
			--MESH:Draw()
		cam.End()
	end
end )
