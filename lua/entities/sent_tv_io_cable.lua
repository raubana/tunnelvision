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

ENT.InstantUpdate = true




list.Add( "TV_IO_ents", "sent_tv_io_cable" )




function ENT:Initialize()
	self:SetModel( "models/tunnelvision/io_models/io_default.mdl" )
	self:DrawShadow( false )
	self:SetCollisionGroup( COLLISION_GROUP_DEBRIS )
	
	if SERVER then
		if engine.ActiveGamemode() == "sandbox" then
			self:PhysicsInit(SOLID_VPHYSICS)
			self:GetPhysicsObject():EnableMotion(false)
		end
		
		self.old_high = self:GetHigh()
		
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
	self:NetworkVar("Int", 0, "InputID", { KeyName = "InputID", Edit = { type = "Int", min = 1, max = 10 } })
	self:NetworkVar("Entity", 1, "OutputEnt")
	self:NetworkVar("Int", 1, "OutputID", { KeyName = "OutputID", Edit = { type = "Int", min = 1, max = 10 } })
	self:NetworkVar("Bool", 0, "High")
end




function ENT:GetDistanceTo( vec )
	local start_ent = self:GetInputEnt()
	local end_ent = self:GetOutputEnt()
	if start_ent and IsValid( start_ent ) and end_ent and IsValid( end_ent ) then
		local dist, pos, frac = util.DistanceToLine(start_ent:GetOutputPos(self:GetInputID()), end_ent:GetInputPos(self:GetOutputID()), vec)
		return dist, pos, frac
	end
	return nil, nil, nil
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
	
	
	
	
	function ENT:ConnectInputTo( ent, do_not_update )
		self:SetInputEnt( ent )
		table.insert( ent.output_cables[self:GetInputID()], self )
		if not do_not_update then
			hook.Call( "TV_IO_MarkEntityToBeUpdated", nil, self )
			hook.Call( "TV_IO_MarkEntityToBeUpdated", nil, ent )
		end
	end
	
	
	
	
	function ENT:ConnectOutputTo( ent, do_not_update )
		self:SetOutputEnt( ent )
		table.insert( ent.input_cables[self:GetOutputID()], self )
		if not do_not_update then
			hook.Call( "TV_IO_MarkEntityToBeUpdated", nil, self )
			hook.Call( "TV_IO_MarkEntityToBeUpdated", nil, ent )
		end
	end
	
	
	
	
	function ENT:DisconnectInput( do_not_update_input, do_not_update_self )
		local old_ent = self:GetInputEnt()
		self:SetInputEnt( nil )
		if old_ent and IsValid(old_ent) then
			table.RemoveByValue( old_ent.output_cables[self:GetInputID()], self )
			if not do_not_update_input then 
				hook.Call( "TV_IO_MarkEntityToBeUpdated", nil, old_ent )
			end
		end
		if not do_not_update_self then
			hook.Call( "TV_IO_MarkEntityToBeUpdated", nil, self )
		end
	end
	
	
	
	
	function ENT:DisconnectOutput( do_not_update_output, do_not_update_self )
		local old_ent = self:GetOutputEnt()
		self:SetOutputEnt( nil )
		if old_ent and IsValid(old_ent) then
			table.RemoveByValue( old_ent.input_cables[self:GetOutputID()], self )
			if not do_not_update_output then
				hook.Call( "TV_IO_MarkEntityToBeUpdated", nil, old_ent )
			end
		end
		if not do_not_update_self then
			hook.Call( "TV_IO_MarkEntityToBeUpdated", nil, self )
		end
	end
	
	
	
	
	function ENT:OnRemove()
		self:DisconnectInput( false, true )
		self:DisconnectOutput( false, true )
	end
	
	
	
	
	function ENT:Update()
		self.old_high = self:GetHigh()
	
		local is_high = false
		
		local start_ent = self:GetInputEnt()
		if start_ent and IsValid( start_ent ) then
			is_high = start_ent:GetOutputX( self:GetInputID() )
		end
		
		if is_high != self.old_high then
			self:SetHigh( is_high )
			local ent_ent = self:GetOutputEnt()
			if ent_ent and IsValid( ent_ent ) then
				hook.Call( "TV_IO_MarkEntityToBeUpdated", nil, ent_ent )
			end
			self.old_high = is_high
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
		self:SetInputID( data.i_id )
		self:SetOutputID( data.o_id )
		if data.i_ent > 0 then
			self:ConnectInputTo( ent_list[data.i_ent] )
		end
		if data.o_ent > 0 then
			self:ConnectOutputTo( ent_list[data.o_ent] )
		end
	end
	
end




