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

ENT.NumInputs 		= 2
ENT.NumOutputs 		= 1




list.Add( "TV_IO_ents", "sent_tv_io_capacitor" )




function ENT:Initialize()
	self:SetModel( "models/tunnelvision/io_models/io_default.mdl" )
	
	if SERVER then
		self:PhysicsInit(SOLID_VPHYSICS)
		self:GetPhysicsObject():EnableMotion(false)
		
		self.charge = 0
		
		self:IOInit()
		
		if self:GetThreshold() == 0 then
			self:SetThreshold( 60 )
		end
		
		if self:GetMaximum() == 0 then
			self:SetMaximum( 90 )
		end
		
		if self.start_state then
			self:SetState( self.start_state )
			self:DeriveIOFromState()
			self.start_state = nil
		end
		
		if self.start_charge then
			self.charge = self.start_charge
			self.start_charge = nil
		end
	end
end




function ENT:SetupDataTables()
	self:NetworkVar( "Int", 0, "State" )
	self:NetworkVar( "Int", 1, "Threshold", { KeyName = "threshold", Edit = { type = "Int", min = 1, max = 600 } } )
	self:NetworkVar( "Int", 2, "Maximum", { KeyName = "maximum", Edit = { type = "Int", min = 1, max = 600 } } )
end




function ENT:GetInputPos( x )
	local pos = self:GetPos()
	if x == 1 then
		pos = pos + (self:GetForward()*0.5) + (self:GetRight()*2) + (self:GetUp()*1)
	else
		pos = pos + (self:GetForward()*0.5) + (self:GetRight()*2) - (self:GetUp()*1)
	end
	return pos
end




function ENT:GetOutputPos( x )
	local pos = self:GetPos()
	pos = pos + (self:GetForward()*0.5) - (self:GetRight()*2)
	return pos
end




if SERVER then

	function ENT:KeyValue(key, value)
		if key == "state" then
			self.start_state = tonumber( value )
		elseif key == "charge" then
			self.start_charge = tonumber( value )
		elseif key == "threshold" then
			self:SetThreshold( tonumber( value ) )
		elseif key == "maximum" then
			self:SetMaximum( tonumber( value ) )
		end
	end
	
	
	
	
	function ENT:Update()
		self:UpdateInputs()
		self:StoreCopyOfOutputs()
	
		local in1 = self:GetInputX(1)
		local in2 = self:GetInputX(2)
		local charge = self.charge
		
		if in2 then
			charge = 0
		elseif in1 then
			charge = math.min( charge + 1, self:GetMaximum() )
		else
			charge = math.max( charge - 1, 0 )
		end
		
		self:SetOutputX(1, charge >= self:GetThreshold() )
		
		if self:GetOutputX( 1 ) then
			if in1 then
				charge = self:GetMaximum()
			end
		else
			if not in1 then
				charge = 0
			end
		end
		
		self.charge = charge
		
		-- I need to check if I'm in a stable state.
		-- As long as I'm not stable I'll need to keep updating.
		local is_stable = (in1 and self.charge >= self:GetMaximum()) or ((not in1) and self.charge <= 0 )
		if not is_stable then
			hook.Call( "TV_IO_MarkEntityToBeUpdated", nil, self )
		end
		
		self:UpdateIOState()
		self:MarkChangedOutputs()
	end
	
	
	
	
	function ENT:Pickle( ent_list, cable_list )
		local data = {}
		
		data.threshold = self:GetThreshold()
		data.maximum = self:GetMaximum()
		data.charge = self.charge
		
		data.class = self:GetClass()
		data.pos = self:GetPos()
		data.angles = self:GetAngles()
		data.state = self:GetState()
		
		return util.TableToJSON( data )
	end
	
	
	
	
	function ENT:UnPickle( data, ent_list )
		self:SetPos( data.pos )
		self:SetAngles( data.angles )
		self:SetState( data.state )
		self:DeriveIOFromState()
		
		self:SetThreshold( data.threshold )
		self:SetMaximum( data.maximum )
		self.charge = data.charge
	end
	
end