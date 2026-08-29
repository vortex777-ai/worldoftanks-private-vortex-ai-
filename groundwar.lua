local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"

local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Options = Library.Options
local Toggles = Library.Toggles

Library.ForceCheckbox = false
Library.ShowToggleFrameInKeybinds = true

local Window = Library:CreateWindow({
    Title = "JulyScripts",
    Footer = "GroundWar v0.1",
    Icon = "rbxassetid://116255434488074",
    NotifySide = "Right",
    ShowCustomCursor = true,
})

local Tabs = {
    Main = Window:AddTab("Main", "crosshair"),
    Visuals = Window:AddTab("Visuals", "eye"),
    Misc = Window:AddTab("Misc", "settings"),
    ["UI Settings"] = Window:AddTab("UI", "wrench"),
}

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local character = nil
local humanoid = nil
local humanoidRootPart = nil
local camera = workspace.CurrentCamera

local isUnloaded = false

local function RefreshCharacter()
    character = player.Character
    if not character then
        humanoid = nil
        humanoidRootPart = nil
        return
    end
    humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        humanoid = character:WaitForChild("Humanoid", 10)
    end
    humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then
        humanoidRootPart = character:WaitForChild("HumanoidRootPart", 10)
    end
    camera = workspace.CurrentCamera
end

RefreshCharacter()

local function GetHumanoid()
    local char = player.Character
    if not char then return nil end
    return char:FindFirstChildOfClass("Humanoid")
end

-- =========================================================
-- ГЛОБАЛЬНЫЕ ПЕРЕМЕННЫЕ
-- =========================================================

-- Aimbot
local aimbotEnabled = false
local aimbotRange = 3000
local aimbotFOV = 90 -- градусы
local aimAtHead = true
local teamCheck = true
local wallCheck = true
local aimbotSmoothness = 0.3
local isAiming = false
local aimbotConnection = nil

-- FOV Circle
local showFOVCircle = false
local fovCircleDrawing = nil
local fovCircleColor = Color3.fromRGB(255, 255, 255)
local fovCircleThickness = 1

local predictionEnabled = false
local predictionStrength = 1
local predictionMaxTime = 1.5
local predictionWeaponFallback = 1500

local rcsEnabled = false
local noSpreadEnabled = false
local rcsStrength = 100

local rapidFireEnabled = false
local rapidFireRate = 1200
local originalWeaponSettings = {}
local originalShootRates = {}
local weaponConnections = {}

-- Speed hack
local speedHackEnabled = false
local speedHackValue = 50
local speedHackHeartbeat = nil
local speedHackPropertyConnection = nil
local speedHackHumanoid = nil

-- Jump height
local jumpHeightEnabled = false
local jumpHeightValue = 50
local jumpHeightHeartbeat = nil
local jumpHeightPropertyConnection = nil
local jumpHeightHumanoid = nil

-- Fly
local flyEnabled = false
local flySpeed = 50
local flyConnection = nil
local flyBodyVelocity = nil
local flyBodyGyro = nil
local flyHumanoid = nil
local StopFly = nil

-- ESP
local espEnabled = false
local espConfig = {
    Boxes = true,
    BoxColor = Color3.fromRGB(255, 50, 50),
    BoxThickness = 1,
    Names = true,
    NameColor = Color3.fromRGB(255, 255, 255),
    NameSize = 13,
    Distance = true,
    DistanceColor = Color3.fromRGB(200, 200, 200),
    DistanceSize = 11,
    HealthBar = true,
    Tracers = false,
    TracerColor = Color3.fromRGB(255, 50, 50),
    TracerThickness = 1,
    TracerOnlyEnemy = false,
    HeadDots = false,
    HeadDotColor = Color3.fromRGB(255, 255, 255),
    HeadDotRadius = 3,
    MaxDistance = 2500,
    TeamColor = false
}
local espObjects = {}
local espConnections = {}
local espRenderConnection = nil

-- =========================================================
-- ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ
-- =========================================================

local function createDrawing(type, props)
    local obj = Drawing.new(type)
    for k, v in pairs(props) do
        obj[k] = v
    end
    return obj
end

-- =========================================================
-- TEAM CHECK
-- =========================================================

local function GetPlayerTeamKey(plr)
    if not plr then return nil end
    local mgTeam = plr:GetAttribute("MG_Team")
    if mgTeam ~= nil then return mgTeam end
    if plr.Team ~= nil then return plr.Team end
    return nil
end

local function SameTeam(plr)
    if not teamCheck then return false end
    local myTeam = GetPlayerTeamKey(player)
    local theirTeam = GetPlayerTeamKey(plr)
    if myTeam == nil or theirTeam == nil then return false end
    return myTeam == theirTeam
end

local function IsAlly(plr)
    local myTeam = GetPlayerTeamKey(player)
    local theirTeam = GetPlayerTeamKey(plr)
    return myTeam ~= nil and theirTeam ~= nil and myTeam == theirTeam
end

-- =========================================================
-- ESP ЛОГИКА (без изменений)
-- =========================================================

local function registerESPPlayer(plr)
    if espObjects[plr] or plr == player or not plr then return end
    local drawings = {
        BoxOutline = createDrawing("Square", { Thickness = espConfig.BoxThickness + 2, Color = Color3.fromRGB(0, 0, 0), Filled = false, Visible = false }),
        Box = createDrawing("Square", { Thickness = espConfig.BoxThickness, Color = espConfig.BoxColor, Filled = false, Visible = false }),
        Name = createDrawing("Text", { Size = espConfig.NameSize, Center = true, Outline = true, Color = espConfig.NameColor, Visible = false }),
        Distance = createDrawing("Text", { Size = espConfig.DistanceSize, Center = true, Outline = true, Color = espConfig.DistanceColor, Visible = false }),
        HealthBarOutline = createDrawing("Line", { Thickness = 3, Color = Color3.fromRGB(0, 0, 0), Visible = false }),
        HealthBar = createDrawing("Line", { Thickness = 1, Visible = false }),
        Tracer = createDrawing("Line", { Thickness = espConfig.TracerThickness, Color = espConfig.TracerColor, Visible = false }),
        HeadDot = createDrawing("Circle", { Radius = espConfig.HeadDotRadius, Filled = true, Color = espConfig.HeadDotColor, Visible = false })
    }
    espObjects[plr] = drawings
