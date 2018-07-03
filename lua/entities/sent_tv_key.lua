AddCSLuaFile()

DEFINE_BASECLASS( "base_anim" )

ENT.PrintName		= "Tunnel Vision: Key"
ENT.Author			= "raubana"
ENT.Information		= ""
ENT.Category		= "Tunnel Vision"

ENT.Editable		= false
ENT.Spawnable		= true
ENT.AdminOnly		= true
ENT.RenderGroup		= RENDERGROUP_OPAQUE





function ENT:Initialize()
	self:SetModel("models/props_interiors/pot02a.mdl")
	
	if SERVER then
		self:PhysicsInit( SOLID_VPHYSICS )
		self:GetPhysicsObject():Wake()
		self:SetUseType( SIMPLE_USE )
	
		self.door = nil
		self.next_message = 0
	end
end




function ENT:ShowMessage( msg )
	if CurTime() > self.next_message then
		if self:IsPlayerHolding() then
			PrintMessage( HUD_PRINTTALK, msg )
			self.next_message = CurTime() + 5
		end
	end
end




function ENT:PhysicsCollide( colData, collider )
	if isentity(colData.HitEntity) and IsValid( colData.HitEntity ) then
		if self:IsPlayerHolding() then
			if colData.HitEntity == self.door then
				colData.HitEntity:Fire( "unlock" )
				SafeRemoveEntity(self)
				PrintMessage( HUD_PRINTTALK, "You use the key on this door and it unlocks." )
			else
				local class = colData.HitEntity:GetClass()
				
				if class == "func_rotating_door" or class == "func_door" or class == "prop_door_rotating" then
					self:ShowMessage( "You use the key on this door but it doesn't work." )
				end
			end
		end
	end
end




function ENT:Use( activator, caller, useType, value )
	if isentity( caller) and IsValid(caller) and caller:IsPlayer () then
		caller:PickupObject( self )
	end
end




function ENT:GravGunPickupAllowed( ply )
	return true
end