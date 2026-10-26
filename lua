-- master venom: racket rivals — Rayfield Premium Hub
-- runtime: Real executor (Solara, Wave, Velocity, Xeno)
-- game: Racket Rivals
-- features: Auto Swing, Ball Magnet, Aimbot, Hitbox, Dash/Set Spam, Auto Ability, ESP

local success, Rayfield = pcall(function()
    return loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
end)
if not success or not Rayfield then return end

local Window = Rayfield:CreateWindow({
    Name = "master venom | racket rivals",
    LoadingTitle = "master venom",
    LoadingSubtitle = "loading premium hub...",
    Theme = "Dark",
    AccentColor = Color3.fromRGB(255, 50, 50),
    ConfigurationSaving = {Enabled = false},
    Discord = {Enabled = false},
    KeySystem = false,
})

task.wait(0.5)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local LocalPlayer = Players.LocalPlayer

local state = {
    autoSwing = false,
    autoAim = false,
    magnet = false,
    magnetStrength = 0.15,
    hitboxExpander = false,
    hitboxSize = 10,
    dashSpam = false,
    setSpam = false,
    autoAbility = false,
    espEnabled = false,
    ballTracer = false,
}

-- ============================================================
-- GAME LOGIC & HELPERS
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

local function pressKey(keyCode, holdTime)
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:KeyDown(keyCode)
        task.wait(holdTime or 0.05)
        VirtualUser:KeyUp(keyCode)
    end)
end

local function clickMouse()
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton1(Vector2.new(0, 0))
    end)
end

-- ============================================================
-- AUTO SWING (Ball + Shadow Proximity)
-- ============================================================
task.spawn(function()
    while task.wait(0.1) do
        if state.autoSwing then
            local ball = getBall()
            local shadow = getBallShadow()
            local char = LocalPlayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            
            if root and (shadow or ball) then
                local targetPos = shadow and shadow.Position or ball.Position
                if (root.Position - targetPos).Magnitude < 30 then
                    clickMouse()
                    pressKey(Enum.KeyCode.F)
                end
            end
        end
    end
end)

-- ============================================================
-- BALL MAGNET (CFrame Lerp to Shadow)
-- ============================================================
RunService.Heartbeat:Connect(function()
    if state.magnet then
        local shadow = getBallShadow()
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if shadow and root then
            local targetPos = Vector3.new(shadow.Position.X, root.Position.Y, shadow.Position.Z)
            root.CFrame = CFrame.new(root.Position:Lerp(targetPos, state.magnetStrength), root.CFrame.LookVector)
        end
    end
end)

-- ============================================================
-- CAMERA AIMBOT (Locks to Ball)
-- ============================================================
local oldNameIndex
oldNameIndex = hookmetamethod(game, "__newindex", function(self, key, value)
    if self == Workspace.CurrentCamera and key == "CFrame" then
        if state.autoAim then
            local ball = getBall()
            if ball then
                value = CFrame.lookAt(value.Position, ball.Position)
            end
        end
    end
    return oldNameIndex(self, key, value)
end)

-- ============================================================
-- DASH & SET SPAM
-- ============================================================
task.spawn(function()
    while task.wait(0.15) do
        if state.dashSpam then pressKey(Enum.KeyCode.Q) end
        if state.setSpam then pressKey(Enum.KeyCode.E) end
    end
end)

-- ============================================================
-- AUTO ABILITY
-- ============================================================
task.spawn(function()
    while task.wait(0.5) do
        if state.autoAbility then pressKey(Enum.KeyCode.One) end
    end
end)

-- ============================================================
-- HITBOX EXPANDER (Custom Racket Model)
-- ============================================================
task.spawn(function()
    while task.wait(0.5) do
        if state.hitboxExpander then
            local char = LocalPlayer.Character
            if char then
                local racket = char:FindFirstChild("Racket") or char:FindFirstChild("RacketModel")
                if racket and racket:IsA("Model") then
                    local handle = racket:FindFirstChild("Handle") or racket.PrimaryPart
                    if handle then
                        handle.Size = Vector3.new(state.hitboxSize, state.hitboxSize, state.hitboxSize)
                        handle.Transparency = 0.5
                    end
                end
            end
        end
    end
end)

-- ============================================================
-- ESP & BALL TRACER
-- ============================================================
local espCache = {}
local ballTracer = Drawing.new("Line")
ballTracer.Thickness = 2
ballTracer.Color = Color3.fromRGB(255, 50, 50)
ballTracer.Visible = false

local function clearESP()
    for _, drawing in pairs(espCache) do
        if drawing and drawing.Remove then drawing:Remove() end
    end
    espCache = {}
end

