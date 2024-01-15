local osclock = os.clock()
if not game:IsLoaded() then
    game.Loaded:Wait()
end
task.wait(15)
game.Players.LocalPlayer.PlayerScripts.Scripts.Core["Idle Tracking"].Enabled = false
game:GetService("RunService"):Set3dRenderingEnabled(false)
local Booths_Broadcast = game:GetService("ReplicatedStorage").Network:WaitForChild("Booths_Broadcast")
local Players = game:GetService('Players')
local getPlayers = Players:GetPlayers()
local PlayerInServer = #getPlayers
local http = game:GetService("HttpService")
local ts = game:GetService("TeleportService")
local rs = game:GetService("ReplicatedStorage")
local snipeNormal, signal
local Library = require(rs:WaitForChild("Library"))
if snipeNormalPets == nil then
    snipeNormalPets = false
end
local vu = game:GetService("VirtualUser")
Players.LocalPlayer.Idled:connect(function()
   vu:Button2Down(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
   task.wait(1)
   vu:Button2Up(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
end)
local function processListingInfo(uid, gems, item, version, shiny, amount, boughtFrom, boughtStatus, class, failMessage, snipeNormal)
    local gemamount = Players.LocalPlayer.leaderstats["💎 Diamonds"].Value
    local snipeMessage ="||".. Players.LocalPlayer.Name .. "||"
    local weburl, webContent, webcolor, webStatus
    local versionVal = { [1] = "Golden ", [2] = "Rainbow " }
    local versionStr = versionVal[version] or (version == nil and "")
    local mention = ( class == "Pet" and (Library.Directory.Pets[item].huge or Library.Directory.Pets[item].titanic)) and "<@" .. userid .. ">" or ""
    
    if boughtStatus then
        webcolor = tonumber(0x00ff00)
        snipeMessage = snipeMessage .. " ✅ ".. amount .."x "
        webContent = mention
        webStatus = "Success!"
        
        if (class == "Pet" and Library.Directory.Pets[item].huge) then
            weburl = hugePetWebhook
        else
            weburl = webhook
            if snipeNormal == true then
                weburl = normalwebhook
                snipeNormal = false
            end
        end
    else
        webcolor = tonumber(0xff0000)
        weburl = webhookFail
        webStatus = failMessage
        snipeMessage = snipeMessage .. " ⛔️ ".. amount .."x "
        
        if snipeNormal == true then
            snipeNormal = false
        end
    end
    
    snipeMessage = snipeMessage .. "**" .. versionStr
    
    if shiny then
        snipeMessage = snipeMessage .. " Shiny "
    end
    
    snipeMessage = snipeMessage .. item .. "**"

    local message1 = {
        ['content'] = webContent,
        ['embeds'] = {
            {
                ["author"] = {
                    ["name"] = "🌟2FA's Boothsniper🌟",
                    ["icon_url"] = "https://i.imgur.com/K5dxOcu.jpg",
                },
                ['title'] = snipeMessage,
                ["color"] = webcolor,
                ["timestamp"] = DateTime.now():ToIsoDate(),
                ["thumbnail"] = {
                    ["url"] = "https://i.imgur.com/qgTTLSX.png"
                },
                ['fields'] = {
                    {
                        ['name'] = "🛒__*PURCHASE INFO:*__🛒",
                        ['value'] = "\n",
                    },
                    {
                        ['name'] = "🤑PRICE:",
                        ['value'] = string.format("%s", tostring(gems):reverse():gsub("%d%d%d", "%1,"):reverse()),
                    },
                    {
                        ['name'] = "📦AMOUNT:",
                        ['value'] = amount .. "x",
                    },
                    {
                        ['name'] = "🤡 BOUGHT FROM:",
                        ['value'] = "||"..tostring(boughtFrom).."||",
                    },
                    {
                        ['name'] = "__*PETID:*__",
                        ['value'] = "||"..tostring(uid).."||",
                    },
                    {
                        ['name'] = "👥__*USER INFO:*__👥",
                        ['value'] = "\n",
                    },
                    {
                        ['name'] = "👤USER:",
                        ['value'] = "||"..game.Players.LocalPlayer.Name.."||",
                    },
                    {
                        ['name'] = "💎GEM'S LEFT:",
                        ['value'] = string.format("%s", tostring(gemamount):reverse():gsub("%d%d%d", "%1,"):reverse()),
                    },
                    {
                        ['name'] = "🎯__*SNIPER INFO*__🎯",
                        ['value'] = "\n",
                    },
                    {
                        ['name'] = "⌛STATUS:",
                        ['value'] = webStatus,
                    },
                    {
                        ['name'] = "🚀PING:",
                        ['value'] = math.round(Players.LocalPlayer:GetNetworkPing() * 2000) .. "ms",
                    }
                },
                ["footer"] = {
                    ["icon_url"] = "https://i.imgur.com/K5dxOcu.jpg", -- optional
                    ["text"] = "©️BIG GAMES"
                }
            },
        }
    }
    
    local jsonMessage = http:JSONEncode(message1)
    local success, webMessage = pcall(function()
        http:PostAsync(weburl, jsonMessage)
    end)

    if success == false then
        local response = request({
            Url = weburl,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = jsonMessage
        })
    end
end

local function tryPurchase(uid, gems, item, version, shiny, amount, username, class, playerid, buytimestamp, listTimestamp, snipeNormal)
    signal = game:GetService("RunService").Heartbeat:Connect(function()
	if buytimestamp < workspace:GetServerTimeNow() then
	    signal:Disconnect()
	    signal = nil
        end
    end)
    repeat task.wait() until signal == nil
    local boughtPet, boughtMessage = rs.Network.Booths_RequestPurchase:InvokeServer(playerid, uid)
    processListingInfo(uid, gems, item, version, shiny, amount, username, boughtPet, class, boughtMessage, snipeNormal)
end

Booths_Broadcast.OnClientEvent:Connect(function(username, message)
        if type(message) == "table" then
            local highestTimestamp = -math.huge -- Initialize with the smallest possible number
            local key = nil
            local listing = nil
            for v, value in pairs(message["Listings"] or {}) do
                if type(value) == "table" and value["ItemData"] and value["ItemData"]["data"] then
                    local timestamp = value["Timestamp"]
                    if timestamp > highestTimestamp then
                        highestTimestamp = timestamp
                        key = v
                        listing = value
                    end
                end
            end
            if listing then
                local buytimestamp = listing["ReadyTimestamp"]
                local listTimestamp = listing["Timestamp"]
                local data = listing["ItemData"]["data"]
                local gems = tonumber(listing["DiamondCost"])
                local uid = key
                local item = data["id"]
                local version = data["pt"]
                local shiny = data["sh"]
                local amount = tonumber(data["_am"]) or 1
                local playerid = message['PlayerID']
                local class = tostring(listing["ItemData"]["class"])
                local unitGems = gems/amount
		snipeNormal = false
				
if string.find(item, "Huge") and unitGems <= 2000000 then
                    coroutine.wrap(tryPurchase)(uid, gems, item, version, shiny, amount, username, class, playerid, buytimestamp, listTimestamp, snipeNormal)
                    return
                elseif snipeNormalPets == true and gems == 1 then
                        snipeNormal = true
                        coroutine.wrap(tryPurchase)(uid, gems, item, version, shiny, amount, username, class, playerid, buytimestamp, listTimestamp,   snipeNormal)
                        return
                elseif class == "Pet" then
                    local type = Library.Directory.Pets[item]
                    if type.exclusiveLevel and unitGems <= 90000 and item ~= "Banana" and item ~= "Coin" then
                        coroutine.wrap(tryPurchase)(uid, gems, item, version, shiny, amount, username, class, playerid, buytimestamp, listTimestamp, snipeNormal)
                        return
                    elseif type.titanic and unitGems <= 10000000 then
                        coroutine.wrap(tryPurchase)(uid, gems, item, version, shiny, amount, username, class, playerid, buytimestamp, listTimestamp, snipeNormal)
                        return
                    elseif type.huge and unitGems <= 5000000 then
                        coroutine.wrap(tryPurchase)(uid, gems, item, version, shiny, amount, username, class, playerid, buytimestamp, listTimestamp, snipeNormal)
                        return
                    end
    
                    -- Presents and Eggs
                elseif (item == "Titanic Christmas Present" or string.find(item, "2024 New Year")) and unitGems <= 200000 then
                    coroutine.wrap(tryPurchase)(uid, gems, item, version, shiny, amount, username, class, playerid, buytimestamp, listTimestamp, snipeNormal)
                    return
                elseif class == "Egg" and unitGems <= 500000 then
                    coroutine.wrap(tryPurchase)(uid, gems, item, version, shiny, amount, username, class, playerid, buytimestamp, listTimestamp, snipeNormal)
                    return
    
                    -- Items
                elseif item == "Crystal Key" and unitGems <= 30000 then
                    coroutine.wrap(tryPurchase)(uid, gems, item, version, shiny, amount, username, class, playerid, buytimestamp, listTimestamp, snipeNormal)
                    return
                elseif item == "Crystal Key Lower Half" and unitGems <= 3500 then
                    coroutine.wrap(tryPurchase)(uid, gems, item, version, shiny, amount, username, class, playerid, buytimestamp, listTimestamp, snipeNormal)
                    return
                elseif item == "Crystal Key Upper Half" and unitGems <= 31000 then
                    coroutine.wrap(tryPurchase)(uid, gems, item, version, shiny, amount, username, class, playerid, buytimestamp, listTimestamp, snipeNormal)
                    return
                elseif item == "Spinny Wheel Ticket" and unitGems <= 10000 then
                    coroutine.wrap(tryPurchase)(uid, gems, item, version, shiny, amount, username, class, playerid, buytimestamp, listTimestamp, snipeNormal)
                    return
                elseif item == "Booth Slot Voucher" and unitGems <= 50000 then
                    coroutine.wrap(tryPurchase)(uid, gems, item, version, shiny, amount, username, class, playerid, buytimestamp, listTimestamp, snipeNormal)
                    return
                elseif string.find(item, "Charm") and unitGems <= 100000 and item ~= "Agility Charm" and item ~= "Coin Charm" and item ~= "Bonus Charm" and item ~= "Charm Stone" then
                    coroutine.wrap(tryPurchase)(uid, gems, item, version, shiny, amount, username, class, playerid, buytimestamp, listTimestamp, snipeNormal)
                    return
    
                    -- Enchants    
                elseif class == "Enchant" and unitGems <= 30000 then
                    if item == "Chest Breaker" and unitGems <= 10000000 then
                        coroutine.wrap(tryPurchase)(uid, gems, item, version, shiny, amount, username, class, playerid, buytimestamp, listTimestamp, snipeNormal)
                        return
                    elseif string.find(item, "Chest Mimic") and unitGems <= 6000000 then
                        coroutine.wrap(tryPurchase)(uid, gems, item, version, shiny, amount, username, class, playerid, buytimestamp, listTimestamp, snipeNormal)
                        return
                    elseif item == "Huge Hunter" and unitGems <= 1500000 then
                        coroutine.wrap(tryPurchase)(uid, gems, item, version, shiny, amount, username, class, playerid, buytimestamp, listTimestamp, snipeNormal)
                        return
                    elseif item == "Starfall" and unitGems <= 2000000 then
                        coroutine.wrap(tryPurchase)(uid, gems, item, version, shiny, amount, username, class, playerid, buytimestamp, listTimestamp, snipeNormal)
                        return
                    elseif item == "Super Lightning" and unitGems <= 1500000 then
                        coroutine.wrap(tryPurchase)(uid, gems, item, version, shiny, amount, username, class, playerid, buytimestamp, listTimestamp, snipeNormal)
                        return
                    elseif item == "Lucky Block" and unitGems <= 1000000 then
                        coroutine.wrap(tryPurchase)(uid, gems, item, version, shiny, amount, username, class, playerid, buytimestamp, listTimestamp, snipeNormal)
                        return
                    elseif item == "Fortune" and unitGems <= 250000 then
                        coroutine.wrap(tryPurchase)(uid, gems, item, version, shiny, amount, username, class, playerid, buytimestamp, listTimestamp, snipeNormal)
                        return
                    elseif item == "Massive Comet" and unitGems <= 1500000 then
                        coroutine.wrap(tryPurchase)(uid, gems, item, version, shiny, amount, username, class, playerid, buytimestamp, listTimestamp, snipeNormal)
                        return
                    elseif item == "Shiny Hunter" and unitGems <= 300000 then
                        coroutine.wrap(tryPurchase)(uid, gems, item, version, shiny, amount, username, class, playerid, buytimestamp, listTimestamp, snipeNormal)
                        return
                    elseif item == "Party Time" and unitGems <= 45000 then
                        coroutine.wrap(tryPurchase)(uid, gems, item, version, shiny, amount, username, class, playerid, buytimestamp, listTimestamp, snipeNormal)
                        return
                    elseif item == "Exotic Pet" and unitGems <= 25000 then
                        coroutine.wrap(tryPurchase)(uid, gems, item, version, shiny, amount, username, class, playerid, buytimestamp, listTimestamp, snipeNormal)
                        return
                    elseif item == "Diamond Chest Mimic" and unitGems <= 4000000 then
                        coroutine.wrap(tryPurchase)(uid, gems, item, version, shiny, amount, username, class, playerid, buytimestamp, listTimestamp, snipeNormal)
                        return
    
                    -- Misc Items
                    elseif class == "HoverBoard" and unitGems <= 30000 then 
                        coroutine.wrap(tryPurchase)(uid, gems, item, version, shiny, amount, username, class, playerid, buytimestamp, listTimestamp, snipeNormal)
                        return
                    elseif class == "Booth" and unitGems <= 5000 and item ~= "Christmas" and item ~= "Dragon" and item ~= "Rainbow" and item ~= "Gold" and item ~= "Cat" and item ~= "Egg" and item ~= "Monkey" then     
                        coroutine.wrap(tryPurchase)(uid, gems, item, version, shiny, amount, username, class, playerid, buytimestamp, listTimestamp, snipeNormal)
                        return
                    elseif item == "Balloon Hoverboard" and unitGems <= 500000 then
                        coroutine.wrap(tryPurchase)(uid, gems, item, version, shiny, amount, username, class, playerid, buytimestamp, listTimestamp, snipeNormal)
                        return
                    elseif item == "UFO" and unitGems <= 1000000 then
                        coroutine.wrap(tryPurchase)(uid, gems, item, version, shiny, amount, username, class, playerid, buytimestamp, listTimestamp, snipeNormal)
                        return
                    elseif item == "Noob Hoverboard" and unitGems <= 400000 then
                        coroutine.wrap(tryPurchase)(uid, gems, item, version, shiny, amount, username, class, playerid, buytimestamp, listTimestamp, snipeNormal)
                        return
    
                        -- Potion   
                    elseif item == "The Cocktail" and gems <= 50000 then
                        coroutine.wrap(tryPurchase)(uid, gems, item, version, shiny, amount, username, class, playerid, buytimestamp, listTimestamp, snipeNormal)
                        return
                    elseif item == "Lucky Eggs VIII" and gems <= 120000 then
                        coroutine.wrap(tryPurchase)(uid, gems, item, version, shiny, amount, username, class, playerid, buytimestamp, listTimestamp, snipeNormal)
                        return
                    elseif string.find(item, "Potion VIII") and price <= 30000 and item == "Diamonds Potion VI" then
                        coroutine.wrap(tryPurchase)(uid, gems, item, version, shiny, amount, username, class, playerid, buytimestamp, listTimestamp, snipeNormal)
                        return
                        -- Tools 
                    elseif item == "Golden Shovel" and unitGems <= 1000000 then
                        coroutine.wrap(tryPurchase)(uid, gems, item, version, shiny, amount, username, class, playerid, buytimestamp, listTimestamp, snipeNormal)
                        return
                    elseif item == "Golden Fishing Rod" and unitGems <= 25000 then
                        coroutine.wrap(tryPurchase)(uid, gems, item, version, shiny, amount, username, class, playerid, buytimestamp, listTimestamp, snipeNormal)
                        return
                    elseif item == "Golden Watering Can" and unitGems <= 25000 then
                        coroutine.wrap(tryPurchase)(uid, gems, item, version, shiny, amount, username, class, playerid, buytimestamp, listTimestamp, snipeNormal)
                        return
                    elseif item == "Exotic Treasure Flag" and unitGems <= 50000 then
                        coroutine.wrap(tryPurchase)(uid, gems, item, version, shiny, amount, username, class, playerid, buytimestamp, listTimestamp, snipeNormal)
                        return
                    end
                end
            end
        end
    end)
local function jumpToServer() 
    local sfUrl = "https://games.roblox.com/v1/games/%s/servers/Public?sortOrder=%s&limit=%s&excludeFullGames=true" 
    local req = request({ Url = string.format(sfUrl, 15502339080, "Desc", 50) }) 
    local body = http:JSONDecode(req.Body) 
    local deep = math.random(1, 3)
    if deep > 1 then 
        for i = 1, deep, 1 do 
             req = request({ Url = string.format(sfUrl .. "&cursor=" .. body.nextPageCursor, 15502339080, "Desc", 50) }) 
             body = http:JSONDecode(req.Body) 
             task.wait(0.1)
        end 
    end 
    local servers = {} 
    if body and body.data then 
        for i, v in next, body.data do 
            if type(v) == "table" and tonumber(v.playing) and tonumber(v.maxPlayers) and v.playing < v.maxPlayers and v.id ~= game.JobId then
                table.insert(servers, v.id)
            end
        end
    end
    local randomCount = #servers
    if not randomCount then
       randomCount = 2
    end
    ts:TeleportToPlaceInstance(15502339080, servers[math.random(1, randomCount)], game:GetService("Players").LocalPlayer) 
end
if PlayerInServer < 30 then
    while task.wait(10) do
	jumpToServer()
    end
end
for i = 1, PlayerInServer do
   for ii = 1,#alts do
        if getPlayers[i].Name == alts[ii] and alts[ii] ~= Players.LocalPlayer.Name then
            while task.wait(10) do
		jumpToServer()
	    end
        end
    end
end
Players.PlayerRemoving:Connect(function(player)
    getPlayers = Players:GetPlayers()
    PlayerInServer = #getPlayers
    if PlayerInServer < 20 then
        while task.wait(10) do
	    jumpToServer()
	end
    end
end) 
Players.PlayerAdded:Connect(function(player)
    for i = 1,#alts do
        if player.Name == alts[i] and alts[i] ~= Players.LocalPlayer.Name then
	    task.wait(math.random(0, 60))
            while task.wait(10) do
	        jumpToServer()
	    end
        end
    end
end) 
local hopDelay = math.random(720, 1000)
while task.wait(1) do
    if math.floor(os.clock() - osclock) >= hopDelay then
        while task.wait(10) do
	    jumpToServer()		
	end	
    end
end
