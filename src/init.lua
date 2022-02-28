local ServerScriptService = game:GetService("ServerScriptService")
local RunService: RunService = game:GetService("RunService")
local Players: Players = game:GetService("Players")

local Package = script
local Utility = Package:FindFirstChild("Utility")
local Shared = Package:FindFirstChild("Shared")
local Global = Package:FindFirstChild("Global")

local Types = require(Package.Types)
local Proxy = require(Package.Parent.Proxy)

-- Utility functions/modules:

local GetInstance = require(Utility.Shared.GetInstance)

local SetReflexValue = require(Utility.Server.SetReflexValue)
local DestroyChildren = require(Utility.Server.DestroyChildren)

local ReflexesToTable = require(Utility.Client.ReflexesToTable)

local NonSupportedValues = require(Shared.NonSupportedValues)

local IsClient: boolean = RunService:IsClient()
local IsServer: boolean = RunService:IsServer()

local GetReflexRealValue: RemoteFunction = Package.Remotes.GetReflexRealValue

local MainContainer: Folder = Package.Container

local ActiveMirrors: {[string]: Mirror} = {}

--[=[
    @class Mirror
]=]
local Mirror = {}
local METATABLE = {__index = Mirror}

--- @prop Data Proxy
--- @within Mirror

--[=[
    Makes passed reflex to start listening to value changes, child additions
    and ancestry changes so server-mirror values can be replicated to the
    client mirror through reflexes.

    @private
    @client

    @within Mirror
]=]
local function ListenToReflexUpdates(Reflex: Instance | Types.Reflex, Table: Proxy)
    if not rawget(Table._Proxy, Reflex.Name) then
        local Value: any = if Reflex:GetAttribute("Value") ~= nil then Reflex:GetAttribute("Value") else GetReflexRealValue:InvokeServer(Reflex)

        if Value == nil and #Reflex:GetChildren() > 0 then
            Table[Reflex.Name] = TableToProxy(ReflexesToTable(Reflex), true, Reflex)
        else
            Table[Reflex.Name] = Value
        end
    end

    --[=[
        Listens to reflex value changes and updates the [Mirror.Data] entry accordingly

        :::info Listener
        This function is a listener function that is activated when [Mirror.ListenToReflexUpdates]
        is called and stops listening when the reflex which updates are being tracked is destroyed

        @private
        @client
        @tag Listener

        @within Mirror
    ]=]
    local function ValueChanged()
        local NewValue: any = if Reflex:GetAttribute("Value") ~= nil then Reflex:GetAttribute("Value") else GetReflexRealValue:InvokeServer(Reflex)

        if NewValue == nil and #Reflex:GetChildren() > 0 then -- When a reflex has children and its real value is nil, it is considered a table
            Table[Reflex.Name] = TableToProxy(ReflexesToTable(Reflex), true, Reflex)
        else
            Table[Reflex.Name] = NewValue
        end
    end

    --[=[
        Listens to reflex child additions. When a child is added to a reflex, it means that the reflex
        real value is now a table and the children are its entry values. Reflex's children listeners
        are initiated on creation just as the parent reflex listeners were initiated too.

        :::info Listener
        This function is a listener function that is activated when [Mirror.ListenToReflexUpdates]
        is called and stops listening when the reflex which updates are being tracked is destroyed

        @private
        @client
        @tag Listener

        @within Mirror
    ]=]
    local function ChildAdded(Child: Instance | Types.Reflex)
        if type(Table[Reflex.Name]) ~= "table" then
            Table[Reflex.Name] = TableToProxy({}, false, Table._Container)
        end

        Table[Reflex.Name][Child.Name] = Child:GetAttribute("Value")

        ListenToReflexUpdates(Child, Table[Reflex.Name])
    end

    local ValueChangedConnection: RBXScriptConnection = Reflex:GetAttributeChangedSignal("Value"):Connect(ValueChanged)
    local ChildAddedConnection: RBXScriptConnection = Reflex.ChildAdded:Connect(ChildAdded)
    local DestroyedConnection: RBXScriptConnection

    --[=[
        Listens to reflex ancestry changes to check if the reflex no longer exists and to
        disconnect its connections if it is the case

        :::info Listener
        This function is a listener function that is activated when [Mirror.ListenToReflexUpdates]
        is called and stops listening when the reflex which updates are being tracked is destroyed

        @private
        @client
        @tag Listener

        @within Mirror
    ]=]
    local function Destroyed(_, Parent: Instance | nil)
        if Parent then
            return
        end

        ValueChangedConnection:Disconnect()
        ChildAddedConnection:Disconnect()
        DestroyedConnection:Disconnect()

        Table[Reflex.Name] = nil
    end

    DestroyedConnection = Reflex.AncestryChanged:Connect(Destroyed)
