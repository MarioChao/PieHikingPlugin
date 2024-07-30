--!strict
-- Load Lighting Script

---------- Validate container ----------
-- Validate the script's container before running any code

-- For some server scripts
if not script:FindFirstAncestorWhichIsA("ServerScriptService") then
	return
end

---------- Services----------

local ReplicatedStorage = script.Parent.Parent.Parent.ReplicatedStorage or game:GetService("ReplicatedStorage")

---------- Imports ----------

local LightingModules = ReplicatedStorage:FindFirstChild("LightingModules")
local LightingTypes = require(LightingModules.Types)
local UpdateLighting = require(LightingModules.UpdateLighting)

---------- Instances ----------

local DefaultDreamValue: ObjectValue = workspace:FindFirstChild("DefaultDreamValue", true)
local DefaultDream = DefaultDreamValue.Value
local DefaultLightingConfig: LightingTypes.LightingConfigType = require(DefaultDream:FindFirstChild("LightingConfig"))

---------- Local functions ----------

local function loadDefaultLighting()
	print(`Loading {DefaultDream.Name}'s lighting configurations`)
	UpdateLighting.applyLightingConfig(DefaultLightingConfig)
end

---------- Calling / connecting functions ----------

loadDefaultLighting()
