local Package = script.Parent.Parent.Parent

local GetReflexRealValue: RemoteFunction = Package.Remotes.GetReflexRealValue

--[=[
    @within Mirror
    Converts the children reflexes of an instance or a whole instance tree of reflexes and their values
    to a vanilla table that can later be used as a proxy for [Mirror.Data]

    @private
    @client
    @tag Utility
]=]
function ReflexesToTable(Parent: Instance, Recursive: boolean): Dictionary<any>
    local Table: {[string]: any} = {}

    for _: number, Reflex: Instance in pairs(Parent:GetChildren()) do

        -- If the value is not present as an attribute, it means that the real value is being held by the server and must be requested
        local Value = if Reflex:GetAttribute("Value") then Reflex:GetAttribute("Value") else GetReflexRealValue:InvokeServer(Reflex)

        if Value then
            Table[Reflex.Name] = Value
        elseif #Reflex:GetChildren() > 0 and Recursive then
            Table[Reflex.Name] = ReflexesToTable(Reflex)
        else
            Table[Reflex.Name] = nil
        end
    end

    return Table
end

return ReflexesToTable