end

--[=[
    Fires when a key is changed on the server's [Mirror.Data]. The function updates
    the reflex equivalent of the key and triggers the whole replication process
    by updating its value, connecting listeners and destroying old children

    @private
    @server

    @within Mirror
]=]
local function OnServerKeyChange(Key: string, Value: any, OldValue: any, self: Proxy)
    local Reflex: Types.Reflex = GetInstance(Key, "Configuration", self._Container)

    SetReflexValue(Reflex, Value)

    if type(Value) == "table" then
        rawset(self._Proxy, Key, TableToProxy(Value, true, GetInstance(Key, "Configuration", self._Container)))
    else
        DestroyChildren(Reflex) -- Old value could be a table with children that must be destroyed to represent it is now a single-value
    end
end

--[=[
    Converts a vanilla table into a proxy object that is able to detect key
    changes. Proxies serve the purpose of detecting value changes from the
    server so they can be replicated through reflexes to the client.

    @private

    @within Mirror
]=]
function TableToProxy(Table: table, Recursive: boolean, Container: Instance): Proxy
    local NewProxy: Proxy = Proxy.new(Table, { ["_Container"] = Container })

    if Recursive then
        if IsServer and #Container:GetChildren() > 0 then -- Cleans old reflexes that could were present in an old proxy
            for _: number, Reflex: Instance | Types.Reflex in pairs(Container:GetChildren()) do
                if Table[Reflex.Name] == nil then
                    Reflex:Destroy()
                end
            end
        end

        for Key: string, Value: any | table in pairs(NewProxy._Proxy) do
            local Reflex: Types.Reflex = GetInstance(Key, "Configuration", Container)

            if IsServer then
                SetReflexValue(Reflex, Value)
            else
                ListenToReflexUpdates(Reflex, NewProxy)
            end

            if type(Value) == "table" then
                NewProxy:Set(Key, TableToProxy(Value, true, Reflex))
            end
        end
    end

    if IsServer then
        NewProxy:OnChange(OnServerKeyChange)
    end

    return NewProxy
end

