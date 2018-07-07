print( "MAP GEN" )



local PLACE_APARTMENT = 1
local PLACE_BOMBSITEA = 2
local PLACE_BOMBSITEB = 3
local PLACE_BOMBSITEC = 4
local PLACE_BRIDGE = 5
local PLACE_CTSPAWN = 6
local PLACE_HOSTAGERESCUEZONE = 7
local PLACE_HOUSE = 8
local PLACE_MARKET = 9
local PLACE_MIDDLE = 10
local PLACE_TSPAWN = 11
local PLACE_VIPRESCUEZONE = 12


local PLACE_CONNECTION_TABLE = {}
PLACE_CONNECTION_TABLE[PLACE_APARTMENT] = {
	PLACE_CTSPAWN,
	PLACE_HOUSE,
	PLACE_MARKET,
	PLACE_VIPRESCUEZONE
}
PLACE_CONNECTION_TABLE[PLACE_BOMBSITEA] = {
	PLACE_MIDDLE
}
PLACE_CONNECTION_TABLE[PLACE_BOMBSITEB] = {
	PLACE_MIDDLE
}
PLACE_CONNECTION_TABLE[PLACE_BOMBSITEC] = {
	PLACE_HOUSE
}
PLACE_CONNECTION_TABLE[PLACE_BRIDGE] = {
	PLACE_MARKET
}
PLACE_CONNECTION_TABLE[PLACE_CTSPAWN] = {
	PLACE_APARTMENT
}
PLACE_CONNECTION_TABLE[PLACE_HOSTAGERESCUEZONE] = {
	PLACE_HOUSE
}
PLACE_CONNECTION_TABLE[PLACE_HOUSE] = {
	PLACE_APARTMENT,
	PLACE_HOSTAGERESCUEZONE,
	PLACE_MARKET,
	PLACE_MIDDLE
}
PLACE_CONNECTION_TABLE[PLACE_MARKET] = {
	PLACE_APARTMENT,
	PLACE_BRIDGE,
	PLACE_HOUSE,
	PLACE_MIDDLE,
	PLACE_TSPAWN
}
PLACE_CONNECTION_TABLE[PLACE_MIDDLE] = {
	PLACE_BOMBSITEA,
	PLACE_BOMBSITEB,
	PLACE_HOUSE,
	PLACE_MARKET
}
PLACE_CONNECTION_TABLE[PLACE_TSPAWN] = {
	PLACE_MARKET
}
PLACE_CONNECTION_TABLE[PLACE_VIPRESCUEZONE] = {
	PLACE_APARTMENT
}



local function makeDoorConnectionString( place1, place2 )
	local min = math.min( place1, place2 )
	local max = math.max( place1, place2 )
	
	return tostring(min).." "..tostring(max)
end



local COLOR_RED = Color(255,128,128)
local COLOR_GREEN = Color(128,255,128)
local COLOR_CYAN = Color(128,255,255)
local COLOR_YELLOW = Color(255,255,128)



DOOR_CONNECTION_TABLE = {}
DOOR_CONNECTION_TABLE["door_1"] = {PLACE_BOMBSITEA, PLACE_MIDDLE, COLOR_GREEN}
DOOR_CONNECTION_TABLE["door_2"] = {PLACE_BOMBSITEB, PLACE_MIDDLE, COLOR_GREEN}
DOOR_CONNECTION_TABLE["door_3"] = {PLACE_HOUSE, PLACE_HOSTAGERESCUEZONE, COLOR_RED}
DOOR_CONNECTION_TABLE["door_4"] = {PLACE_BOMBSITEC, PLACE_HOUSE, COLOR_RED}
DOOR_CONNECTION_TABLE["door_5"] = {PLACE_MARKET, PLACE_TSPAWN, COLOR_CYAN}
DOOR_CONNECTION_TABLE["door_6"] = {PLACE_MARKET, PLACE_BRIDGE, COLOR_CYAN}
DOOR_CONNECTION_TABLE["door_7"] = {PLACE_APARTMENT, PLACE_CTSPAWN, COLOR_YELLOW}
DOOR_CONNECTION_TABLE["door_8"] = {PLACE_APARTMENT, PLACE_VIPRESCUEZONE, COLOR_YELLOW}
DOOR_CONNECTION_TABLE["door_9"] = {PLACE_MIDDLE, PLACE_HOUSE, color_white}
DOOR_CONNECTION_TABLE["door_10"] = {PLACE_MIDDLE, PLACE_MARKET, color_white}
DOOR_CONNECTION_TABLE["door_11"] = {PLACE_MIDDLE, PLACE_MARKET, color_white}
DOOR_CONNECTION_TABLE["door_12"] = {PLACE_APARTMENT, PLACE_MARKET, color_white}
DOOR_CONNECTION_TABLE["door_13"] = {PLACE_APARTMENT, PLACE_HOUSE, color_white}
DOOR_CONNECTION_TABLE["door_14"] = {PLACE_APARTMENT, PLACE_HOUSE, color_white}
DOOR_CONNECTION_TABLE["door_15"] = {PLACE_HOUSE, PLACE_MARKET, color_white}




