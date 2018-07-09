if not SERVER then return end




local DEBUGMODE = CreateConVar("tv_io_debug", 0, FCVAR_CHEAT+FCVAR_REPLICATED)
local UPDATE_DISABLED = CreateConVar("tv_io_update_disabled", 0, FCVAR_CHEAT+FCVAR_REPLICATED)




local cable_list = cable_list or {}
local ent_list = ent_list or {}




hook.Add( "Tick", "TVIO_Tick", function( )
	if UPDATE_DISABLED:GetBool() then return end

	-- cables grab their input.
	for i, ent in ipairs( cable_list ) do
		ent:UpdateI()
	end
	
	-- cables give their output.
	for i, ent in ipairs( cable_list ) do
		ent:UpdateO()
	end
	
	-- updates the entities.
	for i, ent in ipairs( ent_list ) do
		ent:Update()
	end
end )




hook.Add( "OnEntityCreated", "TVIO_OnEntityCreated", function( ent )
	local class = ent:GetClass() 
	if list.Contains( "TV_IO_ents", class ) then
		if class == "sent_tv_io_cable" then
			table.insert( cable_list, ent )
		else
			table.insert( ent_list, ent )
		end
	end
end )




hook.Add( "EntityRemoved", "TVIO_EntityRemoved", function( ent )
	local class = ent:GetClass() 
	if list.Contains( "TV_IO_ents", class ) then
		if class == "sent_tv_io_cable" then
			table.RemoveByValue( cable_list, ent )
		else
			table.RemoveByValue( ent_list, ent )
		end
	end
end )
