local DEBUG_MODE = GetConVar("twg_debug")




function ENT:RunBehaviourCurious()
	self.current_behaviour = self.BEHAVIOUR_CURIOUS
	
	self.home_pos = self:GetPos()
	self.home_ang = self:GetAngles()

	self:PushActivity( ACT_IDLE )
	
	coroutine.wait( 1 )
	
	while true do
		while self.frozen do
			coroutine.yield()
		end
		
		local result
		
		coroutine.wait(1.0)
		
		if self:IsAtHome() then
			
			if self.have_target then
				
				if CurTime() - self.target_last_seen > 3 then
						
					if not isvector( self.target_last_known_position )  then
					
						if DEBUG_MODE:GetBool() then
							print( self, "I'm going to look around." )
						end
						
						result = self:Search()
						
					else
					
						if DEBUG_MODE:GetBool() then
							print( self, "I'm going to look where I last saw them." )
						end
						
						result = self:MoveToPos( self.target_last_known_position )
						
					end
				
				end
				
			else
			
				if DEBUG_MODE:GetBool() then
					print( self, "I'm going to wander." )
				end
				
				result = self:Wander( )
				
			end
			
		else
		
			if DEBUG_MODE:GetBool() then
				print( self, "I'm going home." )
			end
			
			result = self:MoveToPos( self.home_pos )
			
		end
		
		if DEBUG_MODE:GetBool() then
			print( self, "RESULT:", result )
		end
		
		if self.interrupt then
			self.interrupt = false
			local reason = self.interrupt_reason
			self.interrupt_reason = nil
			
			if DEBUG_MODE:GetBool() then
				print( self, "INTERRUPT:", reason )
			end
			
			if reason == "heard something" then
				self:Listen()
			elseif reason == "found target" then
				coroutine.wait(1)
			elseif reason == "became unstable" then
				coroutine.wait(1)
			end
		end
	
		coroutine.yield()
	end
end