local function getDoorsInBetween( a, b )
	local matches = {}

	for key, val in pairs( DOOR_CONNECTION_TABLE ) do
		if val[1] == a and val[2] == b or val[2] == a and val[1] == b then
			table.insert( matches, key )
		end
	end
	
	return matches
end




local function CanGetFromPlaceAToPlaceB( a, b, locked_doors )
	if a == b then return true end

	local open_list = {a}
	local closed_list = {}
	
	while #open_list > 0 do
		local current_place = table.remove( open_list )
		table.insert( closed_list, current_place )
		
		for i, next_place in ipairs( PLACE_CONNECTION_TABLE[current_place] ) do
			if not table.HasValue(open_list, next_place) and not table.HasValue(closed_list, next_place) then
				local doors_in_between = getDoorsInBetween( current_place, next_place )
				local can_get_through = #doors_in_between <= 0
				
				if not can_get_through then
					for i, door_name in ipairs( doors_in_between ) do
						if not table.HasValue( locked_doors, door_name ) then
							can_get_through = true
							break
						end
					end
				end
				
				if can_get_through then
					if next_place == b then
						return true
					end
					
					table.insert( open_list, next_place )
				end
			end
		end
	end
	
	return false
end




local function CanGetFromPlaceToDoor( place, door, locked_doors )
	return CanGetFromPlaceAToPlaceB(place, DOOR_CONNECTION_TABLE[door][1], locked_doors) or CanGetFromPlaceAToPlaceB(place, DOOR_CONNECTION_TABLE[door][2], locked_doors)
end



SPAWN_LOCATION_TABLE = {
	{PLACE_BOMBSITEA, Vector(-2338, -2796, 12)},
	{PLACE_BOMBSITEB , Vector(-930, -2084, 12)},
	{PLACE_HOSTAGERESCUEZONE, Vector(-6646, -2224, 12)},
	{PLACE_BOMBSITEC, Vector(-3097, -4245, 12)},
	{PLACE_TSPAWN, Vector(-797, -3888, 12)},
	{PLACE_BRIDGE, Vector(-2488, -6429, 12)},
	{PLACE_CTSPAWN, Vector(-5282, -4505, 12)},
	{PLACE_VIPRESCUEZONE, Vector( -6855, -6940, 12)},
	{PLACE_HOUSE, Vector(-3386, -192, 12)},
	{PLACE_HOUSE, Vector(-4102, -1823, 12)},
	{PLACE_HOUSE, Vector(-4047, -2791, 12)},
	{PLACE_HOUSE, Vector(-5997, -168, 12)},
	{PLACE_MIDDLE, Vector(-1394, -1118, 12)},
	{PLACE_MIDDLE, Vector(-248, -2978, 12)},
	{PLACE_MIDDLE, Vector(-2341, -3894, 12)},
	{PLACE_APARTMENT, Vector(-5953, -4960, 12)},
	{PLACE_APARTMENT, Vector(-3554, -7391, 12)},
	{PLACE_APARTMENT, Vector(-6821, -7848, 12)},
	{PLACE_MARKET, Vector(-2504, -5705, 12)},
	{PLACE_MARKET, Vector(-1623, -6311, 12)},
	{PLACE_MARKET, Vector(-696, -5240, 12)},
}



local function getSpawnsOfType( spawns, target_type )
	local result = {}
	
	for i, val in ipairs( spawns ) do
		if type(val) == target_type then
			table.insert( result, i )
		end
	end
	
	return result
end



