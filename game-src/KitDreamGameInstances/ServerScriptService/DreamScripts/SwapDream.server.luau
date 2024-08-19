--!strict
-- Swap Dream Script

---------- Validate container ----------
-- Validate the script's container before running any code

-- For some server scripts
if not script:FindFirstAncestorWhichIsA("ServerScriptService") then
	return
end

---------- Services ----------

local Players = game:GetService("Players")
local ReplicatedStorage = script.Parent.Parent.Parent:FindFirstChild("ReplicatedStorage") or game:GetService("ReplicatedStorage")
local ServerStorage = script.Parent.Parent.Parent:FindFirstChild("ServerStorage") or game:GetService("ServerStorage")

---------- Imports ----------

local DreamServerModules = ServerStorage.DreamServerModules
local FilterDreams = require(DreamServerModules.FilterDreams)
local MovePlayers = require(DreamServerModules.MovePlayers)

local PieMapKitModules = ReplicatedStorage.PieMapKitModules
local DreamMaps = require(PieMapKitModules.DreamMaps)

---------- Instances ----------

local DreamEvents = ReplicatedStorage.DreamEvents
local DreamItemBindable = DreamEvents.DreamItemBindable
local DreamTeleportBindable = DreamEvents.DreamTeleportBindable
local DreamTeleportRemote = DreamEvents.DreamTeleportRemote
local DreamVoteRemote = DreamEvents.DreamVoteRemote

local PieMapKitEvents = ReplicatedStorage.PieMapKitEvents
local LoadDreamBindable = PieMapKitEvents.LoadDreamBindable

local DefaultDreamValue: ObjectValue = workspace:FindFirstChild("_DefaultDreamValue", true)
local DefaultDream = DefaultDreamValue.Value :: Folder

---------- Types ----------

type DreamInfo = FilterDreams.DreamInfo

---------- Variables ----------

local currentDreamFolder: Folder
local dreamStorage = {} :: {DreamInfo}

local votingPromptDecisions: {{string}}
local votingPromptMaximumTimeSeconds = 10
local promptSwapFailCooldownSeconds = 50

local dreamSwapWaitTimeSeconds = 2
local dreamSwapRemoveDreamTimeSeconds = 1
local dreamSwapLoadDreamTimeSeconds = 2

local visitedDreamNames: {string} = {}

local promptSwapThrottle = false
local swapDreamThrottle = false

---------- Local functions ----------

local function startVotingPrompt(targetDreamInfo: DreamInfo)
	DreamVoteRemote:FireAllClients("Start Voting Prompt", targetDreamInfo.Name)
end

local function stopVotingPrompt()
	DreamVoteRemote:FireAllClients("Stop Voting Prompt")
end

