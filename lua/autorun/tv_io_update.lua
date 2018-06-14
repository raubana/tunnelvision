if not SERVER then return end



local DEBUGMODE = CreateConVar("tv_io_debug", 0, FCVAR_CHEAT+FCVAR_REPLICATED)




local cable_list = cable_list or {}
local ent_list = ent_list or {}




hook.Add( "Tick", "TVIO_Tick", function( )
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




local function connectCables()
	for i, cable in ipairs( cable_list ) do
		if cable.input_entity_name then
			local ent = ents.FindByName(cable.input_entity_name)
			if #ent == 1 then
				ent = ent[1]
				if IsValid( ent ) then
					cable:SetInputEnt( ent )
				end
			end
		end
		
		if cable.output_entity_name then
			local ent = ents.FindByName(cable.output_entity_name)
			if #ent == 1 then
				ent = ent[1]
				if IsValid( ent ) then
					cable:SetOutputEnt( ent )
				end
			end
		end
		
		if cable.input_id_value then
			cable:SetInputID( cable.input_id_value )
		end
		
		if cable.output_id_value then
			cable:SetOutputID( cable.output_id_value )
		end
		
		cable.input_id_value = nil
		cable.output_id_value = nil
		cable.input_entity_name = nil
		cable.output_entity_name = nil
	end
end




hook.Add( "InitPostEntity", "TVIO_InitPostEntity", function( )
	connectCables()
end )

hook.Add( "PostCleanupMap", "TVIO_PostCleanupMap", function( )
	connectCables()
end )