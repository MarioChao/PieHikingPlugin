--!strict
-- Move Players Module

---------- Module ----------
local MovePlayers = {}

---------- Services ----------

local Players = game:GetService("Players")

---------- Instances ----------

local DefaultAlignPosition = script:WaitForChild("PropelAlignPosition")

---------- Variables ----------

local playerPropelAlignPositions = {} :: {AlignPosition}

---------- Module functions ----------

function MovePlayers.propelPlayerTo(player: Player, targetCFrame: CFrame)
	-- Validate humanoid root part
	local character = player.Character
	local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart") :: Part
	if not humanoidRootPart then
		return
	end

	-- Get attachment
	local attachment = humanoidRootPart:FindFirstChild("MovePlayerPropelAttachment") :: Attachment
	if not attachment then
		local newAttachment = Instance.new("Attachment")
		newAttachment.Name = "MovePlayerPropelAttachment"
		newAttachment.Parent = humanoidRootPart
		attachment = newAttachment
	end

	-- Get align position
	local alignPosition = humanoidRootPart:FindFirstChild("PropelAlignPosition") :: AlignPosition
	if not alignPosition then
		local newAlignPosition = DefaultAlignPosition:Clone()
		newAlignPosition.Parent = humanoidRootPart
		alignPosition = newAlignPosition
	end
	alignPosition.Attachment0 = attachment
	alignPosition.Position = targetCFrame.Position
	alignPosition.Enabled = true
	table.insert(playerPropelAlignPositions, alignPosition)
end

function MovePlayers.propelAllPlayersTo(targetCFrame: CFrame)
	-- Create alignPosition in all player humanoid root parts
	playerPropelAlignPositions = {}
	for _, player in Players:GetPlayers() do
		task.defer(function()
			MovePlayers.propelPlayerTo(player, targetCFrame)
		end)
	end
end

function MovePlayers.teleportPlayerTo(player: Player, targetCFrame: CFrame)
	-- Validate humanoid root part
	local character = player.Character
	local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart") :: Part
	if not (character and humanoidRootPart) then
		return
	end

	-- Teleport humanoid root part
	humanoidRootPart:PivotTo(targetCFrame)
end

function MovePlayers.teleportAllPlayersTo(targetCFrame: CFrame)
	-- Teleport all player humanoid root parts
	for _, player in Players:GetPlayers() do
		task.defer(function()
			MovePlayers.teleportPlayerTo(player, targetCFrame)
		end)
	end
end

function MovePlayers.stopPropellingPlayers()
	for _, alignPosition in playerPropelAlignPositions do
		alignPosition.Enabled = false
	end
end

---------- Return module ----------
return MovePlayers
