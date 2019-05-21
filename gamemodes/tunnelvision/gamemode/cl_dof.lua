local DOF_ENABLED = CreateConVar("tv_dof", "1", bit.bor( FCVAR_ARCHIVE ))


-- NOTE: DOF SYSTEM NEEDS TO BE REWORKED:
-- BLUR-LEVEL CHANGES WHEN QUALITY IS TWEAKED.


local QUALITY = 1.0

local function SourceUnit2Inches( x )
	return x * 0.75
end

local function Inches2SourceUnits( x )
	return x / 0.75
end

local DOF_LENGTH = 256--512
local DOF_LAYERS = math.ceil((ScrH()*QUALITY)/50)

local MAX_FOCAL_LENGTH = math.pow( 2, 8.5 ) --1024*2

local focal_length = focal_length or 128
local FOCAL_LENGTH_RATE = 0.25 -- speed
local next_focal_length = next_focal_length or 128
local next_trace = 0

local QUAD_WIDTH = 100000
local QUAD_HEIGHT = 100000

local color_mask_1 = Color(0,0,0,0)
local color_mask_2 = Color(0,0,0,0)

local blurMat = Material( "pp/videoscale" )
local bokehBlurMat = Material( "pp/bokehblur" )
local debugMat = Material( "attack_of_the_mimics/debug/dof_test_image" )

local USE_SPHERES = true
local DOF_DEBUG = false
local DOF_DEBUG_FORCE_FOCAL_LENGTH = 0 -- set to 0 to disable


local sprite_size = 96
local real_sprite_size = Inches2SourceUnits(2)
local dist_increase_rate = 2
local num_test_images = 12
local skip_count = 3
local assumed_fov = 60




local function drawDebugImage(pos, ang, size)
	render.SetMaterial(debugMat)
	render.DrawQuadEasy(pos, -ang:Forward(), size, size, color_white, 0)
end




local function calc_viewing_distance(fov,screen_width)
	return screen_width/(2*math.tan(math.rad(fov)/2))
end




hook.Add( "PostDrawOpaqueRenderables", "TV_PostDrawOpaqueRenderables_DOF", function(isDrawingDepth, isDrawingSkybox)
	if DOF_DEBUG then
		local eye_angles = EyeAngles()
		local eye_pos = EyePos()
		local scrw = ScrW()
		local scrh = ScrH()
		
		local viewing_distance = calc_viewing_distance(assumed_fov, (scrh*4)/3)
	
		render.OverrideDepthEnable(true, true)
		
		local screen_y = scrh*0.5
		for i = 1+skip_count, num_test_images do
			local p = (i-1-skip_count)/(num_test_images-1-skip_count)
			local screen_x = Lerp(p, scrw*0.25, scrw*0.75)
			
			local dist = math.pow(dist_increase_rate,i-1)
			
			local true_x = (dist*(screen_x-(scrw/2)))/viewing_distance
			local true_size = (dist*(sprite_size))/viewing_distance
			
			local true_y = (dist*((scrh*0.75)-(scrh/2)))/viewing_distance
			drawDebugImage( 
				eye_pos
				+ eye_angles:Forward()*dist
				+ eye_angles:Right()*true_x
				+ eye_angles:Up()*true_y,
				eye_angles,
				real_sprite_size
			)
			
			drawDebugImage( 
				eye_pos
				+ eye_angles:Forward()*dist
				+ eye_angles:Right()*true_x,
				eye_angles,
				true_size
			)
		end
		
		render.OverrideDepthEnable(false, true)
	end
end )




local function drawLengthUnits( label, units, posx, posy, offset_y )
	local real_length = SourceUnit2Inches(units)
	
	surface.SetTextPos( posx, posy )
	surface.DrawText(label)
	surface.SetTextPos( posx, posy+offset_y )
	surface.DrawText(tostring(math.Round(units,3)) .. " su")
	surface.SetTextPos( posx, posy+(offset_y*2) )
	surface.DrawText(tostring(math.Round(real_length,3)).." in")
	surface.SetTextPos( posx, posy+(offset_y*3) )
	surface.DrawText(tostring(math.Round(real_length/12,3)).." ft")
end




