local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/sametexe001/sametlibs/refs/heads/main/Stellar/Library.lua"))()

local Window = Library:Window({
    Name = "JulyScripts",
    SubName = "+1 Power Per Click",
    Logo = "rbxassetid://116255434488074",
})

-- ==================== CLEAN SIDEBAR ====================

task.defer(function()
    local sidebar = Window.Items
        and Window.Items["Sidebar"]
        and Window.Items["Sidebar"].Instance

    if not sidebar then
        return
    end

    for _, child in ipairs(sidebar:GetChildren()) do
        if child:IsA("Frame") then
            if child.Size.Y.Offset == 105 and child.AnchorPoint.Y == 1 then
                child:Destroy()
            elseif child.Size.Y.Offset == 1 and child.AnchorPoint.Y == 1 then
                child:Destroy()
            end
        end
    end

    local pages = Window.Items["Pages"]
        and Window.Items["Pages"].Instance

    if pages then
        pages.Size = UDim2.new(1, -16, 1, -85)
    end
end)

-- ==================== SERVICES ====================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer

local PetFunction = ReplicatedStorage:WaitForChild("PetFunction", 15)

-- ==================== KEYBIND LIST ====================

local KeybindList = {}

do
    local Theme = Library.Theme
    local Font = Library.Font

    local Gui = Instance.new("ScreenGui")
    Gui.Name = "StellarKeybindList"
    Gui.ResetOnSpawn = false
    Gui.ZIndexBehavior = Enum.ZIndexBehavior.Global
    Gui.Parent = (gethui and gethui()) or game:GetService("CoreGui")

    local Frame = Instance.new("Frame")
    Frame.Name = "KeybindList"
    Frame.Size = UDim2.new(0, 180, 0, 0)
    Frame.AutomaticSize = Enum.AutomaticSize.Y
    Frame.Position = UDim2.new(0, 20, 0.4, 0)
    Frame.BackgroundColor3 = Theme.Background
    Frame.BorderSizePixel = 0
    Frame.Visible = true
    Frame.Parent = Gui

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 6)
    Corner.Parent = Frame

    local Stroke = Instance.new("UIStroke")
    Stroke.Color = Theme.Outline
    Stroke.Thickness = 1
    Stroke.Parent = Frame

    local Padding = Instance.new("UIPadding")
    Padding.PaddingTop = UDim.new(0, 8)
    Padding.PaddingBottom = UDim.new(0, 8)
    Padding.PaddingLeft = UDim.new(0, 10)
    Padding.PaddingRight = UDim.new(0, 10)
    Padding.Parent = Frame

    local Layout = Instance.new("UIListLayout")
    Layout.SortOrder = Enum.SortOrder.LayoutOrder
    Layout.Padding = UDim.new(0, 4)
    Layout.Parent = Frame

    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, 0, 0, 18)
    Title.BackgroundTransparency = 1
    Title.Text = "Keybinds"
    Title.TextColor3 = Theme.Text
    Title.FontFace = Font
    Title.TextSize = 15
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = Frame

    local Separator = Instance.new("Frame")
    Separator.Size = UDim2.new(1, 0, 0, 1)
    Separator.BackgroundColor3 = Theme.Outline
    Separator.BorderSizePixel = 0
    Separator.Parent = Frame

    local dragging = false
    local dragStart
    local startPos

    Title.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = Frame.Position
        end
    end)

    Title.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart

            Frame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)

    local Entries = {}

    local function IsValidKey(keyText)
        if not keyText then
            return false
        end

        keyText = tostring(keyText)

        return keyText ~= ""
            and keyText ~= "None"
            and keyText ~= "Unknown"
    end

    local function TweenObject(object, goals)
        local tween = TweenService:Create(
            object,
            TweenInfo.new(
                0.2,
                Enum.EasingStyle.Circular,
                Enum.EasingDirection.Out
            ),
            goals
        )

        tween:Play()
    end

    local function CreateActiveIndicator(Row)
        local Indicator = Instance.new("Frame")
        Indicator.Name = "ActiveIndicator"
        Indicator.AnchorPoint = Vector2.new(0, 0.5)
        Indicator.Position = UDim2.new(0, 0, 0.5, 0)
        Indicator.Size = UDim2.new(0, 3, 0, 0)
        Indicator.BackgroundColor3 = Theme.Accent
        Indicator.BackgroundTransparency = 1
        Indicator.BorderSizePixel = 0
        Indicator.ZIndex = Row.ZIndex + 2
        Indicator.Parent = Row

        local IndicatorCorner = Instance.new("UICorner")
        IndicatorCorner.CornerRadius = UDim.new(1, 0)
        IndicatorCorner.Parent = Indicator

        return Indicator
    end

    local function ApplyActive(entry, active)
        entry.Active = active == true

        TweenObject(entry.Indicator, {
            Size = entry.Active
                and UDim2.new(0, 3, 0.75, 0)
                or UDim2.new(0, 3, 0, 0),

            BackgroundTransparency = entry.Active and 0 or 1,
        })

        TweenObject(entry.Name, {
            Position = entry.Active
                and UDim2.new(0, 10, 0, 0)
                or UDim2.new(0, 0, 0, 0),

            TextTransparency = entry.Active and 0 or 0.35,
        })

        TweenObject(entry.Key, {
            TextTransparency = entry.Active and 0 or 0.35,
            TextColor3 = entry.Active
                and Theme.Accent
                or Theme.Text,
        })
    end

    function KeybindList:Add(name, keyText, active)
        if not IsValidKey(keyText) then
            self:Remove(name)
            return
        end

        if Entries[name] then
            self:Set(name, keyText, active)
            return
        end

        local Row = Instance.new("Frame")
        Row.Name = "Row_" .. tostring(name)
        Row.Size = UDim2.new(1, 0, 0, 18)
        Row.BackgroundTransparency = 1
        Row.BorderSizePixel = 0
        Row.Parent = Frame

        local Indicator = CreateActiveIndicator(Row)

        local NameLabel = Instance.new("TextLabel")
        NameLabel.Name = "Name"
        NameLabel.Size = UDim2.new(0.6, 0, 1, 0)
        NameLabel.Position = UDim2.new(0, 0, 0, 0)
        NameLabel.BackgroundTransparency = 1
        NameLabel.Text = tostring(name)
        NameLabel.TextColor3 = Theme.Text
        NameLabel.TextTransparency = 0.35
        NameLabel.FontFace = Font
        NameLabel.TextSize = 13
        NameLabel.TextXAlignment = Enum.TextXAlignment.Left
        NameLabel.ZIndex = Row.ZIndex + 1
        NameLabel.Parent = Row

        local KeyLabel = Instance.new("TextLabel")
        KeyLabel.Name = "Key"
        KeyLabel.Size = UDim2.new(0.4, 0, 1, 0)
        KeyLabel.Position = UDim2.new(0.6, 0, 0, 0)
        KeyLabel.BackgroundTransparency = 1
        KeyLabel.Text = tostring(keyText)
        KeyLabel.TextColor3 = Theme.Text
        KeyLabel.TextTransparency = 0.35
        KeyLabel.FontFace = Font
        KeyLabel.TextSize = 13
        KeyLabel.TextXAlignment = Enum.TextXAlignment.Right
        KeyLabel.ZIndex = Row.ZIndex + 1
        KeyLabel.Parent = Row

        Entries[name] = {
            Row = Row,
            Name = NameLabel,
            Key = KeyLabel,
            Indicator = Indicator,
            Active = false,
        }

        ApplyActive(Entries[name], active)
    end

    function KeybindList:Set(name, keyText, active)
        if not IsValidKey(keyText) then
            self:Remove(name)
            return
        end

        if not Entries[name] then
            self:Add(name, keyText, active)
            return
        end

        local entry = Entries[name]

        entry.Key.Text = tostring(keyText)

        ApplyActive(entry, active)
    end

    function KeybindList:SetActive(name, active)
        local entry = Entries[name]

        if not entry then
            return
        end

        ApplyActive(entry, active)
    end

    function KeybindList:Remove(name)
        local entry = Entries[name]

        if entry then
            entry.Row:Destroy()
            Entries[name] = nil
        end
    end

    function KeybindList:SetVisible(state)
        Frame.Visible = state == true
    end

    function KeybindList:Destroy()
        if Gui then
            Gui:Destroy()
        end

        table.clear(Entries)
    end
