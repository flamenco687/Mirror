local Package = script.Parent.Parent.Parent

--[=[
    Destroys all children of an Instance

    @private
    @server
    @tag Utility

    @within Mirror
]=]
local function DestroyChildren(Parent: Instance): nil
    local Children: Array<Instance> = Parent:GetChildren()

    if #Children > 0 then
        for _, Child: Instance in pairs(Parent:GetChildren()) do
            Child:Destroy()
        end
    end

    return nil
end

return DestroyChildren