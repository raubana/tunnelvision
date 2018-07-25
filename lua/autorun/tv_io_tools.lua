if not SERVER then return end
-- if not game.SinglePlayer() then return end
if engine.ActiveGamemode() != "sandbox" then return end




concommand.Add( "tv_props_save",  function( ply, cmd, args, argStr )
	if #args != 1 then return end
	
	if not IsValid( ply ) then return end
	if not ply:IsAdmin() then
		ply:PrintMessage( HUD_PRINTCONSOLE, "You do not have permission to use tv_props_save!" )
		return
	end
	
	local o = ""
	
	local ent_list = ents.FindByClass("prop_physics*")
	
	for i, ent in ipairs( ent_list ) do
		if not ent:CreatedByMap() then
			local data = {}
			data.model = ent:GetModel()
			data.pos = ent:GetPos()
			data.ang = ent:GetAngles()
			
			o = o .. util.TableToJSON( data ) .. "\n"
		end
	end
	
	file.CreateDir( "tv_prop_saves" )
	file.Write( "tv_prop_saves/"..args[1]..".txt", o )
	
	print( "Saved." )
end )




concommand.Add( "tv_props_load",  function( ply, cmd, args, argStr )
	if #args != 1 then return end
	
	if not IsValid( ply ) then return end
	if not ply:IsAdmin() then
		ply:PrintMessage( HUD_PRINTCONSOLE, "You do not have permission to use tv_props_load!" )
		return
	end
	
	local filename = "tv_prop_saves/"..args[1]..".txt"
	
	if not file.Exists( filename, "DATA" ) then
		print( "Error: file not found." )
		return
	end
	
	local ent_datas = {}
	local data = file.Read( filename )
	data = string.Trim( data )
	local data_list = string.Explode( "\n", data )
	
	for i, val in ipairs(data_list) do
		table.insert( ent_datas, util.JSONToTable( val ) )
	end
	
	game.CleanUpMap()
	
	for i, ent_data in ipairs( ent_datas ) do
		local ent = ents.Create( "prop_physics" )
		ent:SetModel( ent_data.model )
		ent:SetPos( ent_data.pos )
		ent:SetAngles( ent_data.ang )
		
		ent:Spawn()
		ent:Activate()
	end
	
	print( "Loaded." )
end )




concommand.Add( "tv_io_save",  function( ply, cmd, args, argStr )
	if #args != 1 then return end
	
	if not IsValid( ply ) then return end
	if not ply:IsAdmin() then
		ply:PrintMessage( HUD_PRINTCONSOLE, "You do not have permission to use tv_io_save!" )
		return
	end

	local cable_list = {}
	local ent_list = {}
	
	local keys = list.Get( "TV_IO_ents" )
	table.Add( keys, list.Get( "TV_label_ents" ) )
	
	local unique_keys = {}
	
	for i, key in ipairs( keys ) do
		if not table.HasValue( unique_keys, key ) then
			table.insert( unique_keys, key )
		end
	end
	
	for i, val in ipairs( unique_keys ) do
		local temp_list = ents.FindByClass( val )
		for j, ent in ipairs( temp_list ) do
			if not ent:CreatedByMap() then
				if val == "sent_tv_io_cable" then
					table.insert( cable_list, ent )
				else
					table.insert( ent_list, ent )
				end
			end
		end
	end
	
	local o = ""
	
	for i, ent in ipairs( ent_list ) do
		o = o .. ent:Pickle( ent_list, cable_list ) .. "\n"
	end
	
	for i, ent in ipairs( cable_list ) do
		o = o .. ent:Pickle( ent_list, cable_list ) .. "\n"
	end
	
	file.CreateDir( "tv_io_circuits" )
	file.Write( "tv_io_circuits/"..args[1]..".txt", o )
	
	print( "Saved." )
end )




