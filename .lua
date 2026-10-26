-- master venom: steal an egg — tween glide & prompt bypass
-- runtime: Roblox executor (supports fireproximityprompt & getconnections)

local success, Rayfield = pcall(function()
    return loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
end)

if not success or not Rayfield then return end

local Window = Rayfield:CreateWindow({
    Name = "master venom: steal an egg",
    LoadingTitle = "master venom",
    LoadingSubtitle = "tween glide bypass...",
    ConfigurationSaving = {Enabled = false},
    Discord = {Enabled = false},
    KeySystem = false,
})

task.wait(0.5)

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

local state = {
    autoSteal = false,
    autoHatch = false,
    autoPlace = false,
    espEnabled = false,
}

-- ============================================================
-- TARGETING
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
-- SMOOTH TWEEN GLIDE
-- ============================================================
local function tweenGlide(targetPos, speed)
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local distance = (targetPos - hrp.Position).Magnitude
    local time = distance / speed

    local tweenInfo = TweenInfo.new(time, Enum.EasingStyle.Linear)
    local goal = {CFrame = CFrame.new(targetPos + Vector3.new(0, 3, 0))}
    
    local tween = TweenService:Create(hrp, tweenInfo, goal)
    tween:Play()
    
    -- Wait for the tween to finish
    tween.Completed:Wait()
    task.wait(0.1)
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

        -- 1. Smooth glide to egg (speed 50)
        tweenGlide(part.Position, 50)
        
        -- 2. Fire prompt
        fireEggPrompts(egg)
        task.wait(0.3)

        -- 3. Smooth glide back to base
        tweenGlide(basePos, 50)
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

MainTab:CreateSection("Tween Glide Bypass")
MainTab:CreateToggle({
    Name = "Auto Steal (Tween Glide)",
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
    Content = "tween glide bypass active",
    Duration = 5,
})