end

KeybindList:SetVisible(true)

-- ==================== PAGES ====================

local MainPage = Window:Page({
    Name = "Main",
    Icon = "rbxassetid://10723407389",
})

local UpgradesPage = Window:Page({
    Name = "Upgrades",
    Icon = "rbxassetid://10709782497",
})

local PlayerPage = Window:Page({
    Name = "Player",
    Icon = "rbxassetid://10747373176",
})

local SettingsPage = Library:CreateSettingsPage(Window)

local KeybindSection = SettingsPage:Section({
    Name = "Keybinds",
    Side = 1,
})

KeybindSection:Toggle({
    Name = "Keybind List",
    Flag = "KeybindListVisible",
    Default = true,

    Callback = function(state)
        KeybindList:SetVisible(state)
    end,
})

-- ==================== MAIN ====================

local MainSection = MainPage:Section({
    Name = "Main",
    Side = 1,
})

-- ==================== AUTO STRENGTH ====================

local AutoStrengthEnabled = false

local function StartAutoStrength()
    task.spawn(function()
        while AutoStrengthEnabled do
            local event = ReplicatedStorage:FindFirstChild("ClickTrainEvent")

            if event then
                pcall(function()
                    event:FireServer()
                end)
            end

            task.wait(0.02)
        end
    end)
