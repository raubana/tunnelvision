include("shared.lua")
include("sv_movement.lua")



function ENT:Initialize()
	self:SetModel( "models/gman_high.mdl" )
	self:SetMaterial( "models/props_wasteland/rockcliff02c" )
	
	self:RSNBInit()
	self.use_bodymoveyaw = true
	
	self.walk_speed = 100
	self.run_speed = 500
	
	self.walk_accel = 400
	self.walk_decel = 400
	
	self.run_accel = 400
	self.run_decel = 400
	
	self.frozen = false
	
	self.target = nil
	self.target_last_seen = 0
	self.target_last_known_position = nil
	
	self.interrupt = false
	
	self:SetMaxHealth(1000000)
	self:SetHealth(1000000)
end




function ENT:OnInjured( info )
	info:ScaleDamage(0)
end




function ENT:CheckShouldBeFrozen()
	local ply_list = player.GetAll()
	
	for i, ply in ipairs(ply_list) do
		if ply:Alive() and self:Visible( ply ) then
			local view_ang_dif = (self:GetHeadPos() - ply:GetShootPos()):Angle() - ply:EyeAngles()
			view_ang_dif:Normalize()
			
			if math.abs( view_ang_dif.yaw ) < 70 and math.abs( view_ang_dif.pitch ) < 70 then
				return true
			end
		end
	end
	
	return false
end




function ENT:BodyUpdate()
	if self.frozen then return end

	local act = self:GetActivity()
	
	if act == ACT_WALK or act == ACT_RUN then
		self:BodyMoveXY()
		if self.use_bodymoveyaw then
			self:BodyMoveYaw()
		end
		return
	end
	
	self:FrameAdvance()
end





function ENT:Think()
	self.frozen = self:CheckShouldBeFrozen()

	if not self.frozen then
		self:RSNBUpdate()
		
		if self.target then
			if not self.target:Alive() then
				print("lost target - he dead or gone too long")
				self.interrupt = true
				self.target = nil
			elseif self:Visible( self.target ) then
				self.target_last_seen = CurTime()
				self.target_last_known_position = self.target:GetPos()
				
				if self:GetRangeTo(self.target) < 30 then
					self.target:Kill()
					self.interrupt = true
				end
			elseif (CurTime()-self.target_last_seen > 15) then
				print("lost target - he dead or gone too long")
				self.interrupt = true
				self.target = nil
			end
		else
			self:FindTarget()
		end
	end
	self:NextThink( CurTime() )
	return true
end




function ENT:FindTarget()
	local ent_list = ents.FindInPVS(self)
	for i, ent in ipairs( ent_list ) do
		if IsValid(ent) and ent:IsPlayer() and ent:Alive() and self:Visible(ent) then
			print("found target")
			self.target = ent
			self.target_last_known_position = ent:GetPos()
			self.interrupt = true
			return
		end
	end
end




function ENT:HearSound( data )
	if self.target and CurTime() - self.target_last_seen > 1.0 then
		if data.Entity == self.target then
			local pos = data.Pos
			if not isvector(pos) then
				pos = data.Entity:GetPos()
			end
			
			local dist = pos:Distance(self:GetPos())
			local chance = 1/(math.pow(dist/250, 2)+1)
			local radius = dist/2
			
			
			if math.random() < chance then
				print( "I heard that!" )
				self.target_last_known_position = self:FindSpot("near", {
					pos = pos,
					radius = radius
				})
				
				if not isvector(self.target_last_known_position) then
					self.target_last_known_position = pos
				end
			end
		end
	end
end




function ENT:RunBehaviour()
	self:PushActivity( ACT_IDLE )
	
	coroutine.wait( 1 )
	
	while true do
		local pos
	
		if self.target then
			pos = self.target:GetPos()
		else
			pos = self:FindSpot(
				"random",
				{
					type = "hiding",
					pos = self:GetPos(),
					radius = 100000
				}
			)
		end
		
		local result = self:MoveToPos( pos, {} )
		print( "MOVE TO POS RESULT:", result )
		
		if result == "interrupt" then
			self.interrupt = false
		else
			if not self.frozen then
				if self.target then
					if self:Visible(self.target) then
						self.target_last_known_position = self.target:GetPos()
					elseif self:GetPos():Distance( self.target_last_known_position ) < 10 then
						print("lost target - reached last known position")
						self.target = nil
						self.interrupt = true
					end
				end
			end
		end
	
		coroutine.yield( )
	end
end




hook.Add( "EntityEmitSound", "WeepingGman_EntityEmitSound", function( data )
	local weepers = ents.FindByClass("snpc_weeping_gman")
	for i, npc in ipairs(weepers) do
		npc:HearSound( data )
	end
end )
