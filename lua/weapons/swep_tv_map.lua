AddCSLuaFile()




SWEP.Base = "weapon_base"

SWEP.PrintName 				= "Map"
SWEP.Category				= "Tunnel Vision"
SWEP.Purpose				= ""
SWEP.Instructions			= ""
SWEP.Spawnable				= true
SWEP.AdminSpawnable			= true

if CLIENT then
	SWEP.BounceWeaponIcon	= false
	SWEP.WepSelectIcon		= surface.GetTextureID( "" )
end

SWEP.Slot 					= 0
SWEP.SlotPos				= 0

SWEP.ViewModelFOV			= 62
SWEP.ViewModelFlip			= false
SWEP.ViewModel				= "models/weapons/v_slam.mdl"
SWEP.WorldModel				= "models/alyx_emptool_prop.mdl"
SWEP.HoldType				= "duel"
SWEP.UseHands				= true
SWEP.DrawCrosshair			= false

SWEP.Primary.Delay 			= 0
SWEP.Primary.ClipSize		= -1
SWEP.Primary.DefaultClip	= -1
SWEP.Primary.Automatic		= true
SWEP.Primary.Ammo			= "none"

SWEP.Secondary.Delay 		= 0
SWEP.Secondary.ClipSize		= -1
SWEP.Secondary.DefaultClip	= -1
SWEP.Secondary.Automatic	= true
SWEP.Secondary.Ammo			= "none"

SWEP.DrawAmmo				= false




function SWEP:Initialize()
	
	if self.SetHoldType then
		self:SetHoldType(self.HoldType)
	end


	if CLIENT then
		local map_name = game.GetMap()
		self.map_material = Material( "tunnelvision/maps/"..map_name )
	end
end




function SWEP:PrimaryAttack()
end


function SWEP:CanPrimaryAttack()
end


function SWEP:SecondaryAttack()
end


function SWEP:CanSecondaryAttack()
end




function SWEP:DrawHUD()
	local localplayer = LocalPlayer()
	
	if not IsValid( localplayer ) then return end

	local scrw = ScrW()
	local scrh = ScrH()
	
	local min = math.min( scrw, scrh )
	
	local size = min * 0.4
	
	local color = color_white
	
	if self.Owner and IsValid( self.Owner ) and not self.Owner:FlashlightIsOn() then
		local light = render.ComputeLighting( self:GetPos(), vector_up ) * 255 * 5
			
		color = Color(
								math.min( light.x, 255),
								math.min( light.y, 255),
								math.min( light.z, 255)
							)
	end
	
	surface.SetMaterial( self.map_material )
	surface.SetDrawColor( color )
	surface.DrawTexturedRect( Lerp(0.9, (scrw-size)/2, scrw-size), Lerp(0.75, (scrh-size)/2, scrh-size), size, size )
end