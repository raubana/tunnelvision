AddCSLuaFile()




local DEBUG_MODE = CreateConVar("tv_voltagetester_debug", "0", bit.bor( FCVAR_SERVER_CAN_EXECUTE, FCVAR_NOTIFY, FCVAR_CHEAT ) )




SWEP.Base = "weapon_base"

SWEP.PrintName 				= "Voltage Tester"
SWEP.Category				= "Tunnel Vision"
SWEP.Purpose				= ""
SWEP.Instructions			= ""
SWEP.Spawnable				= true
SWEP.AdminSpawnable			= true

if CLIENT then
	SWEP.BounceWeaponIcon	= false
	SWEP.WepSelectIcon		= surface.GetTextureID( "" )
end

SWEP.Slot 					= 1
SWEP.SlotPos				= 0

SWEP.ViewModelFOV			= 62
SWEP.ViewModelFlip			= false
SWEP.ViewModel				= "models/weapons/v_slam.mdl"
SWEP.WorldModel				= "models/tunnelvision/weapons/tester.mdl"
SWEP.HoldType				= "pistol"
SWEP.UseHands				= true
SWEP.DrawCrosshair 			= false

SWEP.DeploySpeed 			= 5.0

SWEP.Primary.Delay 			= 1/30
SWEP.Primary.ClipSize		= -1
SWEP.Primary.DefaultClip	= -1
SWEP.Primary.Automatic		= true
SWEP.Primary.Ammo			= "none"

SWEP.Secondary.ClipSize		= -1
SWEP.Secondary.DefaultClip	= -1
SWEP.Secondary.Automatic	= false
SWEP.Secondary.Ammo			= "none"

SWEP.DrawAmmo				= false


SWEP.SensingDistance = 2.0



function SWEP:Initialize()
	self:SetDeploySpeed(self.DeploySpeed)

	if self.SetHoldType then
		self:SetHoldType(self.HoldType)
	end
	
	self.last_tested = 0
end




function SWEP:GetTestPos()
	local tr = util.TraceLine( {
		start = self.Owner:GetShootPos(),
		endpos = self.Owner:GetShootPos() + self.Owner:GetAngles():Forward() * 70,
		filter = self.Owner
	} )
	
	if not tr.Hit then return nil end

	return tr.HitPos
end




local COLOR_RED = Color(255,0,0)
local COLOR_YELLOW = Color(255,255,0)
local COLOR_GREEN = Color(0,255,0)

function SWEP:TestForVoltage()
	local test_pos = self:GetTestPos()
	
	if not test_pos then return false end
	
	-- debugoverlay.Cross( test_pos, 1, 1, true )

	local min_high_dist = self.SensingDistance
	local min_high_pos = nil
	local ent_list = ents.FindInPVS(self.Owner)
	
	for i, ent in ipairs(ent_list) do
		if IsValid(ent) then
			local class = ent:GetClass()
			if list.Contains( "TV_IO_ents", class ) then
				local dist, pos
				
				if class == "sent_tv_io_cable" then
					if ent:GetHigh() then
						dist, pos = ent:GetDistanceTo( test_pos )
						dist = dist - 2
					end
				else
					if ent:GetState() > 0 then
						pos = ent:GetPos()
						dist = pos:Distance( test_pos ) - (ent:BoundingRadius()*0.5)
					end
				end
				
				if dist != nil then
					local c = COLOR_RED
				
					if dist < self.SensingDistance then
						c = COLOR_YELLOW
					
						min_high_dist = math.min( min_high_dist, dist )
						min_high_pos = pos
						if min_high_dist <= 0 then
							break
						end
					end
					
					if DEBUG_MODE:GetBool() then
						debugoverlay.Line( test_pos, pos, 0.1, c, true )
					end
				end
			end
		end
	end
	
	min_high_dist = math.max( min_high_dist, 0 )
	
	if min_high_dist < self.SensingDistance then
		if DEBUG_MODE:GetBool() then
			debugoverlay.Line( test_pos, min_high_pos, 0.1, COLOR_GREEN, true )
		end
	
		local p = 1 - ( min_high_dist / self.SensingDistance  )
		p = p * p * p
		return math.random() <= p
	end
	
	return false
end




function SWEP:PrimaryAttack()
	if not self:CanPrimaryAttack() then return end
	
	if CurTime() - self.last_tested > 0.25 then
		self:EmitSound( "player/geiger1.wav", 35, 150, 1, CHAN_WEAPON )
	end
	
	self.last_tested = CurTime()
	
	self:SetNextSecondaryFire( CurTime() + self.Primary.Delay )
	self:SetNextPrimaryFire( CurTime() + self.Primary.Delay )
	
	if SERVER then
		if self:TestForVoltage() then
			self:EmitSound( "player/geiger1.wav", 35, 200, 1, CHAN_WEAPON )
		end
	end
end




function SWEP:CanPrimaryAttack()
   if not IsValid(self.Owner) then return end
   
   return true
end




function SWEP:SecondaryAttack()
	if not self:CanSecondaryAttack() then return end
	
end




function SWEP:CanSecondaryAttack()
   if not IsValid(self.Owner) then return end
   
   return true
end




function SWEP:DoDrawCrosshair( x, y )
	local test_pos = self:GetTestPos()
	
	if test_pos then
		local data = test_pos:ToScreen()
		
		surface.SetDrawColor( color_white )
		surface.DrawRect( data.x-3, data.y-3, 6, 6 )
		surface.SetDrawColor( color_black )
		surface.DrawOutlinedRect( data.x-4, data.y-4, 8, 8 )
	end
	
	return true
end

// TODO: Add flashing sprite on the model.