end

MainSection:Toggle({
    Name = "Auto Strength",
    Flag = "AutoStrength",
    Default = false,

    Callback = function(state)
        AutoStrengthEnabled = state

        if state then
            StartAutoStrength()
        end
    end,
})

-- ==================== AUTO REBIRTH ====================

local AutoRebirthEnabled = false

local function StartAutoRebirth()
    task.spawn(function()
        while AutoRebirthEnabled do
            local rebirthFunction = ReplicatedStorage:FindFirstChild("RebirthFunction")

            if rebirthFunction then
                pcall(function()
                    rebirthFunction:InvokeServer("Rebirth")
                end)
            end

            task.wait(0.02)
        end
    end)
end

MainSection:Toggle({
    Name = "Auto Rebirth",
    Flag = "AutoRebirth",
    Default = false,

    Callback = function(state)
        AutoRebirthEnabled = state

        if state then
            StartAutoRebirth()
        end
    end,
})

-- ==================== AUTO SPIN WHEEL ====================

local AutoSpinWheelEnabled = false

local function StartAutoSpinWheel()
    task.spawn(function()
        while AutoSpinWheelEnabled do
            local spinWheelFunction = ReplicatedStorage:FindFirstChild("SpinWheelFunction")

            if spinWheelFunction then
                pcall(function()
                    spinWheelFunction:InvokeServer("Spin")
                end)
            end

            task.wait(0.02)
        end
    end)
end

MainSection:Toggle({
    Name = "Auto Spin Wheel",
    Flag = "AutoSpinWheel",
    Default = false,

    Callback = function(state)
        AutoSpinWheelEnabled = state

        if state then
            StartAutoSpinWheel()
        end
    end,
})

-- ==================== AUTO ROLL TITLE ====================

local AutoRollTitleEnabled = false

local function StartAutoRollTitle()
    task.spawn(function()
        while AutoRollTitleEnabled do
            local titleFunction = ReplicatedStorage:FindFirstChild("TitleFunction")

            if titleFunction then
                pcall(function()
                    titleFunction:InvokeServer("Roll", "base")
                end)
            end

            task.wait(0.02)
        end
    end)
end

MainSection:Toggle({
    Name = "Auto Roll Title",
    Flag = "AutoRollTitle",
    Default = false,

    Callback = function(state)
        AutoRollTitleEnabled = state

        if state then
            StartAutoRollTitle()
        end
    end,
})

-- ==================== AUTO MERGE ====================

local AutoMergeEnabled = false
local AutoMergeConnectionId = 0

