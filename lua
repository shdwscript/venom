-- master venom: racket rivals — Raw Custom UI Build
-- runtime: Real executor (No external libraries required)
-- game: Racket Rivals

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

local state = {
    autoSwing = false,
    autoAim = false,
    magnet = false,
    speedEnabled = false,
    speedValue = 30,
    jumpEnabled = false,
    jumpValue = 100,
}

-- ============================================================
-- GAME LOGIC
-- ============================================================
local function getBallShadow()
    local fx = Workspace:FindFirstChild("FX")
    if fx then
        local shadow = fx:FindFirstChild("BallShadow")
        if shadow then return shadow end
    end
    return nil
end

local function getBall()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            local n = string.lower(obj.Name)
            if (string.find(n, "ball") or string.find(n, "shuttle")) and not string.find(n, "shadow") then
                return obj
            end
        end
    end
    return nil
end

-- Auto Swing
task.spawn(function()
    while task.wait(0.1) do
        if state.autoSwing then
            local ball = getBall()
            local shadow = getBallShadow()
            local char = LocalPlayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            
            if root and (shadow or ball) then
                local targetPos = shadow and shadow.Position or ball.Position
                if (root.Position - targetPos).Magnitude < 25 then
                    pcall(function()
                        keypress(0x46) -- F key
                        task.wait(0.05)
                        keyrelease(0x46)
                        mouse1click()
                    end)
                end
            end
        end
    end
end)

-- Ball Magnet
RunService.Heartbeat:Connect(function()
    if state.magnet then
        local shadow = getBallShadow()
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if shadow and hum and root then
            hum:MoveTo(shadow.Position)
        end
    end
end)

-- Camera Auto Aim
local oldIndex
oldIndex = hookmetamethod(game, "__newindex", function(self, key, value)
    if self == Workspace.CurrentCamera and key == "CFrame" then
        if state.autoAim then
            local ball = getBall()
            if ball then
                value = CFrame.lookAt(value.Position, ball.Position)
            end
        end
    end
    return oldIndex(self, key, value)
end)

-- Speed & Jump
RunService.Heartbeat:Connect(function()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        if state.speedEnabled then hum.WalkSpeed = state.speedValue
        elseif hum.WalkSpeed ~= 16 then hum.WalkSpeed = 16 end
        if state.jumpEnabled then
            hum.UseJumpPower = true
            hum.JumpPower = state.jumpValue
        elseif hum.JumpPower ~= 50 then hum.JumpPower = 50 end
    end
end)

-- ============================================================
-- CUSTOM UI BUILDER (RAW INSTANCES)
-- ============================================================
local CoreGui = game:GetService("CoreGui")
local Gui = Instance.new("ScreenGui")
Gui.Name = "MasterVenomUI"
Gui.ResetOnSpawn = false
Gui.Parent = CoreGui

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 500, 0, 350)
Main.Position = UDim2.new(0.5, -250, 0.5, -175)
Main.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
Main.BorderSizePixel = 0
Main.Parent = Gui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = Main

local Stroke = Instance.new("UIStroke")
Stroke.Color = Color3.fromRGB(255, 50, 50)
Stroke.Thickness = 2
Stroke.Parent = Main

-- Top Bar (Draggable)
local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, 35)
TopBar.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
TopBar.BorderSizePixel = 0
TopBar.Parent = Main

local TopCorner = Instance.new("UICorner")
TopCorner.CornerRadius = UDim.new(0, 8)
TopCorner.Parent = TopBar

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -20, 1, 0)
Title.Position = UDim2.new(0, 10, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "master venom | racket rivals"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Font = Enum.Font.GothamBold
Title.TextSize = 14
Title.Parent = TopBar

-- Drag Logic
local dragging, dragInput, dragStart, startPos
TopBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = Main.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
TopBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end
end)
UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- Content Area
local Content = Instance.new("Frame")
Content.Size = UDim2.new(1, -20, 1, -45)
Content.Position = UDim2.new(0, 10, 0, 45)
Content.BackgroundTransparency = 1
Content.Parent = Main

-- UI Helper Functions
local yOffset = 0

