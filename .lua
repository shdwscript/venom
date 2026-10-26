-- master venom: steal an egg — full automation hub
-- runtime: Roblox executor (Delta, Xeno, Solara, Wave, Volt, Potassium)
-- dependencies: Rayfield Interface Suite (loaded via sirius.menu)
-- game: Steal an Egg — place 107778070777162, universe 10563114921
-- entry: paste into executor and execute inside the game

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "master venom: steal an egg",
    LoadingTitle = "master venom",
    LoadingSubtitle = "steal an egg — full hub",
    ConfigurationSaving = {Enabled = false},
    Discord = {Enabled = false},
    KeySystem = false,
})

-- ============================================================
-- SERVICES & STATE
-- ============================================================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
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

-- ============================================================
-- REMOTE RESOLUTION (SCAN + CACHE)
-- ============================================================
local remotes = {}

local function scanRemotes()
    remotes = {}
    local function scan(container)
        for _, obj in ipairs(container:GetDescendants()) do
            if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
                local n = string.lower(obj.Name)
                if string.find(n, "steal") then
                    remotes.steal = remotes.steal or obj
                elseif string.find(n, "treadmill") or string.find(n, "speed") then
                    remotes.treadmill = remotes.treadmill or obj
                elseif string.find(n, "hatch") then
                    remotes.hatch = remotes.hatch or obj
                elseif string.find(n, "place") then
                    remotes.place = remotes.place or obj
                elseif string.find(n, "egg") and not remotes.egg then
                    remotes.egg = obj
                end
            end
        end
    end
    scan(ReplicatedStorage)
    if Workspace:FindFirstChild("Remotes") then
        scan(Workspace.Remotes)
    end
end

scanRemotes()

-- ============================================================
-- EGG / TARGET DISCOVERY
-- ============================================================
local rarityOrder = {
    Common = 1, Uncommon = 2, Rare = 3, Epic = 4,
    Legendary = 5, Secret = 6, Eternal = 7, Divine = 8,
}

local function getEggs()
    local list = {}
    -- common containers
    for _, containerName in ipairs({"Eggs", "Nests", "EggFolder", "SpawnedEggs"}) do
        local c = Workspace:FindFirstChild(containerName)
        if c then
            for _, obj in ipairs(c:GetChildren()) do
                if obj:IsA("Model") or obj:IsA("Part") then
                    table.insert(list, obj)
                end
            end
        end
    end
    -- fallback: scan workspace for egg-named models
    if #list == 0 then
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if (obj:IsA("Model") or obj:IsA("Part"))
                and string.find(string.lower(obj.Name), "egg") then
                table.insert(list, obj)
            end
        end
    end
    return list
end

local function getEggRarity(egg)
    -- read from attributes first
    local r = egg:GetAttribute("Rarity") or egg:GetAttribute("rarity")
    if r and rarityOrder[r] then return r, rarityOrder[r] end
    -- parse from name
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

-- ============================================================
-- AUTO STEAL
-- ============================================================
task.spawn(function()
    while true do
        task.wait(0.15)
        if not state.autoSteal or not remotes.steal then continue end
        local target = findBestEgg(state.autoStealRarity)
        if target then
            pcall(function()
                remotes.steal:FireServer(target)
            end)
        end
    end
end)

-- ============================================================
-- AUTO TREADMILL
-- ============================================================
task.spawn(function()
    while true do
        task.wait(1)
        if not state.autoTreadmill or not remotes.treadmill then continue end
        pcall(function()
            remotes.treadmill:FireServer()
        end)
    end
end)

-- ============================================================
-- AUTO HATCH
-- ============================================================
task.spawn(function()
    while true do
        task.wait(2)
        if not state.autoHatch or not remotes.hatch then continue end
        pcall(function()
            remotes.hatch:FireServer()
        end)
    end
end)

-- ============================================================
-- AUTO PLACE
-- ============================================================
task.spawn(function()
    while true do
        task.wait(2)
        if not state.autoPlace or not remotes.place then continue end
        pcall(function()
            remotes.place:FireServer()
        end)
    end
end)

-- ============================================================
-- ESP
-- ============================================================
local espCache = {}

local function clearESP()
    for obj, hl in pairs(espCache) do
        if hl and hl.Parent then hl:Destroy() end
    end
    espCache = {}
end

local function applyESP()
    clearESP()
    if not state.espEnabled then return end
    for _, egg in ipairs(getEggs()) do
        if egg:IsA("Model") or egg:IsA("Part") then
            local hl = Instance.new("Highlight")
            local rName, rVal = getEggRarity(egg)
            if rVal >= 7 then
                hl.FillColor = Color3.fromRGB(255, 255, 255) -- divine / eternal
                hl.OutlineColor = Color3.fromRGB(0, 0, 0)
            elseif rVal >= 5 then
                hl.FillColor = Color3.fromRGB(200, 200, 200) -- legendary / secret
                hl.OutlineColor = Color3.fromRGB(0, 0, 0)
            else
                hl.FillColor = Color3.fromRGB(80, 80, 80) -- low tier
                hl.OutlineColor = Color3.fromRGB(255, 255, 255)
            end
            hl.Parent = egg
            espCache[egg] = hl
        end
    end