local function promptSwapDream(targetDreamInfo: DreamInfo): boolean
	-- Validate swapping state
	if swapDreamThrottle then
		return false
	end

	-- Check throttle
	if promptSwapThrottle then
		return false
	end
	promptSwapThrottle = true

	-- Get players present at the start of the vote
	local votingPlayerNames: {string} = {}
	for _, player in Players:GetPlayers() do
		table.insert(votingPlayerNames, player.Name)
	end

	-- Start voting prompt
	votingPromptDecisions = {{}, {}}
	startVotingPrompt(targetDreamInfo)

	-- Voting procedure
	local voteStartTime = os.clock()
	local previousCountdownNumber = 0
	while true do
		-- Check elapsed time
		local voteElapsedTimeSeconds = os.clock() - voteStartTime
		if voteElapsedTimeSeconds > votingPromptMaximumTimeSeconds then
			break
		end

		-- Update timer if needed
		local currentCountdownNumber = math.ceil(votingPromptMaximumTimeSeconds - voteElapsedTimeSeconds)
		if currentCountdownNumber ~= previousCountdownNumber then
			previousCountdownNumber = currentCountdownNumber
			DreamVoteRemote:FireAllClients("Update Countdown Number", currentCountdownNumber)
		end

		-- Get players currently in the server
		local currentPlayerNames: {string} = {}
		for _, player in Players:GetPlayers() do
			table.insert(currentPlayerNames, player.Name)
		end

		-- Get valid players present since the beginning
		local validPlayerNames: {string} = {}
		for _, name in currentPlayerNames do
			if table.find(votingPlayerNames, name) then
				table.insert(validPlayerNames, name)
			end
		end

		-- Update the list of players present since the beginning
		do
			-- Find missing players
			local missingPlayerNames: {string} = {}
			for _, name in votingPlayerNames do
				if not table.find(currentPlayerNames, name) then
					table.insert(missingPlayerNames, name)
				end
			end

			-- Remove them from the table
			for _, name in missingPlayerNames do
				table.remove(votingPlayerNames, table.find(votingPlayerNames, name))
			end
		end

		-- Ensure only valid players in table
		for decision, playerNames in votingPromptDecisions do
			-- Find invalid players
			local invalidPlayerNames: {string} = {}
			for _, name in playerNames do
				if not table.find(validPlayerNames, name) then
					table.insert(invalidPlayerNames, name)
				end
			end

			-- Remove them from decisions table
			for _, name in invalidPlayerNames do
				table.remove(playerNames, table.find(playerNames, name))
			end
		end

		-- Check vote result
		local playerCount = #validPlayerNames
		if (#votingPromptDecisions[1] == playerCount) or (#votingPromptDecisions[2] == playerCount) then
			break
		end

		-- Prevent loop running again in the same frame
		task.wait(0.03)
	end

	-- Stop voting prompt
	stopVotingPrompt()

	-- Voting result
	local willSwapDream = true
	if #votingPromptDecisions[1] <= #votingPromptDecisions[2] then
		willSwapDream = false
	end

	-- Revert throttle
	local cooldownTimeSeconds: number
	if willSwapDream then
		cooldownTimeSeconds = dreamSwapWaitTimeSeconds + dreamSwapRemoveDreamTimeSeconds + dreamSwapLoadDreamTimeSeconds
	else
		cooldownTimeSeconds = promptSwapFailCooldownSeconds
	end

	task.delay(cooldownTimeSeconds, function()
		promptSwapThrottle = false
	end)

	return willSwapDream
end

local function getSwapTargetLocation(targetDreamFolder: Folder): CFrame
	-- Get swap spawns
	local dreamSwapSpawn = targetDreamFolder:FindFirstChild("DreamSwapSpawn") :: Folder
	local spawnParts: {BasePart} = {}
	for _, object in dreamSwapSpawn:GetChildren() do
		if object:IsA("BasePart") then
			table.insert(spawnParts, object)
		end
	end

	-- Get spawn CFrame
	local targetCFrame = CFrame.new()
	if #spawnParts > 0 then
		local targetSpawnPart = spawnParts[Random.new():NextInteger(1, #spawnParts)]
		targetCFrame = targetSpawnPart.CFrame
	end
	return targetCFrame
end

local function showTeleportMessage(message: string)
	DreamTeleportRemote:FireAllClients("Show Teleport Message", message)
end

local function hideTeleportMessage()
	DreamTeleportRemote:FireAllClients("Hide Teleport Message")
end

local function loadDreamItems(dreamName: string)
	DreamItemBindable:Fire("Load Dream Item", dreamName)
end

local function loadDream(dreamFolder: Instance)
	LoadDreamBindable:Fire("LoadDream", dreamFolder)
end

local function unloadDream(dreamFolder: Instance)
	LoadDreamBindable:Fire("UnloadDream", dreamFolder)
end

local function swapDream(targetDreamFolder: Folder, targetCFrame: CFrame?)
	-- Validate target dream
	if currentDreamFolder == targetDreamFolder then
		return
	end

	-- Check throttle
	if swapDreamThrottle then
		return
	end
	swapDreamThrottle = true

	-- Get target location
	if not targetCFrame then
		targetCFrame = getSwapTargetLocation(targetDreamFolder)
	end

	-- Propel players to target location
	if targetCFrame then	
		MovePlayers.propelAllPlayersTo(targetCFrame)
		task.delay(1, function()
			MovePlayers.teleportAllPlayersTo(targetCFrame)
		end)
	end

	-- Show teleport message
	showTeleportMessage("Sending you to " .. targetDreamFolder.Name)

	----- Swap dream sequence -----
	-- Wait
	local swapStartTime = os.clock()
	local swapTimeSeconds = dreamSwapWaitTimeSeconds
	task.wait(swapTimeSeconds - (os.clock() - swapStartTime))

	-- Unload dream
	unloadDream(currentDreamFolder)
	swapTimeSeconds += dreamSwapRemoveDreamTimeSeconds
	task.wait(swapTimeSeconds - (os.clock() - swapStartTime))

	-- Load dream
	loadDream(targetDreamFolder)
	currentDreamFolder = targetDreamFolder
	-- Load items
	loadDreamItems(targetDreamFolder.Name)
	swapTimeSeconds += dreamSwapLoadDreamTimeSeconds
	task.wait(swapTimeSeconds - (os.clock() - swapStartTime))

	-- Hide teleport message
	hideTeleportMessage()

	-- Stop propelling
	MovePlayers.stopPropellingPlayers()
	if targetCFrame then
		task.defer(function()
			MovePlayers.teleportAllPlayersTo(targetCFrame)
		end)
	end

	-- Revert throttle
	task.defer(function()
		task.wait(1.0)
		swapDreamThrottle = false
	end)
end

local function onInitiateTeleport(player: Player, dreamFilters: {[string]: any})
	-- Ensure no existing teleport sequence
	if promptSwapThrottle or swapDreamThrottle then
		return
	end

	-- Get the target dreams
	local initialTargetDreams = FilterDreams.getFilteredDreamsTable(dreamStorage, dreamFilters)
	if #initialTargetDreams == 0 then
		return
	end

	-- Filter out repeated dreams
	local filteredTargetDreams: {DreamInfo} = {}
	for _, dreamInfo in initialTargetDreams do
		if table.find(visitedDreamNames, dreamInfo.Name) then
			continue
		end
		table.insert(filteredTargetDreams, dreamInfo)
	end

	-- Unfilter if empty
	if #filteredTargetDreams == 0 then
		-- Remove target dreams from visited dreams
		for _, dreamInfo in initialTargetDreams do
			table.remove(visitedDreamNames, table.find(visitedDreamNames, dreamInfo.Name))
		end
		filteredTargetDreams = initialTargetDreams
	end

	-- Pick a target dream
	-- TODO: a feature for optional spawn positions
	local targetDream = filteredTargetDreams[Random.new():NextInteger(1, #filteredTargetDreams)]
	local targetDreamFolder =  targetDream.Folder

	-- Initiate prompt for teleport
	if promptSwapDream(targetDream) then
		swapDream(targetDreamFolder)
		table.insert(visitedDreamNames, targetDream.Name)
	end
end

local function onVotingPromptDecision(player: Player, playerDecision: number)
	-- Validate voting
	if not promptSwapThrottle then
		return
	end

	-- Validate decisions
	if not (playerDecision and typeof(playerDecision) == "number") then
		return
	end
	if not (#votingPromptDecisions == 2 and votingPromptDecisions[playerDecision]) then
		return
	end

	-- Remove player from decisions table
	local playerName = player.Name
	for decision, names in votingPromptDecisions do
		if table.find(names, playerName) then
			table.remove(names, table.find(names, playerName))
		end
	end

	-- Add player to their decision table
	if votingPromptDecisions[playerDecision] then
		table.insert(votingPromptDecisions[playerDecision], playerName)
	end

	-- Update vote count in all clients
	DreamVoteRemote:FireAllClients("Update Vote Count", #votingPromptDecisions[1], #votingPromptDecisions[2])
end

local function onDreamAddedEvent(dreamFolder: Instance)
	-- Validate dream
	if not (dreamFolder:IsA("Folder") and dreamFolder:GetAttribute("DreamDifficulty")) then
		return
	end

	-- Create dream table
	local dreamTable = {} :: DreamInfo
	dreamTable.Name = dreamFolder.Name
	dreamTable.Difficulty = dreamFolder:GetAttribute("DreamDifficulty")
	dreamTable.Folder = dreamFolder

	-- Store dream table
	table.insert(dreamStorage, dreamTable)
end

local function setUpDreamStorage()
	-- Dream maps
	local dreams = DreamMaps.getAllDreams()
	task.defer(function()
		for _, dreamFolder in dreams do
			onDreamAddedEvent(dreamFolder)
		end
	end)
	DreamMaps.dreamAdded.Event:Connect(onDreamAddedEvent)

	-- Set current dream
	currentDreamFolder = DefaultDream
	loadDream(currentDreamFolder)
end

---------- Event functions ----------

local function onDreamTeleportBindableEvent(mode: string, ...)
	if mode == "Initiate Teleport" then
		onInitiateTeleport(...)
	end
end

local function onDreamVoteServerEvent(player: Player, mode: string, ...)
	if mode == "Voting Prompt Decision" then
		onVotingPromptDecision(player, ...)
	end
end

---------- Calling / connecting functions ----------
DreamTeleportBindable.Event:Connect(onDreamTeleportBindableEvent)
DreamVoteRemote.OnServerEvent:Connect(onDreamVoteServerEvent)
task.defer(setUpDreamStorage)
