--!strict
-- Dream Teleporter Module

---------- Module ----------
local Module = {}

---------- Services ----------

local Players = game:GetService("Players")
local ReplicatedStorage = script.Parent.Parent.Parent or game:GetService("ReplicatedStorage")

---------- Instances ----------

local DreamEvents = ReplicatedStorage:WaitForChild("DreamEvents")
local DreamTeleportBindable = DreamEvents.DreamTeleportBindable

---------- Variables ----------

local taggedPartConnections: {[Instance]: {[BasePart]: {RBXScriptConnection}}} = {}

local dreamFilterAttributeNames = {"FilterDreamDifficulty", "FilterDreamName"}

---------- Local functions ----------
-- Define general functions here

local function onDreamTeleporterPartTouched(otherPart: BasePart, teleporterParent: Folder | Model)
	-- Validate player
	local character = otherPart.Parent
	local player = Players:GetPlayerFromCharacter(character)
	if not (character and player) then
		return
	end

	-- Validate humanoid alive
	local humanoid = character:FindFirstChildOfClass("Humanoid") :: Humanoid
	if not (humanoid.Health > 0) then
		return
	end

	-- Get destination dream filters
	local dreamFilters = {} :: {[string]: any}
	for _, attributeName in dreamFilterAttributeNames do
		local attributeValue = teleporterParent:GetAttribute(attributeName)
		if attributeValue then
			dreamFilters[attributeName] = attributeValue
		end
	end

	-- Switch dream
	DreamTeleportBindable:Fire("Initiate Teleport", player, dreamFilters)
end

local function setUpObject(folder: Folder)
	-- Set up connections
	local partConnections = {}
	taggedPartConnections[folder] = partConnections

	-- Go through children parts
	for _, object in folder:GetChildren() do
		if object:IsA("BasePart") then
			-- Set up connections
			local connections = {}
			partConnections[object] = connections

			-- Create connections
			table.insert(connections, object.Touched:Connect(function(otherPart: BasePart)
				onDreamTeleporterPartTouched(otherPart, folder)
			end))
		end
	end
end

local function cleanUpObject(folder: Folder)
	-- Disconnect and remove stored connections
	if taggedPartConnections[folder] then
		for part, partConnections in taggedPartConnections[folder] do
			for _, connection in partConnections do
				connection:Disconnect()
			end
			partConnections[part] = nil
		end
		taggedPartConnections[folder] = nil
	end
end

local function validateObject(object: Instance)
	return object:IsA("Folder")
end

---------- Module functions ----------

function Module.addInstance(object: Instance)
	-- Validate object
	if not validateObject(object) then
		return
	end

	-- Validate unique
	if taggedPartConnections[object] then
		return
	end

	-- Set up object
	setUpObject(object)
end

function Module.removeInstance(object: Instance)
	-- Validate object
	if not validateObject(object) then
		return
	end

	-- Clean up object
	cleanUpObject(object)
end

---------- Return module ----------
return Module