end

local function removeESPPlayer(plr)
    local drawings = espObjects[plr]
    if not drawings then return end
    for _, d in pairs(drawings) do
        d.Visible = false
        pcall(function() d:Remove() end)
    end
    espObjects[plr] = nil
end

local function getRootPart(model)
    return model.PrimaryPart
        or model:FindFirstChild("HumanoidRootPart")
        or model:FindFirstChild("Torso")
        or model:FindFirstChild("UpperTorso")
        or model:FindFirstChild("Head")
        or model:FindFirstChildWhichIsA("BasePart")
end

local function isAlive(model)
    if not model or not model.Parent then return false end
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    return humanoid and humanoid.Health > 0 and humanoid.Parent
end

local function startESP()
    if espRenderConnection then
        pcall(function() espRenderConnection:Disconnect() end)
        espRenderConnection = nil
    end
    espRenderConnection = RunService.RenderStepped:Connect(function()
        if not espEnabled or isUnloaded then
            for _, drawings in pairs(espObjects) do
                for _, d in pairs(drawings) do
                    d.Visible = false
                end
            end
            return
        end

        local camPos = camera.CFrame.Position
        local viewportSize = camera.ViewportSize

        for plr, drawings in pairs(espObjects) do
            local targetCharacter = plr.Character
            if not targetCharacter or not isAlive(targetCharacter) then
                for _, d in pairs(drawings) do d.Visible = false end
                continue
            end

            local rootPart = getRootPart(targetCharacter)
            if not rootPart then
                for _, d in pairs(drawings) do d.Visible = false end
                continue
            end

            local dist = (camPos - rootPart.Position).Magnitude
            if dist > espConfig.MaxDistance then
                for _, d in pairs(drawings) do d.Visible = false end
                continue
            end

            local isR15 = targetCharacter:FindFirstChildOfClass("Humanoid").RigType == Enum.HumanoidRigType.R15
            local topPoint = rootPart.Position + Vector3.new(0, isR15 and 3.2 or 2.5, 0)
            local botPoint = rootPart.Position - Vector3.new(0, isR15 and 3.4 or 2.8, 0)

            local topPos, topOn = camera:WorldToViewportPoint(topPoint)
            local botPos, botOn = camera:WorldToViewportPoint(botPoint)

            if (topOn or botOn) and topPos.Z > 0 then
                local height = math.abs(topPos.Y - botPos.Y)
                local width = height * 0.6
                local posX = topPos.X - width * 0.5
                local posY = topPos.Y

                drawings.BoxOutline.Thickness = espConfig.BoxThickness + 2
                drawings.Box.Thickness = espConfig.BoxThickness
                drawings.Name.Size = espConfig.NameSize
                drawings.Distance.Size = espConfig.DistanceSize
                drawings.Tracer.Thickness = espConfig.TracerThickness
                drawings.HeadDot.Radius = espConfig.HeadDotRadius

                local boxColor = espConfig.BoxColor
                if espConfig.TeamColor then
                    if IsAlly(plr) then
                        boxColor = Color3.fromRGB(0, 255, 0)
                    else
                        boxColor = Color3.fromRGB(255, 255, 255)
                    end
                end

                if espConfig.Boxes then
                    drawings.BoxOutline.Size = Vector2.new(width, height)
                    drawings.BoxOutline.Position = Vector2.new(posX, posY)
                    drawings.BoxOutline.Visible = true

                    drawings.Box.Size = Vector2.new(width, height)
                    drawings.Box.Position = Vector2.new(posX, posY)
                    drawings.Box.Color = boxColor
                    drawings.Box.Visible = true
                else
                    drawings.BoxOutline.Visible = false
                    drawings.Box.Visible = false
                end

                if espConfig.Names then
                    drawings.Name.Position = Vector2.new(topPos.X, posY - espConfig.NameSize - 2)
                    drawings.Name.Text = plr.DisplayName
                    drawings.Name.Color = espConfig.NameColor
                    drawings.Name.Visible = true
                else
                    drawings.Name.Visible = false
                end

                if espConfig.Distance then
                    drawings.Distance.Position = Vector2.new(topPos.X, botPos.Y + 2)
                    drawings.Distance.Text = string.format("[%d studs]", math.floor(dist))
                    drawings.Distance.Color = espConfig.DistanceColor
                    drawings.Distance.Visible = true
                else
                    drawings.Distance.Visible = false
                end

                if espConfig.HealthBar then
                    local maxHp = targetCharacter:FindFirstChildOfClass("Humanoid").MaxHealth
                    local hp = maxHp > 0 and math.clamp(targetCharacter:FindFirstChildOfClass("Humanoid").Health / maxHp, 0, 1) or 1
                    local barX = posX - 5

                    drawings.HealthBarOutline.From = Vector2.new(barX, posY)
                    drawings.HealthBarOutline.To = Vector2.new(barX, posY + height)
                    drawings.HealthBarOutline.Visible = true

                    drawings.HealthBar.From = Vector2.new(barX, posY + height)
                    drawings.HealthBar.To = Vector2.new(barX, posY + height - (height * hp))
                    drawings.HealthBar.Color = Color3.fromRGB(255 - math.floor(hp * 255), math.floor(hp * 255), 0)
                    drawings.HealthBar.Visible = true
                else
                    drawings.HealthBarOutline.Visible = false
                    drawings.HealthBar.Visible = false
                end

                if espConfig.Tracers then
                    local showTracer = true
                    local tracerColor = espConfig.TracerColor

                    if espConfig.TracerOnlyEnemy then
                        if IsAlly(plr) then
                            showTracer = false
                        else
                            tracerColor = Color3.fromRGB(255, 255, 255)
                        end
                    else
                        if IsAlly(plr) then
                            tracerColor = Color3.fromRGB(0, 255, 0)
                        else
                            tracerColor = Color3.fromRGB(255, 255, 255)
                        end
                    end

                    if showTracer then
                        drawings.Tracer.From = Vector2.new(viewportSize.X * 0.5, viewportSize.Y)
                        drawings.Tracer.To = Vector2.new(topPos.X, botPos.Y)
                        drawings.Tracer.Color = tracerColor
                        drawings.Tracer.Visible = true
                    else
                        drawings.Tracer.Visible = false
                    end
                else
                    drawings.Tracer.Visible = false
                end

                if espConfig.HeadDots then
                    local head = targetCharacter:FindFirstChild("Head")
                    if head then
                        local headPos, headOn = camera:WorldToViewportPoint(head.Position)
                        if headOn and headPos.Z > 0 then
                            drawings.HeadDot.Position = Vector2.new(headPos.X, headPos.Y)
                            drawings.HeadDot.Color = espConfig.HeadDotColor
                            drawings.HeadDot.Visible = true
                        else
                            drawings.HeadDot.Visible = false
                        end
                    else
                        drawings.HeadDot.Visible = false
                    end
                else
                    drawings.HeadDot.Visible = false
                end
            else
                for _, d in pairs(drawings) do d.Visible = false end
            end
        end
    end)
