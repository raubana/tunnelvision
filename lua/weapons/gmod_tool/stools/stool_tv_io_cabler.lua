TOOL.Category = "Tunnel Vision IO"
TOOL.Name = "IO STool Cabler"
TOOL.Command = nil
TOOL.ConfigName = ""




function TOOL:Restart()
	self:SetStage(0)
	self:ClearObjects()
end




function TOOL:LeftClick(tr)
	if tr.Hit and tr.Entity:IsWorld() then
		local stage = self:GetStage()
		
		local through = ents.Create( "sent_tv_io_through" )
		through:SetPos( tr.HitPos + tr.HitNormal )
		through:Spawn()
		through:Activate()
		
		undo.Create( "TV IO Cabler Link" )
		undo.AddEntity( through )
		undo.SetPlayer( self:GetOwner() )
		
		if stage == 0 then
			-- The user has started a cable.
			self:SetStage( 1 )
		elseif stage == 1 then
			-- The user has placed another point for the cable.
			local prev_through = self:GetEnt(1) -- the last "through" entity.
			
			local cable = ents.Create( "sent_tv_io_cable" )
			cable:SetPos( LerpVector(0.5, prev_through:GetPos(), through:GetPos()) )
			cable:Spawn()
			cable:Activate()
			
			cable:SetInputEnt(prev_through)
			cable:SetOutputEnt(through)
			
			undo.AddEntity( cable )
		end
		
		undo.Finish()
		
		self:SetObject( 1, through, through:GetPos(), through:GetPhysicsObject(), 0, vector_up )
		
		return true
	end
end




function TOOL:RightClick(tr)
	
end




function TOOL:Reload(tr)
	self:Restart()
	
	return true
end