local function FindMergeTarget()
    if not PetFunction then
        return nil, nil
    end

    local success, state = pcall(function()
        return PetFunction:InvokeServer("GetState")
    end)

    if not success or type(state) ~= "table" then
        return nil, nil
    end

    if type(state.owned) ~= "table" then
        return nil, nil
    end

    local groups = {}

    for _, pet in ipairs(state.owned) do
        if type(pet) == "table" and type(pet.name) == "string" then
            local variant = pet.variant or "Normal"

            if not pet.locked and not pet.scalePct then
                local key = pet.name .. "\0" .. tostring(variant)

                if not groups[key] then
                    groups[key] = {
                        name = pet.name,
                        variant = variant,
                        count = 0,
                    }
                end

                groups[key].count = groups[key].count + 1

                if groups[key].count >= 3 then
                    return groups[key].name, groups[key].variant
                end
            end
        end
    end

    return nil, nil
end

local function StartAutoMerge()
    AutoMergeConnectionId = AutoMergeConnectionId + 1

    local myConnectionId = AutoMergeConnectionId

    task.spawn(function()
        while AutoMergeEnabled
            and myConnectionId == AutoMergeConnectionId do

            local petName, variant = FindMergeTarget()

            if not petName then
                task.wait(1)
                continue
            end

            local startSuccess = pcall(function()
                PetFunction:InvokeServer(
                    "StartMerge",
                    petName,
                    variant
                )
            end)

            if not startSuccess then
                task.wait(1)
                continue
            end

            -- Wait exactly 6 minutes.
            local mergeEndTime = os.clock() + 310

            while AutoMergeEnabled
                and myConnectionId == AutoMergeConnectionId
                and os.clock() < mergeEndTime do

                task.wait(1)
            end

            if not AutoMergeEnabled
                or myConnectionId ~= AutoMergeConnectionId then

                break
            end

            -- Claim completed merge.
            pcall(function()
                PetFunction:InvokeServer("ClaimMerge")
            end)

            task.wait(0.5)

            -- Equip best after claiming the merge.
            pcall(function()
                PetFunction:InvokeServer("EquipBest")
            end)

            task.wait(0.5)
        end
    end)
end

MainSection:Toggle({
    Name = "Auto Merge",
    Flag = "AutoMerge",
    Default = false,

    Callback = function(state)
        AutoMergeEnabled = state

        if state then
            StartAutoMerge()
        else
            AutoMergeConnectionId = AutoMergeConnectionId + 1
        end
    end,
})

-- ==================== AUTO HATCH EGG ====================

local SelectedEgg = 1
local AutoHatchEggEnabled = false

local function StartAutoHatchEgg()
    task.spawn(function()
        while AutoHatchEggEnabled do
            if PetFunction then
                pcall(function()
                    PetFunction:InvokeServer(
                        "HatchEgg",
                        SelectedEgg,
                        1
                    )
                end)
            end

            task.wait(0.02)
        end
    end)
end

MainSection:Toggle({
    Name = "Auto Hatch Egg",
    Flag = "AutoHatchEgg",
    Default = false,

    Callback = function(state)
        AutoHatchEggEnabled = state

        if state then
            StartAutoHatchEgg()
        end
    end,
})

MainSection:Dropdown({
    Name = "Egg",
    Flag = "HatchEggNumber",

    Items = {
        "1",
        "2",
        "3",
        "4",
        "5",
        "7",
        "8",
        "9",
        "10",
        "11",
        "12",
        "13",
        "14",
        "15"
    },

    Default = "1",
    Multi = false,

    Callback = function(value)
        SelectedEgg = tonumber(value) or 1
    end,
})

-- ==================== UPGRADES ====================

local UpgradesSection = UpgradesPage:Section({
    Name = "Upgrades",
    Side = 1,
})

local function MakeAutoUpgrade(name, flag, buyArg)
    local enabled = false

    local function Start()
        task.spawn(function()
            while enabled do
                local upgradeFunction = ReplicatedStorage:FindFirstChild("UpgradeFunction")

                if upgradeFunction then
                    pcall(function()
                        upgradeFunction:InvokeServer(
                            "Buy",
                            buyArg
                        )
                    end)
                end

                task.wait(0.02)
            end
        end)
    end

    UpgradesSection:Toggle({
        Name = name,
        Flag = flag,
        Default = false,

        Callback = function(state)
            enabled = state

            if state then
                Start()
            end
        end,
    })

    return function()
        enabled = false
    end
