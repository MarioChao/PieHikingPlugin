--!strict
-- Client Dream Vote Script

---------- Validate container ----------
-- Validate the script's container before running any code

-- For certain client scripts
if not script:FindFirstAncestorWhichIsA("PlayerScripts") then
	return
end

---------- Services ----------

local Players = game:GetService("Players")
local ReplicatedStorage = script.Parent.Parent.Parent:FindFirstChild("ReplicatedStorage") or game:GetService("ReplicatedStorage")

---------- Instances ----------

local DreamEvents = ReplicatedStorage:WaitForChild("DreamEvents")
local DreamVoteRemote = DreamEvents.DreamVoteRemote

local LocalPlayer = Players.LocalPlayer or Players:GetPropertyChangedSignal("LocalPlayer"):Wait() :: Player
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local DreamVoteScreenGui = PlayerGui:WaitForChild("DreamVoteScreenGui") :: ScreenGui
local VotePromptFrame = DreamVoteScreenGui:WaitForChild("VotePromptFrame") :: Frame
local YesButton = VotePromptFrame:WaitForChild("YesButton") :: TextButton
local NoButton = VotePromptFrame:WaitForChild("NoButton") :: TextButton
local TitleLabel = VotePromptFrame:WaitForChild("TitleLabel") :: TextLabel
local CountdownLabel = VotePromptFrame:WaitForChild("CountdownLabel") :: TextLabel
local VoteCountLabel = VotePromptFrame:WaitForChild("VoteCountLabel") :: TextLabel

---------- Variables ----------

local connections = {} :: {RBXScriptConnection}

local countdownNumberColorHex = Color3.fromRGB(48, 255, 0):ToHex()
local voteNumberColorHex = Color3.fromRGB(48, 255, 0):ToHex()

local startVotingPromptThrottle = false

---------- Local functions ----------

local function updateCountdown(currentNumber: number)
	local countdownPrefixString = `<font color="#000000">Countdown: </font>`
	local countdownNumberString = `<font color="#{countdownNumberColorHex}">{currentNumber}</font>`

	CountdownLabel.Text = countdownPrefixString .. countdownNumberString
end

local function updateVoteCount(yesVoteCount: number, noVoteCount: number)
	local yesVoteString = `<font color="#{voteNumberColorHex}">{yesVoteCount}</font>`
	local middleString = `<font color="#000000"> vs </font>`
	local noVoteString = `<font color="#{voteNumberColorHex}">{noVoteCount}</font>`

	VoteCountLabel.Text = yesVoteString .. middleString .. noVoteString
end

local function onYesButtonClicked()
	DreamVoteRemote:FireServer("Voting Prompt Decision", 1)
end

local function onNoButtonClicked()
	DreamVoteRemote:FireServer("Voting Prompt Decision", 2)
end

local function onStartVotingPrompt(targetDreamName: string)
	-- Check throttle
	if startVotingPromptThrottle then
		return
	end
	startVotingPromptThrottle = true

	-- Set up text
	TitleLabel.Text = "Vote for " .. targetDreamName
	updateCountdown(10)
	updateVoteCount(0, 0)

	-- Set up connections
	local connection = YesButton.MouseButton1Click:Connect(onYesButtonClicked)
	table.insert(connections, connection)

	connection = NoButton.MouseButton1Click:Connect(onNoButtonClicked)
	table.insert(connections, connection)

	-- Show gui
	DreamVoteScreenGui.Enabled = true

	-- Revert throttle
	startVotingPromptThrottle = false
end

local function onStopVotingPrompt()
	-- Hide gui
	DreamVoteScreenGui.Enabled = false

	-- Clean up connections
	for index, connection in connections do
		connection:Disconnect()
		connections[index] = nil
	end
end

local function onUpdateVoteCount(yesVoteCount: number, noVoteCount: number)
	updateVoteCount(yesVoteCount, noVoteCount)
end

local function onUpdateCountdownNumber(currentNumber: number)
	updateCountdown(currentNumber)
end

---------- Event functions ----------

local function onDreamTeleportClientEvent(mode: string, ...)
	if mode == "Start Voting Prompt" then
		onStartVotingPrompt(...)
	elseif mode == "Stop Voting Prompt" then
		onStopVotingPrompt()
	elseif mode == "Update Vote Count" then
		onUpdateVoteCount(...)
	elseif mode == "Update Countdown Number" then
		onUpdateCountdownNumber(...)
	end
end

---------- Calling / connecting functions ----------

DreamVoteRemote.OnClientEvent:Connect(onDreamTeleportClientEvent)
