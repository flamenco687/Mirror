local Package = script.Parent.Parent.Parent
local Shared = Package:FindFirstChild("Shared")

local Types = require(Package.Types)

local NonSupportedValues = require(Shared.NonSupportedValues)
local SupportedValueTypes: Types.SupportedValueTypes = require(Shared.SupportedValueTypes)

--[=[
    Sets a new value for the passed reflex. The function checks if the value type
    is supported by attributes, in which case they are used. Otherwhise, the real
    value is stored in the `NonSupportedValues` shared table and the attribute is
    set to nil to indicate that the real value must be requested.

    :::danger
    All changes made to the reflex instance must be done after working with the
    `NonSupportedValues` table, otherwise the client could receive a wrong value

    @private
    @server
    @tag Utility

    @within Mirror
]=]
local function SetReflexValue(Reflex: Types.Reflex, Value: any): Types.Reflex
    if SupportedValueTypes[typeof(Value)] then
        Reflex:SetAttribute("Value", Value)

        NonSupportedValues.Set(Reflex, nil) -- Cleans real value link in case there was any
    else
        if Value == nil then
            NonSupportedValues.Set(Reflex, nil)
            Reflex:Destroy()
        else
            if type(Value) == "table" then
                -- The client doesn't need to request the real value for tables, it will interpretate
                -- the reflex equivalent instance tree as the table structure.

                NonSupportedValues.Set(Reflex, nil)
            else
                NonSupportedValues.Set(Reflex, Value)
            end

            Reflex:SetAttribute("Value", nil)
        end
    end
end

return SetReflexValue