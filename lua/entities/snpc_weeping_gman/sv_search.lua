function ENT:SearchInit()
	self.search_spots = {}
	self.search_radius = 750
	self.search_forget_radius = 1500
	self.search_spot_timeout = 60
	self.search_duration = 90
	
	self.search_interval = 0.5
	self.search_next = 0
end




function ENT:PickSpotToSearch()
	local best_spot = nil
	local best_spot_score = nil
	
	for i, spot in ipairs(self.search_spots) do
		if not spot.checked then
			local dist = spot.vector:Distance(self:GetPos())
			if best_spot == nil or dist < best_spot_score then
				best_spot = spot
				best_spot_score = dist
			end
		end
	end
	
	return best_spot
end




function ENT:Search()
	print( self, "Search" )
	
	while CurTime() - self.target_last_seen < self.search_duration do
		if self.interrupt then return "interrupt" end
		
		local spot = self:PickSpotToSearch()
	
		if istable(spot) then
			local result = self:MoveToPos( spot.vector )
			if result != "ok" then
				spot.checked = true
				spot.time = CurTime()
			end
		else
			return "failed"
		end
	end
	
	return "timeout"
end




local NOT_CHECKED_SPOT_COLOR = Color(255,255,0)
local CHECKED_SPOT_COLOR = Color(255,0,255)


function ENT:SearchUpdate()
	if CurTime() < self.search_next then return end
	self.search_next = CurTime() + self.search_interval

	local i = #self.search_spots
	while i > 0 do
		--[[
		local c = NOT_CHECKED_SPOT_COLOR
		if self.search_spots[i].checked then
			c = CHECKED_SPOT_COLOR
		end
		debugoverlay.Line( self.search_spots[i].vector, self.search_spots[i].vector + Vector(0,0,10), self.search_interval, c, true )
		]]
		
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