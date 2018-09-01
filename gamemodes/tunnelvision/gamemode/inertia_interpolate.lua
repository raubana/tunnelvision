
IntertiaInterpolate = {}
IntertiaInterpolate.__index = IntertiaInterpolate

function IntertiaInterpolate:create(  )
	local instance = {}
	setmetatable(instance,IntertiaInterpolate)
	return instance
end