end

local function startESPConnections()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= player then registerESPPlayer(plr) end
    end

    if not espConnections.PlayerAdded then
        espConnections.PlayerAdded = Players.PlayerAdded:Connect(function(plr)
            if plr ~= player and not isUnloaded then
                task.wait(0.5)
                registerESPPlayer(plr)
            end
        end)
    end
    if not espConnections.PlayerRemoving then
        espConnections.PlayerRemoving = Players.PlayerRemoving:Connect(function(plr)
            removeESPPlayer(plr)
        end)
    end
end

local function stopESP()
    if espRenderConnection then
        pcall(function() espRenderConnection:Disconnect() end)
        espRenderConnection = nil
    end
    for _, drawings in pairs(espObjects) do
        for _, d in pairs(drawings) do
            d.Visible = false
            pcall(function() d:Remove() end)
        end
    end
    espObjects = {}
    for _, conn in pairs(espConnections) do
        pcall(function() conn:Disconnect() end)
    end
    espConnections = {}
end

-- =========================================================
-- FLY
-- =========================================================

local function StartFly()
    if not flyEnabled or isUnloaded then return end
    StopFly()

    local char = player.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    flyHumanoid = hum
    hum.PlatformStand = true
    hum.Sit = false

    flyBodyVelocity = Instance.new("BodyVelocity")
    flyBodyVelocity.MaxForce = Vector3.new(1e5, 1e5, 1e5)
    flyBodyVelocity.Velocity = Vector3.zero
    flyBodyVelocity.Parent = root

    flyBodyGyro = Instance.new("BodyGyro")
    flyBodyGyro.MaxTorque = Vector3.new(1e6, 1e6, 1e6)
    flyBodyGyro.CFrame = root.CFrame
    flyBodyGyro.Parent = root

    flyConnection = RunService.Heartbeat:Connect(function()
        if not flyEnabled or isUnloaded or not char.Parent or not root.Parent then
            StopFly()
            return
        end

        local cam = workspace.CurrentCamera
        if not cam then return end

        local forward = UserInputService:IsKeyDown(Enum.KeyCode.W) and 1 or 0
        local backward = UserInputService:IsKeyDown(Enum.KeyCode.S) and 1 or 0
        local left = UserInputService:IsKeyDown(Enum.KeyCode.A) and 1 or 0
        local right = UserInputService:IsKeyDown(Enum.KeyCode.D) and 1 or 0
        local up = UserInputService:IsKeyDown(Enum.KeyCode.Space) and 1 or 0
        local down = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) and 1 or 0

        local moveX = right - left
        local moveZ = forward - backward
        local moveY = up - down

        if moveX == 0 and moveZ == 0 and moveY == 0 then
            flyBodyVelocity.Velocity = Vector3.zero
            return
        end

        local camCFrame = cam.CFrame
        local forwardVec = camCFrame.LookVector
        local rightVec = camCFrame.RightVector
        local upVec = camCFrame.UpVector

        local flatForward = Vector3.new(forwardVec.X, 0, forwardVec.Z)
        local flatRight = Vector3.new(rightVec.X, 0, rightVec.Z)
        if flatForward.Magnitude > 0 then flatForward = flatForward.Unit end
        if flatRight.Magnitude > 0 then flatRight = flatRight.Unit end

        local moveDirection = flatForward * moveZ + flatRight * moveX + upVec * moveY
        if moveDirection.Magnitude > 0 then moveDirection = moveDirection.Unit * flySpeed end

        flyBodyVelocity.Velocity = moveDirection

        if moveDirection.Magnitude > 0 then
            local target = root.Position + moveDirection.Unit * 100
            flyBodyGyro.CFrame = CFrame.lookAt(root.Position, target, upVec)
        end
    end)
end

StopFly = function()
    if flyConnection then pcall(function() flyConnection:Disconnect() end) flyConnection = nil end
    if flyBodyVelocity then pcall(function() flyBodyVelocity:Destroy() end) flyBodyVelocity = nil end
    if flyBodyGyro then pcall(function() flyBodyGyro:Destroy() end) flyBodyGyro = nil end
    if flyHumanoid then pcall(function() flyHumanoid.PlatformStand = false end) flyHumanoid = nil end
end

-- =========================================================
-- ПОИСК ЦЕЛИ (СТАРЫЙ АИМ: угловой FOV, несколько точек видимости)
-- =========================================================

local function GetTargetPart(char)
    if not char then return nil end
    if aimAtHead then
        local head = char:FindFirstChild("Head")
        if head and head:IsA("BasePart") then return head end
    end
    local root = char:FindFirstChild("HumanoidRootPart")
    if root and root:IsA("BasePart") then return root end
    local upperTorso = char:FindFirstChild("UpperTorso")
    if upperTorso and upperTorso:IsA("BasePart") then return upperTorso end
    local torso = char:FindFirstChild("Torso")
    if torso and torso:IsA("BasePart") then return torso end
    return nil
end

local function IsCharacterAlive(char)
    if not char then return false end
    local targetHumanoid = char:FindFirstChildOfClass("Humanoid")
    return targetHumanoid ~= nil and targetHumanoid.Health > 0
