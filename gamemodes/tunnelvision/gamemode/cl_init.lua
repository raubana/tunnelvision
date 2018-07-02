print( "cl_init" )




function GM:CalcView( ply, origin, angles, fov, znear, zfar )
	local data = {}
	data.origin = origin
	data.angles = angles
	data.fov = fov
	data.znear = znear
	data.zfar = zfar
	
	data.fov = 55
	
	return data
end




local DO_NOT_DRAW = {}
DO_NOT_DRAW["CHudAmmo"] = true
DO_NOT_DRAW["CHudBattery"] = true
DO_NOT_DRAW["CHudHealth"] = true
DO_NOT_DRAW["CHudWeaponSelection"] = true

function GM:HUDShouldDraw( name )
	return not DO_NOT_DRAW[name]
end




local expected_weapon = nil
function GM:PlayerBindPress( ply, bind, pressed )
	if bind == "invprev" or bind == "invnext" then
		local all_weps = ply:GetWeapons()
		
		if #all_weps <= 1 then return end
		
		local selected = ply:GetActiveWeapon()
		local index
		for i, wep in ipairs( all_weps ) do
			if wep == selected then
				index = i
				break
			end
		end
		
		if bind == "invprev" then
			index = index - 1
			if index <= 0 then index = #all_weps end
		else
			index = index + 1
			if index > #all_weps then index = 1 end
		end
		
		expected_weapon = all_weps[index]
		
		ply:PrintMessage( HUD_PRINTTALK, "You switch to your "..expected_weapon.PrintName.."." )
	end
end




function GM:CreateMove( cmd )
	if expected_weapon != nil and LocalPlayer():GetActiveWeapon() != expected_weapon and IsValid( expected_weapon ) then
		cmd:SelectWeapon( expected_weapon )
	end
end