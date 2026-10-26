-- master venom: bloxstrike — apex flawless edition
-- runtime: Real executor

local success, Rayfield = pcall(function()
    return loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
end)
if not success or not Rayfield then return end

local Window = Rayfield:CreateWindow({
    Name = "master venom | apex",
    LoadingTitle = "master venom",
    LoadingSubtitle = "loading flawless modules...",
    Theme = "Dark",
    AccentColor = Color3.fromRGB(255, 255, 255),
    ConfigurationSaving = {Enabled = false},
    Discord = {Enabled = false},
    KeySystem = false,
})

task.wait(0.5)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

local state = {
    aimbot = false,
    silentAim = false,
    aimRadarGhosts = true,
    aimbotPart = "Head",
    aimbotFOV = 300,
    aimbotSmooth = 0.15,
    requireHold = true,
    showFOV = true,
    triggerbot = false,
    triggerbotDelay = 0.1,
    espEnabled = false,
    espFilter = "Enemies Only",
    espBox = true,
    espName = true,
    espHealth = true,
    espDistance = true,
    espTracer = false,
    crosshair = true,
}

-- ============================================================
-- CACHING & RADAR MATH
-- ============================================================
local function getMyTeam()
    local myTeam = LocalPlayer:GetAttribute("Team")
    if not myTeam and LocalPlayer.Character and LocalPlayer.Character.Parent then
        local pName = LocalPlayer.Character.Parent.Name
        if pName == "Terrorists" or pName == "Counter-Terrorists" then myTeam = pName end
    end
    return myTeam
end

local radarScale = 1.214
local cachedCharacters = {}

local function getRadarDots()
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    local radarRoot = pg and pg:FindFirstChild("MainGui") and pg.MainGui:FindFirstChild("Gameplay") and pg.MainGui.Gameplay:FindFirstChild("Middle") and pg.MainGui.Gameplay.Middle:FindFirstChild("Radar") and pg.MainGui.Gameplay.Middle.Radar:FindFirstChild("Radar")
    if not radarRoot then return nil, nil end
    return radarRoot:FindFirstChild("LocalPlayer"), radarRoot
end

local function calibrateRadar()
    local localChar = LocalPlayer.Character
    local localRoot = localChar and localChar:FindFirstChild("HumanoidRootPart")
    if not localRoot then return end
    local localDot, radarRoot = getRadarDots()
    if not localDot or not radarRoot then return end
    
    -- Use ANY player (teammate or enemy) to calibrate
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            local eDot = radarRoot:FindFirstChild(plr.Name)
            if eDot and eDot.Visible then
                local eRoot = plr.Character.HumanoidRootPart
                local dist3D = (Vector2.new(eRoot.Position.X, eRoot.Position.Z) - Vector2.new(localRoot.Position.X, localRoot.Position.Z)).Magnitude
                local dx = eDot.AbsolutePosition.X - localDot.AbsolutePosition.X
                local dy = eDot.AbsolutePosition.Y - localDot.AbsolutePosition.Y
                local distPixels = math.sqrt(dx*dx + dy*dy)
                if distPixels > 10 then
                    radarScale = dist3D / distPixels
                    break
                end
            end
        end
    end
end

local function updateCache()
    local list = {}
    local myTeam = getMyTeam()
    local seenNames = {}
    local charFolder = Workspace:FindFirstChild("Characters")
    local pvsFolder = ReplicatedStorage:FindFirstChild("_PVS_CulledCharacters")
    local localDot, radarRoot = getRadarDots()
    local localRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local camRot = Workspace.CurrentCamera.CFrame

    local function processChar(plr, char, isCulled)
        if not char or seenNames[char.Name] then return end
        local health = plr:GetAttribute("Health")
        local dead = plr:GetAttribute("Dead")
        if not (dead == true or (health and health <= 0)) then
            local head = char:FindFirstChild("Head")
            local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
            if head and root then
                seenNames[char.Name] = true
                local theirTeam = plr:GetAttribute("Team")
                
                local predictedPos = root.Position
                if isCulled and localRoot and localDot and radarRoot then
                    local eDot = radarRoot:FindFirstChild(plr.Name)
                    if eDot and eDot.Visible then
                        local dx = eDot.AbsolutePosition.X - localDot.AbsolutePosition.X
                        local dy = eDot.AbsolutePosition.Y - localDot.AbsolutePosition.Y
                        
                        local rightOffset = dx * radarScale
                        local forwardOffset = -dy * radarScale
                        
                        predictedPos = localRoot.Position + (camRot.RightVector * rightOffset) + (camRot.LookVector * forwardOffset)
                    end
                end

                table.insert(list, {
                    Player = plr, Model = char, Head = head, Root = root,
                    Health = health, MaxHealth = plr:GetAttribute("MaxHealth") or 100,
                    Team = theirTeam or "Unknown",
                    IsTeammate = (myTeam ~= nil and myTeam == theirTeam),
                    IsCulled = isCulled, PredictedPos = predictedPos
                })
            end
        end
    end

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            if plr.Character and plr.Character:IsDescendantOf(Workspace) then
                processChar(plr, plr.Character, false)
            elseif charFolder then
                local wChar = charFolder:FindFirstChild(plr.Name, true)
                if wChar then processChar(plr, wChar, false) end
            end
            if pvsFolder then
                local pvsChar = pvsFolder:FindFirstChild(plr.Name, true)
                if pvsChar then processChar(plr, pvsChar, true) end
            end
        end
    end
    cachedCharacters = list
