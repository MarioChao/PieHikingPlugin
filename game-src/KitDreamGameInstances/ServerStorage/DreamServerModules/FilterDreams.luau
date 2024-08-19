--!strict
-- Filter Dreams Module

---------- Module ----------
local FilterDreams = {}

---------- Types ----------

export type DreamInfo = {Name: string, Difficulty: number, Folder: Folder}

---------- Variables ----------

local dreamFilterAttributeNames = {"FilterDreamDifficulty", "FilterDreamName"}

---------- Local functions ----------

local function filterDreamProperty(sourceTable: DreamInfo, filterName: string, filterValue: any): boolean
	-- Different properties have different ways of filtering
	if filterName == "FilterDreamDifficulty" then
		-- Filter difficulty in range
		local difficultyRange = filterValue :: NumberRange
		local dreamDifficulty = sourceTable.Difficulty
		if not (difficultyRange.Min <= dreamDifficulty and dreamDifficulty <= difficultyRange.Max) then
			return false
		end
	elseif filterName == "FilterDreamName" then
		-- Filter substring
		if not string.find(sourceTable.Name, filterValue, 1, true) then
			return false
		end
	end
	return true
end

---------- Module functions ----------

function FilterDreams.getFilteredDreamsTable(originalTable: {DreamInfo}, filterIncludeProperties: {[string]: any}): {DreamInfo}
	-- Validate filter names
	for filterName, _ in filterIncludeProperties do
		if not table.find(dreamFilterAttributeNames, filterName) then
			return {}
		end
	end

	-- Initialize table
	local filteredTable = {} :: {DreamInfo}

	-- Store successfully filtered dreams from originalTable
	for _, dreamInfo in originalTable do
		-- Check filter properties
		local filterSuccessful = true
		for filterName, filterValue in filterIncludeProperties do
			if not filterDreamProperty(dreamInfo, filterName, filterValue) then
				filterSuccessful = false
				break
			end
		end

		-- Add to table if successfully filtered
		if filterSuccessful then
			table.insert(filteredTable, dreamInfo)
		end
	end

	-- Return table
	return filteredTable
end

---------- Return module ----------
return FilterDreams
