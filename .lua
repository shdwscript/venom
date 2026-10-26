-- master venom: steal an egg — anti-freeze / anti-mangle cut
-- runtime: Roblox executor (Test this CLEAN before obfuscating)

-- 1. Load Rayfield safely
local success, Rayfield = pcall(function()
    return loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
end)

if not success or not Rayfield then
    warn("master venom: Rayfield failed to load.")
    return
end

local Window = Rayfield:CreateWindow({
    Name = "master venom: steal an egg",
    LoadingTitle = "master venom",
    LoadingSubtitle = "loading hub...",
    ConfigurationSaving = {Enabled = false},
    Discord = {Enabled = false},
    KeySystem = false,
})

-- Yield a frame so the Window can render before we add tabs
task.wait(1)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

local state = {
    autoSteal = false,
    autoStealRarity = "Any",
    autoTreadmill = false,
    autoHatch = false,
    autoPlace = false,
    espEnabled = false,
    speedEnabled = false,
    speedValue = 16,
    infiniteJump = false,
    antiGuard = false,
}

local remotes = {}

-- 2. Safe Remote Scanner (Stops scanning after 10,000 objects to prevent freeze)
local function scanRemotes()
    remotes = {}
    local count = 0
    
    local function scan(container)
        for _, obj in ipairs(container:GetChildren()) do
            if count > 10000 then break end
            count = count + 1
            
            local n = string.lower(obj.Name)
            if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
                if string.find(n, "steal") then
                    remotes.steal = remotes.steal or obj
                elseif string.find(n, "treadmill") or string.find(n, "speed") then
                    remotes.treadmill = remotes.treadmill or obj
                elseif string.find(n, "hatch") then
                    remotes.hatch = remotes.hatch or obj
                elseif string.find(n, "place") then
                    remotes.place = remotes.place or obj
                end
            end
            -- Recursive search
            if #obj:GetChildren() > 0 then
                scan(obj)
            end
        end
    end
    
    scan(ReplicatedStorage)
    if Workspace:FindFirstChild("Remotes") then
        scan(Workspace.Remotes)
    end
end

task.spawn(scanRemotes)

-- 3. Safe Target Finder
local rarityOrder = {
    Common = 1, Uncommon = 2, Rare = 3, Epic = 4,
    Legendary = 5, Secret = 6, Eternal = 7, Divine = 8,
}

local function getEggs()
    local list = {}
    -- Only look in direct workspace folders to avoid massive scans
    for _, containerName in ipairs({"Eggs", "Nests", "EggFolder", "SpawnedEggs", "Map"}) do
        local c = Workspace:FindFirstChild(containerName)
        if c then
            for _, obj in ipairs(c:GetChildren()) do
                if (obj:IsA("Model") or obj:IsA("Part")) and string.find(string.lower(obj.Name), "egg") then
                    table.insert(list, obj)
                end
            end
        end
    end
    return list
end

local function getEggRarity(egg)
    local r = egg:GetAttribute("Rarity") or egg:GetAttribute("rarity")
    if r and rarityOrder[r] then return r, rarityOrder[r] end
    for rName, rVal in pairs(rarityOrder) do
        if string.find(string.lower(egg.Name), string.lower(rName)) then
            return rName, rVal
        end
    end
    return "Common", 1
end

local function findBestEgg(filter)
    local eggs = getEggs()
    local best, bestVal = nil, 0
    for _, egg in ipairs(eggs) do
        local rName, rVal = getEggRarity(egg)
        if filter == "Any" or filter == rName then
            if rVal > bestVal then
                bestVal = rVal
                best = egg
            end
        end
    end
    return best
end

-- 4. Safe Automation Loops
task.spawn(function()
    while task.wait(1) do
        if not state.autoSteal or not remotes.steal then continue end
        local target = findBestEgg(state.autoStealRarity)
        if target then
            pcall(function() remotes.steal:FireServer(target) end)
        end
    end
end)

task.spawn(function()
    while task.wait(2) do
        if not state.autoTreadmill or not remotes.treadmill then continue end
        pcall(function() remotes.treadmill:FireServer() end)
    end
end)

task.spawn(function()
    while task.wait(3) do
        if not state.autoHatch or not remotes.hatch then continue end
        pcall(function() remotes.hatch:FireServer() end)
    end
end)

task.spawn(function()
    while task.wait(3) do
        if not state.autoPlace or not remotes.place then continue end
        pcall(function() remotes.place:FireServer() end)
    end
end)

-- 5. UI Creation (Wrapped in pcall to catch errors)
local uiSuccess, uiError = pcall(function()
    local FarmTab = Window:CreateTab("Farm", nil)
    local VisualTab = Window:CreateTab("Visual", nil)
    local MiscTab = Window:CreateTab("Misc", nil)

    -- FARM TAB
    FarmTab:CreateSection("Steal Automation")
    
    FarmTab:CreateToggle({
        Name = "Auto Steal",
        CurrentValue = false,
        Flag = "AutoSteal",
        Callback = function(v) state.autoSteal = v end,
    })

    FarmTab:CreateDropdown({
        Name = "Rarity Filter",
        Options = {"Any", "Common", "Uncommon", "Rare", "Epic", "Legendary", "Secret", "Eternal", "Divine"},
        CurrentOption = {"Any"},
        MultipleOptions = false,
        Flag = "StealRarity",
        Callback = function(opt) state.autoStealRarity = opt[1] end,
    })

    FarmTab:CreateSection("Base Automation")
    FarmTab:CreateToggle({Name = "Auto Treadmill", Flag = "AutoTreadmill", Callback = function(v) state.autoTreadmill = v end})
    FarmTab:CreateToggle({Name = "Auto Hatch", Flag = "AutoHatch", Callback = function(v) state.autoHatch = v end})
    FarmTab:CreateToggle({Name = "Auto Place", Flag = "AutoPlace", Callback = function(v) state.autoPlace = v end})

    -- VISUAL TAB
    VisualTab:CreateSection("ESP")
    VisualTab:CreateButton({
        Name = "Highlight All Eggs",
        Callback = function()
            for _, egg in ipairs(getEggs()) do
                local hl = Instance.new("Highlight")
                hl.FillColor = Color3.fromRGB(255, 255, 255)
                hl.OutlineColor = Color3.fromRGB(0, 0, 0)
                hl.Parent = egg
            end
        end,
    })

    -- MISC TAB
    MiscTab:CreateSection("Movement")
    MiscTab:CreateToggle({
        Name = "Speed Enabled",
        Flag = "SpeedEnabled",
        Callback = function(v)
            state.speedEnabled = v
            if not v then
                local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                if hum then hum.WalkSpeed = 16 end
            end
        end,
    })

    MiscTab:CreateSlider({
        Name = "WalkSpeed",
        Range = {16, 350},
        Increment = 1,
        CurrentValue = 16,
        Flag = "SpeedValue",
        Callback = function(v) state.speedValue = v end,
    })
end)

if not uiSuccess then
    warn("master venom UI Error: " .. tostring(uiError))
end

-- 6. Heartbeat Speed Loop
RunService.Heartbeat:Connect(function()
    if state.speedEnabled then
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = state.speedValue end
    end
end)

Rayfield:Notify({
    Title = "master venom online",
    Content = "clean build loaded",
    Duration = 5,
})
