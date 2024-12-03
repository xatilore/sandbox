local shopItems = require(workspace.ShopItemsHandler)
local ds = game:GetService("DataStoreService")
local datastore = ds:GetDataStore("SFOTEDatastore") --get the datastore
local playerData = {
	["Money"] = 0;
	["TotalKills"] = 0;
	["Wins"] = 0;
	["Inventory"] = {
		["Skins"] = {};
		["Cosmetics"] = {};
	};
	["EquippedSkins"] = {};
	["Username"] = nil;
}
-- ^^^^^^ data dictionary for new players

local serverJoins = {}
local events = game.ReplicatedStorage.RemoteEvents::Folder
local buyEvent = events.ItemBought::RemoteEvent
local equipEvent = events.ItemEquipped::RemoteEvent
--- get shop events

local function checkItem(v, category, itemName) -- check if user owns an item from the shop
	local inventory = v:FindFirstChild("Inventory") -- inventory folder inside the player
	local categoryF = inventory:FindFirstChild(category) -- item type folder inside the inventory folder
	if categoryF == nil then
		return false
	end
	local check = categoryF:FindFirstChild(itemName)
	if check == nil then
		return false
	end
	-- returns true if none of the conditions are met, which means user owns the item.
end

local function equip(equipper, item, category, itemReplaced, equipCheck) -- function to equip item from the shop, used when the equip event is fired.
	local itemName = item.Name
	if checkItem(equipper, category, itemName) ~= false then -- uses the check item function, if they own then condition is met
		local inv = equipper:FindFirstChild("Inventory")::Folder
		for i,v in inv:GetDescendants() do
			if v.Name == "Equipped" and v.Value == itemReplaced then
				-- unequips shop items (skins) from the same sword
				v:Destroy()
			end
		end
		local value = inv:FindFirstChild(itemName, true)
		for ii,vv in equipCheck do
			if ii == itemReplaced and vv ~= {} or vv ~= "" then
				local equipped = Instance.new("StringValue", value)
				equipped.Name = "Equipped"
				equipped.Value = itemReplaced
				equipCheck[itemReplaced] = itemName
				equipEvent:FireClient(equipper)
				-- creates the equipped indicator, and it saves the equipped item in the player's data
			end
		end
	end
end

local function createItem(itemTable, folder) -- create the shop item's representation inside the player's inventory folder
	-- item table contains the information about the item, such as Name, Price, etc..
	local array = {}
	local ogValue = Instance.new("BoolValue", folder)
	ogValue.Name = itemTable["Name"] -- gets item's name
	for i,v in itemTable do
		table.insert(array, {Item = i; Value = v}) --puts the items inside an array
	end
	for i,v in array do
		for ii,vv in v do
			--print(vv)
			local value
			if vv == "SkinPath" then
				local source = itemTable[vv]
				value = Instance.new("ObjectValue", ogValue)
				value.Name = vv
				value.Value = source
			elseif vv == "ItemReplaced" then
				local source = itemTable[vv]
				value = Instance.new("StringValue", ogValue)
				value.Name = vv
				value.Value = source
			elseif vv == "ItemId" then
				local source = itemTable[vv]
				value = Instance.new("IntValue", ogValue)
				value.Name = vv
				value.Value = source
			elseif vv == "Price" then
				local source = itemTable[vv]
				value = Instance.new("IntValue", ogValue)
				value.Name = vv
				value.Value = source
			elseif itemTable[vv] and vv ~= "Image" and vv ~= "Pattern" and vv ~= "Name" then
				local source = itemTable[vv]
				value = Instance.new("StringValue", ogValue)
				value.Name = vv
				value.Value = source
			end
		end
	end
end