end

-- ============================================================
-- SPEED + INFINITE JUMP
-- ============================================================
RunService.Heartbeat:Connect(function()
    if state.speedEnabled then
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = state.speedValue end
    end
end)

UserInputService.JumpRequest:Connect(function()
    if state.infiniteJump then
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

-- ============================================================
-- ANTI-GUARD (STANDARD DISABLE PATCH)
-- ============================================================
task.spawn(function()
    while true do
        task.wait(0.5)
        if not state.antiGuard then continue end
        pcall(function()
            local char = LocalPlayer.Character
            if char then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum then
                    hum.PlatformStand = false
                    hum.Sit = false
                end
            end
        end)
    end
end)

-- ============================================================
-- GUI
-- ============================================================
local FarmTab = Window:CreateTab("Farm", nil)
local VisualTab = Window:CreateTab("Visual", nil)
local MiscTab = Window:CreateTab("Misc", nil)

-- ------------------------------------------------------------
-- FARM
-- ------------------------------------------------------------
FarmTab:CreateSection("Steal Automation")

FarmTab:CreateToggle({
    Name = "Auto Steal",
    CurrentValue = false,
    Flag = "AutoSteal",
    Callback = function(v) state.autoSteal = v end,
})

FarmTab:CreateDropdown({
    Name = "Steal Rarity Filter",
    Options = {"Any", "Common", "Uncommon", "Rare", "Epic", "Legendary", "Secret", "Eternal", "Divine"},
    CurrentOption = {"Any"},
    MultipleOptions = false,
    Flag = "StealRarity",
    Callback = function(opt)
        state.autoStealRarity = opt[1]
    end,
})

FarmTab:CreateButton({
    Name = "Manual Steal Best",
    Callback = function()
        local target = findBestEgg(state.autoStealRarity)
        if target and remotes.steal then
            pcall(function() remotes.steal:FireServer(target) end)
        end
    end,
})

FarmTab:CreateSection("Base Automation")

FarmTab:CreateToggle({
    Name = "Auto Treadmill",
    CurrentValue = false,
    Flag = "AutoTreadmill",
    Callback = function(v) state.autoTreadmill = v end,
})

FarmTab:CreateToggle({
    Name = "Auto Hatch",
    CurrentValue = false,
    Flag = "AutoHatch",
    Callback = function(v) state.autoHatch = v end,
})

FarmTab:CreateToggle({
    Name = "Auto Place Eggs",
    CurrentValue = false,
    Flag = "AutoPlace",
    Callback = function(v) state.autoPlace = v end,
})

-- ------------------------------------------------------------
-- VISUAL
-- ------------------------------------------------------------
VisualTab:CreateSection("ESP")

VisualTab:CreateToggle({
    Name = "Egg ESP",
    CurrentValue = false,
    Flag = "ESP",
    Callback = function(v)
        state.espEnabled = v
        applyESP()
    end,
})

VisualTab:CreateButton({
    Name = "Refresh ESP",
    Callback = function() applyESP() end,
})

VisualTab:CreateButton({
    Name = "Clear ESP",
    Callback = function()
        state.espEnabled = false
        clearESP()
    end,
})

-- ------------------------------------------------------------
-- MISC
-- ------------------------------------------------------------
MiscTab:CreateSection("Movement")

MiscTab:CreateToggle({
    Name = "Speed Enabled",
    CurrentValue = false,
    Flag = "SpeedEnabled",
    Callback = function(v)
        state.speedEnabled = v
        if not v then
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = 16 end
        end
    end,
})

MiscTab:CreateSlider({
    Name = "WalkSpeed",
    Range = {16, 350},
    Increment = 1,
    CurrentValue = 16,
    Suffix = "speed",
    Flag = "SpeedValue",
    Callback = function(v) state.speedValue = v end,
})

MiscTab:CreateToggle({
    Name = "Infinite Jump",
    CurrentValue = false,
    Flag = "InfJump",
    Callback = function(v) state.infiniteJump = v end,
})

MiscTab:CreateSection("Utility")

MiscTab:CreateToggle({
    Name = "Anti-Guard / Anti-Ragdoll",
    CurrentValue = false,
    Flag = "AntiGuard",
    Callback = function(v) state.antiGuard = v end,
})

MiscTab:CreateButton({
    Name = "Teleport to Best Egg",
    Callback = function()
        local target = findBestEgg(state.autoStealRarity)
        if target then
            local part = target:IsA("Model") and target.PrimaryPart or target
            if part then
                local char = LocalPlayer.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    hrp.CFrame = part.CFrame + Vector3.new(0, 5, 0)
                end
            end
        end
    end,
})

MiscTab:CreateButton({
    Name = "Refresh Remotes",
    Callback = function()
        scanRemotes()
        Rayfield:Notify({
            Title = "master venom",
            Content = "remotes rescanned",
            Duration = 3,
        })
    end,
})

-- ============================================================
-- BOOT NOTIFICATION
-- ============================================================
Rayfield:Notify({
    Title = "master venom online",
    Content = "steal an egg hub loaded",
    Duration = 5,
})
