--!strict
-- Client Dream Teleport Script

---------- Validate container ----------
-- Validate the script's container before running any code

-- For certain client scripts
if not script:FindFirstAncestorWhichIsA("PlayerScripts") then
	return
end

---------- Services ----------

local Players = game:GetService("Players")
local ReplicatedStorage = script.Parent.Parent.Parent:FindFirstChild("ReplicatedStorage") or game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

---------- Instances ----------

local DreamEvents = ReplicatedStorage:WaitForChild("DreamEvents")
local DreamTeleportRemote = DreamEvents.DreamTeleportRemote

local LocalPlayer = Players.LocalPlayer or Players:GetPropertyChangedSignal("LocalPlayer"):Wait() :: Player
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local DreamTransitionScreenGui = PlayerGui:WaitForChild("DreamTransitionScreenGui") :: ScreenGui
local TransitionFrame = DreamTransitionScreenGui:WaitForChild("TransitionFrame") :: Frame
local TransitionTextLabel = DreamTransitionScreenGui:WaitForChild("TransitionTextLabel") :: TextLabel

---------- Variables ----------

local showTeleportMessageDebounce = false
local showingMessage = false

---------- Functions ----------

local function setGuiTransparency(transparency : number)
	-- Set transparency
	TransitionFrame.BackgroundTransparency = transparency
	TransitionTextLabel.TextTransparency = transparency
end

local function tweenGuiTransparency(tweenTime : number, transparency : number)
	-- Prepare variable
	local tweenInfo = TweenInfo.new(tweenTime)
	local tweens = {} :: {Tween}

	-- Create tweens
	local transitionFrameTween = TweenService:Create(TransitionFrame, tweenInfo, {["BackgroundTransparency"] = transparency})
	local transitionTextLabelTween = TweenService:Create(TransitionTextLabel, tweenInfo, {["TextTransparency"] = transparency})
	table.insert(tweens, transitionFrameTween)
	table.insert(tweens, transitionTextLabelTween)

	-- Play tweens
	for _, tween in tweens do
		tween:Play()
	end
end

local function onShowTeleportMessage(messageText : string)
	-- Validate
	if showingMessage then
		return
	end

	-- Check debounce
	if showTeleportMessageDebounce then
		return
	end
	showTeleportMessageDebounce = true

	-- Show gui
	setGuiTransparency(1)
	showingMessage = true
	DreamTransitionScreenGui.Enabled = true
	tweenGuiTransparency(1, 0)

	-- Loading text
	local trailingText = ""
	while showingMessage do
		TransitionTextLabel.Text = messageText .. trailingText
		task.wait(0.5)
		trailingText = if string.len(trailingText) >= 3 then "" else (trailingText .. ".")
	end

	-- Reset debounce
	showTeleportMessageDebounce = false
end

local function onHideTeleportMessage()
	-- Hide gui
	tweenGuiTransparency(1, 1)
	showingMessage = false
	task.delay(1, function()
		if not showingMessage then
			DreamTransitionScreenGui.Enabled = false
		end
	end)
end

---------- Event functions ----------

local function onDreamTeleportClientEvent(mode : string, ...)
	if mode == "Show Teleport Message" then
		onShowTeleportMessage(...)
	elseif mode == "Hide Teleport Message" then
		onHideTeleportMessage()
	end
end

---------- Calling / connecting functions ----------

DreamTeleportRemote.OnClientEvent:Connect(onDreamTeleportClientEvent)
