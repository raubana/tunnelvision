AddCSLuaFile()

DEFINE_BASECLASS( "sent_tv_io_base" )

ENT.PrintName		= "IO: Relay"
ENT.Author			= "raubana"
ENT.Information		= ""
ENT.Category		= "Tunnel Vision"

ENT.Editable		= true
ENT.Spawnable		= true
ENT.AdminOnly		= true
ENT.RenderGroup		= RENDERGROUP_OPAQUE

ENT.NumInputs 		= 2
ENT.NumOutputs 		= 2




list.Add( "TV_IO_ents", "sent_tv_io_relay" )




function ENT:Initialize()
	self:SetModel( "models/tunnelvision/io_models/io_relay.mdl" )
	
	if SERVER then
		self:PhysicsInit(SOLID_VPHYSICS)
		self:GetPhysicsObject():EnableMotion(false)
		
		self:IOInit()
		
		self.is_on = false
		
		self:SetSkin( 0 )
	end
end




function ENT:GetInputPos( x )
	local pos = self:GetPos()
	if x == 1 then
		pos = pos + (self:GetForward() * 0.5) + (self:GetRight()*1.75) + (self:GetUp() * 1.75)
	else
		pos = pos + (self:GetForward() * 0.5) + (self:GetRight()*1.75) - (self:GetUp() * 1.75)
	end
	return pos
end




function ENT:GetOutputPos( x )
	local pos = self:GetPos()
	if x == 1 then
		pos = pos + (self:GetForward() * 0.5) - (self:GetRight()*1.75) + (self:GetUp() * 1.75)
	else
		pos = pos + (self:GetForward() * 0.5) - (self:GetRight()*1.75) - (self:GetUp() * 1.75)
	end
	return pos
end




if SERVER then
	
	function ENT:Update()
		local old_is_on = self.is_on
		local new_is_on = self:GetInputX(2)
		
		if old_is_on != new_is_on then
			self.is_on = new_is_on
			
			if new_is_on then
				self:EmitSound( "buttons/lightswitch2.wav", 75, 175 )
				filter = RecipientFilter()
				filter:AddAllPlayers()
				self.sound_loop = CreateSound(
					self,
					"ambient/atmosphere/laundry_amb.wav",
					filter
				)
				self.sound_loop:SetSoundLevel( 65 )
				self.sound_loop:PlayEx(0.1, 255)
				
				self:SetSkin( 1 )
			else
				self:EmitSound( "buttons/lightswitch2.wav", 75, 125 )
				if self.sound_loop then
					self.sound_loop:Stop()
				end
				
				self:SetSkin( 0 )
			end
		end
	
		if not self:GetInputX( 2 ) then
			self:SetOutputX( 1, false )
			self:SetOutputX( 2, self:GetInputX( 1 ) )
		else
			self:SetOutputX( 1, self:GetInputX( 1 ) )
			self:SetOutputX( 2, false )
		end
		
		self:UpdateIOState()
		
		self:SetInputX( 1, false )
		self:SetInputX( 2, false )
	end
	
end