end

task.spawn(function() while task.wait(0.1) do pcall(updateCache) end end)
task.spawn(function() while task.wait(1) do pcall(calibrateRadar) end end)

-- ============================================================
-- AIMBOT & HOOKS
-- ============================================================
local function getAimPart(charModel)
    if state.aimbotPart == "Head" then return charModel:FindFirstChild("Head")
    elseif state.aimbotPart == "Torso" then return charModel:FindFirstChild("UpperTorso") or charModel:FindFirstChild("Torso") end
    return charModel:FindFirstChild("HumanoidRootPart")
end

local function getClosestToMouse(maxFOV)
    local closestChar, closestPos, closestDist = nil, nil, math.huge
    local mousePos = UserInputService:GetMouseLocation()
    local cam = Workspace.CurrentCamera
    for _, data in ipairs(cachedCharacters) do
        if not data.IsTeammate then
            local targetPos = not data.IsCulled and getAimPart(data.Model) and getAimPart(data.Model).Position or (state.aimRadarGhosts and data.PredictedPos + Vector3.new(0, 1.5, 0))
            if targetPos then
                local screenPos, onScreen = cam:WorldToViewportPoint(targetPos)
                if onScreen then
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                    if dist < closestDist and dist < maxFOV then
                        closestDist, closestChar, closestPos = dist, data.Model, targetPos
                    end
                end
            end
        end
    end
    return closestChar, closestPos
end

local oldIndex
oldIndex = hookmetamethod(game, "__newindex", function(self, key, value)
    if self == Workspace.CurrentCamera and key == "CFrame" then
        if state.aimbot then
            if not state.requireHold or UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
                local target, targetPos = getClosestToMouse(state.aimbotFOV)
                if target and targetPos then
                    local lookAt = CFrame.lookAt(value.Position, targetPos)
                    value = state.aimbotSmooth > 0 and value:Lerp(lookAt, state.aimbotSmooth) or lookAt
                end
            end
        end
    end
    return oldIndex(self, key, value)
end)

pcall(function()
    local mt = getrawmetatable(game)
    local oldNamecall = mt.__namecall
    setreadonly(mt, false)
    mt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        if state.silentAim and (method == "FindPartOnRay" or method == "Raycast") then
            local target, targetPos = getClosestToMouse(state.aimbotFOV)
            if target and targetPos then
                local args = {...}
                if method == "FindPartOnRay" then
                    args[1] = Ray.new(Workspace.CurrentCamera.CFrame.Position, (targetPos - Workspace.CurrentCamera.CFrame.Position).Unit * 1000)
                elseif method == "Raycast" then
                    if typeof(args[1]) == "Ray" then
                        args[1] = Ray.new(Workspace.CurrentCamera.CFrame.Position, (targetPos - Workspace.CurrentCamera.CFrame.Position).Unit * 1000)
                    end
                end
                return oldNamecall(self, unpack(args))
            end
        end
        return oldNamecall(self, ...)
    end)
    setreadonly(mt, true)
end)

-- ============================================================
-- DRAWING ENGINE
-- ============================================================
local watermark = Drawing.new("Text")
watermark.Text = "master venom | apex"
watermark.Color = Color3.new(1, 1, 1)
watermark.Outline = true
watermark.Size = 16
watermark.Position = Vector2.new(20, 20)
watermark.Visible = true

local crosshairLine1 = Drawing.new("Line")
local crosshairLine2 = Drawing.new("Line")
local fovCircle = Drawing.new("Circle")
local espCache = {}