concommand.Add( "tv_io_load",  function( ply, cmd, args, argStr )
	if #args != 1 then return end
	
	if not IsValid( ply ) then return end
	if not ply:IsAdmin() then
		ply:PrintMessage( HUD_PRINTCONSOLE, "You do not have permission to use tv_io_load!" )
		return
	end
	
	local filename = "tv_io_circuits/"..args[1]..".txt"
	
	if not file.Exists( filename, "DATA" ) then
		print( "Error: file not found." )
		return
	end
	
	local ent_datas = {}
	local data = file.Read( filename )
	data = string.Trim( data )
	local data_list = string.Explode( "\n", data )
	
	for i, val in ipairs(data_list) do
		table.insert( ent_datas, util.JSONToTable( val ) )
	end
	
	game.CleanUpMap()
	
	local ent_list = {}
	
	for i, ent_data in ipairs( ent_datas ) do
		local cls = ent_data.class
		
		if not ( list.Contains( "TV_IO_ents", cls ) or list.Contains( "TV_label_ents", cls ) ) then
			print( "Error: received unexpected class type:", cls )
			return
		end
		
		local ent = ents.Create( cls )
		
		ent:Spawn()
		ent:Activate()
		
		ent:UnPickle( ent_data, ent_list )
		
		table.insert( ent_list, ent )
	end
	
	print( "Loaded." )
end )




concommand.Add( "tv_remove_flies",  function( ply, cmd, args, argStr )
	local ent_list = ents.FindByClass( "sent_tv_fly" )
	
	for i, ent in ipairs( ent_list ) do
		SafeRemoveEntity( ent )
	end
	
	print( "Done." )
end )




concommand.Add( "tv_io_find_connectionless_entities",  function( ply, cmd, args, argStr )
	if not IsValid( ply ) then return end
	if not ply:IsAdmin() then
		ply:PrintMessage( HUD_PRINTCONSOLE, "You do not have permission to use tv_io_find_connectionless_entities!" )
		return
	end
	
	local cable_list = {}
	local ent_list = {}
	
	local keys = list.Get( "TV_IO_ents" )
	
	local unique_keys = {}
	
	for i, key in ipairs( keys ) do
		if not table.HasValue( unique_keys, key ) then
			table.insert( unique_keys, key )
		end
	end
	
	for i, val in ipairs( unique_keys ) do
		local temp_list = ents.FindByClass( val )
		for j, ent in ipairs( temp_list ) do
			if not ent:CreatedByMap() then
				if val == "sent_tv_io_cable" then
					table.insert( cable_list, ent )
				else
					table.insert( ent_list, ent )
				end
			end
		end
	end
	
	for i, cable in ipairs( cable_list ) do
		local input_ent = cable:GetInputEnt() 
		local output_ent = cable:GetOutputEnt() 
	
		if (not IsValid(input_ent)) or (not IsValid(output_ent)) then
			print( "CABLE WITH MISSING CONNECTION(S):", cable )
		end
	end
end )




concommand.Add( "nav_clear_place",  function( ply, cmd, args, argStr )
	if not IsValid( ply ) then return end
	if not ply:IsAdmin() then
		ply:PrintMessage( HUD_PRINTCONSOLE, "You do not have permission to use nav_clear_place!" )
		return
	end
	
	local cnav = navmesh.GetMarkedArea()
	
	if IsValid( cnav ) then
		local corner_1 = cnav:GetCorner( 0 )
		local corner_2 = cnav:GetCorner( 2 )
		
		print( corner_1, corner_2 )
		
		cnav:Remove()
		
		navmesh.CreateNavArea( corner_1, corner_2 )
		
		print( "Done" )
	end
end )




concommand.Add( "nav_clear_place2",  function( ply, cmd, args, argStr )
	if not IsValid( ply ) then return end
	if not ply:IsAdmin() then
		ply:PrintMessage( HUD_PRINTCONSOLE, "You do not have permission to use nav_clear_place!" )
		return
	end
	
	local cnav = navmesh.GetMarkedArea()
	
	if IsValid( cnav ) then
		local corner_1 = cnav:GetCorner( 1 )
		local corner_2 = cnav:GetCorner( 3 )
		
		print( corner_1, corner_2 )
		
		cnav:Remove()
		
		navmesh.CreateNavArea( corner_1, corner_2 )
		
		print( "Done" )
	end
end )