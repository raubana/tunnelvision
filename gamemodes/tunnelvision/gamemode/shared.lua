print( "shared" )

AddCSLuaFile()

include( "sh_sound_precacher.lua" )

GM.Name				= "Tunnel Vision"
GM.Author			= "raubana"
GM.FOV				= 70




function GM:StartCommand( ply, ucmd )
	ucmd:RemoveKey(IN_ZOOM)
	ucmd:RemoveKey(IN_WALK)
	
	if ucmd:GetForwardMove() < 0 or 
	math.abs( ucmd:GetSideMove() ) > math.abs( ucmd:GetForwardMove() )
	then
		ucmd:RemoveKey(IN_SPEED)
	end
	
end




local listening_ents = {}
if SERVER then
	hook.Add( "PreventEntityEmitSoundHookForHearingEntity", "TV_PreventEntityEmitSoundHookForHearingEntity", function( ent )
		table.insert( listening_ents, ent )
		return true
	end )
end




function GM:EntityEmitSound( data )
	if data.SoundName == "items/flashlight1.wav" then
		return false
	end
	
	if SERVER then
		for i, ent in ipairs(listening_ents) do
			ent:HearSound( data )
		end
		
		listening_ents = {}
		
		return true
	end
end




function GM:calcFallDamage( ply, speed )
	return math.ceil( 0.23*speed - 120 )
end




local function randSign()
	return ((math.random(2)-1)*2)-1
end




-- The fall damage sound plays in this hook.
function GM:OnPlayerHitGround( ply, inWater, onFloater, speed)
	local dmg_amount = 0
	if not inWater then
		dmg_amount = GAMEMODE:calcFallDamage( ply, speed )
	end
	
	-- Damage and Pain Sound
	if dmg_amount > 0 then
		local dmg = DamageInfo()
		dmg:SetDamageType(DMG_FALL)
		dmg:SetDamage(dmg_amount)
		dmg:SetInflictor(game.GetWorld())
		dmg:SetAttacker(game.GetWorld())
		ply:TakeDamageInfo(dmg)
		
		local s
	
		if dmg_amount < 20 then
			s = "player/pl_pain"..tostring(math.random(5,7))..".wav"
		else
			if SERVER then
				net.Start( "TV_OnPain" )
				net.WriteInt( DMG_FALL, 32 )
				net.WriteBool( false )
				net.Send( ply )
			--elseif CLIENT then
			--	GAMEMODE:DoPainEffect( true, false )
			end
		
			if math.random() < 0.5 then
				s = "player/pl_fallpain1.wav"
			else
				s = "player/pl_fallpain3.wav"
			end
		end
		
		ply:EmitSound( s )
	end
	
	-- Landing Sound
	if not inWater then
		local min = -100
		local max = -20
		local p = math.Clamp( (dmg_amount-min)/(max-min), 0, 1 )
	
		ply:PlayStepSound( Lerp( p, 0.2, 1.0 ) )
	end
	
	-- View Punch
	if not inWater then
		local min = -50
		local max = 50
		local p = math.Clamp( (dmg_amount-min)/(max-min), 0, 1 )
		p = p * p
		
		local ang = Angle( 
								360,
								randSign()*Lerp(math.random(),0.75,1)*30,
								randSign()*Lerp(math.random(),0.75,1)*90 
							)
		
		ply:ViewPunch( Lerp(p, 0.01, 1.0) * ang )
	end
	
	return true
end