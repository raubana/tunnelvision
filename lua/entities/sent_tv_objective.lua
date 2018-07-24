AddCSLuaFile()

DEFINE_BASECLASS( "base_anim" )

ENT.PrintName		= "TV: Objective"
ENT.Author			= "Raubana"
ENT.Information		= ""
ENT.Category		= "Other"

ENT.Editable		= false
ENT.Spawnable		= false
ENT.AdminOnly		= false
ENT.RenderGroup		= RENDERGROUP_OTHER







function ENT:Initialize()
	self:SetNoDraw(true)
	self:DrawShadow(false)
	self:SetSolid(SOLID_NONE)
	self:SetMoveType(MOVETYPE_NONE)
	
	if SERVER then
		self.description = "TODO"
		self.known = false
		
		self.total_known = true
		self.total_done = 0
		self.total_needed = 1
		
		self.must_be_known_to_complete = true
		
		self.status = 0
		
		if self.start_description != nil then
			self.description = self.start_description
			self.start_description = nil
		end
		
		if self.start_known != nil then
			self.known = self.start_known
			self.start_known = nil
		end
		
		if self.start_total_known != nil then
			self.total_known = self.start_total_known
			self.start_total_known = nil
		end
		
		if self.start_total_done != nil then
			self.total_done = self.start_total_done
			self.start_total_done = nil
		end
		
		if self.start_total_needed != nil then
			self.total_needed = self.start_total_needed
			self.start_total_needed = nil
		end
		
		if self.start_must_be_known_to_complete != nil then
			self.must_be_known_to_complete = self.start_must_be_known_to_complete
			self.start_must_be_known_to_complete = nil
		end
		
		if self.start_status != nil then
			self.status = self.start_status
			self.start_status = nil
		end
		
	end
	
end




if SERVER then
	
	function ENT:KeyValue(key, value)
		if key == "OnBecomeKnown" or key == "OnTotalBecomeKnown" or
		key == "OnStatusComplete" or key == "OnStatusIncomplete" or 
		key =="OnStatusChange" or key =="OnTotalChange" or key =="OnChange" then
			self:StoreOutput(key, value)
		elseif key == "message" then
			self.start_description = value
		elseif key == "known" then
			self.start_known = tobool( tonumber( value ) )
		elseif key == "total_known" then
			self.start_total_known = tobool( tonumber( value ) )
		elseif key == "total_done" then
			self.start_total_done = tonumber( value )
		elseif key == "total_needed" then
			self.start_total_needed = tonumber( value )
		elseif key == "must_be_known_to_complete" then
			self.start_must_be_known_to_complete = tobool( tonumber( value ) )
		elseif key == "status" then
			self.start_status = tonumber( value )
		end
	end
	
	
	
	
	function ENT:CheckStatus()
		if self.must_be_known_to_complete and ( (not self.known) or (not self.total_known) ) then return end
	
		local old_status = self.status
		local new_status = 0
		
		if self.known and self.total_known and self.total_done >= self.total_needed then
			new_status = 1
		end
		
		if old_status != new_status then
			self.status = new_status
			if new_status == 0 then
				if engine.ActiveGamemode() == "tunnelvision" then
					GAMEMODE:SendMessage( "Objective Incomplete: "..self.description )
				end
				self:TriggerOutput("OnStatusIncomplete", self)
			elseif new_status == 1 then
				if engine.ActiveGamemode() == "tunnelvision" then
					GAMEMODE:SendMessage( "Objective Complete: "..self.description )
				end
				self:TriggerOutput("OnStatusComplete", self)
			end
			self:TriggerOutput("OnStatusChange", self)
			self:TriggerOutput("OnChange", self)
		end
	end
	
	
	
	
	function ENT:TotalBecomeKnown()
		if self.total_known then return end
		self.total_known = true
		
		if engine.ActiveGamemode() == "tunnelvision" then
			GAMEMODE:SendMessage( "Objective updated." )
		end
		
		self:TriggerOutput("OnTotalBecomeKnown", self)
		self:TriggerOutput("OnChange", self)
		
		self:CheckStatus()
	end
	
	
	
	
	function ENT:BecomeKnown()
		if self.known then return end
		self.known = true
		
		if engine.ActiveGamemode() == "tunnelvision" then
			GAMEMODE:SendMessage( "New objective: "..self.description )
		end
		
		self:TriggerOutput("OnBecomeKnown", self)
		self:TriggerOutput("OnChange", self)
		
		if self.total_known then
			self:TriggerOutput("OnTotalBecomeKnown", self)
			self:TriggerOutput("OnChange", self)
		end
		
		self:CheckStatus()
	end
	
	
	
	
	function ENT:SetTotal( new_total )
		if new_total == self.total_done then return end
		self.total_done = new_total
		
		if engine.ActiveGamemode() == "tunnelvision" then
			if ( self.total_needed > 1 ) and self.known and self.total_known then
				GAMEMODE:SendMessage( tostring(self.total_done).." / "..tostring(self.total_needed) )
			end
		end
		
		self:TriggerOutput("OnTotalChange", self)
		self:TriggerOutput("OnChange", self)
		
		self:CheckStatus()
	end
	
	
	
	
	function ENT:AcceptInput( name, activator, caller, data )
		if name == "BecomeKnown" then
			self:BecomeKnown()
		elseif name == "TotalBecomeKnown" then
			self:TotalBecomeKnown()
		elseif name == "SetTotal" then
			self:SetTotal( tonumber( data ) )
		end
	end
	
end