local function clearESP()
    for _, drawingTable in pairs(espCache) do
        for _, d in pairs(drawingTable) do 
            if typeof(d) == "Instance" and d.Remove then d:Remove() end 
        end
    end
    espCache = {}
end

RunService.RenderStepped:Connect(function()
    local cam = Workspace.CurrentCamera
    if not cam then return end
    
    local mPos = UserInputService:GetMouseLocation()
    
    if state.crosshair then
        crosshairLine1.From = mPos - Vector2.new(7, 0); crosshairLine1.To = mPos + Vector2.new(7, 0)
        crosshairLine2.From = mPos - Vector2.new(0, 7); crosshairLine2.To = mPos + Vector2.new(0, 7)
        crosshairLine1.Color = Color3.new(1, 1, 1); crosshairLine2.Color = Color3.new(1, 1, 1)
        crosshairLine1.Thickness = 1; crosshairLine2.Thickness = 1
        crosshairLine1.Visible = true; crosshairLine2.Visible = true
    else
        crosshairLine1.Visible = false; crosshairLine2.Visible = false
    end

    if state.showFOV and state.aimbot then
        fovCircle.Position = mPos; fovCircle.Radius = state.aimbotFOV; fovCircle.Visible = true
    else
        fovCircle.Visible = false
    end

    if state.espEnabled then
        local seenPlayers = {}
        for _, data in ipairs(cachedCharacters) do
            local show = (state.espFilter == "Both") or (state.espFilter == "Enemies Only" and not data.IsTeammate) or (state.espFilter == "Teammates Only" and data.IsTeammate)
            
            if show then
                seenPlayers[data.Player] = true
                if not espCache[data.Player] then
                    espCache[data.Player] = {
                        name = Drawing.new("Text"), box = Drawing.new("Square"), health = Drawing.new("Line"),
                        headDot = Drawing.new("Circle"), distance = Drawing.new("Text")
                    }
                    local c = espCache[data.Player]
                    c.name.Size = 14; c.name.Center = true; c.name.Outline = true
                    c.box.Thickness = 1; c.box.Filled = false
                    c.health.Thickness = 2
                    c.headDot.Radius = 3; c.headDot.Filled = true
                    c.distance.Size = 12; c.distance.Center = true; c.distance.Outline = true
                end

                local c = espCache[data.Player]
                local targetPos = data.IsCulled and (data.PredictedPos + Vector3.new(0, 1.5, 0)) or data.Head.Position
                local rootPos = data.IsCulled and data.PredictedPos or data.Root.Position
                local isGhost = data.IsCulled

                local screenHead, onHead = cam:WorldToViewportPoint(targetPos)
                local screenRoot, onRoot = cam:WorldToViewportPoint(rootPos)

                if onHead and onRoot then
                    local height = math.abs(screenHead.Y - screenRoot.Y)
                    local width = height * 0.5
                    local color = data.IsTeammate and Color3.new(0.5, 0.5, 0.5) or (isGhost and Color3.fromRGB(255, 100, 100) or Color3.new(1, 1, 1))

                    c.name.Position = Vector2.new(screenHead.X, screenHead.Y - 20)
                    c.name.Text = data.Player.Name .. (isGhost and " (Radar)" or "")
                    c.name.Color = color
                    c.name.Visible = state.espName

                    c.box.Position = Vector2.new(screenHead.X - width / 2, screenHead.Y)
                    c.box.Size = Vector2.new(width, height)
                    c.box.Color = color
                    c.box.Visible = state.espBox

                    if state.espHealth and data.Health then
                        local hPct = math.clamp(data.Health / data.MaxHealth, 0, 1)
                        c.health.From = Vector2.new(screenHead.X - width / 2 - 6, screenHead.Y + height)
                        c.health.To = Vector2.new(screenHead.X - width / 2 - 6, screenHead.Y + height - (height * hPct))
                        c.health.Color = Color3.fromRGB(255 * (1 - hPct), 255 * hPct, 0)
                        c.health.Visible = true
                    else c.health.Visible = false end

                    if state.espDistance then
                        local dist = (rootPos - cam.CFrame.Position).Magnitude
                        c.distance.Position = Vector2.new(screenHead.X, screenHead.Y + height + 5)
                        c.distance.Text = string.format("%d studs", math.floor(dist))
                        c.distance.Color = color
                        c.distance.Visible = true
                    else c.distance.Visible = false end

                    c.headDot.Position = Vector2.new(screenHead.X, screenHead.Y)
                    c.headDot.Color = color
                    c.headDot.Visible = true
                else
                    for _, d in pairs(c) do d.Visible = false end
                end
            end
        end
        for plr, drawings in pairs(espCache) do
            if not seenPlayers[plr] then
                for _, d in pairs(drawings) do d.Visible = false end
            end
        end
    end
end)

