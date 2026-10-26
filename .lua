-- master venom: steal an egg — smooth glide bypass
-- runtime: Roblox executor (supports fireproximityprompt & getconnections)

local success, Rayfield = pcall(function()
    return loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
end)

if not success or not Rayfield then return end

local Window = Rayfield:CreateWindow({
    Name = "master venom: steal an egg",
    LoadingTitle = "master venom",
    LoadingSubtitle = "initializing glide bypass...",
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
}

-- ============================================================
-- TARGETING & BYPASS LOGIC
-- ============================================================
local function getEggs()
    local list = {}
    local map = Workspace:FindFirstChild("Map") or Workspace:FindFirstChild("Eggs") or Workspace
    for _, obj in ipairs(map:GetDescendants()) do
        if (obj:IsA("Model") or obj:IsA("Part")) and string.find(string.lower(obj.Name), "egg") then
            table.insert(list, obj)
        end
    end
    return list
end

-- Finds the closest egg to prevent long glide times
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
-- SMOOTH GLIDE MECHANIC
-- ============================================================
local function glideTo(targetPos)
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local attachment = Instance.new("Attachment", hrp)
    local alignPosition = Instance.new("AlignPosition", hrp)
    
    alignPosition.Mode = Enum.PositionAlignmentMode.OneAttachment
    alignPosition.Attachment0 = attachment
    alignPosition.MaxForce = 50000
    alignPosition.Responsiveness = 20 -- Adjust for glide smoothness
    alignPosition.Position = targetPos + Vector3.new(0, 3, 0)

    -- Wait until we are within 6 studs of the target or timeout after 3 seconds
    local t = 0
    while t < 3 do
        if (hrp.Position - (targetPos + Vector3.new(0, 3, 0))).Magnitude < 6 then break end
        task.wait(0.05)
        t = t + 0.05
    end

    alignPosition:Destroy()
    attachment:Destroy()
end

-- ============================================================
-- AUTOMATION LOOPS
-- ============================================================
task.spawn(function()
    while task.wait(1) do
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
        glideTo(part.Position)
        task.wait(0.15) -- let the server register our position

        -- 2. Press E
        fireEggPrompts(egg)
        task.wait(0.2)

        -- 3. Glide back to base
        glideTo(basePos)
    end
end)

local function clickUIButtons(keyword)
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if not pg then return end
    for _, obj in ipairs(pg:GetDescendants()) do
        if obj:IsA("TextButton") or obj:IsA("ImageButton") then
            local text = obj.Text and string.lower(obj.Text) or ""
            local name = string.lower(obj.Name)
            if string.find(text, keyword) or string.find(name, keyword) then
                if getconnections then
                    for _, conn in ipairs(getconnections(obj.MouseButton1Click)) do
                        pcall(function() conn:Fire() end)
                    end
                else
                    pcall(function() obj:Click() end) 
                end
            end
        end
    end
end

task.spawn(function()
    while task.wait(2) do
        if state.autoHatch then clickUIButtons("hatch") end
        if state.autoPlace then clickUIButtons("place") end
    end
end)

-- ============================================================
-- VISUALS
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
            hl.FillColor = Color3.fromRGB(255, 255, 255)
            hl.OutlineColor = Color3.fromRGB(0, 0, 0)
            hl.Parent = egg
            espCache[egg] = hl
        end
    end
end

-- ============================================================
-- GUI
-- ============================================================
local MainTab = Window:CreateTab("Farm", nil)
local VisualTab = Window:CreateTab("Visual", nil)

MainTab:CreateSection("Glide Bypass")
MainTab:CreateToggle({
    Name = "Auto Steal (Glide)",
    CurrentValue = false,
    Flag = "AutoSteal",
    Callback = function(v) state.autoSteal = v end,
})

MainTab:CreateToggle({
    Name = "Auto Hatch (UI Click)",
    CurrentValue = false,
    Flag = "AutoHatch",
    Callback = function(v) state.autoHatch = v end,
})

MainTab:CreateToggle({
    Name = "Auto Place (UI Click)",
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
        applyESP()
    end,
})

VisualTab:CreateButton({
    Name = "Refresh ESP",
    Callback = function() applyESP() end,
})

Rayfield:Notify({
    Title = "master venom online",
    Content = "glide bypass active",
    Duration = 5,
})
