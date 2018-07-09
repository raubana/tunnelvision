TOOL.Category = "Tunnel Vision IO"
TOOL.Name = "IO STool Connector"
TOOL.Command = nil
TOOL.ConfigName = ""




function TOOL:Restart()
	self:SetStage(0)
	self:ClearObjects()
end




function TOOL:LeftClick(tr)
	if tr.Hit and IsValid(tr.Entity) and 
	list.Contains( "TV_IO_ents", tr.Entity:GetClass() ) then
		local stage = self:GetStage()
	
		if stage == 0 then
			-- The user has selected an entity who's output is to be connected.
			self:SetObject( 1, tr.Entity, tr.Entity:GetPos(), tr.Entity:GetPhysicsObject(), 0, vector_up  )
			self:SetStage( 1 )
		elseif stage == 1 then
			-- The user has selected an entity who's input is to be connected.
			local input_ent = self:GetEnt(1) -- gives a signal to the cable
			local output_ent = tr.Entity -- receives a signal from the cable.
			
			local cable = ents.Create( "sent_tv_io_cable" )
			cable:SetPos( LerpVector(0.5, input_ent:GetPos(), output_ent:GetPos()) )
			cable:Spawn()
			cable:Activate()
			
			cable:SetInputEnt(input_ent)
			cable:SetOutputEnt(output_ent)
			
			undo.Create( "TV IO Cable" )
				undo.AddEntity( cable )
				undo.SetPlayer( self:GetOwner() )
			undo.Finish()
			
			self:Restart()
		end
		
		return true
	end
end




function TOOL:RightClick(tr)
	-- Unwires a cable.
	if tr.Hit and IsValid(tr.Entity) and 
	tr.Entity:GetClass() == "sent_tv_io_cable" then
		SafeRemoveEntity( tr.Entity )
		
		self:Restart()
		
		return true
	end
end




function TOOL:Reload(tr)
	self:Restart()
	
	return true
end