include( "shared.lua" )

AddCSLuaFile()




function ENT:GetIOState( x )
	return bit.band( self:GetState(), math.pow( 2, x ) ) > 0
end




function ENT:DrawConnection( pos, state )
	local c = self.LOW_COLOR
	if state then c = self.HIGH_COLOR end
	
	render.SetColorMaterial()
	render.DrawBox( pos, angle_zero, Vector(1,1,1)*-0.5, Vector(1,1,1)*0.5, c, true )
end





local DEBUGMODE = GetConVar("tv_io_debug")

function ENT:Draw()
	if DEBUGMODE:GetBool() then
		for x = 1, self.NumInputs do
			self:DrawConnection( self:GetInputPos(x), self:GetIOState( x ) )
		end
		
		for x = 1, self.NumOutputs do
			self:DrawConnection( self:GetOutputPos(x), self:GetIOState( self.NumInputs + x ) )
		end
	end
	
	self:DrawModel()
end