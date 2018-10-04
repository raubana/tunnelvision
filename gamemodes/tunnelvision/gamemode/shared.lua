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
	if ply:Crouching() then
		speed = speed * 1.25
	end
	
	return math.floor( math.pow( 2, (speed-450)/66 ) )
end




local function randSign()
	return ((math.random(2)-1)*2)-1
end




-- The fall damage sound plays in this hook.
function GM:OnPlayerHitGround( ply, inWater, onFloater, speed)
	local dmg_amount = GAMEMODE:calcFallDamage( ply, speed )
	if inWater then
		dmg_amount = math.floor( dmg_amount / 10 )
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
	
		if dmg_amount < 10 then
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
	ply:PlayStepSound( Lerp( dmg_amount/100, 0.2, 1.0 ) )
	
	-- View Punch
	local ang = Angle( 
						5,
						randSign()*Lerp(math.random(),0.5,1)*1,
						randSign()*Lerp(math.random(),0.5,1)*1
					)
	
	if dmg_amount > 0 then
		ang.yaw = ang.yaw * 10
		ang.roll = ang.roll * 10
		ang = ang * Lerp(dmg_amount/100, 5.0, 25.0)
	end
	
	ply:ViewPunch( ang )
	
	return true
end