--!strict
-- Server Map Controller Script

---------- Validate container ----------
-- Validate the script's container before running any code

-- For some server scripts
if not script:FindFirstAncestorWhichIsA("ServerScriptService") then
	return
end

---------- Services ----------

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = script.Parent.Parent.Parent:FindFirstChild("ReplicatedStorage") or game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

---------- Imports ----------

local PieMapKitModules = ReplicatedStorage:WaitForChild("PieMapKitModules")
require(PieMapKitModules.MapObjects)

---------- Types ----------

---------- Instances ----------

local PieMapKitEvents = ReplicatedStorage:WaitForChild("PieMapKitEvents")
local LoadDreamRemote = PieMapKitEvents.LoadDreamRemote
local LightingBindable = PieMapKitEvents.LightingBindable

local DefaultDreamValue: ObjectValue = workspace:FindFirstChild("DefaultDreamValue", true)
local DefaultDream = DefaultDreamValue.Value


---------- Variables ----------

local mapTagName = "HikeMap"

local storedDreamFolders: {Instance} = {}

local savedMapFolder: {[Instance]: Folder} = {}

local activeClientDreamMapFolder: {[Instance]: Instance} = {}

---------- Local functions ----------
-- Define general functions here

local function getMapFolder(dreamFolder: Instance)
	for _, object in dreamFolder:GetChildren() do
		if object:HasTag(mapTagName) then
			return object
		end
	end
	return nil
end

local function loadDream(dreamFolder: Instance)
	-- Validate map
	local mapFolder = getMapFolder(dreamFolder)
	if not mapFolder then
		return
	end

	-- Load dream
	dreamFolder.Parent = workspace

	if dreamFolder:GetAttribute("IsClientMap") then
		-- Load dream on client
		LoadDreamRemote:FireAllClients("LoadClientDream", dreamFolder, mapFolder)
		activeClientDreamMapFolder[dreamFolder] = mapFolder

		-- Remove map from server
		savedMapFolder[dreamFolder] = mapFolder
		mapFolder.Parent = ReplicatedStorage
	end

	-- Load lighting
	LightingBindable:Fire("LoadLighting", dreamFolder)
end

local function unloadDream(dreamFolder: Instance)
	-- Unload dream on client
	LoadDreamRemote:FireAllClients("UnloadDream", dreamFolder)
	activeClientDreamMapFolder[dreamFolder] = nil

	-- Move the dream to storage
	dreamFolder.Parent = ServerStorage

	-- Move map if saved
	if savedMapFolder[dreamFolder] then
		savedMapFolder[dreamFolder].Parent = dreamFolder
		savedMapFolder[dreamFolder] = nil
	end
end

---------- Event functions ----------
-- Functions that are directly connected by events or signals

local function onMapAdded(map: Folder)
	-- Validate dream
	local dreamFolder = map.Parent
	if not (dreamFolder and dreamFolder:GetAttribute("DreamDifficulty")) then
		return
	end

	-- Save dream
	table.insert(storedDreamFolders, dreamFolder)

	-- Load or unload dream
	if dreamFolder == DefaultDream then
		loadDream(dreamFolder)
	else
		unloadDream(dreamFolder)
	end
end

local function onPlayerAdded(player: Player)
	for dreamFolder, mapFolder in activeClientDreamMapFolder do
		-- Validate map folder
		if not mapFolder then
			return
		end

		-- Load dream on client
		LoadDreamRemote:FireAllClients("LoadClientDream", dreamFolder, mapFolder)
	end
end

local function allPlayerEvents()
	local players = Players:GetPlayers()
	task.defer(function()
		for _, player in players do
			onPlayerAdded(player)
		end
	end)
	Players.PlayerAdded:Connect(onPlayerAdded)
end

---------- Set up function ----------
local function initSetUp()
	-- Tags
	local tagged = CollectionService:GetTagged(mapTagName)
	task.defer(function()
		for _, object in tagged do
			onMapAdded(object)
		end
	end)
	CollectionService:GetInstanceAddedSignal(mapTagName):Connect(onMapAdded)
	CollectionService:GetInstanceRemovedSignal(mapTagName):Connect(onMapAdded)

	-- Players
	allPlayerEvents()
end

---------- Calling / connecting functions ----------
-- Connect functions to events and signals, then call set up functions

initSetUp()
