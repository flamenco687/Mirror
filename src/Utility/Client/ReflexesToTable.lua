local Package = script.Parent.Parent.Parent

local GetReflexRealValue: RemoteFunction = Package.Remotes.GetReflexRealValue

--[=[
    Converts the equivalent values of a whole instance tree of reflexes into
    a vanilla table that can later be used as a proxy for [Mirror.Data]

    @private
    @client
    @tag Utility

    @within Mirror
]=]
function ReflexesToTable(Parent: Instance): Dictionary<any>
    local Table: {[string]: any} = {}

    for _: number, Reflex: Instance in pairs(Parent:GetChildren()) do
        -- If the value is not present as an attribute, it means that the real value is being held by the server and must be requested

        local Value = Reflex:GetAttribute("Value")

        -- The real value must be requested if no children are present under the reflex, in which case, the real value is a table
        -- which can't be requested, the client automatically interpretates the reflex's instance tree as the table structure

        if Value == nil and #Reflex:GetChildren() <= 0 then
            Value = GetReflexRealValue:InvokeServer(Reflex)
        end

        if Value ~= nil then
            Table[Reflex.Name] = Value
        elseif #Reflex:GetChildren() > 0 then -- The real value is a table, the table keys are the reflex's children equivalent values
            Table[Reflex.Name] = ReflexesToTable(Reflex)
        else
            Table[Reflex.Name] = nil
        end
    end

    return Table
end

return ReflexesToTable