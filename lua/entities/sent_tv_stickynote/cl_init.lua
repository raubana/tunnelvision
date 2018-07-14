include( "shared.lua" )

AddCSLuaFile()




ENT.SIZE = Vector(4,4,0.7)




function ENT:UpdateMessageData()
	surface.SetFont( self.FONT_NAME )
	
	local message = string.Replace( self.message, "/n", "\n" )
	local parts = string.Explode( "\n", message )
	
	self.message_data = {}
	
	local sizes = {}
	
	local total_height = 0
	
	for i, part in ipairs( parts ) do
		local width, height = surface.GetTextSize( part )
		total_height = total_height + height
		table.insert( sizes, {width, height} )
	end
	
	local y = ((self.SIZE.y/self.SCALE) - total_height) / 2
	for i = 1, #parts do
		local part = parts[i]
		local size = sizes[i]
		
		local data = {}
		data.text = part
		data.x = ((self.SIZE.x/self.SCALE) - size[1]) / 2
		data.y = 1.0 * y
		
		y = y + size[2]
		
		table.insert( self.message_data, data )
	end
end




function ENT:DrawMessage()
	self:SetupToDrawMessage()
	
	for i, data in ipairs( self.message_data ) do
		surface.SetTextPos( data.x, data.y )
		surface.DrawText( data.text )
	end
	
	cam.End3D2D()
end