local function recursePickKeySpawn( data )
	local possible_picks = getSpawnsOfType( data.spawns, type(false) )
	util.ShuffleTable( possible_picks )
	
	local original_locked_doors = data.locked_doors
	
	local start_location = data.current_location
	
	local original_summary = data.summary
	
	for j, i in ipairs( possible_picks ) do
		local key_location = SPAWN_LOCATION_TABLE[i][1]
	
		local locked_doors = table.Copy(data.locked_doors)
		util.ShuffleTable( locked_doors )
		
		data.summary = data.summary .. "player moves from "..tostring(start_location).." to "..tostring(key_location).." to get key "..tostring(#possible_picks)..", "
		
		if CanGetFromPlaceAToPlaceB( start_location, key_location, data.locked_doors ) then
		
			data.current_location = key_location
		
			for k, door in ipairs( locked_doors ) do
				
				if CanGetFromPlaceToDoor( key_location, door, data.locked_doors ) then
			
					local new_locked_doors = table.Copy( original_locked_doors )
					table.RemoveByValue( new_locked_doors, door )
					
					data.summary = data.summary .. "player goes to "..door.." and unlocks it, "
					data.spawns[i] = {1.0*data.num_keys, door}
					data.locked_doors = new_locked_doors
					data.num_keys = data.num_keys + 1
					
					print( data.summary )
					
					local result
					if data.num_keys >= data.num_doors then
						return data
					else
						result = recursePickKeySpawn( data )
					end
					if result != false then return result end
					
					data.num_keys = data.num_keys - 1
					data.locked_doors = original_locked_doors
					data.spawns[i] = false
					data.summary = original_summary
					
				end
				
			end
		
			data.current_location = start_location
		end
		
		data.summary = original_summary
	end
	
	return false
end



local function recursePickWeepingGmanSpawn( data )
	local possible_picks = getSpawnsOfType( data.spawns, type(false) )
	util.ShuffleTable( possible_picks )
	
	local original_summary = data.summary
	
	for j, i in ipairs( possible_picks ) do
		if CanGetFromPlaceAToPlaceB( data.current_location, SPAWN_LOCATION_TABLE[i][1], data.locked_doors ) then
	
			data.summary = data.summary .. "Gman spawns at "..tostring(i).." (place "..tostring(SPAWN_LOCATION_TABLE[i][1]).."), "
			data.spawns[i] = "gman"
			
			local result = recursePickKeySpawn( data )
			if result != false then return result end
			
			data.spawns[i] = false
			data.summary = original_summary
		
		end
	end
	
	return false
end




local function recursePickCorpseSpawn( data )
	local possible_picks = getSpawnsOfType( data.spawns, type(false) )
	util.ShuffleTable( possible_picks )
	
	local original_summary = data.summary
	
	for j, i in ipairs( possible_picks ) do
		
		--data.summary = data.summary .. "Gman spawns at "..tostring(i).." (place "..tostring(SPAWN_LOCATION_TABLE[i][1]).."), "
		data.spawns[i] = "corpse"
		
		local result = recursePickWeepingGmanSpawn( data )
		if result != false then return result end
		
		data.spawns[i] = false
		data.summary = original_summary
		
	end
	
	return false
end



local function recursePickPlayerSpawn( data )
	local possible_picks = getSpawnsOfType( data.spawns, type(false) )
	util.ShuffleTable( possible_picks )
	
	local original_summary = data.summary
	
	for j, i in ipairs( possible_picks ) do
		data.summary = data.summary .. "Player spawns at "..tostring(i).." (place "..tostring(SPAWN_LOCATION_TABLE[i][1]).."), "
		data.spawns[i] = "player"
		data.current_location = SPAWN_LOCATION_TABLE[i][1]
		
		local result = recursePickCorpseSpawn( data )
		if result != false then return result end
		
		data.spawns[i] = false
		data.current_location = 0
		data.summary = original_summary
		
		collectgarbage()
	end
	
	return false
end



local function recurseBeginGeneration( )
	collectgarbage()

	local data = {}
	data.summary = ""
	data.spawns = {}
	data.current_location = 0
	data.num_keys = 0
	data.num_doors = #table.GetKeys(DOOR_CONNECTION_TABLE)
	data.locked_doors = {}
	
	for i, val in ipairs( SPAWN_LOCATION_TABLE ) do
		table.insert( data.spawns, false )
	end
	
	for key, val in pairs( DOOR_CONNECTION_TABLE ) do
		table.insert( data.locked_doors, key )
	end
	
	local result = recursePickPlayerSpawn( data )
	
	return result
end



function GM:GenerateMap()
	-- math.randomseed( 1 )
	
	-- Until I can get navmesh place names, I'm going to keep this simplish...
	
	-- First we lock all of the doors.
	
	if game.GetMap() != "output" then return end
	
	for key, val in pairs( DOOR_CONNECTION_TABLE ) do
		local ent_list = ents.FindByName(key)
		local door_ent = ent_list[1]
		
		if IsValid( door_ent ) then
			door_ent:Fire( "Lock" )
		end
	end
	
	-- Next we generate our puzzle data.
	
	return recurseBeginGeneration()
end