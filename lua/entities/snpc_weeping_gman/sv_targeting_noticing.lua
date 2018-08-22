local DEBUG_TARGETING = GetConVar( "twg_debug_targeting" )
local SIGHT_DISABLED = GetConVar( "twg_sight_disabled" )
local DISABLE_SENSES_AND_STUFF = GetConVar( "twg_disable_senses_and_stuff" )




function ENT:TargetingNoticingInit()
	
end




function ENT:CanSeeFlashlight( ply )
	if SIGHT_DISABLED:GetBool() or DISABLE_SENSES_AND_STUFF:GetBool() then return false end

	if not ply:FlashlightIsOn() then return false end

	local ang = ply:EyeAngles()
	ang:RotateAroundAxis( ang:Forward(), math.random()*360 )
	ang:RotateAroundAxis( ang:Right(), math.random()*45 )
	
	local start = ply:GetShootPos()
	local endpos = start + ang:Forward() * 800
	
	local tr = util.TraceLine({
		start = start,
		endpos = endpos,
		filter = ply,
		mask = bit.bor( MASK_OPAQUE, CONTENTS_IGNORE_NODRAW_OPAQUE, CONTENTS_MONSTER )
	})
	
	if tr.Hit then
		can_see = self:CanSeeVector( tr.HitPos +  tr.HitNormal )
		if DEBUG_TARGETING:GetBool() and can_see then
			print( "I can see their flashlight..." )
			return true
		end
	end
	
	return false
end