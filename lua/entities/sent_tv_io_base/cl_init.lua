include( "shared.lua" )

AddCSLuaFile()




function ENT:GetConnectionPos( a )
	local pos = self:GetPos()
	local ang = self:GetAngles()
	
	ang:RotateAroundAxis( ang:Forward(), a )
	pos = pos + ang:Right() * 10
	
	return pos
end




function ENT:GetInputPos( x )
	return self:GetConnectionPos( -60 + (x * 15) )
end




function ENT:GetOutputPos( x )
	return self:GetConnectionPos( 240 - (x * 15) )
end




function ENT:GetIOState( x )
	return bit.band( self:GetState(), math.pow( 2, x ) ) > 0
end




function ENT:DrawConnection( pos, state )
	local c = self.LOW_COLOR
	if state then c = self.HIGH_COLOR end
	
	render.SetColorMaterial()
	render.DrawBox( pos, angle_zero, Vector(1,1,1)*-1, Vector(1,1,1)*1, c, true )
end




function ENT:Draw()
	for x = 1, self.NumInputs do
		self:DrawConnection( self:GetInputPos(x), self:GetIOState( x ) )
	end
	
	for x = 1, self.NumOutputs do
		self:DrawConnection( self:GetOutputPos(x), self:GetIOState( self.NumInputs + x ) )
	end
	
	self:DrawModel()
end