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
		
		self.is_on = false
		
		if self.start_state then
			self:SetState( self.start_state )
			self:DeriveIOFromState()
			self.start_state = nil
		end
		
		if self.start_is_on then
			self.is_on = start_is_on
			self.start_is_on = nil
		end
	end
end




if SERVER then

	function ENT:KeyValue(key, value)
		if key == "OnLowToHigh" or key == "OnHighToLow" then
			self:StoreOutput(key, value)
		elseif key == "state" then
			self.start_state = tonumber( value )
		elseif key == "is_on" then
			self.start_is_on = tobool( value )
		end
	end
	
	
	
	
	function ENT:Update()
		self:UpdateIOState()
		
		local new_input = self:GetInputX( 1 )
		
		if self.is_on != new_input then
			if not new_input then
				self:TriggerOutput("OnHighToLow", self)
			else
				self:TriggerOutput("OnLowToHigh", self)
			end
		end
		
		self.is_on = new_input
		self:SetInputX( 1, false )
	end
	
end




if CLIENT then
	
	function ENT:GetConnectionPos( a )
		return self:GetPos()
	end
	
	
	
	
	function ENT:Pickle( ent_list, cable_list )
		local data = {}
		
		data.is_on = self.is_on
		
		data.class = self:GetClass()
		data.pos = self:GetPos()
		data.angles = self:GetAngles()
		data.state = self:GetState()
		
		return util.TableToJSON( data )
	end
	
end