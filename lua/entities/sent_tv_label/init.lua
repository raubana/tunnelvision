include("shared.lua")

AddCSLuaFile("cl_init.lua")




list.Add( "TV_label_ents", "sent_tv_label" )




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
	self:DrawShadow( false )
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




-- This is for saving circuits.
function ENT:Pickle( ent_list, cable_list )
	local data = {}
	
	data.class = self:GetClass()
	data.pos = self:GetPos()
	data.angles = self:GetAngles()
	data.message = self:GetMessage()
	data.editable = self:GetEditable()
	data.pickupable = self:GetPickupable()
	
	return util.TableToJSON( data )
end




-- This is for loading circuits.
function ENT:UnPickle( data, ent_list )
	self:SetPos( data.pos )
	self:SetAngles( data.angles )
	self:SetMessage( data.message )
	self:SetEditable( data.editable )
	self:SetPickupable( data.pickupable )
end