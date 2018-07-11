AddCSLuaFile()




DEFINE_BASECLASS( "sent_tv_io_base" )

ENT.PrintName		= "IO: Cable"
ENT.Author			= "raubana"
ENT.Information		= ""
ENT.Category		= "Tunnel Vision"

ENT.Editable		= true
ENT.Spawnable		= true
ENT.AdminOnly		= true
ENT.RenderGroup		= RENDERGROUP_OPAQUE

ENT.NumInputs 		= 1
ENT.NumOutputs 		= 1




list.Add( "TV_IO_ents", "sent_tv_io_cable" )




function ENT:Initialize()
	self:SetModel( "models/props_lab/huladoll.mdl" )
	self:SetCollisionGroup( COLLISION_GROUP_DEBRIS )
	
	if SERVER then
		self:PhysicsInit(SOLID_VPHYSICS)
		self:GetPhysicsObject():EnableMotion(false)
		
		if self:GetInputID() <= 0 then self:SetInputID( 1 ) end
		if self:GetOutputID() <= 0 then self:SetOutputID( 1 ) end
		
		if self.start_input_entity then
			local matches = ents.FindByName( self.start_input_entity )
			
			if #matches > 1 then
				print( "Warning:", self, "found multiple entities with the same name: ", self.start_input_entity )
			elseif #matches < 1 then
				print( "Warning:", self, "found no entities with this name: ", self.start_input_entity )
			else
				self:SetInputEnt( matches[1] )
			end
			
			self.start_input_entity = nil
		end
		
		if self.start_output_entity then
			local matches = ents.FindByName( self.start_output_entity )
			
			if #matches > 1 then
				print( "Warning:", self, "found multiple entities with the same name: ", self.start_output_entity )
			elseif #matches < 1 then
				print( "Warning:", self, "found no entities with this name: ", self.start_output_entity )
			else
				self:SetOutputEnt( matches[1] )
			end
			
			self.start_output_entity = nil
		end
	end
end




function ENT:SetupDataTables()
	self:NetworkVar("Entity", 0, "InputEnt")
	self:NetworkVar("Int", 0, "InputID", { KeyName = "InputID", Edit = { type = "Int", min = 1, max = 8 } })
	self:NetworkVar("Entity", 1, "OutputEnt")
	self:NetworkVar("Int", 1, "OutputID", { KeyName = "OutputID", Edit = { type = "Int", min = 1, max = 8 } })
	self:NetworkVar("Bool", 0, "High")
end




function ENT:GetDistanceTo( vec )
	local start_ent = self:GetInputEnt()
	local end_ent = self:GetOutputEnt()
	if start_ent and IsValid( start_ent ) and end_ent and IsValid( end_ent ) then
		local dist, pos, frac = util.DistanceToLine(start_ent:GetPos(), end_ent:GetPos(), vec) -- TODO: Use connection position?
		return dist, pos, frac
	end
	return nil
end





if SERVER then

	function ENT:KeyValue(key, value)
		if key == "InputID" then
			self:SetInputID( tonumber( value ) )
		elseif key == "OutputID" then
			self:SetOutputID( tonumber( value ) )
		elseif key == "InputEntity" then
			self.start_input_entity = value
		elseif key == "OutputEntity" then
			self.start_output_entity = value
		elseif key == "high" then
			self:SetHigh( tobool(value) )
		end
	end
	
	
	
	
	function ENT:UpdateI()
		local is_high = false
		
		local start_ent = self:GetInputEnt()
		if start_ent and IsValid( start_ent ) then
			is_high = start_ent:GetOutputX( self:GetInputID() )
		end
		
		self:SetHigh( is_high )
	end
	
	
	
	
	function ENT:UpdateO()
		if self:GetHigh() then
			local end_ent = self:GetOutputEnt()
			if end_ent and IsValid( end_ent ) then
				end_ent:SetInputX( self:GetOutputID(), true )
			end
		end
	end
	
	
	
	
	function ENT:Pickle( ent_list, cable_list )
		local data = {}
		
		data.i_ent = table.KeyFromValue( ent_list, self:GetInputEnt() ) or -1
		data.o_ent = table.KeyFromValue( ent_list, self:GetOutputEnt() ) or -1
		data.i_id = self:GetInputID()
		data.o_id = self:GetOutputID()
		
		data.class = self:GetClass()
		data.pos = self:GetPos()
		data.angles = self:GetAngles()
		data.high = self:GetHigh()
		
		return util.TableToJSON( data )
	end
	
	
	
	
	function ENT:UnPickle( data, ent_list )
		self:SetPos( data.pos )
		self:SetAngles( data.angles )
		self:SetHigh( data.high )
		self:SetInputEnt( ent_list[data.i_ent] )
		self:SetOutputEnt( ent_list[data.o_ent] )
		self:SetInputID( data.i_id )
		self:SetOutputID( data.o_id )
	end
	
end




if CLIENT then
	
	function ENT:Think()
		local mins = self:GetPos() - (Vector(1,1,1)*10)
		local maxs = self:GetPos() + (Vector(1,1,1)*10)
		
		local start_ent = self:GetInputEnt()
		if start_ent and IsValid( start_ent ) then
			local ent_pos = start_ent:GetPos()
			mins = Vector(math.min(mins.x, ent_pos.x), math.min(mins.y, ent_pos.y), math.min(mins.z, ent_pos.z))
			maxs = Vector(math.max(maxs.x, ent_pos.x), math.max(maxs.y, ent_pos.y), math.max(maxs.z, ent_pos.z))
		end
		
		local end_ent = self:GetOutputEnt()
		if end_ent and IsValid( end_ent ) then
			local ent_pos = end_ent:GetPos()
			mins = Vector(math.min(mins.x, ent_pos.x), math.min(mins.y, ent_pos.y), math.min(mins.z, ent_pos.z))
			maxs = Vector(math.max(maxs.x, ent_pos.x), math.max(maxs.y, ent_pos.y), math.max(maxs.z, ent_pos.z))
		end
		
		self:SetRenderBoundsWS( mins, maxs )
	
		self:SetNextClientThink( CurTime() + 10 )
		return true
	end

	
	
	
	local beam_mat = Material( "cable/cable" )
	local beam_debug_mat = Material( "cable/rope" )
	local DEBUGMODE = GetConVar("tv_io_debug")

	function ENT:Draw()
		local c = color_white
		if DEBUGMODE:GetBool() then
			c = self.LOW_COLOR
			if self:GetHigh() then
				c = self.HIGH_COLOR
			end
			
			self:SetColor( c )
			self:DrawModel()
		end
		
		local start_ent = self:GetInputEnt()
		local end_ent = self:GetOutputEnt()
		if start_ent and IsValid( start_ent ) and end_ent and IsValid( end_ent ) then
			local offset = 0
			if DEBUGMODE:GetBool() then 
				offset = (RealTime()/5)%1.0
				render.SetMaterial(beam_debug_mat)
			else
				render.SetMaterial(beam_mat)
			end
			
			render.DrawBeam(start_ent:GetOutputPos(self:GetInputID()), end_ent:GetInputPos(self:GetOutputID()), 0.5, 0-offset, 1-offset, c)
		end
	end
	
end