RunService.RenderStepped:Connect(function()
    local cam = Workspace.CurrentCamera
    if not cam then return end

    -- Ball Tracer
    if state.ballTracer then
        local ball = getBall()
        if ball then
            local screenPos, onScreen = cam:WorldToViewportPoint(ball.Position)
            if onScreen then
                ballTracer.From = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y)
                ballTracer.To = Vector2.new(screenPos.X, screenPos.Y)
                ballTracer.Visible = true
            else
                ballTracer.Visible = false
            end
        else
            ballTracer.Visible = false
        end
    else
        ballTracer.Visible = false
    end

    -- Player ESP
    if state.espEnabled then
        local seen = {}
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character then
                local head = plr.Character:FindFirstChild("Head")
                local root = plr.Character:FindFirstChild("HumanoidRootPart")
                if head and root then
                    seen[plr] = true
                    if not espCache[plr] then
                        espCache[plr] = {
                            name = Drawing.new("Text"),
                            box = Drawing.new("Square"),
                        }
                        espCache[plr].name.Size = 14
                        espCache[plr].name.Center = true
                        espCache[plr].name.Outline = true
                        espCache[plr].box.Thickness = 1
                        espCache[plr].box.Filled = false
                    end

                    local screenHead, onHead = cam:WorldToViewportPoint(head.Position)
                    local screenRoot, onRoot = cam:WorldToViewportPoint(root.Position)

                    if onHead and onRoot then
                        local height = math.abs(screenHead.Y - screenRoot.Y)
                        local width = height * 0.5
                        espCache[plr].name.Position = Vector2.new(screenHead.X, screenHead.Y - 20)
                        espCache[plr].name.Text = plr.Name
                        espCache[plr].name.Color = Color3.new(1, 1, 1)
                        espCache[plr].name.Visible = true
                        espCache[plr].box.Position = Vector2.new(screenHead.X - width / 2, screenHead.Y)
                        espCache[plr].box.Size = Vector2.new(width, height)
                        espCache[plr].box.Color = Color3.new(1, 1, 1)
                        espCache[plr].box.Visible = true
                    else
                        espCache[plr].name.Visible = false
                        espCache[plr].box.Visible = false
                    end
                end
            end
        end
        for plr, drawings in pairs(espCache) do
            if not seen[plr] then
                drawings.name.Visible = false
                drawings.box.Visible = false
            end
        end
    end
end)

-- ============================================================
-- UI CONSTRUCTION (RAYFIELD)
-- ============================================================
local CombatTab = Window:CreateTab("Combat", nil)
local VisualsTab = Window:CreateTab("Visuals", nil)

CombatTab:CreateSection("Automation")
CombatTab:CreateToggle({ Name = "Auto Swing", CurrentValue = false, Flag = "AutoSwing", Callback = function(v) state.autoSwing = v end })
CombatTab:CreateToggle({ Name = "Camera Aimbot", CurrentValue = false, Flag = "AutoAim", Callback = function(v) state.autoAim = v end })
CombatTab:CreateToggle({ Name = "Ball Magnet", CurrentValue = false, Flag = "Magnet", Callback = function(v) state.magnet = v end })
CombatTab:CreateSlider({ Name = "Magnet Strength", Range = {0.05, 0.5}, Increment = 0.01, CurrentValue = 0.15, Suffix = "lerp", Flag = "MagnetStr", Callback = function(v) state.magnetStrength = v end })

CombatTab:CreateSection("Mechanics")
CombatTab:CreateToggle({ Name = "Dash Spam (Q)", CurrentValue = false, Flag = "DashSpam", Callback = function(v) state.dashSpam = v end })
CombatTab:CreateToggle({ Name = "Set Spam (E)", CurrentValue = false, Flag = "SetSpam", Callback = function(v) state.setSpam = v end })
CombatTab:CreateToggle({ Name = "Auto Ability (1)", CurrentValue = false, Flag = "AutoAbility", Callback = function(v) state.autoAbility = v end })

CombatTab:CreateSection("Hitbox")
CombatTab:CreateToggle({ Name = "Expand Hitbox", CurrentValue = false, Flag = "Hitbox", Callback = function(v) state.hitboxExpander = v end })
CombatTab:CreateSlider({ Name = "Hitbox Size", Range = {5, 30}, Increment = 1, CurrentValue = 10, Suffix = "studs", Flag = "HitboxSize", Callback = function(v) state.hitboxSize = v end })

VisualsTab:CreateSection("ESP")
VisualsTab:CreateToggle({ Name = "Player ESP", CurrentValue = false, Flag = "ESP", Callback = function(v) state.espEnabled = v end })
VisualsTab:CreateToggle({ Name = "Ball Tracer", CurrentValue = false, Flag = "BallTracer", Callback = function(v) state.ballTracer = v end })

Rayfield:Notify({ Title = "master venom online", Content = "Racket Rivals premium hub loaded", Duration = 5 })
