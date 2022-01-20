local RunService: RunService = game:GetService("RunService")

local IsServer: boolean = RunService:IsServer()
local IsClient: boolean = RunService:IsClient()

--[=[
    Looks for an existing instance with the given name or creates a new one
    of the specified class if the caller is the server. The client will only
    wait for the existance of the desired instance if a parent was specified.

    :::note
    No return type is specified since function can return any type of instance
    and type check may freak out when working with this function if [Instance]
    was specified as the returned value type

    @private
    @tag Utility

    @within Mirror
]=]
local function GetInstance(Name: string, Class: string?, Parent: Instance?)
	local RequestedInstance: Instance = if Parent then Parent:FindFirstChild(Name) else nil

	if RequestedInstance then
		return RequestedInstance
	end

	if IsServer and Class then
		RequestedInstance = Instance.new(Class)
		RequestedInstance.Name = Name
		RequestedInstance.Parent = if Parent then Parent else nil
	elseif IsClient and Parent then
		RequestedInstance = Parent:WaitForChild(Name)
    else
        warn("Client cannot find desired instance because no parent was specified:", Name)
	end

	return RequestedInstance
end

return GetInstance