hook.Add( "HUDPaint", "TV_HUDPaint_DOF", function()
	if DOF_DEBUG then
		local scrw = ScrW()
		local scrh = ScrH()
		surface.SetDrawColor(color_white)
		surface.SetTextColor(color_white)
		surface.SetFont("HudHintTextLarge")
		
		local viewing_distance = calc_viewing_distance(assumed_fov, (scrh*4)/3)
		
		drawLengthUnits("FOCAL LENGTH", focal_length, 50, 50, 16)
		drawLengthUnits("TOP SIZE", real_sprite_size, 50, 150, 16)
		
		local screen_y = scrh*0.5
		for i = 1+skip_count, num_test_images do
			local p = (i-1-skip_count)/(num_test_images-1-skip_count)
			local screen_x = Lerp(p, scrw*0.25, scrw*0.75)
			
			dist = math.pow(dist_increase_rate,i-1)
			
			local true_size = (dist*(sprite_size))/viewing_distance
			
			drawLengthUnits("DIST", dist, screen_x-(sprite_size/2), screen_y+(sprite_size/2), 16)
			drawLengthUnits("SIZE", true_size, screen_x-(sprite_size/2), screen_y+(sprite_size/2)+(16*5), 16)
		end
	end
end )




-- TODO: Make this work better with the offset.
local curve_exp = 2 --3 is good. this scales the distances between the layers.

local function DoFFunction( p, focal_length )
	--return focal_length*p*2 --linear. looks like a dream. don't use.
	
	return focal_length * math.pow(p*2, curve_exp)
end




-- Copied from TWG code. I need to store this function as another addon
-- or something.

local TEST_DIRECTIONS = {
	vector_up,
	Vector(1,0,0),
	Vector(-1,0,0),
	Vector(0,1,0),
	Vector(0,-1,0),
	-vector_up
}

local function GetMaxLightingAt( pos )
	local max = 0
	
	for i, dir in ipairs(TEST_DIRECTIONS) do
		local light = render.ComputeLighting(pos, dir)
		max = math.max( max, light.x, light.y, light.z )
	end
	
	return max
end




