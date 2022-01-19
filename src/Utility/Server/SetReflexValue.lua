local Package = script.Parent.Parent.Parent
local Shared = Package:FindFirstChild("Shared")

local Types = require(Package.Types)

local NonSupportedValues = require(Shared.NonSupportedValues)
local SupportedValueTypes: Types.SupportedValueTypes = require(Shared.SupportedValueTypes)

--[=[
    @within Mirror
    Sets a new value for the passed reflex. The function checks if the value type
    is supported by attributes, in which case they are used. Otherwhise, the value
    is stored in the `NonSupportedValues` shared table.

    :::danger
    All changes made to the reflex instance must be done after working with the
    `NonSupportedValues` table, otherwise the client could receive a wrong value

    @private
    @server
    @tag Utility
]=]
local function SetReflexValue(Reflex: Types.Reflex, Value: any): Types.Reflex
    if SupportedValueTypes[typeof(Value)] then
        Reflex:SetAttribute("Value", Value)

        NonSupportedValues.Set(Reflex, nil)
    else
        if Value == nil then
            NonSupportedValues[Reflex] = nil

            Reflex:Destroy()
        else
            if type(Value) == "table" then
                NonSupportedValues.Set(Reflex, nil)
            else
                NonSupportedValues.Set(Reflex, Value)
            end

            Reflex:SetAttribute("Value", nil) -- Clients listening to value changes understand that nil means the real value must be requested
        end
    end
end

return SetReflexValue