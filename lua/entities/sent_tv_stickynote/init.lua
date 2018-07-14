include("shared.lua")

AddCSLuaFile("cl_init.lua")




function ENT:Initialize()
	self:SetModel( "models/tunnelvision/misc/tv_stickynote.mdl" )
	self:PhysicsInit( SOLID_OBB )
	self:SetCollisionGroup( COLLISION_GROUP_DEBRIS )
	self:GetPhysicsObject():EnableMotion( false )
end