end

local function IsVisible(targetPart)
    if not wallCheck then return true end
    local cam = workspace.CurrentCamera
    if not cam or not targetPart then return false end

    local targetCharacter = targetPart.Parent
    if not targetCharacter then return false end

    local origin = cam.CFrame.Position
    local points = {}
    local head = targetCharacter:FindFirstChild("Head")
    local upperTorso = targetCharacter:FindFirstChild("UpperTorso")
    local torso = targetCharacter:FindFirstChild("Torso")
    local root = targetCharacter:FindFirstChild("HumanoidRootPart")

    if head and head:IsA("BasePart") then table.insert(points, head.Position) end
    if upperTorso and upperTorso:IsA("BasePart") then table.insert(points, upperTorso.Position) end
    if torso and torso:IsA("BasePart") then table.insert(points, torso.Position) end
    if root and root:IsA("BasePart") then table.insert(points, root.Position) end
    if #points == 0 then table.insert(points, targetPart.Position) end

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = { character, targetCharacter }
    params.IgnoreWater = true

    for _, position in ipairs(points) do
        local direction = position - origin
        if direction.Magnitude > 0.001 then
            local result = workspace:Raycast(origin, direction, params)
            if result == nil then return true end
        end
    end
    return false
end

local function GetClosestTarget()
    local cam = workspace.CurrentCamera
    if not cam then return nil end
    if not character then RefreshCharacter(); if not character then return nil end end

    local cameraPosition = cam.CFrame.Position
    local cameraLook = cam.CFrame.LookVector
    local bestTarget = nil
    local bestScore = math.huge

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == player then continue end
        if SameTeam(plr) then continue end

        local char = plr.Character
        if not char or not IsCharacterAlive(char) then continue end

        local targetPart = GetTargetPart(char)
        if not targetPart then continue end

        local offset = targetPart.Position - cameraPosition
        local distance = offset.Magnitude
        if distance <= 0.001 or distance > aimbotRange then continue end

        local direction = offset.Unit
        local dot = math.clamp(cameraLook:Dot(direction), -1, 1)
        local angle = math.deg(math.acos(dot))
        if angle > aimbotFOV then continue end

        if wallCheck and not IsVisible(targetPart) then continue end

        local distancePenalty = (distance / math.max(aimbotRange, 1)) * 0.05
        local score = angle + distancePenalty

        if score < bestScore then
            bestScore = score
            bestTarget = targetPart
        end
    end
    return bestTarget
end

-- =========================================================
-- AIMBOT
-- =========================================================

local function GetCamera()
    camera = workspace.CurrentCamera
    return camera
end

local function GetWeaponSettings(tool)
    if not tool or not tool:IsA("Tool") then return nil end
    local settingsModule = tool:FindFirstChild("ACS_Settings")
    if not settingsModule or not settingsModule:IsA("ModuleScript") then return nil end
    local success, settings = pcall(function() return require(settingsModule) end)
    if not success or type(settings) ~= "table" then return nil end
    return settings
end

local function GetCurrentWeaponSettings()
    if not character then return nil, nil end
    for _, child in ipairs(character:GetChildren()) do
        if child:IsA("Tool") then
            local settings = GetWeaponSettings(child)
            if settings then return settings, child end
        end
    end
    return nil, nil
end

local function GetBulletVelocity()
    local settings = GetCurrentWeaponSettings()
    if settings and tonumber(settings.MuzzleVelocity) then
        local velocity = tonumber(settings.MuzzleVelocity)
        if velocity > 0 then return velocity end
    end
    return predictionWeaponFallback
end

local function GetTargetVelocity(targetPart)
    if not targetPart then return Vector3.zero end
    local targetCharacter = targetPart.Parent
    if not targetCharacter then return Vector3.zero end
    local root = targetCharacter:FindFirstChild("HumanoidRootPart")
    if root and root:IsA("BasePart") then return root.AssemblyLinearVelocity end
    local upperTorso = targetCharacter:FindFirstChild("UpperTorso")
    if upperTorso and upperTorso:IsA("BasePart") then return upperTorso.AssemblyLinearVelocity end
    local torso = targetCharacter:FindFirstChild("Torso")
    if torso and torso:IsA("BasePart") then return torso.AssemblyLinearVelocity end
    if targetPart:IsA("BasePart") then return targetPart.AssemblyLinearVelocity end
    return Vector3.zero
end

local function GetPredictedPosition(targetPart)
    if not targetPart then return nil end
    if not predictionEnabled then return targetPart.Position end
    local cam = GetCamera()
    if not cam then return targetPart.Position end
    local bulletVelocity = GetBulletVelocity()
    if bulletVelocity <= 0 then return targetPart.Position end
    local targetPosition = targetPart.Position
    local targetVelocity = GetTargetVelocity(targetPart)
    local distance = (targetPosition - cam.CFrame.Position).Magnitude
    local travelTime = distance / bulletVelocity
    travelTime = math.clamp(travelTime, 0, predictionMaxTime)
    return targetPosition + targetVelocity * travelTime * predictionStrength
end

local function AimAt(targetPart, dt)
    if not targetPart or not targetPart.Parent then return end
    local cam = GetCamera()
    if not cam then return end
    local targetCharacter = targetPart.Parent
    if not IsCharacterAlive(targetCharacter) then return end
    local origin = cam.CFrame.Position
    local targetPosition = GetPredictedPosition(targetPart)
    if not targetPosition then return end
    local direction = targetPosition - origin
    if direction.Magnitude <= 0.001 then return end
    local targetCFrame = CFrame.lookAt(origin, targetPosition)
    if aimbotSmoothness <= 0 then
        cam.CFrame = targetCFrame
        return
    end
    local response = 12
    local alpha = 1 - math.exp(-math.clamp(aimbotSmoothness, 0, 1) * dt * response)
    alpha = math.clamp(alpha, 0, 1)
    cam.CFrame = cam.CFrame:Lerp(targetCFrame, alpha)
end

local function StopAimbot()
    isAiming = false
    if aimbotConnection then
        pcall(function() aimbotConnection:Disconnect() end)
        aimbotConnection = nil
    end
