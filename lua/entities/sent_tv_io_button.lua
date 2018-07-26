AddCSLuaFile()

DEFINE_BASECLASS( "sent_tv_io_base" )

ENT.PrintName		= "IO: Button"
ENT.Author			= "raubana"
ENT.Information		= ""
ENT.Category		= "Tunnel Vision"

ENT.Editable		= true
ENT.Spawnable		= true
ENT.AdminOnly		= true
ENT.RenderGroup		= RENDERGROUP_OPAQUE

ENT.NumInputs 		= 1
ENT.NumOutputs 		= 2

ENT.InstantUpdate	= false




list.Add( "TV_IO_ents", "sent_tv_io_button" )




function ENT:Initialize()
	self:SetModel( "models/tunnelvision/io_models/io_default.mdl" )
	
	if SERVER then
		self:PhysicsInit(SOLID_VPHYSICS)
		self:GetPhysicsObject():EnableMotion(false)
		
		self:SetUseType( CONTINUOUS_USE )
		
		self:IOInit()
		
		self.is_on = false
		self.release_at = 0
		
		self:SetSkin( 0 )
		
		if self.start_state then
			self:SetState( self.start_state )
			self:DeriveIOFromState()
			self.start_state = nil
		end
	end
end




function ENT:GetInputPos( x )
	local pos = self:GetPos()
	pos = pos + (self:GetForward()*0.5) + (self:GetRight()*2)
	return pos
end




function ENT:GetOutputPos( x )
	local pos = self:GetPos()
	if x == 1 then
		pos = pos + (self:GetForward()*0.5) - (self:GetRight()*2) + (self:GetUp()*1)
	else
		pos = pos + (self:GetForward()*0.5) - (self:GetRight()*2) - (self:GetUp()*1)
	end
	return pos
end





if SERVER then

	function ENT:KeyValue(key, value)
		if key == "state" then
			self.start_state = tonumber( value )
		end
		
		-- don't worry about is_on; it's going to be false by default in any case.
	end
	
	
	

	function ENT:Use( activator, caller, useType, value )
		self.release_at = CurTime() + engine.TickInterval() * 2
		
		if not self.is_on then
			self.is_on = true
			self:SetSkin( 1 )
			self:EmitSound( "buttons/lightswitch2.wav", 65, 125 )
		end
			
		hook.Call( "TV_IO_MarkEntityToBeUpdated", nil, self )
	end
	
	
	
	
	function ENT:Update()
		self:UpdateInputs()
		self:StoreCopyOfOutputs()
		
		if not self.is_on then
			self:SetOutputX( 1, false )
			self:SetOutputX( 2, self:GetInputX( 1 ) )
		else
			self:SetOutputX( 1, self:GetInputX( 1 ) )
			self:SetOutputX( 2, false )
		end
		
		if self.is_on then
			if CurTime() >= self.release_at then
				self:SetSkin( 0 )
				self:EmitSound( "buttons/lightswitch2.wav", 65, 75 )
				self.is_on = false
			end
			hook.Call( "TV_IO_MarkEntityToBeUpdated", nil, self )
		end
		
		self:UpdateIOState()
		self:MarkChangedOutputs()
	end
	
end