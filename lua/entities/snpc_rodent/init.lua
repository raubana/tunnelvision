include("shared.lua")
include("sv_movement.lua")



function ENT:Initialize()
	self:SetModel( "models/gman_high.mdl" )
	
	self:RSNBInit()
end




function ENT:Think()
	self:NextThink( CurTime() )
	return true
end




function ENT:HearSound( data )
	
end




function ENT:RunBehaviour()
	self:PushActivity( ACT_IDLE )
	
	coroutine.wait( 1 )
	
	while true do
	
		coroutine.wait( 2 )
	end
end

