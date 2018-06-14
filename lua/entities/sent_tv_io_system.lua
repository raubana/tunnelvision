AddCSLuaFile()

DEFINE_BASECLASS( "sent_tv_io_base" )

ENT.PrintName		= "IO: System"
ENT.Author			= "raubana"
ENT.Information		= ""
ENT.Category		= "Tunnel Vision"

ENT.Editable		= true
ENT.Spawnable		= true
ENT.AdminOnly		= true
ENT.RenderGroup		= RENDERGROUP_OPAQUE

ENT.NumInputs 		= 1
ENT.NumOutputs 		= 0




list.Add( "TV_IO_ents", "sent_tv_io_system" )




function ENT:Initialize()
	self:SetModel( "models/props_borealis/door_wheel001a.mdl" )
	
	if SERVER then
		self:PhysicsInit(SOLID_VPHYSICS)
		self:GetPhysicsObject():EnableMotion(false)
		
		self:IOInit()
		
		self.old_input = false
	end
end




if SERVER then

	function ENT:KeyValue(key, value)
		if key == "OnLowToHigh" or key == "OnHighToLow" then
			self:StoreOutput(key, value)
		end
	end
	
	
	
	
	function ENT:Update()
		self:UpdateIOState()
		
		local new_input = self:GetInputX( 1 )
		
		if self.old_input != new_input then
			if not new_input then
				self:TriggerOutput("OnHighToLow", self)
			else
				self:TriggerOutput("OnLowToHigh", self)
			end
		end
		
		self.old_input = new_input
		self:SetInputX( 1, false )
	end
	
end




if CLIENT then
	
	function ENT:GetConnectionPos( a )
		return self:GetPos()
	end
	
end