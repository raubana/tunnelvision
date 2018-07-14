include("shared.lua")

AddCSLuaFile("cl_init.lua")




function ENT:SpawnFunction( ply, tr, classname )
	if not tr.Hit then return end
	
	local pos = tr.HitPos + tr.HitNormal * 0.2
	local ang = tr.HitNormal:Angle()

	local ent = ents.Create( ClassName )
	ent:SetPos( pos )
	ent:SetAngles( ang )
	ent:Spawn()
	ent:Activate()

	return ent
end




function ENT:Initialize()
	self:SetModel( "models/tunnelvision/misc/tv_label.mdl" )
	self:PhysicsInit( SOLID_OBB )
	self:SetCollisionGroup( COLLISION_GROUP_DEBRIS )
	self:GetPhysicsObject():EnableMotion( false )
end




function ENT:KeyValue(key, value)
	if key == "message" then
		self:SetMessage( value )
	elseif key == "editable" then
		self:SetEditable( tobool( tonumber( value ) ) )
	elseif key == "pickupable" then
		self:SetPickupable( tobool( tonumber( value ) ) )
	end
end