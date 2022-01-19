--[[

    This table should not be modified nor used by the client. It contains values with a
    non-supported type by the attributes, meaning that the value must be stored in a table.

--]]

local Package = script.Parent.Parent

local Types = require(Package.Types)

local Holder: {[Types.Reflex]: any} = {}

local NonSupportedValues = {}

function NonSupportedValues.Set(Reflex: Types.Reflex, Value: any)
    Holder[Reflex] = Value
end

function NonSupportedValues.Get(Reflex: Types.Reflex): any
    return Holder[Reflex]
end

--- @within Mirror
--- @type NonSupportedValues {[Reflex]: any}
--- This type is only used by a shared table made to hold values which are not supported by attributes
--- and for such reason must be requested by the client through [RemoteFunction]s

return NonSupportedValues