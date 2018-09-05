local EASE_THRESHOLD = 90.0
local EASE_RATE = 0.975
local EASE_TIMESCALE_MULT = 1
local SPEED = 300 -- TODO: Calculate this value using the above values.


local function angle_dif_abs(a, b)
	return math.min((a-b)%360, (b-a)%360)
end


local function ang_dist(angle1, angle2)
	local x = angle_dif_abs(angle1.pitch, angle2.pitch)
	local y = angle_dif_abs(angle1.yaw, angle2.yaw)
	return math.sqrt(math.pow(x,2) + math.pow(y,2))
end


local function overlerp(p,a,b)
	return a+(b-a)*p
end


local function lerpPitch(p, ang1, ang2)
	//ang1 = (ang1+180)%360-180
	//ang2 = (ang2+180)%360-180
	return overlerp(p, ang1, ang2)
end


local function lerpYaw(p, ang1, ang2)
	ang1 = (ang1+180)%360
	ang2 = (ang2+180)%360
	if ang2 > ang1 + 180 then
		ang2 = ang2 - 360
	elseif ang2 < ang1 - 180 then
		ang2 = ang2 + 360
	end
	return overlerp(p, ang1, ang2)-180
end


hook.Add( "StartCommand", "TV_StartCommand_PlayerAngVelClamp", function(ply, ucmd)
	if GetGlobalBool( "tv_retain_normal_speeds", false) then return end

	local current_angle = ply:EyeAngles()

	local t = RealFrameTime()
	
	if not isangle(ply.target_view_angle) then
		ply.target_view_angle = current_angle
	end
	if not isangle(ply.prev_view_angle) then
		ply.prev_view_angle = current_angle
	end
	
	local pitch_delta = current_angle.pitch - ply.prev_view_angle.pitch
	local yaw_delta = current_angle.yaw - ply.prev_view_angle.yaw
	
	if math.abs(yaw_delta) > 180 then
		-- we assume we crossed the 180/-180 threshold.
		if current_angle.yaw < 0 then
			yaw_delta = (current_angle.yaw + 360) - ply.prev_view_angle.yaw
		else
			yaw_delta = current_angle.yaw - (ply.prev_view_angle.yaw+360)
		end
	end
	
	ply.target_view_angle = Angle(
		math.Clamp( ply.target_view_angle.pitch + pitch_delta, -89, 89 ),
		ply.target_view_angle.yaw + yaw_delta,
		0
	)
	
	local travel_dist = SPEED * EASE_TIMESCALE_MULT * t * game.GetTimeScale()
	
	local dist = ang_dist(ply.target_view_angle, ply.prev_view_angle)
	
	local new_angle
	local p
	--print("START", dist)
	if dist-travel_dist <= EASE_THRESHOLD then
		--print("A")
		if dist > EASE_THRESHOLD then
			--print("A2")
			-- we find out at what time the transition would have changed from
			-- linear to easing.
			local time_to_trans = (dist-EASE_THRESHOLD)/SPEED
			t = t - time_to_trans
			p = (EASE_THRESHOLD-dist)/(-dist)
			ply.prev_view_angle = Angle(
				lerpPitch(p, ply.prev_view_angle.pitch, ply.target_view_angle.pitch),
				lerpYaw(p, ply.prev_view_angle.yaw, ply.target_view_angle.yaw),
				0
			)
		end
		p = 1-math.pow(1-EASE_RATE,t * EASE_TIMESCALE_MULT * game.GetTimeScale())
	else
		--print("B")
		if travel_dist > dist then
			--print("B1")
			p = 1.0
		else
			--print("B2")
			p = travel_dist/dist
		end
	end
	--print("END", p)
	
	
	if isnumber(p) then
		new_angle = Angle(
			lerpPitch(p, ply.prev_view_angle.pitch, ply.target_view_angle.pitch),
			lerpYaw(p, ply.prev_view_angle.yaw, ply.target_view_angle.yaw),
			0
		)
		
		ply:SetEyeAngles(new_angle)
		ply.prev_view_angle = new_angle
		
		GRAPHING_DEBUG_TOOL_VALUE = new_angle.yaw%360/360
		
		ucmd:SetViewAngles(new_angle)
	end
end )


print("player_angvel_clamp cl_init")