local function CreateSection(text)
    local section = Instance.new("TextLabel")
    section.Size = UDim2.new(1, 0, 0, 20)
    section.Position = UDim2.new(0, 0, 0, yOffset)
    section.BackgroundTransparency = 1
    section.Text = string.upper(text)
    section.TextColor3 = Color3.fromRGB(255, 50, 50)
    section.TextXAlignment = Enum.TextXAlignment.Left
    section.Font = Enum.Font.GothamBold
    section.TextSize = 12
    section.Parent = Content
    yOffset = yOffset + 25
end

local function CreateToggle(name, default, callback)
    local toggleFrame = Instance.new("Frame")
    toggleFrame.Size = UDim2.new(1, 0, 0, 30)
    toggleFrame.Position = UDim2.new(0, 0, 0, yOffset)
    toggleFrame.BackgroundTransparency = 1
    toggleFrame.Parent = Content

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -50, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = Color3.fromRGB(200, 200, 200)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Font = Enum.Font.Gotham
    label.TextSize = 13
    label.Parent = toggleFrame

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 40, 0, 20)
    btn.Position = UDim2.new(1, -40, 0.5, -10)
    btn.BackgroundColor3 = default and Color3.fromRGB(255, 50, 50) or Color3.fromRGB(50, 50, 50)
    btn.BorderSizePixel = 0
    btn.Text = ""
    btn.Parent = toggleFrame

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 4)
    btnCorner.Parent = btn

    local indicator = Instance.new("Frame")
    indicator.Size = UDim2.new(0, 16, 0, 16)
    indicator.Position = default and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
    indicator.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    indicator.BorderSizePixel = 0
    indicator.Parent = btn

    local indCorner = Instance.new("UICorner")
    indCorner.CornerRadius = UDim.new(0, 4)
    indCorner.Parent = indicator

    local toggled = default
    btn.MouseButton1Click:Connect(function()
        toggled = not toggled
        btn.BackgroundColor3 = toggled and Color3.fromRGB(255, 50, 50) or Color3.fromRGB(50, 50, 50)
        indicator.Position = toggled and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
        callback(toggled)
    end)

    yOffset = yOffset + 35
end

local function CreateSlider(name, min, max, default, callback)
    local sliderFrame = Instance.new("Frame")
    sliderFrame.Size = UDim2.new(1, 0, 0, 45)
    sliderFrame.Position = UDim2.new(0, 0, 0, yOffset)
    sliderFrame.BackgroundTransparency = 1
    sliderFrame.Parent = Content

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 20)
    label.BackgroundTransparency = 1
    label.Text = name .. ": " .. tostring(default)
    label.TextColor3 = Color3.fromRGB(200, 200, 200)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Font = Enum.Font.Gotham
    label.TextSize = 13
    label.Parent = sliderFrame

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, 0, 0, 6)
    bar.Position = UDim2.new(0, 0, 0, 25)
    bar.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    bar.BorderSizePixel = 0
    bar.Parent = sliderFrame

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
    fill.BorderSizePixel = 0
    fill.Parent = bar

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.Parent = bar

    local sliding = false
    local function update(input)
        local pos = math.clamp((input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        local val = math.floor(min + (max - min) * pos)
        fill.Size = UDim2.new(pos, 0, 1, 0)
        label.Text = name .. ": " .. tostring(val)
        callback(val)
    end

    btn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            sliding = true
            update(input)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if sliding and input.UserInputType == Enum.UserInputType.MouseMovement then
            update(input)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then sliding = false end
    end)

    yOffset = yOffset + 55
end

-- ============================================================
-- BUILD THE MENU
-- ============================================================
CreateSection("Combat")
CreateToggle("Auto Swing", false, function(v) state.autoSwing = v end)
CreateToggle("Camera Auto Aim", false, function(v) state.autoAim = v end)
CreateToggle("Ball Magnet", false, function(v) state.magnet = v end)

CreateSection("Movement")
CreateToggle("Speed Enabled", false, function(v) state.speedEnabled = v end)
CreateSlider("Walk Speed", 16, 100, 30, function(v) state.speedValue = v end)
CreateToggle("Jump Enabled", false, function(v) state.jumpEnabled = v end)
CreateSlider("Jump Power", 50, 300, 100, function(v) state.jumpValue = v end)
