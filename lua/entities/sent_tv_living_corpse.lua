AddCSLuaFile()

DEFINE_BASECLASS( "base_anim" )

ENT.PrintName		= "Tunnel Vision: Living Corpse"
ENT.Author			= "raubana"
ENT.Information		= ""
ENT.Category		= "Tunnel Vision"

ENT.Editable		= false
ENT.Spawnable		= true
ENT.AdminOnly		= true
ENT.RenderGroup		= RENDERGROUP_OPAQUE



ENT.PHYS_OBJ_INFO = {}
ENT.PHYS_OBJ_INFO[0] = {connectsto = nil}
ENT.PHYS_OBJ_INFO[1] = {connectsto = 0, power=100}
ENT.PHYS_OBJ_INFO[2] = {connectsto = 1, power=100}
ENT.PHYS_OBJ_INFO[3] = {connectsto = 2, power=100}
ENT.PHYS_OBJ_INFO[4] = {connectsto = 1, power=100}
ENT.PHYS_OBJ_INFO[5] = {connectsto = 1, power=100}
ENT.PHYS_OBJ_INFO[6] = {connectsto = 0, power=100}
ENT.PHYS_OBJ_INFO[7] = {connectsto = 6, power=100}
ENT.PHYS_OBJ_INFO[8] = {connectsto = 4, power=100}
ENT.PHYS_OBJ_INFO[9] = {connectsto = 0, power=100}
ENT.PHYS_OBJ_INFO[10] = {connectsto = 9, power=100}
ENT.PHYS_OBJ_INFO[11] = {connectsto = 10, power=1}
ENT.PHYS_OBJ_INFO[12] = {connectsto = 7, power=1}

ENT.CHEST = 1
ENT.HEAD = 5

ENT.TARGET_CHECK_INTERVAL = 3.0
ENT.TARGET_RADIUS = 192
ENT.TARGET_LOSE_RADIUS = 768
ENT.LOW_CPU_RADIUS = 1024




function ENT:Initialize()
	if SERVER then
	
		self.target = nil
		self.have_target = false
		self.target_next_check = 0
		
		self.lowCPUmode = false
		self.lowCPUmode_interval = 0.25
	
		self.ragdoll = ents.Create( "prop_ragdoll" )
		self.ragdoll:SetModel( "models/Humans/corpse1.mdl" )
		self.ragdoll:SetPos( self:GetPos() )
		self.ragdoll:SetAngles( self:GetAngles() )
		self.ragdoll:Spawn()
		self.ragdoll:Activate()
		
		self.last_decal = CurTime() + 10
		
		self.ragdoll.ent = self
		
		self.ragdoll:AddCallback( "PhysicsCollide", function( ent, data )
			if CurTime() >= ent.ent.last_decal then return end
			
			if isentity( data.HitEntity ) and data.HitEntity:IsWorld() then
				local normal = VectorRand()
			
				util.Decal(
					"Blood",
					data.HitPos + normal,
					data.HitPos - normal,
					ent
				)
			end
		end )
		
		self:SetParent( self.ragdoll )
		self:SetNoDraw( true )
		self:DrawShadow( false )
		
		local phys_count = self.ragdoll:GetPhysicsObjectCount()
		for i = 0, phys_count-1 do
			local physobj = self.ragdoll:GetPhysicsObjectNum( i )
			
			physobj:ApplyForceCenter( physobj:GetMass() * VectorRand() * Lerp(math.random(), 100, 200) )
			-- physobj:EnableGravity( false )
		end
		
	end
end




if SERVER then
	function ENT:OnRemove()
		SafeRemoveEntity( self.ragdoll )
	end




	function ENT:Think()
		local interval
		if self.lowCPUmode then
			interval = self.lowCPUmode_interval
		else
			interval = engine.TickInterval()
		end
		
		local t = CurTime()
		
		if t >= self.target_next_check then
			self.target_next_check = t + self.TARGET_CHECK_INTERVAL
			
			local no_one_here = true
			local ply_list = player.GetAll()
			
			util.ShuffleTable( ply_list )
			
			if self.have_target then
				if not IsValid(self.target) or self:GetPos():Distance( self.target:GetPos() ) > self.TARGET_LOSE_RADIUS or not self.ragdoll:Visible( self.target ) then
					self.target = nil
					self.have_target = false
				end
			end
			
			for i, ply in ipairs( ply_list ) do
				if no_one_here or not self.have_target then
					local dist = self:GetPos():Distance( ply:GetPos() )
					
					if no_one_here and dist < self.LOW_CPU_RADIUS then
						no_one_here = false
					end
					
					if not self.have_target and dist < self.TARGET_RADIUS and self.ragdoll:Visible( ply ) then
						self.target = ply
						self.have_target = true
						
						self:EmitSound( "npc/fast_zombie/idle"..tostring(math.random(3))..".wav" )
					end
				else
					break
				end
			end
			
			if no_one_here != self.lowCPUmode then
				self.lowCPUmode = no_one_here
			end
		end
		
		if (not self.lowCPUmode) and self.have_target then
			local phys_count = self.ragdoll:GetPhysicsObjectCount()
			for i = 0, phys_count-1 do
				local physobj_info = self.PHYS_OBJ_INFO[i]
				
				if isnumber( physobj_info.connectsto ) then
					local physobj = self.ragdoll:GetPhysicsObjectNum( i )
				
					local physobjconnectsto = self.ragdoll:GetPhysicsObjectNum( physobj_info.connectsto )
					
					local torque 
					
					if self.have_target and (i == self.HEAD or i == self.CHEST) then
						local dif = self.target:GetShootPos() - physobj:GetPos()
						dif:Normalize()
						local dif_ang = dif:Angle()
						
						local part_ang = physobj:GetAngles()
						if i == self.HEAD then
							part_ang:RotateAroundAxis(part_ang:Right(), -90)
							part_ang:RotateAroundAxis(part_ang:Up(), -90)
						else
							part_ang:RotateAroundAxis(part_ang:Right(), -90)
							part_ang:RotateAroundAxis(part_ang:Up(), 90)
						end
						part_ang.roll = 0
						
						local ang_dif = dif_ang - part_ang
						ang_dif:Normalize()
						
						torque = part_ang:Up() * (math.Clamp( ang_dif.yaw, -10, 10 )/10.0)
						torque = torque + part_ang:Right() * (math.Clamp( -ang_dif.pitch, -10, 10 )/10.0)
						
					else
					
						local speed = 0.25
						local persistance = 0.25
						local octaves = 1
					
						torque = Vector(
							util.PerlinNoise( t + (i*137), speed, persistance, octaves )*2-1,
							util.PerlinNoise( t + (i*137) + 372, speed, persistance, octaves )*2-1,
							util.PerlinNoise( t + (i*137) + 697, speed, persistance, octaves )*2-1
						)
	
					end
					
					if isvector( torque ) then
						torque = torque * interval * (physobj_info.power or 150) * physobj:GetMass()
					
						physobj:ApplyTorqueCenter( torque )
						physobjconnectsto:ApplyTorqueCenter( -torque )
					end
				end
			end
		end
		
		if self.lowCPUmode then
			self:NextThink( t+interval )
		else
			self:NextThink( t )
		end
		return true
	end
end