--[=[
    Adds player or array of players to the [Mirror._Whitelist]

    @server
]=]
function Mirror:AddWhitelist(PlayerToAdd: Player | Array<Player>)
    if type(PlayerToAdd) == "table" then
        table.move(PlayerToAdd, 1, #PlayerToAdd, #self._Whitelist + 1, self._Whitelist)
    else
        table.insert(self._Whitelist, PlayerToAdd)
    end
end

--[=[
    Removes player or array of players from the [Mirror._Whitelist]

    @server
]=]
function Mirror:RemoveWhitelist(PlayerToRemove: Player | Array<Player>)
    local function RemoveFirstOccurrence(Player: Player)
        local Index: number? = table.find(self._Whitelist, Player)

        if Index then
            table.remove(self._Whitelist, Player)
        end
    end

    if type(PlayerToRemove) == "table" then
        for _: number, Player: Player in pairs(PlayerToRemove) do
            RemoveFirstOccurrence(Player)
        end
    else
        RemoveFirstOccurrence(PlayerToRemove)
    end
end

--[=[
    Overrides the current [Mirror.Data] and sets it to the passed table

    @server
]=]
function Mirror:Set(NewData: table)
    if IsClient then
        return error(":Set() is restricted to the server; clients cannot override the Mirror.Data\n\n"..debug.traceback())
    end

    DestroyChildren(self._Container)

    local DataToDelete: Proxy = self.Data
    self.Data = TableToProxy(NewData, true, self._Container)

    DataToDelete:Destroy()
end

--[=[
    Returns an existing mirror

    @yields
]=]
function Mirror.Get(Name: string): Mirror
    if ActiveMirrors[Name] then
        return ActiveMirrors[Name]
    end

    if IsServer then
        while not ActiveMirrors[Name] do
            task.wait()
        end
    else
        -- MirrorSettings are requested before loading anything else because it yields until the player has access
        -- to the mirror. This way, the scritp doesn't run functions that may not be necessary since the player
        -- will never have access to the mirror

        return Mirror.new(Name, ReflexesToTable(GetInstance(Name, "Folder", MainContainer)))
    end

    return ActiveMirrors[Name]
end

--[=[
    Constructs a new mirror

    :::caution
    The constructor function is used by both client and server but it should only directly be called
    by the server to create new mirrors. The client will automatically retrieve all mirror settings
    and construct the mirror internally when requesting a mirror with [Mirror.Get]

    @tag Constructor

    @param Name string
    @param Origin table? -- Optional table to work as a base for the mirror's [Mirror.Data]
    @param Settings MirrorSettings? -- Additional settings such as whitelist, visibility...
]=]
function Mirror.new(Name: string, Origin: table?, Settings: Types.MirrorSettings?): Mirror
    if IsClient and debug.info(2, "n") ~= "Get" then
        return error("Clients may not direclty construct new mirrors; .Get() will automatically do so\n\n"..debug.traceback())
    end

    if ActiveMirrors[Name] then
        warn("Tried to construct an already existing mirror; use .Get() instead\n\n"..debug.traceback())
        return ActiveMirrors[Name]
    end

    local Container: Folder = GetInstance(Name, "Folder", MainContainer) -- The instance that will contain the reflexes
    local Data: Proxy = TableToProxy(if Origin then Origin else {}, if Origin then true else false, Container)

    if IsClient then

        -- When calling TableToProxy, existing values are automatically converted to reflexes and their listening
        -- functions get connected by default. Newly added reflexes to the mirror's first and main container
        -- are not tracked by default and for such reason this function exists

        Container.ChildAdded:Connect(function(ChildReflex: Types.Reflex)
            ListenToReflexUpdates(ChildReflex, Data)
        end)
    end

    local self = {
        _Whitelist = if Settings and Settings.Whitelist then Settings.Whitelist else {},
        _IsPrivate = if Settings and Settings.IsPrivate then Settings.IsPrivate else false,

        _ChangeListeners = {},

        _Container = Container,
        _Name = Name,

        Data = Data,
    }

    ActiveMirrors[Name] = self

    return setmetatable(self, METATABLE)
end

export type Mirror = {
    _Whitelist: {[number]: Player},
    _IsPrivate: boolean,

    _ChangeListeners: table,

    _Container: Folder,
    _Name: string,

    Data: table,

    Set: (self: Mirror, NewData: table) -> (),
    RemoveWhitelist: (self: Mirror, PlayerToRemove: Player | Array<Player>) -> (),
    AddWhitelist: (self: Mirror, PlayerToAdd: Player | Array<Player>) -> (),
}

if IsServer then

    --[=[
        Returns the real value of the requested reflex. The function automatically checks if the
        requested reflex exists or is valid and if the player that requested the value is in the
        reflex's mirror whitelist (in case the mirror is private).

        @private
        @server
        @tag RemoteFunction

        @within Mirror
    ]=]
    local function RequestRealValue(Player: Player, Reflex: Types.Reflex): any
        local RealValue: any = NonSupportedValues.Get(Reflex)
        local MirrorContainer: Folder? = Reflex:FindFirstAncestorOfClass("Folder")

        if not MirrorContainer or not MirrorContainer.Parent == MainContainer then
            return warn("Player "..Player.Name.." requested real value of an invalid reflex:", Reflex)
        end

        local RequestedMirror: string = if MirrorContainer then ActiveMirrors[MirrorContainer.Name] else nil

        if not RequestedMirror or RequestedMirror._IsPrivate and not table.find(RequestedMirror._Whitelist, Player) then
            return warn("Player "..Player.Name.." attempted to get real value of a reflex owned by a null/private mirror", RequestedMirror, Reflex)
        end

        return RealValue
    end

    GetReflexRealValue.OnServerInvoke = RequestRealValue
end

export type Proxy = typeof(Proxy.new())

export type table = {[any]: any}

return Mirror