if CLIENT then
	
	local SEGMENT_MIN_LENGTH = 25
	

	function ENT:UpdateRenderBounds()
		local mins = self:GetPos() - (Vector(1,1,1)*10)
		local maxs = self:GetPos() + (Vector(1,1,1)*10)
		
		local start_ent = self:GetInputEnt()
		local end_ent = self:GetOutputEnt()
		
		if not start_ent or not IsValid( start_ent ) or not end_ent or not IsValid( end_ent ) then
			return
		end
		
		if start_ent and IsValid( start_ent ) then
			local ent_pos = start_ent:GetPos()
			mins = Vector(math.min(mins.x, ent_pos.x), math.min(mins.y, ent_pos.y), math.min(mins.z, ent_pos.z))
			maxs = Vector(math.max(maxs.x, ent_pos.x), math.max(maxs.y, ent_pos.y), math.max(maxs.z, ent_pos.z))
		end
		
		
		if end_ent and IsValid( end_ent ) then
			local ent_pos = end_ent:GetPos()
			mins = Vector(math.min(mins.x, ent_pos.x), math.min(mins.y, ent_pos.y), math.min(mins.z, ent_pos.z))
			maxs = Vector(math.max(maxs.x, ent_pos.x), math.max(maxs.y, ent_pos.y), math.max(maxs.z, ent_pos.z))
		end
		
		self:SetRenderBoundsWS( mins, maxs )
	end
	
	
	
	
	function ENT:Initialize()
		self.num_segments = 5
		self.nearby_players = {}
	
		self:SetRenderBoundsWS( Vector(1,1,1)*-1000000, Vector(1,1,1)*1000000 )
	end


	
	
	function ENT:Think()
		self:UpdateRenderBounds()
		
		local start_ent = self:GetInputEnt()
		local end_ent = self:GetOutputEnt()
		
		self.length = 1
		
		if start_ent and IsValid( start_ent ) and end_ent and IsValid( end_ent ) then
			local start_pos = start_ent:GetOutputPos(self:GetInputID())
			local end_pos = end_ent:GetInputPos(self:GetOutputID())
			local dist = start_pos:Distance( end_pos )
			
			self.length = dist
			self.num_segments = math.max( 2, math.ceil( dist / SEGMENT_MIN_LENGTH ) )
		end
		
		self.nearby_players = player.GetAll() -- meh
	
		self:SetNextClientThink( CurTime() + Lerp(math.random(), 3, 6) )
		return true
	end

	
	
	
	local beam_mat = Material( "cable/cable_lit" )
	local beam_debug_mat = Material( "cable/chain" )
	local DEBUGMODE = GetConVar("tv_io_debug")

	function ENT:Draw()
		local c = color_white
		if DEBUGMODE and DEBUGMODE:GetBool() then
			c = self.LOW_COLOR
			if self:GetHigh() then
				c = self.HIGH_COLOR
			end
			
			self:SetColor( c )
			--self:DrawModel()
		end
		
		local start_ent = self:GetInputEnt()
		local end_ent = self:GetOutputEnt()
		if start_ent and IsValid( start_ent ) and end_ent and IsValid( end_ent ) then
			local offset = 0
			if DEBUGMODE and DEBUGMODE:GetBool() then 
				offset = (RealTime()/15)%1.0
				render.SetMaterial(beam_debug_mat)
			else
				render.SetMaterial(beam_mat)
			end
			
			--render.DrawBeam(start_ent:GetOutputPos(self:GetInputID()), end_ent:GetInputPos(self:GetOutputID()), 0.5, 0-offset, 1-offset, c)
			
			local p, start_pos, end_pos, light, color, pos
			
			start_pos = start_ent:GetOutputPos(self:GetInputID())
			end_pos = end_ent:GetInputPos(self:GetOutputID())
			
			render.StartBeam( self.num_segments+1 )
			for i = 0, self.num_segments do
				local p = i/self.num_segments
				
				pos = LerpVector( p, start_pos, end_pos )
				
				light = render.GetLightColor( pos )
				
				for i, ply in ipairs( self.nearby_players ) do
					if ply:FlashlightIsOn() then
						local ply_pos = ply:GetShootPos()
						local dif = pos - ply_pos
						local dist = dif:Length()
						
						if dist < 800 then
							local ply_eye_normal = ply:GetAngles():Forward()
							local normal = dif / dist
							local dot = normal:Dot( ply_eye_normal )
							
							local intensity = math.invlerp( dot, 0.9, 1.0 )
							if intensity > 0 then
								intensity = intensity * (1-(dist/800))
								light = light + ( Vector( 1, 1, 1 ) * intensity * 0.25  )
							end
						end
					end
				end
		
				color = Color(
								math.min( c.r * light.x, 255 ),
								math.min( c.g * light.y, 255 ),
								math.min( c.b * light.z, 255 )
							)
				
				render.AddBeam( pos, 0.5, 0.25*i*(self.length / self.num_segments)-offset*5, color )
			end
			render.EndBeam()
		end
	end
	
end