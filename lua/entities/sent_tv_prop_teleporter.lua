AddCSLuaFile()

DEFINE_BASECLASS( "base_anim" )

ENT.PrintName		= "TV: Prop Teleporter"
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
		self.prop_name = nil
		self.target_name = nil
	
		if self.start_prop_name then
			self.prop_name = self.start_prop_name
			self.start_prop_name = nil
		end
		
		if self.start_target_name then
			self.target_name = self.start_target_name
			self.start_prop_name = nil
		end
	end
	
end




if SERVER then
	
	function ENT:KeyValue(key, value)
		if key == "prop_name" then
			self.start_prop_name = value
		elseif key == "target_name" then
			self.start_target_name = value
		end
	end
	
	
	
	
	function ENT:TeleportProps()
		local props = ents.FindByName(self.prop_name)
		local targets = ents.FindByName(self.target_name)
		
		while math.min( #props, #targets ) > 0 do
			local prop = table.remove( props, math.random(#props) )
			local target = table.remove( targets, math.random(#targets) )
			
			prop:SetPos( target:GetPos() )
			prop:SetAngles( target:GetAngles() )
			
			local physobj = prop:GetPhysicsObject()
			if IsValid( physobj ) then
				physobj:Wake()
			end
		end
	end
	
	
	
	
	function ENT:AcceptInput( name, activator, caller, data )
		if name == "TeleportProps" then
			self:TeleportProps()
		end
	end
	
end