-- master venom: steal an egg — ultimate bypass (manual CFrame glide)
-- runtime: Roblox executor

local success, Rayfield = pcall(function()
    return loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
end)

if not success or not Rayfield then return end

local Window = Rayfield:CreateWindow({
    Name = "master venom: steal an egg",
    LoadingTitle = "master venom",
    LoadingSubtitle = "initializing bypass...",
    ConfigurationSaving = {Enabled = false},
    Discord = {Enabled = false},
    KeySystem = false,
})

task.wait(0.5)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

local state = {
    autoSteal = false,
    autoHatch = false,
    autoPlace = false,
    espEnabled = false,
    speedEnabled = false,
    speedValue = 16,
}

local remotes = {}

-- ============================================================
-- REMOTE SCANNER (For Hatch & Place)
-- ============================================================
local function scanRemotes()
    remotes = {}
    for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            local n = string.lower(obj.Name)
            if string.find(n, "hatch") then
                remotes.hatch = remotes.hatch or obj
            elseif string.find(n, "place") then
                remotes.place = remotes.place or obj
            end
        end
    end
end
scanRemotes()

-- ============================================================
-- TARGETING (Deep Scan)
-- ============================================================
local function getEggs()
    local list = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if (obj:IsA("Model") or obj:IsA("Part")) and string.find(string.lower(obj.Name), "egg") then
            table.insert(list, obj)
        end
    end
    return list
end

local function getClosestEgg()
    local eggs = getEggs()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp or #eggs == 0 then return nil end

    local closest = nil
    local minDist = math.huge
    for _, egg in ipairs(eggs) do
        local part = egg:IsA("Model") and egg.PrimaryPart or egg
        if part then
            local dist = (part.Position - hrp.Position).Magnitude
            if dist < minDist then
                minDist = dist
                closest = egg
            end
        end
    end
    return closest
end

local function fireEggPrompts(egg)
    if not egg then return end
    for _, prompt in ipairs(egg:GetDescendants()) do
        if prompt:IsA("ProximityPrompt") then
            if fireproximityprompt then
                pcall(function() fireproximityprompt(prompt) end)
            else
                pcall(function()
                    prompt.HoldDuration = 0
                    prompt:InputHoldBegin()
                    task.wait(0.05)
                    prompt:InputHoldEnd()
                end)
            end
        elseif prompt:IsA("ClickDetector") then
            if fireclickdetector then
                pcall(function() fireclickdetector(prompt) end)
            end
        end
    end
end

-- ============================================================
-- MANUAL CFrame GLIDE (Smooth & Bypasses Physics)
-- ============================================================
local function manualGlide(targetPos)
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local speed = 120 -- studs per second
    local originalCanCollide = hrp.CanCollide
    hrp.CanCollide = false

    local distance = (targetPos - hrp.Position).Magnitude
    local timeToTravel = distance / speed
    local elapsed = 0

    local connection
    connection = RunService.Heartbeat:Connect(function(dt)
        if not hrp or not hrp.Parent then
            connection:Disconnect()
            return
        end
        
        elapsed = elapsed + dt
        local alpha = math.clamp(elapsed / timeToTravel, 0, 1)
        
        -- Smooth interpolation
        hrp.CFrame = hrp.CFrame:Lerp(CFrame.new(targetPos + Vector3.new(0, 3, 0)), alpha * 0.5)
        
        if alpha >= 1 or (hrp.Position - targetPos).Magnitude < 5 then
            connection:Disconnect()
            hrp.CanCollide = originalCanCollide
        end
    end)
    
    -- Wait until glide finishes
    task.wait(timeToTravel + 0.1)
    if connection then connection:Disconnect() end
    hrp.CanCollide = originalCanCollide
end

-- ============================================================
-- AUTOMATION LOOPS
-- ============================================================
task.spawn(function()
    while task.wait(1.5) do
        if not state.autoSteal then continue end
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then continue end

        local egg = getClosestEgg()
        if not egg then continue end
        local part = egg:IsA("Model") and egg.PrimaryPart or egg
        if not part then continue end

        local basePos = hrp.Position

        -- 1. Glide to egg
        manualGlide(part.Position)
        task.wait(0.2)

        -- 2. Fire Prompt
        fireEggPrompts(egg)
        task.wait(0.3)

        -- 3. Glide back to base
        manualGlide(basePos)
    end
end)

task.spawn(function()
    while task.wait(2) do
        if state.autoHatch and remotes.hatch then
            pcall(function() remotes.hatch:FireServer() end)
        end
        if state.autoPlace and remotes.place then
            pcall(function() remotes.place:FireServer() end)
        end
    end
end)

-- ============================================================
-- ESP (Lag-Free Highlighting)
-- ============================================================
local espCache = {}
local function clearESP()
    for obj, hl in pairs(espCache) do
        if hl and hl.Parent then hl:Destroy() end
    end
    espCache = {}
end

local function updateESP()
    if not state.espEnabled then return end
    local eggs = getEggs()
    
    -- Clean up deleted eggs
    for egg, hl in pairs(espCache) do
        if not egg.Parent or not egg:IsDescendantOf(Workspace) then
            hl:Destroy()
            espCache[egg] = nil
        end
    end

    -- Add missing eggs
    for _, egg in ipairs(eggs) do
        if not espCache[egg] and (egg:IsA("Model") or egg:IsA("Part")) then
            local hl = Instance.new("Highlight")
            hl.FillColor = Color3.fromRGB(255, 255, 255)
            hl.OutlineColor = Color3.fromRGB(0, 0, 0)
            hl.Parent = egg
            espCache[egg] = hl
        end
    end
end

task.spawn(function()
    while task.wait(1) do
        if state.espEnabled then updateESP() end
    end
end)

-- ============================================================
-- SPEED CHANGER
-- ============================================================
RunService.Heartbeat:Connect(function()
    if state.speedEnabled then
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = state.speedValue end
    end
end)

-- ============================================================
-- GUI
-- ============================================================
local MainTab = Window:CreateTab("Farm", nil)
local VisualTab = Window:CreateTab("Visual", nil)
local MiscTab = Window:CreateTab("Misc", nil)

MainTab:CreateSection("Glide Bypass")
MainTab:CreateToggle({
    Name = "Auto Steal (Glide)",
    CurrentValue = false,
    Flag = "AutoSteal",
    Callback = function(v) state.autoSteal = v end,
})

MainTab:CreateSection("Remote Automation")
MainTab:CreateToggle({
    Name = "Auto Hatch",
    CurrentValue = false,
    Flag = "AutoHatch",
    Callback = function(v) state.autoHatch = v end,
})
MainTab:CreateToggle({
    Name = "Auto Place",
    CurrentValue = false,
    Flag = "AutoPlace",
    Callback = function(v) state.autoPlace = v end,
})

VisualTab:CreateSection("ESP")
VisualTab:CreateToggle({
    Name = "Egg ESP",
    CurrentValue = false,
    Flag = "ESP",
    Callback = function(v)
        state.espEnabled = v
        if not v then clearESP() end
    end,
})

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
    Name = "WalkSpeed (Max 100)",
    Range = {16, 100},
    Increment = 1,
    CurrentValue = 16,
    Suffix = "speed",
    Flag = "SpeedValue",
    Callback = function(v) state.speedValue = v end,
})

MiscTab:CreateButton({
    Name = "Refresh Remotes",
    Callback = function()
        scanRemotes()
        Rayfield:Notify({Title = "master venom", Content = "remotes rescanned", Duration = 3})
    end,
})

Rayfield:Notify({
    Title = "master venom online",
    Content = "manual CFrame glide active",
    Duration = 5,
})
