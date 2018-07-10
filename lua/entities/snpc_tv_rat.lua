AddCSLuaFile()

ENT.Base 			= "base_nextbot"
ENT.Spawnable		= true

function ENT:Initialize()
	self:SetModel( "models/tunnelvision/npc/rat.mdl" )
	self:SetCollisionGroup( COLLISION_GROUP_NPC_ACTOR )
	
	if SERVER then
		self:SetHealth( 1 )
	
		self.loco:SetDesiredSpeed( 25 )
	end
end




function ENT:RunBehaviour()
	while ( self:Health() > 0 ) do
		local target = self:GetPos() + Vector(1000,0,0)
	
		self.loco:Approach( target , 1 )
		self.loco:FaceTowards( target )
	
		coroutine.yield( )
	end
end




list.Set( "NPC", "snpc_tv_rat", {
	Name = "TV: Rat",
	Class = "snpc_tv_rat",
	Category = "Tunnel Vision"
} )