-- ============================================================
-- MOVEMENT & TRIGGERBOT
-- ============================================================
task.spawn(function()
    while task.wait(state.triggerbotDelay) do
        if state.triggerbot then
            local target = getClosestToMouse(state.aimbotFOV)
            if target then
                local part = getAimPart(target)
                if part and part.Transparency < 1 then
                    pcall(function() mouse1click() end)
                end
            end
        end
    end
end)

-- ============================================================
-- UI CONSTRUCTION
-- ============================================================
local CombatTab = Window:CreateTab("Combat", nil)
local VisualsTab = Window:CreateTab("Visuals", nil)

CombatTab:CreateSection("Aim Assistance")
CombatTab:CreateToggle({ Name = "Camera Aimbot", CurrentValue = false, Flag = "Aimbot", Callback = function(v) state.aimbot = v end })
CombatTab:CreateToggle({ Name = "Silent Aim (Raycast)", CurrentValue = false, Flag = "SilentAim", Callback = function(v) state.silentAim = v end })
CombatTab:CreateToggle({ Name = "Aim Radar Ghosts (Wallbang)", CurrentValue = true, Flag = "AimGhosts", Callback = function(v) state.aimRadarGhosts = v end })
CombatTab:CreateToggle({ Name = "Hold Right-Click (Legit)", CurrentValue = true, Flag = "HoldRMB", Callback = function(v) state.requireHold = v end })
CombatTab:CreateDropdown({ Name = "Aim Part", Options = {"Head", "Torso", "Root"}, CurrentOption = {"Head"}, MultipleOptions = false, Flag = "AimPart", Callback = function(opt) state.aimbotPart = opt[1] end })
CombatTab:CreateSlider({ Name = "Aimbot FOV", Range = {10, 800}, Increment = 1, CurrentValue = 300, Suffix = "px", Flag = "FOV", Callback = function(v) state.aimbotFOV = v end })
CombatTab:CreateSlider({ Name = "Aimbot Smoothness", Range = {0, 1}, Increment = 0.01, CurrentValue = 0.15, Suffix = "lerp", Flag = "Smooth", Callback = function(v) state.aimbotSmooth = v end })

CombatTab:CreateSection("Triggerbot")
CombatTab:CreateToggle({ Name = "Triggerbot", CurrentValue = false, Flag = "Triggerbot", Callback = function(v) state.triggerbot = v end })
CombatTab:CreateSlider({ Name = "Trigger Delay", Range = {0, 1}, Increment = 0.01, CurrentValue = 0.1, Suffix = "s", Flag = "TriggerDelay", Callback = function(v) state.triggerbotDelay = v end })

VisualsTab:CreateSection("3D ESP")
VisualsTab:CreateToggle({ Name = "ESP Enabled", CurrentValue = false, Flag = "ESP", Callback = function(v) state.espEnabled = v end })
VisualsTab:CreateDropdown({ Name = "ESP Filter", Options = {"Enemies Only", "Teammates Only", "Both"}, CurrentOption = {"Enemies Only"}, MultipleOptions = false, Flag = "ESPFilter", Callback = function(opt) state.espFilter = opt[1] end })
VisualsTab:CreateToggle({ Name = "Box", CurrentValue = true, Flag = "ESPBox", Callback = function(v) state.espBox = v end })
VisualsTab:CreateToggle({ Name = "Name", CurrentValue = true, Flag = "ESPName", Callback = function(v) state.espName = v end })
VisualsTab:CreateToggle({ Name = "Health Bar", CurrentValue = true, Flag = "ESPHealth", Callback = function(v) state.espHealth = v end })
VisualsTab:CreateToggle({ Name = "Distance", CurrentValue = true, Flag = "ESPDistance", Callback = function(v) state.espDistance = v end })

VisualsTab:CreateSection("Visuals")
VisualsTab:CreateToggle({ Name = "Custom Crosshair", CurrentValue = true, Flag = "Crosshair", Callback = function(v) state.crosshair = v end })
VisualsTab:CreateToggle({ Name = "Show FOV Circle", CurrentValue = true, Flag = "ShowFOV", Callback = function(v) state.showFOV = v end })
VisualsTab:CreateButton({ Name = "Refresh ESP", Callback = function() clearESP() end })

Rayfield:Notify({ Title = "master venom online", Content = "flawless build loaded", Duration = 5 })
