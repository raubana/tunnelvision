AddCSLuaFile()




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
SWEP.WorldModel				= "models/weapons/w_slam.mdl"
SWEP.HoldType				= "slam"
SWEP.UseHands				= true
SWEP.DrawCrosshair			= false

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


SWEP.SensingDistance = 10



function SWEP:Initialize()
	self:SetDeploySpeed(self.DeploySpeed)

	if self.SetHoldType then
		self:SetHoldType(self.HoldType)
	end
end




function SWEP:Deploy()
	self:SendWeaponAnim(ACT_SLAM_DETONATOR_DRAW)
end




function SWEP:TestForVoltage()
	local tr = util.TraceLine( {
		start = self.Owner:GetShootPos(),
		endpos = self.Owner:GetShootPos() + self.Owner:GetAngles():Forward() * 30,
		filter = self.Owner
	} )

	local test_pos = tr.HitPos
	
	-- debugoverlay.Cross( test_pos, 1, 1, true )

	local min_high_dist = self.SensingDistance
	local ent_list = ents.FindInPVS(self.Owner)
	
	for i, ent in ipairs(ent_list) do
		if IsValid(ent) then
			local class = ent:GetClass()
			if list.Contains( "TV_IO_ents", class ) then
				local dist = nil
				
				if class == "sent_tv_io_cable" then
					if ent:GetHigh() then
						dist = ent:GetDistanceTo( test_pos ) - 5
					end
				else
					if ent:GetState() > 0 then
						dist = ent:GetPos():Distance( test_pos ) - ent:BoundingRadius()
					end
				end
				
				if dist != nil and dist < self.SensingDistance then
					min_high_dist =  math.min( min_high_dist, dist )
					if min_high_dist <= 0 then
						break
					end
				end
			end
		end
	end
	
	min_high_dist = math.max( min_high_dist, 0 )
	
	if min_high_dist < self.SensingDistance then
		local p = 1 - ( min_high_dist / self.SensingDistance  )
		p = p * p * p
		return math.random() <= p
	end
	
	return false
end




function SWEP:PrimaryAttack()
	if not self:CanPrimaryAttack() then return end
	
	self:SetNextSecondaryFire( CurTime() + self.Primary.Delay )
	self:SetNextPrimaryFire( CurTime() + self.Primary.Delay )
	
	if self:TestForVoltage() then
		self:EmitSound( "player/geiger1.wav", 65, 255, 1, CHAN_WEAPON )
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