if not SERVER then return end
if not game.SinglePlayer() then return end
if engine.ActiveGamemode() != "sandbox" then return end




concommand.Add( "tv_io_save",  function( ply, cmd, args, argStr )
	if #args != 1 then return end

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
		if val == "sent_tv_io_cable" then
			cable_list = temp_list
		else
			table.Add( ent_list, temp_list )
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