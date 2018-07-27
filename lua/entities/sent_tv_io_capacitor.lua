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
	self:SetModel( "models/tunnelvision/io_models/io_capacitor.mdl" )
	
	if SERVER then
		self:PhysicsInit(SOLID_VPHYSICS)
		self:GetPhysicsObject():EnableMotion(false)
		
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
			self:SetCharge( self.start_charge )
			self.start_charge = nil
		end
	end
end




function ENT:SetupDataTables()
	self:NetworkVar( "Int", 0, "State" )
	self:NetworkVar( "Int", 1, "Charge", { KeyName = "charge", Edit = { type = "Int", min = 0, max = 600 } } )
	self:NetworkVar( "Int", 2, "Threshold", { KeyName = "threshold", Edit = { type = "Int", min = 1, max = 600 } } )
	self:NetworkVar( "Int", 3, "Maximum", { KeyName = "maximum", Edit = { type = "Int", min = 1, max = 600 } } )
end




function ENT:GetInputPos( x )
	local pos = self:GetPos()
	if x == 1 then
		pos = pos + (self:GetForward() * 0.5) + (self:GetRight()*2) + (self:GetUp() * 1.75)
	else
		pos = pos + (self:GetForward() * 0.5) + (self:GetRight()*2) - (self:GetUp() * 1.75)
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
		local charge = self:GetCharge()
		
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
		
		self:SetCharge( charge )
		
		-- I need to check if I'm in a stable state.
		-- As long as I'm not stable I'll need to keep updating.
		local is_stable = (in1 and charge >= self:GetMaximum()) or ((not in1) and charge <= 0 )
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
		data.charge = self:GetCharge()
		
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
		self:SetCharge( data.charge )
	end
	
end




if CLIENT then
	local DEBUGMODE = GetConVar("tv_io_debug")
	local SCALE = 0.1
	local WIDTH = 2/SCALE
	local HEIGHT = 4.6/SCALE

	function ENT:Draw()
		if DEBUGMODE and DEBUGMODE:GetBool() then
			for x = 1, self.NumInputs do
				self:DrawConnection( self:GetInputPos(x), self:GetIOState( x ) )
			end
			
			for x = 1, self.NumOutputs do
				self:DrawConnection( self:GetOutputPos(x), self:GetIOState( self.NumInputs + x ) )
			end
		end
		
		self:DrawModel()
		
		local charge = self:GetCharge()
		local threshold = self:GetThreshold()
		local maximum = self:GetMaximum()
		
		local my_pos = self:GetPos()
		local my_ang = self:GetAngles()
		
		local new_ang = 1.0 * my_ang
		new_ang:RotateAroundAxis( new_ang:Right(), -90 )
		new_ang:RotateAroundAxis( new_ang:Up(), 90 )
		
		local offset = Vector( 1.1, -1, 2.3 )
		offset:Rotate( my_ang )
		
		cam.Start3D2D( my_pos + offset, new_ang, SCALE )
			surface.SetDrawColor( color_black )
			surface.DrawRect( 1, Lerp( charge/maximum, HEIGHT-1, 1 ), WIDTH-2-(WIDTH*0.33), 1 )
			local y = Lerp( threshold/maximum, HEIGHT-1, 1 )
			surface.DrawRect( WIDTH*0.66, 1, WIDTH*0.33-0, y )
		cam.End3D2D()
	end
end