game.Players.PlayerAdded:Connect(function(player) -- when player joins, get data and create leaderstats values
	local folder = Instance.new("Folder", player)
	folder.Name = "ModeSpecific"
	local leaderstats = Instance.new("Folder", player)
	leaderstats.Name = "leaderstats"
	local moneyValue = Instance.new("IntValue", leaderstats)
	moneyValue.Name = "Money"
	local killValue = Instance.new("IntValue", leaderstats)
	killValue.Name = "Kills"
	local deathValue = Instance.new("IntValue", leaderstats)
	deathValue.Name = "Deaths"
	local killsTValue = Instance.new("IntValue", leaderstats)
	killsTValue.Name = "Total Kills"
	local winsValue = Instance.new("IntValue", leaderstats)
	winsValue.Name = "Wins"	
	local data = datastore:GetAsync(player.UserId) or playerData
	local username = game.Players:GetNameFromUserIdAsync(player.UserId)
	local inventory = data["Inventory"]
	if inventory == nil then
		data["Inventory"] = {}
		inventory = data["Inventory"]
		-- if new users join, this wouldn't be an issue, but for old players, to avoid problems of the script not finding an "Inventory" inside their
		-- data, register it, and make the inventory variable the new registered folder
		-- could be easily polished, will be for the future.
	end
	local inventoryF = Instance.new("Folder", player)
	inventoryF.Name = "Inventory"
	local equipCheck = data["EquippedItems"]
	if not equipCheck then
		data["EquippedItems"] = {}
		equipCheck = data["EquippedItems"]
		-- same reasons as the inventory
	end
	for i,v in game.ReplicatedStorage.StoredItems:GetChildren() do
		-- for each current available sword in the game, check if the player has a skin for it
		-- if the value isn't even there, create it and make it blank for the future
		if not equipCheck[v.Name] then
			equipCheck[v.Name] = ""
		end
	end
	local items = shopItems.getItems()
	-- with the help of a module script, get all information about shop items, such as skins, death noises..
	for i,v in items do
		local folder = Instance.new("Folder", inventoryF)
		folder.Name = i
		local check = inventory[i]
		if not check then
			inventory[i] = {}
			check = inventory[i]
			-- if the item's type isn't a folder inside the inventory folder, create it. (Example: 'Skins')
		end
		for ii,vv in check do -- for all categories
			for iii,vvv in items do -- find all shop items inside the categories obtained from the shop's module script
				if vvv[vv] then
					-- if any shop items are found inside the player's inventory data, create them as values
					createItem(vvv[vv], folder) -- call the function to properly represent the shop item, inside the inventory folder
				end
			end
		end
	end
	for i,v in equipCheck do
		if v ~= {} and v ~= "" then
			for ii,vv in inventoryF:GetDescendants() do
				if vv.Name == v then -- if the shop item is equipped inside the player's data, then make a value called equipped
					local itemInfo = items[vv.Parent.Name][v]
					local equipped = Instance.new("StringValue", vv)
					equipped.Name = "Equipped"
					equipped.Value = itemInfo.ItemReplaced
				end
			end
		end
	end
	data["Username"] = username -- for analytics, save the player's username inside their data
	table.insert(serverJoins, player.UserId) -- add the player's userId, inside the leaderboard array, to display them on the global leaderboard
	local loadedData = nil
	if data then -- player data was found, data will become the player's data
		loadedData = data
		moneyValue.Value = loadedData.Money
		winsValue.Value = loadedData.Wins
	else -- player data wasn't found, give them the default data dictionary found above
		loadedData = playerData
		datastore:SetAsync(player.UserId, loadedData)
	end
	local totalKills = loadedData.TotalKills
	killsTValue.Value = totalKills
	buyEvent.OnServerEvent:Connect(function(buyerPlayer, item, category) -- when player buys shop item, properly save it inside the player's data
		if buyerPlayer ~= player then
			return
		end
		local onsaleItems = shopItems.getShopItems()
		local onsaleCategory = onsaleItems[category]
		if not onsaleCategory then -- if the shop item given in the event wasn't actually available, return
			return
		end
		for i,v in onsaleCategory do
			local itemNameL = item.Name
			if v == itemNameL then
				continue
			end
			local itemI = items[category][itemNameL]
			local itemPrice = itemI.Price
			local itemName = itemI.Name
			if checkItem(buyerPlayer, category, itemName) == false then
				local leaderstats = buyerPlayer:FindFirstChild("leaderstats")
				local money = leaderstats:FindFirstChild("Money")
				local multiplier = 10 -- the shop currency is in gold, compared to money, its formula is (Money/10)
				if (money.Value/10) >= itemPrice then -- actually owns the amount of money necessary
					local categoryF = inventoryF:FindFirstChild(category) -- item type inside player's inventory folder
					if categoryF then -- for safety, if it is not found, do not remove any gold
						money.Value -= (itemPrice*multiplier)
						createItem(itemI, categoryF) -- shop item bought, register it
						print("Successfully bought", itemName)
					else
						error("No category folder!")
					end
					table.insert(inventory[category], itemName) -- save it inside the player's data
				end
			end
		end
	end)
	equipEvent.OnServerEvent:Connect(function(equipper, item, category, itemReplaced)
		if equipper == player then
			equip(equipper, item, category, itemReplaced, equipCheck) -- calls the equip function above
		end
	end)
	game.Players.PlayerRemoving:Connect(function(player2)
		if player == player2 then -- for safety, player leaving is the same player that joined
			loadedData.Money = moneyValue.Value -- money earned saved
			loadedData.TotalKills = killsTValue.Value -- total kills saved
			loadedData.Wins = winsValue.Value -- wins earned saved
			loadedData.Username = player2.Name -- to make sure, make the username player2's name.
			datastore:SetAsync(player.UserId, loadedData) -- SAVE the player's data
		end
	end)
end)

game:BindToClose(function() -- when server shuts down
	local playerDatabase = datastore:GetAsync("Players") or {} -- {} makes a new array if it was not found.
	for i,v in serverJoins do
		local exists = false
		for ii,vv in playerDatabase do
			if vv==v then -- player is already registered inside the global leaderboard's array
				exists = true
			end
		end	
		if exists == false then -- not registered
			table.insert(playerDatabase, v) -- register the player
		end
	end
	datastore:SetAsync("Players", playerDatabase) -- save the array
end)