end

local StopAutoDamageUpgrade = MakeAutoUpgrade(
    "Auto Damage Upgrade",
    "AutoDamageUpgrade",
    "damage"
)

local StopAutoWinsUpgrade = MakeAutoUpgrade(
    "Auto Wins Upgrade",
    "AutoWinsUpgrade",
    "wins"
)

local StopAutoClickPowerUpgrade = MakeAutoUpgrade(
    "Auto ClickPower Upgrade",
    "AutoClickPowerUpgrade",
    "clickPower"
)

local StopAutoAttackSpeedUpgrade = MakeAutoUpgrade(
    "Auto AttackSpeed Upgrade",
    "AutoAttackSpeedUpgrade",
    "attackSpeed"
)

local StopAutoEggLuckUpgrade = MakeAutoUpgrade(
    "Auto EggLuck Upgrade",
    "AutoEggLuckUpgrade",
    "luck"
)

local StopAutoRollLuckUpgrade = MakeAutoUpgrade(
    "Auto RollLuck Upgrade",
    "AutoRollLuckUpgrade",
    "rollLuck"
)

local StopAutoPetStorageUpgrade = MakeAutoUpgrade(
    "Auto PetStorage Upgrade",
    "AutoPetStorageUpgrade",
    "petStorage"
)

-- ==================== PLAYER ====================

local PlayerSection = PlayerPage:Section({
    Name = "Player",
    Side = 1,
})

-- ==================== FLY ====================

local FlyEnabled = false
local FlySpeed = 50
local FlyBodyVelocity = nil
local FlyConnection = nil

local function StartFly()
    local character = LocalPlayer.Character

    if not character then
        return
    end

    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")

    if not humanoidRootPart then
        return
    end

    if FlyConnection then
        FlyConnection:Disconnect()
        FlyConnection = nil
    end

    if FlyBodyVelocity then
        FlyBodyVelocity:Destroy()
        FlyBodyVelocity = nil
    end

    FlyBodyVelocity = Instance.new("BodyVelocity")
    FlyBodyVelocity.MaxForce = Vector3.new(
        math.huge,
        math.huge,
        math.huge
    )
    FlyBodyVelocity.Velocity = Vector3.zero
    FlyBodyVelocity.Parent = humanoidRootPart

    FlyConnection = RunService.RenderStepped:Connect(function()
        if not FlyEnabled or not FlyBodyVelocity then
            return
        end

        local camera = workspace.CurrentCamera

        if not camera then
            return
        end

        local moveDirection = Vector3.zero

        if UserInputService:IsKeyDown(Enum.KeyCode.W) then
            moveDirection += camera.CFrame.LookVector
        end

        if UserInputService:IsKeyDown(Enum.KeyCode.S) then
            moveDirection -= camera.CFrame.LookVector
        end

        if UserInputService:IsKeyDown(Enum.KeyCode.A) then
            moveDirection -= camera.CFrame.RightVector
        end

        if UserInputService:IsKeyDown(Enum.KeyCode.D) then
            moveDirection += camera.CFrame.RightVector
        end

        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            moveDirection += Vector3.new(0, 1, 0)
        end

        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
            moveDirection -= Vector3.new(0, 1, 0)
        end

        if moveDirection.Magnitude > 0 then
            moveDirection = moveDirection.Unit * FlySpeed
        end

        FlyBodyVelocity.Velocity = moveDirection
    end)
end

local function StopFly()
    FlyEnabled = false

    if FlyConnection then
        FlyConnection:Disconnect()
        FlyConnection = nil
    end

    if FlyBodyVelocity then
        FlyBodyVelocity:Destroy()
        FlyBodyVelocity = nil
    end
end

PlayerSection:Toggle({
    Name = "Fly",
    Flag = "Fly",
    Default = false,

    Callback = function(state)
        FlyEnabled = state

        if state then
            StartFly()
        else
            StopFly()
        end
    end,
})