end

local function StartAimbot()
    StopAimbot()
    if not aimbotEnabled or isUnloaded then return end
    aimbotConnection = RunService.RenderStepped:Connect(function(dt)
        if isUnloaded or not aimbotEnabled then return end
        local keybind = Options.AimbotKey
        if not keybind then return end
        local state = false
        pcall(function() state = keybind:GetState() end)
        isAiming = state
        if not state then return end
        local target = GetClosestTarget()
        if target then AimAt(target, dt) end
    end)
end

-- =========================================================
-- FOV CIRCLE (пересчёт градусов в пиксели)
-- =========================================================

local function updateFOVCircle()
    if not fovCircleDrawing then
        fovCircleDrawing = createDrawing("Circle", {
            Radius = 100,
            Thickness = fovCircleThickness,
            Color = fovCircleColor,
            Filled = false,
            Visible = false
        })
    end
    fovCircleDrawing.Visible = showFOVCircle and aimbotEnabled and not isUnloaded
    if fovCircleDrawing.Visible and camera then
        local viewportSize = camera.ViewportSize
        local fovY = camera.FieldOfView
        local radiusPixels = math.tan(math.rad(aimbotFOV / 2)) / math.tan(math.rad(fovY / 2)) * (viewportSize.Y / 2)
        fovCircleDrawing.Position = Vector2.new(viewportSize.X / 2, viewportSize.Y / 2)
        fovCircleDrawing.Radius = radiusPixels
        fovCircleDrawing.Color = fovCircleColor
        fovCircleDrawing.Thickness = fovCircleThickness
    end
end

RunService.RenderStepped:Connect(function()
    if showFOVCircle and aimbotEnabled and not isUnloaded then
        updateFOVCircle()
    end
end)

-- =========================================================
-- SPEED HACK
-- =========================================================

local function DisconnectSpeedHackProperty()
    if speedHackPropertyConnection then
        pcall(function() speedHackPropertyConnection:Disconnect() end)
        speedHackPropertyConnection = nil
    end
end

local function BindSpeedHackProperty(hum)
    DisconnectSpeedHackProperty()
    speedHackHumanoid = hum
    if not hum then return end
    speedHackPropertyConnection = hum:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
        if isUnloaded or not speedHackEnabled then return end
        if hum.Parent and hum.WalkSpeed ~= speedHackValue then
            hum.WalkSpeed = speedHackValue
        end
    end)
end

local function StopSpeedHack()
    if speedHackHeartbeat then
        pcall(function() speedHackHeartbeat:Disconnect() end)
        speedHackHeartbeat = nil
    end
    DisconnectSpeedHackProperty()
    speedHackHumanoid = nil
end

local function StartSpeedHack()
    StopSpeedHack()
    local hum = GetHumanoid()
    if hum then
        BindSpeedHackProperty(hum)
        hum.WalkSpeed = speedHackValue
    end
    speedHackHeartbeat = RunService.Heartbeat:Connect(function()
        if isUnloaded or not speedHackEnabled then return end
        local currentHumanoid = GetHumanoid()
        if not currentHumanoid then return end
        if currentHumanoid ~= speedHackHumanoid then
            BindSpeedHackProperty(currentHumanoid)
        end
        if currentHumanoid.WalkSpeed ~= speedHackValue then
            currentHumanoid.WalkSpeed = speedHackValue
        end
    end)
end

-- =========================================================
-- JUMP HEIGHT
-- =========================================================

local function DisconnectJumpHeightProperty()
    if jumpHeightPropertyConnection then
        pcall(function() jumpHeightPropertyConnection:Disconnect() end)
        jumpHeightPropertyConnection = nil
    end
end

local function BindJumpHeightProperty(hum)
    DisconnectJumpHeightProperty()
    jumpHeightHumanoid = hum
    if not hum then return end
    pcall(function() hum.UseJumpPower = false end)
    jumpHeightPropertyConnection = hum:GetPropertyChangedSignal("JumpHeight"):Connect(function()
        if isUnloaded or not jumpHeightEnabled then return end
        if hum.Parent and hum.JumpHeight ~= jumpHeightValue then
            hum.JumpHeight = jumpHeightValue
        end
    end)
end

local function StopJumpHeight()
    if jumpHeightHeartbeat then
        pcall(function() jumpHeightHeartbeat:Disconnect() end)
        jumpHeightHeartbeat = nil
    end
    DisconnectJumpHeightProperty()
    jumpHeightHumanoid = nil
end

local function StartJumpHeight()
    StopJumpHeight()
    local hum = GetHumanoid()
    if hum then
        pcall(function() hum.UseJumpPower = false end)
        BindJumpHeightProperty(hum)
        hum.JumpHeight = jumpHeightValue
    end
    jumpHeightHeartbeat = RunService.Heartbeat:Connect(function()
        if isUnloaded or not jumpHeightEnabled then return end
        local currentHumanoid = GetHumanoid()
        if not currentHumanoid then return end
        if currentHumanoid ~= jumpHeightHumanoid then
            BindJumpHeightProperty(currentHumanoid)
        end
        pcall(function() currentHumanoid.UseJumpPower = false end)
        if currentHumanoid.JumpHeight ~= jumpHeightValue then
            currentHumanoid.JumpHeight = jumpHeightValue
        end
    end)
end

-- =========================================================
-- WEAPON MODS (RCS, NoSpread, Rapid Fire)
-- =========================================================

local function CopyPair(pair)
    if type(pair) ~= "table" then return nil end
    local first = tonumber(pair[1]) or 0
    local second = tonumber(pair[2]) or first
    return { first, second }
end

local function CopyRecoil(recoil, prefix)
    if type(recoil) ~= "table" then return nil end
    return {
        [prefix .. "Up"] = CopyPair(recoil[prefix .. "Up"]),
        [prefix .. "Tilt"] = CopyPair(recoil[prefix .. "Tilt"]),
        [prefix .. "Left"] = CopyPair(recoil[prefix .. "Left"]),
        [prefix .. "Right"] = CopyPair(recoil[prefix .. "Right"]),
    }
end

