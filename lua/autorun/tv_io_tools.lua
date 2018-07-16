if not SERVER then return end
if not game.SinglePlayer() then return end
if engine.ActiveGamemode() != "sandbox" then return end




concommand.Add( "tv_io_save",  function( ply, cmd, args, argStr )
	if #args != 1 then return end

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
		print( val )
		table.insert( ent_datas, util.JSONToTable( val ) )
	end
	
	PrintTable( ent_datas )
	
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