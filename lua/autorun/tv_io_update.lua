if not SERVER then return end


local ent_list = ent_list or {}




hook.Add( "Tick", "TVIO_Tick", function( )
	-- sets the in values.
	for i, ent in ipairs( ent_list ) do
		ent:UpdateI()
	end
	
	-- sets the out values.
	for i, ent in ipairs( ent_list ) do
		ent:UpdateO()
	end
end )




hook.Add( "OnEntityCreated", "TVIO_OnEntityCreated", function( ent )
	if list.Contains( "Tunnel Vision: IO Entities", ent:GetClass() ) then
		table.insert( ent_list, ent )
	end
end )




hook.Add( "EntityRemoved", "TVIO_EntityRemoved", function( ent )
	if list.Contains( "Tunnel Vision: IO Entities", ent:GetClass() ) then
		table.RemoveByValue( ent_list, ent )
	end
end )