local function SaveOriginalSettings(tool, settings)
    if originalWeaponSettings[tool] then return end
    originalWeaponSettings[tool] = {
        camRecoil = CopyRecoil(settings.camRecoil, "camRecoil"),
        gunRecoil = CopyRecoil(settings.gunRecoil, "gunRecoil"),
        MinSpread = settings.MinSpread,
        MaxSpread = settings.MaxSpread,
        AimSpreadReduction = settings.AimSpreadReduction,
    }
end

local function SaveOriginalShootRate(tool, settings)
    if originalShootRates[tool] ~= nil then return end
    originalShootRates[tool] = settings.ShootRate
end

local function ScaleRecoil(recoil, prefix, multiplier)
    if type(recoil) ~= "table" then return nil end
    local result = {}
    local up = recoil[prefix .. "Up"]
    local tilt = recoil[prefix .. "Tilt"]
    local left = recoil[prefix .. "Left"]
    local right = recoil[prefix .. "Right"]
    if up then result[prefix .. "Up"] = { up[1] * multiplier, up[2] * multiplier } end
    if tilt then result[prefix .. "Tilt"] = { tilt[1] * multiplier, tilt[2] * multiplier } end
    if left then result[prefix .. "Left"] = { left[1] * multiplier, left[2] * multiplier } end
    if right then result[prefix .. "Right"] = { right[1] * multiplier, right[2] * multiplier } end
    return result
end

local function ApplyWeaponSettings(tool)
    local settings = GetWeaponSettings(tool)
    if not settings then return end
    SaveOriginalSettings(tool, settings)
    SaveOriginalShootRate(tool, settings)
    local original = originalWeaponSettings[tool]
    if not original then return end
    if rcsEnabled then
        local strength = math.clamp(rcsStrength / 100, 0, 1)
        local multiplier = 1 - strength
        if original.camRecoil then settings.camRecoil = ScaleRecoil(original.camRecoil, "camRecoil", multiplier) end
        if original.gunRecoil then settings.gunRecoil = ScaleRecoil(original.gunRecoil, "gunRecoil", multiplier) end
    else
        if original.camRecoil then settings.camRecoil = original.camRecoil end
        if original.gunRecoil then settings.gunRecoil = original.gunRecoil end
    end
    if noSpreadEnabled then
        settings.MinSpread = 0
        settings.MaxSpread = 0
        settings.AimSpreadReduction = 0
    else
        settings.MinSpread = original.MinSpread
        settings.MaxSpread = original.MaxSpread
        settings.AimSpreadReduction = original.AimSpreadReduction
    end
    if rapidFireEnabled then
        settings.ShootRate = rapidFireRate
    else
        local originalRate = originalShootRates[tool]
        if originalRate ~= nil then settings.ShootRate = originalRate end
    end
end

local function RestoreWeaponSettings(tool)
    local original = originalWeaponSettings[tool]
    if original then
        local settings = GetWeaponSettings(tool)
        if settings then
            settings.camRecoil = original.camRecoil
            settings.gunRecoil = original.gunRecoil
            settings.MinSpread = original.MinSpread
            settings.MaxSpread = original.MaxSpread
            settings.AimSpreadReduction = original.AimSpreadReduction
        end
    end
    local originalRate = originalShootRates[tool]
    if originalRate ~= nil then
        local settings = GetWeaponSettings(tool)
        if settings then settings.ShootRate = originalRate end
    end
end

local function UpdateCurrentWeapon()
    if not character then return end
    for _, child in ipairs(character:GetChildren()) do
        if child:IsA("Tool") then
            task.defer(function() ApplyWeaponSettings(child) end)
        end
    end
end

local function UpdateRapidFire()
    UpdateCurrentWeapon()
end

local function SetupWeaponTracking(char)
    for _, connection in pairs(weaponConnections) do
        pcall(function() connection:Disconnect() end)
    end
    weaponConnections = {}
    table.insert(weaponConnections, char.ChildAdded:Connect(function(child)
        if isUnloaded then return end
        if child:IsA("Tool") then
            task.defer(function() ApplyWeaponSettings(child) end)
        end
    end))
    table.insert(weaponConnections, char.ChildRemoved:Connect(function(child)
        if child:IsA("Tool") then
            task.defer(function() RestoreWeaponSettings(child) end)
        end
    end))
    for _, child in ipairs(char:GetChildren()) do
        if child:IsA("Tool") then
            task.defer(function() ApplyWeaponSettings(child) end)
        end
    end
end

-- =========================================================
-- CHARACTER ADDED
-- =========================================================

local characterAddedConnection
characterAddedConnection = player.CharacterAdded:Connect(function(newCharacter)
    if isUnloaded then return end
    character = newCharacter
    humanoid = newCharacter:WaitForChild("Humanoid", 10)
    humanoidRootPart = newCharacter:WaitForChild("HumanoidRootPart", 10)
    camera = workspace.CurrentCamera
    SetupWeaponTracking(newCharacter)
    task.wait(0.2)
    UpdateCurrentWeapon()
    if speedHackEnabled then StartSpeedHack() end
    if jumpHeightEnabled then StartJumpHeight() end
    if flyEnabled then StartFly() end
end)

if character then
    SetupWeaponTracking(character)
    UpdateCurrentWeapon()
end

-- =========================================================
-- UI
-- =========================================================

-- --- AIMBOT GROUP ---
local AimGroup = Tabs.Main:AddGroupbox({ Side = "Left", Name = "Aimbot", IconName = "crosshair" })

AimGroup:AddToggle("EnableAimbot", {
    Text = "Enable Aimbot",
    Default = false,
    Callback = function(state)
        if isUnloaded then return end
        aimbotEnabled = state
        if state then StartAimbot() else StopAimbot() end
        updateFOVCircle()
    end,
})

AimGroup:AddSlider("Range", {
    Text = "Range",
    Default = 3000,
    Min = 50,
    Max = 3000,
    Rounding = 0,
    Callback = function(v) aimbotRange = v end,
})

AimGroup:AddSlider("FOV", {
    Text = "FOV (degrees)",
    Default = 90,
    Min = 1,
    Max = 180,
    Rounding = 0,
    Callback = function(v) aimbotFOV = v; updateFOVCircle() end,
})

