include("shared.lua")

AddCSLuaFile("cl_init.lua")




function ENT:Initialize()
	self:SetModel( "models/tunnelvision/misc/tv_stickynote.mdl" )
	self:PhysicsInit( SOLID_OBB )
	self:GetPhysicsObject():EnableMotion( false )
end