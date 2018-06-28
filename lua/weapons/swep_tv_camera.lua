AddCSLuaFile()




SWEP.Base = "weapon_base"

SWEP.PrintName 				= "Video Camera"
SWEP.Category				= "Tunnel Vision"
SWEP.Purpose				= ""
SWEP.Instructions			= ""
SWEP.Spawnable				= true
SWEP.AdminSpawnable			= true

if CLIENT then
	SWEP.BounceWeaponIcon	= false
	SWEP.WepSelectIcon		= surface.GetTextureID( "attack_of_the_mimics/vgui/wep_icons/walkietalkie" )
end

SWEP.Slot 					= 1
SWEP.SlotPos				= 0

SWEP.ViewModelFOV			= 62
SWEP.ViewModelFlip			= false
SWEP.ViewModel				= "models/weapons/v_slam.mdl"
SWEP.WorldModel				= "models/weapons/w_slam.mdl"
SWEP.HoldType				= "camera"
SWEP.UseHands				= true
SWEP.DrawCrosshair			= true

SWEP.DeploySpeed 			= 5.0

SWEP.Primary.Delay 			= 0
SWEP.Primary.ClipSize		= 1
SWEP.Primary.DefaultClip	= 1
SWEP.Primary.Automatic		= true
SWEP.Primary.Ammo			= "slam"

SWEP.Secondary.Delay 		= 0
SWEP.Secondary.ClipSize		= -1
SWEP.Secondary.DefaultClip	= -1
SWEP.Secondary.Automatic	= true
SWEP.Secondary.Ammo			= "slam"

SWEP.DrawAmmo				= false

SWEP.MinFOV = 5
SWEP.MaxFOV = 50
SWEP.FOVChangeRate = 25



function SWEP:Initialize()
	if SERVER then
		self.fov = self.MinFOV
	end
end




function SWEP:Think()
	if SERVER then
		self.Owner:SetFOV( self.fov, engine.TickInterval()/3 )
	end
end




function SWEP:PrimaryAttack()
	if not IsFirstTimePredicted() then return end
	if not self:CanPrimaryAttack() then return end
	
	print( "primary" )
	
	self:SetNextSecondaryFire( CurTime() )
	self:SetNextPrimaryFire( CurTime() )
	
	if SERVER then
		self.fov = math.max( self.MinFOV, self.fov - ( engine.TickInterval() * self.FOVChangeRate ) )
	end
end




function SWEP:CanPrimaryAttack()
   if not IsValid(self.Owner) then return end
   return true
end




function SWEP:SecondaryAttack()
	if not IsFirstTimePredicted() then return end
	if not self:CanSecondaryAttack() then return end

	print( "secondary" )
	
	self:SetNextSecondaryFire( CurTime() )
	self:SetNextPrimaryFire( CurTime() )
	
	if SERVER then
		self.fov = math.min( self.MaxFOV, self.fov + ( engine.TickInterval() * self.FOVChangeRate ) )
	end
end




function SWEP:CanSecondaryAttack()
   if not IsValid(self.Owner) then return end
   return true
end




function SWEP:PreDrawViewModel( vm, ply, wep )
	return true
end