AimGroup:AddToggle("AimAtHead", {
    Text = "Aim at Head",
    Default = true,
    Callback = function(v) aimAtHead = v end,
})

AimGroup:AddToggle("TeamCheck", {
    Text = "Team Check",
    Default = true,
    Callback = function(v) teamCheck = v end,
})

AimGroup:AddToggle("WallCheck", {
    Text = "Wall Check",
    Default = true,
    Callback = function(v) wallCheck = v end,
})

AimGroup:AddSlider("Smoothness", {
    Text = "Smoothness",
    Default = 0.3,
    Min = 0,
    Max = 1,
    Rounding = 2,
    Callback = function(v) aimbotSmoothness = v end,
})

AimGroup:AddDivider()

AimGroup:AddToggle("Prediction", {
    Text = "Prediction",
    Default = false,
    Callback = function(v) predictionEnabled = v end,
})

AimGroup:AddSlider("PredictionStrength", {
    Text = "Prediction Strength",
    Default = 1,
    Min = 0,
    Max = 2,
    Rounding = 2,
    Callback = function(v) predictionStrength = v end,
})

AimGroup:AddSlider("PredictionMaxTime", {
    Text = "Prediction Max Time",
    Default = 1.5,
    Min = 0.05,
    Max = 3,
    Rounding = 2,
    Callback = function(v) predictionMaxTime = v end,
})

AimGroup:AddDivider()

AimGroup:AddLabel("Aimbot Key"):AddKeyPicker("AimbotKey", {
    Default = "MB2",
    Mode = "Hold",
    NoUI = false,
    Text = "Aimbot Key",
})
-- --- RCS GROUP ---
local RCSGroup = Tabs.Main:AddGroupbox({ Side = "Right", Name = "RCS", IconName = "target" })
RCSGroup:AddToggle("RCS", { Text = "RCS", Default = false, Callback = function(state)
    if isUnloaded then return end
    rcsEnabled = state
    UpdateCurrentWeapon()
end })
RCSGroup:AddSlider("RCSStrength", { Text = "RCS Strength", Default = 100, Min = 0, Max = 100, Rounding = 0, Callback = function(v)
    rcsStrength = v
    if rcsEnabled then UpdateCurrentWeapon() end
end })
RCSGroup:AddToggle("NoSpread", { Text = "No Spread", Default = false, Callback = function(state)
    if isUnloaded then return end
    noSpreadEnabled = state
    UpdateCurrentWeapon()
end })

-- --- RAPID FIRE GROUP ---
local RapidFireGroup = Tabs.Main:AddGroupbox({ Side = "Right", Name = "Rapid Fire", IconName = "zap" })
RapidFireGroup:AddToggle("RapidFire", { Text = "Rapid Fire", Default = false, Callback = function(state)
    if isUnloaded then return end
    rapidFireEnabled = state
    UpdateRapidFire()
end })
RapidFireGroup:AddSlider("RapidFireRate", { Text = "Rapid Fire Rate", Default = 1200, Min = 1, Max = 5000, Rounding = 0, Callback = function(v)
    rapidFireRate = v
    if rapidFireEnabled then UpdateRapidFire() end
end })

-- --- MISC TAB ---
local PlayerGroup = Tabs.Misc:AddGroupbox({ Side = "Left", Name = "Player", IconName = "user" })
PlayerGroup:AddSlider("Gravity", { Text = "Gravity", Default = 196, Min = 1, Max = 500, Rounding = 0, Callback = function(v) if not isUnloaded then workspace.Gravity = v end end })

local JumpGroup = Tabs.Misc:AddGroupbox({ Side = "Right", Name = "Jump", IconName = "arrow-up" })
JumpGroup:AddToggle("JumpHeightEnabled", { Text = "Jump Height", Default = false, Callback = function(state)
    if isUnloaded then return end
    jumpHeightEnabled = state
    if state then StartJumpHeight() else StopJumpHeight() end
end })
JumpGroup:AddSlider("JumpHeightValue", { Text = "Jump Height Value", Default = 50, Min = 7, Max = 150, Rounding = 1, Callback = function(v)
    jumpHeightValue = v
    if jumpHeightEnabled then
        local hum = GetHumanoid()
        if hum then hum.JumpHeight = v end
    end
end })

local SpeedGroup = Tabs.Misc:AddGroupbox({ Side = "Left", Name = "Speed", IconName = "zap" })
SpeedGroup:AddToggle("SpeedHack", { Text = "Speed Hack", Default = false, Callback = function(state)
    if isUnloaded then return end
    speedHackEnabled = state
    if state then StartSpeedHack() else StopSpeedHack() end
end })
SpeedGroup:AddSlider("SpeedValue", { Text = "Walk Speed", Default = 50, Min = 16, Max = 200, Rounding = 0, Callback = function(v)
    speedHackValue = v
    if speedHackEnabled then
        local hum = GetHumanoid()
        if hum then hum.WalkSpeed = v end
    end
end })

-- Fly Group
local FlyGroup = Tabs.Misc:AddGroupbox({ Side = "Right", Name = "Fly", IconName = "plane" })
FlyGroup:AddToggle("EnableFly", { Text = "Enable Fly", Default = false, Callback = function(state)
    if isUnloaded then return end
    flyEnabled = state
    if state then StartFly() else StopFly() end
end })
FlyGroup:AddSlider("FlySpeed", { Text = "Fly Speed", Default = 50, Min = 10, Max = 200, Rounding = 0, Callback = function(v) flySpeed = v end })

