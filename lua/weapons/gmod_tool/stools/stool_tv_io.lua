TOOL.Category = "Tunnel Vision IO"
TOOL.Name = "IO STool"
TOOL.Command = nil
TOOL.ConfigName = ""




function TOOL:Restart()
	self:SetStage(0)
	self:ClearObjects()
end




function TOOL:LeftClick(tr)
	if tr.Hit and IsValid(tr.Entity) and 
	list.Contains( "Tunnel Vision: IO Entities", tr.Entity:GetClass() ) then
		local stage = self:GetStage()
	
		if stage == 0 then
			-- The user has selected a cable. We're going to connect it's IN to
			-- an OUT of another entity.
			self:SetObject( 1, tr.Entity, tr.Entity:GetPos(), tr.Entity:GetPhysicsObject(), 0, vector_up )
			self:SetStage( 1 )
		elseif stage == 1 then
			-- The user has selected an entity who's output is to be connected.
			self:SetObject( 2, tr.Entity, tr.Entity:GetPos(), tr.Entity:GetPhysicsObject(), 0, vector_up  )
			self:SetStage( 2 )
		elseif stage == 2 then
			-- The user has selected an entity who's input is to be connected.
			--self:SetObject( 3, tr.Entity )
			--self:SetStage( 3 )
			
			local cable = self:GetEnt(1)
			local input_ent = self:GetEnt(2) -- gives a signal to the cable
			local output_ent = tr.Entity -- receives a signal from the cable.
			
			cable:SetInputEnt(input_ent)
			cable:SetOutputEnt(output_ent)
			
			self:Restart()
		end
		
		return true
	end
end




function TOOL:RightClick(tr)
	-- Unwires a cable.
	if tr.Hit and IsValid(tr.Entity) and 
	list.Contains( "Tunnel Vision: IO Entities", tr.Entity:GetClass() ) then
		local cable = tr.Entity
		
		cable:SetInputEnt(nil)
		cable:SetOutputEnt(nil)
		
		self:Restart()
		
		return true
	end
end




function TOOL:Reload(tr)
	self:Restart()
	
	return true
end