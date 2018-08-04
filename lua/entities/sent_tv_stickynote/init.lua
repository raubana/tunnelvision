include("shared.lua")

AddCSLuaFile("cl_init.lua")




list.Add( "TV_label_ents", "sent_tv_stickynote" )




function ENT:Initialize()
	self:SetModel( "models/tunnelvision/misc/tv_stickynote.mdl" )
	self:DrawShadow( false )
	self:PhysicsInit( SOLID_OBB )
	self:SetCollisionGroup( COLLISION_GROUP_DEBRIS )
	self:GetPhysicsObject():EnableMotion( false )
end