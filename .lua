-- master venom: steal an egg — ultimate prompt hijack build
-- runtime: Roblox executor with getconnections & fireproximityprompt support

local success, Rayfield = pcall(function()
    return loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
end)

if not success or not Rayfield then return end

local Window = Rayfield:CreateWindow({
    Name = "master venom: steal an egg",
    LoadingTitle = "master venom",
    LoadingSubtitle = "bypassing validations...",
    ConfigurationSaving = {Enabled = false},
    Discord = {Enabled = false},
    KeySystem = false,
})

task.wait(0.5)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

local state = {
    autoSteal = false,
    autoHatch = false,
    autoPlace = false,
    espEnabled = false,
    speedEnabled = false,
    speedValue = 16,
    infiniteJump = false,
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

local function getBestEgg()
    local eggs = getEggs()
    if #eggs == 0 then return nil end
    -- Simple fallback to the first egg found in the workspace
    return eggs[1]
end

local function fireEggPrompts(egg)
    if not egg then return end
    for _, prompt in ipairs(egg:GetDescendants()) do
        if prompt:IsA("ProximityPrompt") then
            if fireproximityprompt then
                pcall(function() fireproximityprompt(prompt) end)
            else
                -- Fallback for basic executors
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

-- ============================================================
-- AUTOMATION LOOPS
-- ============================================================
task.spawn(function()
    while task.wait(1) do
        if not state.autoSteal then continue end
        local target = getBestEgg()
        if target then
            -- Teleport to the egg to ensure the prompt fires successfully
            local part = target:IsA("Model") and target.PrimaryPart or target
            if part then
                local char = LocalPlayer.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    hrp.CFrame = part.CFrame + Vector3.new(0, 3, 0)
                    task.wait(0.1)
                    fireEggPrompts(target)
                end
            end
        end
    end
end)

task.spawn(function()
    while task.wait(2) do
        if state.autoHatch then clickUIButtons("hatch") end
        if state.autoPlace then clickUIButtons("place") end
    end
end)

-- ============================================================
-- VISUALS & MOVEMENT
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
-- GUI CONSTRUCTION
-- ============================================================
local MainTab = Window:CreateTab("Farm", nil)
local VisualTab = Window:CreateTab("Visual", nil)
local MiscTab = Window:CreateTab("Misc", nil)

-- FARM TAB
MainTab:CreateSection("Server-Bypass Actions")
MainTab:CreateToggle({
    Name = "Auto Steal (Prompt Hook)",
    CurrentValue = false,
    Flag = "AutoSteal",
    Callback = function(v) state.autoSteal = v end,
})

MainTab:CreateButton({
    Name = "Manual Steal Best",
    Callback = function()
        local target = getBestEgg()
        if target then
            local part = target:IsA("Model") and target.PrimaryPart or target
            if part then
                local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    hrp.CFrame = part.CFrame + Vector3.new(0, 3, 0)
                    task.wait(0.1)
                    fireEggPrompts(target)
                end
            end
        end
    end,
})

MainTab:CreateSection("Base Automation (UI Hook)")
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

-- VISUAL TAB
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

-- MISC TAB
MiscTab:CreateSection("Movement (Server Validated)")
MiscTab:CreateToggle({
    Name = "Speed Enabled",
    CurrentValue = false,
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
    Range = {16, 100},
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

Rayfield:Notify({
    Title = "master venom online",
    Content = "prompt bypass active",
    Duration = 5,
})
