--[[

    This table is used to check if a value type is supported by attributes by doing:

	SupportedValueTypes[typeof(ValueToCheck)] == true

--]]

local Package = script.Parent.Parent

local Types = require(Package.Types)

local SupportedValueTypes: Types.SupportedValueTypes = {
	string = true,
	boolean = true,
	number = true,
	UDim = true,
	UDim2 = true,
	BrickColor = true,
	Color3 = true,
	Vector2 = true,
	Vector3 = true,
	NumberSequence = true,
	ColorSequence = true,
	NumberRange = true,
	Rect = true,
}

return SupportedValueTypes