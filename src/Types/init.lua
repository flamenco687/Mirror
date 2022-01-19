local Package = script.Parent

export type SupportedValueTypes = {
	string: boolean,
	boolean: boolean,
	number: boolean,
	UDim: boolean,
	UDim2: boolean,
	BrickColor: boolean,
	Color3: boolean,
	Vector2: boolean,
	Vector3: boolean,
	NumberSequence: boolean,
	ColorSequence: boolean,
	NumberRange: boolean,
	Rect: boolean,
}

export type MirrorSettings = {
    Whitelist: {[number]: Player}?,
    IsPrivate: boolean?
}

export type Reflex = Configuration

--- @within Mirror
--- @type Reflex Configuration
--- Reflexes are containers that simply hold a value (using roblox attributes) in a studio-instance. The reflexes of a mirror
--- represent that mirror's [Mirror.Data] in an instance tree so the client can easily access primitive values by making
--- use of `:GetAttribute()`. If a reflex's value is nil it means that the real value is being held by the server because
--- it cannot be set as an attribute value.

--- @within Mirror
--- @interface MirrorSettings
--- .Whitelist {[number]: Player}?
--- .IsPrivate boolean?

return nil