PlayerSection:Slider({
    Name = "Fly Speed",
    Flag = "FlySpeedSlider",
    Default = FlySpeed,
    Min = 10,
    Max = 300,

    Callback = function(value)
        FlySpeed = value
    end,
})

-- ==================== SPEED HACK ====================

local SpeedHackEnabled = false
local SpeedHackValue = 50
local OriginalWalkSpeed = nil

local function StartSpeedHack()
    local character = LocalPlayer.Character

    if not character then
        return
    end

    local humanoid = character:FindFirstChildOfClass("Humanoid")

    if humanoid then
        if OriginalWalkSpeed == nil then
            OriginalWalkSpeed = humanoid.WalkSpeed
        end

        humanoid.WalkSpeed = SpeedHackValue
    end
end

local function StopSpeedHack()
    SpeedHackEnabled = false

    local character = LocalPlayer.Character

    if character then
        local humanoid = character:FindFirstChildOfClass("Humanoid")

        if humanoid and OriginalWalkSpeed ~= nil then
            humanoid.WalkSpeed = OriginalWalkSpeed
        end
    end

    OriginalWalkSpeed = nil
end

PlayerSection:Toggle({
    Name = "SpeedHack",
    Flag = "SpeedHack",
    Default = false,

    Callback = function(state)
        SpeedHackEnabled = state

        if state then
            StartSpeedHack()
        else
            StopSpeedHack()
        end
    end,
})

PlayerSection:Slider({
    Name = "Speed Hack Value",
    Flag = "SpeedHackSlider",
    Default = SpeedHackValue,
    Min = 16,
    Max = 300,

    Callback = function(value)
        SpeedHackValue = value

        if SpeedHackEnabled then
            StartSpeedHack()
        end
    end,
})

-- ==================== NOCLIP ====================

local NoClipEnabled = false
local NoClipConnection = nil

local function StartNoClip()
    if NoClipConnection then
        NoClipConnection:Disconnect()
        NoClipConnection = nil
    end

    NoClipConnection = RunService.Stepped:Connect(function()
        if not NoClipEnabled then
            return
        end

        local character = LocalPlayer.Character

        if not character then
            return
        end

        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end)
end

local function StopNoClip()
    NoClipEnabled = false

    if NoClipConnection then
        NoClipConnection:Disconnect()
        NoClipConnection = nil
    end

    local character = LocalPlayer.Character

    if character then
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = true
            end
        end
    end
end

PlayerSection:Toggle({
    Name = "NoClip",
    Flag = "NoClip",
    Default = false,

    Callback = function(state)
        NoClipEnabled = state

        if state then
            StartNoClip()
        else
            StopNoClip()
        end
    end,
})

-- ==================== CHARACTER RESPAWN ====================

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)

    if FlyEnabled then
        StartFly()
    end

    if SpeedHackEnabled then
        OriginalWalkSpeed = nil
        StartSpeedHack()
    end
end)

-- ==================== UNLOAD ====================

local UnloadPage = Window:Page({
    Name = "Unload",
    Icon = "rbxassetid://6031094678",
})

local UnloadSection = UnloadPage:Section({
    Name = "Unload",
    Side = 1,
})

UnloadSection:Button({
    Name = "Unload Script",

    Callback = function()
        AutoStrengthEnabled = false
        AutoRebirthEnabled = false
        AutoSpinWheelEnabled = false
        AutoRollTitleEnabled = false
        AutoHatchEggEnabled = false

        AutoMergeEnabled = false
        AutoMergeConnectionId = AutoMergeConnectionId + 1

        StopAutoDamageUpgrade()
        StopAutoWinsUpgrade()
        StopAutoClickPowerUpgrade()
        StopAutoAttackSpeedUpgrade()
        StopAutoEggLuckUpgrade()
        StopAutoRollLuckUpgrade()
        StopAutoPetStorageUpgrade()

        StopFly()
        StopSpeedHack()
        StopNoClip()

        pcall(function()
            KeybindList:Destroy()
        end)

        task.defer(function()
            task.wait(0.05)

            pcall(function()
                if Library and Library.Unload then
                    Library:Unload()
                end
            end)
        end)
    end,
})
