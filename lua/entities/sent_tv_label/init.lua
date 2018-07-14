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
	self:GetPhysicsObject():EnableMotion( false )
end