hook.Add( "PreDrawEffects", "TV_PreDrawEffects_DOF", function()
	local result = hook.Call("TV_SuppressDOF")
	if result == true then return end
	
	if not DOF_ENABLED:GetBool() then return end
	
	local localplayer = LocalPlayer()
	if not IsValid(localplayer) then return end
	
	local cam_pos = EyePos()
	local cam_normal = EyeVector()
	local cam_angle = EyeAngles()
	
	local realtime = RealTime()
	local realframetime = RealFrameTime()
	
	if DOF_DEBUG_FORCE_FOCAL_LENGTH == 0 then
		if realtime >= next_trace then
			local contents = util.PointContents(cam_pos)
			
			if bit.band( contents, CONTENTS_WATER ) > 0 then
				next_focal_length = 0
			else
				local size = Vector(1,1,1)*1
				
				-- THIS SHIT IS SO STUPID AHASKDASKD:ASMDMASSL:DL:ASL
				
				local offset_cam_ang = 1.0*cam_angle
				offset_cam_ang:RotateAroundAxis(offset_cam_ang:Up(), math.random()*assumed_fov/20)
				offset_cam_ang:RotateAroundAxis(cam_normal, math.random()*360)
				
				local offset_cam_normal = offset_cam_ang:Forward()
				
				local tr = util.TraceLine({
					start = cam_pos,
					endpos = cam_pos + offset_cam_normal*MAX_FOCAL_LENGTH,
					filter = localplayer,
					mask = bit.bor( MASK_OPAQUE, CONTENTS_IGNORE_NODRAW_OPAQUE, CONTENTS_MONSTER, CONTENTS_SOLID, CONTENTS_MONSTER, CONTENTS_WINDOW, CONTENTS_DEBRIS ),
					--mins = -size,
					--maxs = size
				})
				
				if tr.Hit and IsValid( tr.Entity ) and tr.Entity:GetRenderGroup() == RENDERGROUP_OPAQUE then
					-- leave it
				else
					tr = util.TraceLine({
						start = cam_pos,
						endpos = cam_pos + offset_cam_normal*MAX_FOCAL_LENGTH,
						filter = localplayer,
						mask = bit.bor( MASK_OPAQUE, CONTENTS_IGNORE_NODRAW_OPAQUE, CONTENTS_MONSTER ),
						--mins = -size,
						--maxs = size
					})
				end
				
				if tr.Hit then
					-- debugoverlay.Cross( tr.HitPos, 10, 1+engine.TickInterval()*2, color_white, true )
				
					local lightness_at_hit = GetMaxLightingAt( tr.HitPos + tr.HitNormal )
					local lightness_at_cam = GetMaxLightingAt( cam_pos )
					
					local replace_it = false
					
					if lightness_at_hit-lightness_at_cam > 0.005 or lightness_at_hit > 0.0025 then
						replace_it = true
					else
						if localplayer:FlashlightIsOn() then
							local dist = tr.Fraction * MAX_FOCAL_LENGTH
							if dist < 800 then
								replace_it = true
							end
						end
					end
					
					if replace_it then
						next_focal_length = cam_pos:Distance(tr.HitPos)
					end
				else
					next_focal_length = MAX_FOCAL_LENGTH
				end
			end
			
			next_trace = realtime + 0.025
		end
		
		if next_focal_length < focal_length then
			focal_length = Lerp(math.pow(FOCAL_LENGTH_RATE/16, realframetime), next_focal_length, focal_length)
		else
			focal_length = Lerp(math.pow(FOCAL_LENGTH_RATE, realframetime), next_focal_length, focal_length)
		end
	else
		focal_length = DOF_DEBUG_FORCE_FOCAL_LENGTH
	end
	
	
	-- retrieved from https://steamcommunity.com/sharedfiles/filedetails/?id=134207296
	
	--RunConsoleCommand( "pp_bokeh_blur", 50 )
	--RunConsoleCommand( "pp_bokeh_distance", focal_length/4096 )
	--RunConsoleCommand( "pp_bokeh_focus", 1.5 )
	
	
	render.SetStencilEnable(true)
		
	render.SetStencilTestMask(255)
	render.SetStencilWriteMask(255)
	
	render.ClearStencil()
	
	render.SetStencilCompareFunction( STENCILCOMPARISONFUNCTION_ALWAYS )
	render.SetStencilFailOperation( STENCILOPERATION_KEEP )
	
	render.SetStencilReferenceValue( 1 )
	
	render.SetColorMaterial()
		
	render.OverrideDepthEnable( true, false )
	
	for i = 1, DOF_LAYERS do
		local p = i/DOF_LAYERS
		
		-- Stage 1 (Makes distant stuff blurry)
		render.SetStencilPassOperation( STENCILOPERATION_INCR )
		render.SetStencilZFailOperation( STENCILOPERATION_KEEP )
		
		local dist = DoFFunction((p+1)/2, focal_length)
		if dist < 6000 then
			if not USE_SPHERES then
				render.DrawQuadEasy(
					cam_pos + cam_normal * dist, 
					-cam_normal,
					QUAD_WIDTH,
					QUAD_HEIGHT,
					color_mask_1,
					cam_angle.roll
				)
			else
				render.DrawSphere(cam_pos, -dist, 16, 16, color_mask_1)
			end
		end
		
		-- Stage 2 (Makes close stuff blurry)
		render.SetStencilPassOperation( STENCILOPERATION_KEEP )
		render.SetStencilZFailOperation( STENCILOPERATION_INCR )
		
		local dist = DoFFunction(p/2, focal_length)
		if dist > 1 then
			if not USE_SPHERES then
				render.DrawQuadEasy(
					cam_pos + cam_normal * dist, 
					-cam_normal,
					QUAD_WIDTH,
					QUAD_HEIGHT,
					color_mask_2,
					cam_angle.roll
				)
			else
				render.DrawSphere(cam_pos, -dist, 16, 16, color_mask_2)
			end
		end
	end
	
	render.OverrideDepthEnable( false, false )
	
	cam.Start2D()
		render.SetStencilPassOperation( STENCILOPERATION_KEEP )
		render.SetStencilZFailOperation( STENCILOPERATION_KEEP )
		
		render.SetStencilCompareFunction( STENCILCOMPARISONFUNCTION_LESS )
		
		render.SetMaterial(blurMat)
		
		for i = DOF_LAYERS, 1, -1 do
			render.UpdateScreenEffectTexture()
		
			render.SetStencilReferenceValue( i )
			blurMat:SetFloat("$scale", (i/(QUALITY)) * (0.5/QUALITY))
			
			render.DrawScreenQuad()
		end
	cam.End2D()
	
	render.SetStencilEnable(false)
	
	-- render.DrawStencilTestColors(true, DOF_LAYERS)
end )




hook.Add( "PostGamemodeCalcView", "TV_ClDof_PostGamemodeCalcView", function( ply, data )
	assumed_fov = data.fov

	data.fov = data.fov * Lerp( focal_length / MAX_FOCAL_LENGTH, 1.05, 0.95 )
end )