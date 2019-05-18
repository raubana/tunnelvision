include( "shared.lua" )

AddCSLuaFile()




ENT.FONT_NAME = "TV_Label"
local FONT_DATA = {
	font = "Comic Sans MS",
	size = 54,
	antialias = true
}
surface.CreateFont( ENT.FONT_NAME, FONT_DATA )

ENT.SIZE = Vector(4,1,0.25)
ENT.SCALE = 0.025/2




function ENT:Initialize()
	self.message = nil
	self.message_data = {}
	
	self.next_check_message = 0
end




function ENT:UpdateMessageData()
	surface.SetFont( self.FONT_NAME )
	local width, height = surface.GetTextSize( self.message )
	
	self.message_data = {}
	self.message_data.x = ( (self.SIZE.x / self.SCALE) - width) / 2
	self.message_data.y = ( (self.SIZE.y / self.SCALE) - height) / 2
end




function ENT:SetupToDrawMessage()
	local my_pos = self:GetPos()
	local my_ang = self:GetAngles()
	
	local new_ang = 1.0 * my_ang
	new_ang:RotateAroundAxis( new_ang:Right(), -90 )
	new_ang:RotateAroundAxis( new_ang:Up(), 90 )
	
	local offset = Vector( self.SIZE.z, -self.SIZE.x, self.SIZE.y )/2
	offset:Rotate( my_ang )
	
	cam.Start3D2D( my_pos + offset, new_ang, self.SCALE )
	
	surface.SetFont( self.FONT_NAME )
	surface.SetTextColor( color_black )
	
	-- surface.SetDrawColor( color_black )
	-- surface.DrawOutlinedRect( 0, 0, self.SIZE.x/self.SCALE, self.SIZE.y/self.SCALE )
end




function ENT:DrawMessage()
	self:SetupToDrawMessage()
	
	surface.SetTextPos( self.message_data.x, self.message_data.y )
	surface.DrawText( self.message )
	
	cam.End3D2D()
end




function ENT:Draw()
	self:DrawModel()
	
	if CurTime() >= self.next_check_message then
		self.next_check_message = CurTime() + 1
		local message = self:GetMessage()
		if message != self.message then
			self.message = message
			self:UpdateMessageData()
		end
	end
	
	if self.message then
		self:DrawMessage()
	end
end