-- --- VISUALS TAB ---
local VisualGroup = Tabs.Visuals:AddGroupbox({ Side = "Left", Name = "Visuals", IconName = "eye" })
VisualGroup:AddToggle("ESP", { Text = "ESP", Default = false, Callback = function(state)
    if isUnloaded then return end
    espEnabled = state
    if state then
        startESPConnections()
        startESP()
    else
        stopESP()
    end
end })
VisualGroup:AddToggle("ESPBoxes", { Text = "Boxes", Default = true, Callback = function(state) espConfig.Boxes = state end })
VisualGroup:AddToggle("ESPNames", { Text = "Names", Default = true, Callback = function(state) espConfig.Names = state end })
VisualGroup:AddToggle("ESPDistance", { Text = "Distance", Default = true, Callback = function(state) espConfig.Distance = state end })
VisualGroup:AddToggle("ESPHealthBar", { Text = "Health Bar", Default = true, Callback = function(state) espConfig.HealthBar = state end })
VisualGroup:AddToggle("ESPTracers", { Text = "Tracers", Default = false, Callback = function(state) espConfig.Tracers = state end })
VisualGroup:AddToggle("ESPTracerOnlyEnemy", { Text = "Only Enemy", Default = false, Callback = function(state) espConfig.TracerOnlyEnemy = state end })
VisualGroup:AddToggle("ESPHeadDots", { Text = "Head Dots", Default = false, Callback = function(state) espConfig.HeadDots = state end })
VisualGroup:AddToggle("ESPTeamColor", { Text = "Team Color (Green = Ally)", Default = false, Callback = function(state) espConfig.TeamColor = state end })
VisualGroup:AddSlider("ESPMaxDistance", { Text = "Max Distance", Default = 2500, Min = 100, Max = 5000, Rounding = 0, Callback = function(v) espConfig.MaxDistance = v end })
VisualGroup:AddSlider("ESPBoxThickness", { Text = "Box Thickness", Default = 1, Min = 1, Max = 3, Rounding = 0, Callback = function(v) espConfig.BoxThickness = v end })
VisualGroup:AddSlider("ESPNameSize", { Text = "Name Size", Default = 13, Min = 10, Max = 20, Rounding = 0, Callback = function(v) espConfig.NameSize = v end })
VisualGroup:AddSlider("ESPDistanceSize", { Text = "Distance Size", Default = 11, Min = 10, Max = 18, Rounding = 0, Callback = function(v) espConfig.DistanceSize = v end })

-- --- UI SETTINGS TAB ---
local UISettingsTab = Tabs["UI Settings"]
local MenuGroup = UISettingsTab:AddGroupbox({ Side = "Left", Name = "Menu", IconName = "wrench" })
MenuGroup:AddToggle("KeybindMenuOpen", { Default = Library.KeybindFrame.Visible, Text = "Open Keybind Menu", Callback = function(v) if not isUnloaded then Library.KeybindFrame.Visible = v end end })
MenuGroup:AddToggle("ShowCustomCursor", { Text = "Custom Cursor", Default = Library.ShowCustomCursor, Callback = function(v) if not isUnloaded then Library.ShowCustomCursor = v end end })
MenuGroup:AddToggle("AlwaysOnTop", { Text = "Always On Top", Default = Window.AlwaysOnTop, Callback = function(v) if not isUnloaded then Window:SetAlwaysOnTop(v) end end })
MenuGroup:AddDropdown("NotificationSide", { Values = {"Left","Right"}, Default = "Right", Text = "Notification Side", Callback = function(v) if not isUnloaded then Library:SetNotifySide(v) end end })
MenuGroup:AddSlider("DPISlider", { Text = "DPI Scale", Default = 100, Min = 50, Max = 200, Rounding = 0, Callback = function(v) if not isUnloaded then Library:SetDPIScale(v) end end })
MenuGroup:AddSlider("UICornerSlider", { Text = "Corner Radius", Default = Library.CornerRadius, Min = 0, Max = 20, Rounding = 0, Callback = function(v) if not isUnloaded then Window:SetCornerRadius(v) end end })
MenuGroup:AddDivider()
MenuGroup:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", { Default = "RightShift", NoUI = true, Text = "Menu keybind" })
MenuGroup:AddDivider()

local UnloadGroup = UISettingsTab:AddGroupbox({ Side = "Right", Name = "Unload", IconName = "power" })
UnloadGroup:AddButton({ Text = "Unload Script", Func = function() Library:Unload() end, Risky = true })

-- =========================================================
-- SAVE / THEME
-- =========================================================

Library.ToggleKeybind = Options.MenuKeybind
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({"MenuKeybind"})
ThemeManager:SetFolder("JulyGroundWar")
SaveManager:SetFolder("JulyGroundWar")
SaveManager:SetSubFolder("settings")
SaveManager:BuildConfigSection(UISettingsTab)
ThemeManager:ApplyToTab(UISettingsTab)
SaveManager:LoadAutoloadConfig()

-- Применяем сохранённые настройки
if Options.ESP then espEnabled = Options.ESP.Value or false end
if Options.EnableFly and Options.EnableFly.Value then
    flyEnabled = true
    StartFly()
end
if Options.ShowFOVCircle and Options.ShowFOVCircle.Value then
    showFOVCircle = true
    updateFOVCircle()
end
if Options.ESPTracerOnlyEnemy then
    espConfig.TracerOnlyEnemy = Options.ESPTracerOnlyEnemy.Value or false
end

-- =========================================================
-- UNLOAD
-- =========================================================

Library:OnUnload(function()
    if isUnloaded then return end
    isUnloaded = true

    aimbotEnabled = false
    isAiming = false
    StopAimbot()

    speedHackEnabled = false
    StopSpeedHack()

    jumpHeightEnabled = false
    StopJumpHeight()

    flyEnabled = false
    StopFly()

    espEnabled = false
    stopESP()

    if characterAddedConnection then
        pcall(function() characterAddedConnection:Disconnect() end)
        characterAddedConnection = nil
    end

    for tool, _ in pairs(originalWeaponSettings) do
        pcall(function() RestoreWeaponSettings(tool) end)
    end

    for tool, originalRate in pairs(originalShootRates) do
        pcall(function()
            local settings = GetWeaponSettings(tool)
            if settings then settings.ShootRate = originalRate end
        end)
    end

    originalWeaponSettings = {}
    originalShootRates = {}

    for _, connection in pairs(weaponConnections) do
        pcall(function() connection:Disconnect() end)
    end
    weaponConnections = {}

    if fovCircleDrawing then
        fovCircleDrawing.Visible = false
        pcall(function() fovCircleDrawing:Remove() end)
        fovCircleDrawing = nil
    end

    if humanoid then
        pcall(function() humanoid.PlatformStand = false; humanoid.Sit = false end)
    end
end)
