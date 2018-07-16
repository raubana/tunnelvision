local DEBUG_SEARCH = CreateConVar("twg_debug_search", "0", FCVAR_SERVER_CAN_EXECUTE+FCVAR_NOTIFY+FCVAR_CHEAT)




function ENT:SearchInit()
	self.search_spots = {}
	self.search_radius = 1500
	self.search_forget_radius = 2000
	self.search_spot_timeout = 60
	
	self.search_interval = 0.5
	self.search_next = 0
end




function ENT:PickSpotToSearch()
	local scored_spots = {}
	
	local max = 0
	local min = math.huge
	
	for i, spot in ipairs( self.search_spots ) do
		if not spot.checked then
			local dist = spot.vector:Distance(self:GetPos())
			min = math.min( min, dist )
			max = math.max( max, dist )
			table.insert( scored_spots, { spot, dist } )
		end
	end
	
	local total = 0
	for i, scored_spot in ipairs( scored_spots ) do
		scored_spot[2] = (max - scored_spot[2]) + min
		total = total + scored_spot[2]
	end
	
	if #scored_spots == 0 then return end
	
	table.sort( scored_spots, function( a, b ) return a[2] > b[2] end )
	
	local pick = math.random() * total
	
	if DEBUG_SEARCH:GetBool() then
		PrintTable( scored_spots )
		print( pick )
	end
	
	local accum = 0
	for i, spot in ipairs( scored_spots ) do
		accum = accum + spot[2]
		if accum >= pick then
			return spot[1]
		end
	end
end




function ENT:Search()
	if DEBUG_SEARCH:GetBool() then
		print( self, "Search" )
	end
	
	while self.have_target or self.have_old_target do
		if self.interrupt then return "interrupt" end
		
		local spot = self:PickSpotToSearch()
	
		if istable(spot) then
			local result = self:MoveToPos( spot.vector, { maxage = 30 } )
			
			if DEBUG_SEARCH:GetBool() then
				print( self, spot.vector, "RESULT OF SEARCH:", result)
			end
			
			if result == "interrupt" then return result end
			
			spot.checked = true
			spot.time = CurTime()
		else
		
			self.search_spots = {}
			return "failed"
		end
	end
	
	self.search_spots = {}
	return "failed"
end




local NOT_CHECKED_SPOT_COLOR = Color(255,255,0)
local CHECKED_SPOT_COLOR = Color(255,0,255)


function ENT:SearchUpdate()
	if CurTime() < self.search_next then return end
	self.search_next = CurTime() + self.search_interval

	local i = #self.search_spots
	while i > 0 do
		if DEBUG_SEARCH:GetBool() then
			local c = NOT_CHECKED_SPOT_COLOR
			if self.search_spots[i].checked then
				c = CHECKED_SPOT_COLOR
			end
			debugoverlay.Line( self.search_spots[i].vector, self.search_spots[i].vector + Vector(0,0,10), self.search_interval, c, true )
		end
		
		local dist =  self.search_spots[i].vector:Distance(self:GetPos())
		
		if dist < 50 then
			self.search_spots[i].checked = true
			self.search_spots[i].time = CurTime()
		elseif dist >= self.search_forget_radius then
			table.remove( self.search_spots, i )
		elseif self.search_spots[i].checked and CurTime() - self.search_spots[i].time >= self.search_spot_timeout then
			self.search_spots[i].checked = false
		end
		i = i - 1
	end
	
	local spots = self:FindSpots({
		pos = self:GetPos(),
		radius = self.search_radius
	})
	
	for i, spot in ipairs(spots) do
		local can_see = self:CanSeeVector(spot.vector)

		local match = nil
	
		for i, remembered_spot in ipairs( self.search_spots ) do
			if remembered_spot.vector:DistToSqr(spot.vector) < 50 then
				match = remembered_spot
				break
			end
		end
		
		if match then
			if can_see then
				match.time = CurTime()
			end
		else
			-- It's a new spot, we'll need to add it to the list.
			spot.time = CurTime()
			spot.checked = can_see
			spot.distance = nil
			table.insert( self.search_spots, spot )
		end

	end
end