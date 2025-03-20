--Services
local playerService = game:GetService("Players")
local replicatedStorage = game:GetService("ReplicatedStorage")
local serverScriptService = game:GetService("ServerScriptService")
local datastoreService = game:GetService("DataStoreService")

--BaseModules & CoreModules
local baseModules = replicatedStorage.Modules
local mapModule = require(baseModules.MapsHandler)
local badgeModule = require(baseModules.BadgesHandler)
local shopModule = require(baseModules.ShopItemsHandler)
local shopCategories = shopModule.getItems()
local existingModes = mapModule.getModes()

--Variables
local curDatastore = datastoreService:GetDataStore("GameDatastore")
local module = {}
local database = {}

--Default data given to new players.
local baseData = {
	["Money"] = 0;
	["TotalKills"] = 0;
	["Wins"] = 0;
	["Inventory"] = {};
	["Level"] = 0;
	["XP"] = 0;
	["PlayedRounds"] = 0;
	["BoughtItems"] = 0;
	["GivenItems"] = 0;
	["TotalJoins"] = 0;
	["SpentCash"] = 0;
	["RedeemedCodes"] = {};
	["EquippedSkins"] = {};
	["EquippedCard"] = nil;
	["ModeWins"] = {};
	["EquippedDeathSound"] = nil;
	["Username"] = nil; --To identify the player easier.
}

--Default values to be shown to the player through the 'leaderstats' system.
local values = { "Money", "Kills", "Deaths", "Total Kills", "Wins", "Level", "XP", "Killstreak", "Highest Killstreak" }

--Setup function for joining players.
function module.setupData(player:Player)
	local fetchedData	
	local success, err = pcall(function()
		fetchedData = curDatastore:GetAsync(player.UserId)
	end)
	
	if not success then
		player:Kick("Error whilst loading player data, please rejoin.")
		warn(player.Name, "could not fetch their data.")
	end
	
	--Assign default data to new players.
	if not fetchedData then
		fetchedData = baseData
	end

	--Add missing properties to player data.
	for i,v in pairs(baseData) do
		if fetchedData[i] == nil then
			fetchedData[i] = v
		end
	end

	--Dynamic datastore properties.
	for i,v in existingModes do
		fetchedData["ModeWins"][i] = fetchedData["ModeWins"][i] or 0
	end
	for i,v in shopCategories do
		fetchedData["Inventory"][i] = fetchedData["Inventory"][i] or {}
	end

	--Display shown values through a leaderstats system.
	local leaderstats = Instance.new("Folder", player)
	leaderstats.Name = "leaderstats"
	for i,v in values do
		local instance = Instance.new("IntValue", leaderstats)
		instance.Name = v
		instance.Value = fetchedData[v] or 0
	end
	
	--Store player data to the module's database.
	database[player.UserId] = fetchedData
end

--Function that gets called when a player leaves.
function module.saveData(player:Player)
	local leaderstats = player:FindFirstChild("leaderstats")
	local fetchData = database[player.UserId] or baseData --Takes from the module's database.
	
	--Take values and appoint them to player data.
	for i,v in leaderstats:GetChildren() do
		local value = fetchData[v.Name]
		if value then
			fetchData[v.Name] = v.Value
		end
	end
	
	--Protected call to save player data.
	local success, err = pcall(function()
		fetchData = curDatastore:SetAsync(player.UserId, fetchData)
	end)
	
	return success
end

--Function to edit player data.
function module.modifyData(player:Player, index, value)
	local leaderstats = player:FindFirstChild("leaderstats")
	local fetchData = database[player.UserId] or baseData --Takes from the module's database.
	
	--Update property inside player data.
	local foundIndex = fetchData[index]
	if foundIndex then
		fetchData[index] = value
	end
	
	--Update physical value if it exists.
	local physicalValue = leaderstats:FindFirstChild(index)::ValueBase
	if physicalValue then
		physicalValue.Value = value
	end
end

--Function to get player data.
function module.fetchData(player:Player, arg)
	local fetchedData = database[player.UserId][arg] or database[player.UserId] or baseData
	return fetchedData
end

return module
