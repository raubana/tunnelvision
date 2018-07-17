if not SERVER then return end




local DEBUGMODE = CreateConVar("tv_io_debug", 0, FCVAR_CHEAT+FCVAR_REPLICATED)
local UPDATE_DISABLED = CreateConVar("tv_io_update_disabled", 0, FCVAR_CHEAT+FCVAR_REPLICATED)
local INSTANT_TRANSMISSION_DISABLED = CreateConVar("tv_io_instant_transmission_disabled", 0, FCVAR_CHEAT+FCVAR_REPLICATED)




local instant_ent_list = instant_ent_list or {}
local regular_ent_list = regular_ent_list or {}
local always_update_ents = always_update_ents or {}

local instant_ents_to_update = instant_ents_to_update or {}
local other_ents_to_update = other_ents_to_update or {}




hook.Add( "TV_IO_MarkEntityToBeUpdated", "TV_IO_MarkEntityToBeUpdated", function( ent )
	if ent.InstantUpdate and not INSTANT_TRANSMISSION_DISABLED:GetBool() then
		if not table.HasValue( instant_ents_to_update, ent ) then
			table.insert( instant_ents_to_update, ent )
		end
	else
		if ( not ent.AlwaysUpdate ) and (not table.HasValue( other_ents_to_update, ent )) then
			table.insert( other_ents_to_update, ent )
		end
	end
end )




hook.Add( "Tick", "TVIO_Tick", function( )
	if UPDATE_DISABLED:GetBool() then return end
	
	local iterations = 0
	local indent = " "
	while #instant_ents_to_update > 0 do
		local old_instant_entities_to_update = instant_ents_to_update
		instant_ents_to_update = {}
		
		-- updated the instant entities (cables, throughs, etc).
		for i, ent in ipairs( old_instant_entities_to_update ) do
			if DEBUGMODE:GetBool() then
				print( CurTime(), indent, ent )
			end
			if IsValid( ent ) then
				ent:Update()
			end
		end
		
		indent = indent .. " "
		iterations = iterations + 1
		
		if iterations >= 1000 then
			ErrorNoHalt( "Ran maximum number of instant IO iterations! There may be an infinite loop." )
			for i, ent in ipairs( old_instant_entities_to_update ) do
				print( CurTime(), ent )
			end
			
			instant_ents_to_update = {}
			other_ents_to_update = {}
			break
		end
	end
	
	-- updates the regular entities.
	local old_other_ents_to_update = other_ents_to_update
	other_ents_to_update = {}
	for i, ent in ipairs(old_other_ents_to_update) do
		if DEBUGMODE:GetBool() then
			print( CurTime(), ent )
		end
		if IsValid( ent ) then
			ent:Update()
		end
	end
	
	-- updates the ents that always updated
	for i, ent in ipairs(always_update_ents) do
		if DEBUGMODE:GetBool() then
			print( CurTime(), ent )
		end
		if IsValid( ent ) then
			ent:Update()
		end
	end
	
end )




hook.Add( "OnEntityCreated", "TVIO_OnEntityCreated", function( ent )
	if list.Contains( "TV_IO_ents", class ) then
		if ent.AlwaysUpdate then
			table.insert( always_update_ents, ent )
		else
			if ent.InstantUpdate then
				table.insert( instant_ent_list, ent )
			else
				table.insert( regular_ent_list, ent )
			end
			-- hook.Call( "TV_IO_MarkEntityToBeUpdated", nil, ent )
		end
	end
end )




hook.Add( "EntityRemoved", "TVIO_EntityRemoved", function( ent )
	if list.Contains( "TV_IO_ents", class ) then
		if ent.AlwaysUpdate then
			table.RemoveByValue( always_update_ents, ent )
		else
			if ent.InstantUpdate then
				table.RemoveByValue( instant_ent_list, ent )
			else
				table.RemoveByValue( regular_ent_list, ent )
			end
		end
	end
end )




local function PostInitSetupCables()
	local cable_list = ents.FindByClass("sent_tv_io_cable")

	for i, cable in ipairs(cable_list) do
		if IsValid( cable ) then
			local input_ent = cable:GetInputEnt()
			if input_ent and IsValid( input_ent ) then
				cable:ConnectInputTo( input_ent, true )
			end
			
			local output_ent = cable:GetOutputEnt()
			if output_ent and IsValid( output_ent ) then
				cable:ConnectOutputTo( output_ent, true )
			end
		end
	end
end




hook.Add( "InitPostEntity", "TV_IO_InitPostEntity", function()
	PostInitSetupCables()
end )




hook.Add( "PreCleanupMap", "TV_IO_PreCleanupMap", function()
	instant_ent_list = {}
	regular_ent_list = {}
	always_update_ents = {}
end )




hook.Add( "PostCleanupMap", "TV_IO_PostCleanupMap", function()
	PostInitSetupCables()
end )




-- TODO: tv_io_reset concommand
concommand.Add( "tv_io_reset", function( ply, cmd, args, argStr )
	if not IsValid( ply ) then return end
	if not ply:IsAdmin() then
		ply:PrintMessage( HUD_PRINTCONSOLE, "You do not have permission to use tv_io_reset!" )
		return
	end
	
	for i, ent in ipairs( instant_ent_list ) do
	
	end
end )
