AddCSLuaFile()

DEFINE_BASECLASS( "sent_tv_io_base" )

ENT.PrintName		= "IO: Capacitor"
ENT.Author			= "raubana"
ENT.Information		= ""
ENT.Category		= "Tunnel Vision"

ENT.Editable		= true
ENT.Spawnable		= true
ENT.AdminOnly		= true
ENT.RenderGroup		= RENDERGROUP_OPAQUE

ENT.NumInputs 		= 1
ENT.NumOutputs 		= 1




list.Add( "TV_IO_ents", "sent_tv_io_capacitor" )




function ENT:Initialize()
	self:SetModel( "models/props_borealis/door_wheel001a.mdl" )
	
	if SERVER then
		self:PhysicsInit(SOLID_VPHYSICS)
		self:GetPhysicsObject():EnableMotion(false)
		
		self.charge = 0
		
		self:IOInit()
		
		if self:GetThreshold() == 0 then
			self:GetThreshold( 60 )
		end
		
		if self:GetMaximum() == 0 then
			self:SetMaximum( 90 )
		end
	end
end




function ENT:SetupDataTables()
	self:NetworkVar( "Int", 0, "State" )
	self:NetworkVar( "Int", 1, "Threshold", { KeyName = "threshold", Edit = { type = "Int", min = 1, max = 600 } } )
	self:NetworkVar( "Int", 2, "Maximum", { KeyName = "maximum", Edit = { type = "Int", min = 1, max = 600 } } )
end




if SERVER then
	
	function ENT:Update()
		local in1 = self:GetInputX(1)
		local charge = self.charge
		
		if in1 then
			charge = math.min( charge + 1, self:GetMaximum() )
		else
			charge = math.max( charge - 1, 0 )
		end
		self.charge = charge
		
		self:SetOutputX(1, charge >= self:GetThreshold() )
		self:UpdateIOState()
		self:SetInputX( 1, false )
	end
	
end