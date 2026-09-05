

local Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/vortex777-ai/ui-worldofS-st/f27d0e121266420107c5abf4a25751b79f00a509/Stellar.lua"
))()

if not Library then
    return
end


local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

local CharactersFolder =
    Workspace:WaitForChild("Characters", 10)

local isUnloaded = false

local noSpreadEnabled = false
local noRecoilEnabled = false
local instaRevolverEnabled = false

local noSpreadHookInstalled = false
local noRecoilHookInstalled = false
local instaRevolverHookInstalled = false

local OriginalGetTrueSpread = nil
local OriginalSetWeaponRecoil = nil
local OriginalWeaponKick = nil
local OriginalStartRevolverCharge = nil

local function InstallInstaRevolverHook()
    if instaRevolverHookInstalled then
        return true
    end

    local ok, Weapon = pcall(function()
        return require(
            ReplicatedStorage
                :WaitForChild("Components")
                :WaitForChild("Weapon")
        )
    end)

    if not ok or not Weapon or type(Weapon.startRevolverCharge) ~= "function" then
        return false
    end

    local original = Weapon.startRevolverCharge
    local upvalues = {}

    pcall(function()
        upvalues = debug.getupvalues(original) or {}
    end)

    local chargeCallback = upvalues[6]

    if typeof(hookfunction) == "function" then
        local old
        old = hookfunction(
            Weapon.startRevolverCharge,
            function(self, p)
                old(self, p)

                if not instaRevolverEnabled or isUnloaded then
                    return
                end

                if self.IsChargeFiring then
                    if chargeCallback then
                        pcall(chargeCallback, self)
                    elseif (self.Rounds or 0) > 0 then
                        self.CurrentWalkSpeedOverride = nil
                        pcall(self.shoot, self, "Primary")
                    end
                end
            end
        )

        OriginalStartRevolverCharge = old
    else
        Weapon.startRevolverCharge = function(self, p)
            original(self, p)

            if not instaRevolverEnabled or isUnloaded then
                return
            end

            if self.IsChargeFiring then
                if chargeCallback then
                    pcall(chargeCallback, self)
                elseif (self.Rounds or 0) > 0 then
                    self.CurrentWalkSpeedOverride = nil
                    pcall(self.shoot, self, "Primary")
                end
            end
        end

        OriginalStartRevolverCharge = original
    end

    instaRevolverHookInstalled = true
    return true
end

local function InstallWeaponHooks()

    if typeof(hookfunction) ~= "function" then
        return false
    end

    -- ========================================================
    -- NO SPREAD
    -- ========================================================

    if not noSpreadHookInstalled then

        local ok, Bullet = pcall(function()

            return require(
                ReplicatedStorage
                    :WaitForChild("Components")
                    :WaitForChild("Weapon")
                    :WaitForChild("Classes")
                    :WaitForChild("Bullet")
            )

        end)

        if ok
            and Bullet
            and type(Bullet.getTrueSpread) == "function" then

            local original

            original = hookfunction(
                Bullet.getTrueSpread,
                function(self, ...)

                    if noSpreadEnabled
                        and not isUnloaded then

                        return 0
                    end

                    return original(
                        self,
                        ...
                    )
                end
            )

            OriginalGetTrueSpread =
                original

            noSpreadHookInstalled =
                true
        end
    end

    -- ========================================================
    -- NO RECOIL
    -- ========================================================

    if not noRecoilHookInstalled then

        local ok, CameraController = pcall(function()

            return require(
                ReplicatedStorage
                    :WaitForChild("Controllers")
                    :WaitForChild("CameraController")
            )

        end)

        if ok and CameraController then

            local installed =
                false

            if type(
                CameraController.setWeaponRecoil
            ) == "function" then

                local originalSet

                originalSet = hookfunction(
                    CameraController.setWeaponRecoil,
                    function(...)

                        if noRecoilEnabled
                            and not isUnloaded then

                            return nil
                        end

                        return originalSet(...)
                    end
                )

                OriginalSetWeaponRecoil =
                    originalSet

                installed =
                    true
            end

            if type(
                CameraController.weaponKick
            ) == "function" then

                local originalKick

                originalKick = hookfunction(
                    CameraController.weaponKick,
                    function(...)

                        if noRecoilEnabled
                            and not isUnloaded then

                            return nil
                        end

                        return originalKick(...)
                    end
                )

                OriginalWeaponKick =
                    originalKick

                installed =
                    true
            end

            noRecoilHookInstalled =
                installed
        end
    end

    if instaRevolverEnabled and not instaRevolverHookInstalled then
        InstallInstaRevolverHook()
    end

    return
        noSpreadHookInstalled
        or noRecoilHookInstalled
        or instaRevolverHookInstalled
end

InstallWeaponHooks()

-- ============================================================
-- WINDOW
-- ============================================================

local Window = Library:Window({

    Name =
        "JulyScripts",

    SubName =
        "BloxStrike",

    Logo =
        "rbxassetid://116255434488074"
})

-- ============================================================
-- KEYBIND LIST (только для Silent Aim, можно убрать)
-- ============================================================

local KeybindList = {}

do

    local Theme =
        Library.Theme

    local Font =
        Library.Font

    local Gui =
        Instance.new("ScreenGui")

    Gui.Name =
        "StellarKeybindList"

    Gui.ResetOnSpawn =
        false

    Gui.ZIndexBehavior =
        Enum.ZIndexBehavior.Global

    Gui.Parent =
        (gethui and gethui())
        or game:GetService("CoreGui")

    local Frame =
        Instance.new("Frame")

    Frame.Name =
        "KeybindList"

    Frame.Size =
        UDim2.new(
            0,
            180,
            0,
            0
        )

    Frame.AutomaticSize =
        Enum.AutomaticSize.Y

    Frame.Position =
        UDim2.new(
            0,
            20,
            0.4,
            0
        )

    Frame.BackgroundColor3 =
        Theme.Background

    Frame.BorderSizePixel =
        0

    Frame.Visible =
        true

    Frame.Parent =
        Gui

    local Corner =
        Instance.new("UICorner")

    Corner.CornerRadius =
        UDim.new(
            0,
            6
        )

    Corner.Parent =
        Frame

    local Stroke =
        Instance.new("UIStroke")

    Stroke.Color =
        Theme.Outline

    Stroke.Thickness =
        1

    Stroke.Parent =
        Frame

    local Padding =
        Instance.new("UIPadding")

    Padding.PaddingTop =
        UDim.new(
            0,
            8
        )

    Padding.PaddingBottom =
        UDim.new(
            0,
            8
        )

    Padding.PaddingLeft =
        UDim.new(
            0,
            10
        )

    Padding.PaddingRight =
        UDim.new(
            0,
            10
        )

    Padding.Parent =
        Frame

    local Layout =
        Instance.new("UIListLayout")

    Layout.SortOrder =
        Enum.SortOrder.LayoutOrder

    Layout.Padding =
        UDim.new(
            0,
            4
        )

    Layout.Parent =
        Frame

    local Title =
        Instance.new("TextLabel")

    Title.Size =
        UDim2.new(
            1,
            0,
            0,
            18
        )

    Title.BackgroundTransparency =
        1

    Title.Text =
        "Keybinds"

    Title.TextColor3 =
        Theme.Text

    Title.FontFace =
        Font

    Title.TextSize =
        15

    Title.TextXAlignment =
        Enum.TextXAlignment.Left

    Title.Parent =
        Frame

    local Separator =
        Instance.new("Frame")

    Separator.Size =
        UDim2.new(
            1,
            0,
            0,
            1
        )

    Separator.BackgroundColor3 =
        Theme.Outline

    Separator.BorderSizePixel =
        0

    Separator.Parent =
        Frame

    -- ========================================================
    -- DRAG
    -- ========================================================

    local dragging =
        false

    local dragStart
    local startPos

    Title.InputBegan:Connect(
        function(input)

            if input.UserInputType ==
                Enum.UserInputType.MouseButton1 then

                dragging =
                    true

                dragStart =
                    input.Position

                startPos =
                    Frame.Position
            end
        end
    )

    Title.InputEnded:Connect(
        function(input)

            if input.UserInputType ==
                Enum.UserInputType.MouseButton1 then

                dragging =
                    false
            end
        end
    )

    UserInputService.InputChanged:Connect(
        function(input)

            if dragging
                and input.UserInputType ==
                    Enum.UserInputType.MouseMovement then

                local delta =
                    input.Position
                    - dragStart

                Frame.Position =
                    UDim2.new(
                        startPos.X.Scale,
                        startPos.X.Offset + delta.X,
                        startPos.Y.Scale,
                        startPos.Y.Offset + delta.Y
                    )
            end
        end
    )

    -- ========================================================
    -- ENTRIES
    -- ========================================================

    local Entries =
        {}

    local function TweenObject(
        object,
        goals
    )

        local tween =
            TweenService:Create(
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

    local function ApplyActive(
        entry,
        active
    )

        entry.Active =
            active == true

        TweenObject(
            entry.Indicator,
            {

                Size =
                    entry.Active
                    and UDim2.new(
                        0,
                        3,
                        0.75,
                        0
                    )
                    or UDim2.new(
                        0,
                        3,
                        0,
                        0
                    ),

                BackgroundTransparency =
                    entry.Active
                    and 0
                    or 1
            }
        )

        TweenObject(
            entry.Name,
            {

                Position =
                    entry.Active
                    and UDim2.new(
                        0,
                        10,
                        0,
                        0
                    )
                    or UDim2.new(
                        0,
                        0,
                        0,
                        0
                    ),

                TextTransparency =
                    entry.Active
                    and 0
                    or 0.35
            }
        )

        TweenObject(
            entry.Key,
            {

                TextTransparency =
                    entry.Active
                    and 0
                    or 0.35,

                TextColor3 =
                    entry.Active
                    and Theme.Accent
                    or Theme.Text
            }
        )
    end

    function KeybindList:Add(
        name,
        keyText,
        active
    )

        if not keyText then
            return
        end

        keyText =
            tostring(
                keyText
            )

        if keyText == ""
            or keyText == "None"
            or keyText == "Unknown" then

            return
        end

        if Entries[name] then

            self:Set(
                name,
                keyText,
                active
            )

            return
        end

        local Row =
            Instance.new("Frame")

        Row.Name =
            "Row_" ..
            tostring(name)

        Row.Size =
            UDim2.new(
                1,
                0,
                0,
                18
            )

        Row.BackgroundTransparency =
            1

        Row.BorderSizePixel =
            0

        Row.Parent =
            Frame

        local Indicator =
            Instance.new("Frame")

        Indicator.Name =
            "ActiveIndicator"

        Indicator.AnchorPoint =
            Vector2.new(
                0,
                0.5
            )

        Indicator.Position =
            UDim2.new(
                0,
                0,
                0.5,
                0
            )

        Indicator.Size =
            UDim2.new(
                0,
                3,
                0,
                0
            )

        Indicator.BackgroundColor3 =
            Theme.Accent

        Indicator.BackgroundTransparency =
            1

        Indicator.BorderSizePixel =
            0

        Indicator.Parent =
            Row

        local IndicatorCorner =
            Instance.new("UICorner")

        IndicatorCorner.CornerRadius =
            UDim.new(
                1,
                0
            )

        IndicatorCorner.Parent =
            Indicator

        local NameLabel =
            Instance.new("TextLabel")

        NameLabel.Name =
            "Name"

        NameLabel.Size =
            UDim2.new(
                0.6,
                0,
                1,
                0
            )

        NameLabel.BackgroundTransparency =
            1

        NameLabel.Text =
            tostring(name)

        NameLabel.TextColor3 =
            Theme.Text

        NameLabel.TextTransparency =
            0.35

        NameLabel.FontFace =
            Font

        NameLabel.TextSize =
            13

        NameLabel.TextXAlignment =
            Enum.TextXAlignment.Left

        NameLabel.Parent =
            Row

        local KeyLabel =
            Instance.new("TextLabel")

        KeyLabel.Name =
            "Key"

        KeyLabel.Size =
            UDim2.new(
                0.4,
                0,
                1,
                0
            )

        KeyLabel.Position =
            UDim2.new(
                0.6,
                0,
                0,
                0
            )

        KeyLabel.BackgroundTransparency =
            1

        KeyLabel.Text =
            tostring(keyText)

        KeyLabel.TextColor3 =
            Theme.Text

        KeyLabel.TextTransparency =
            0.35

        KeyLabel.FontFace =
            Font

        KeyLabel.TextSize =
            13

        KeyLabel.TextXAlignment =
            Enum.TextXAlignment.Right

        KeyLabel.Parent =
            Row

        Entries[name] = {

            Row =
                Row,

            Name =
                NameLabel,

            Key =
                KeyLabel,

            Indicator =
                Indicator,

            Active =
                false
        }

        ApplyActive(
            Entries[name],
            active
        )
    end

    function KeybindList:Set(
        name,
        keyText,
        active
    )

        if not Entries[name] then

            self:Add(
                name,
                keyText,
                active
            )

            return
        end

        local entry =
            Entries[name]

        entry.Key.Text =
            tostring(keyText)

        ApplyActive(
            entry,
            active
        )
    end

    function KeybindList:SetActive(
        name,
        active
    )

        local entry =
            Entries[name]

        if not entry then
            return
        end

        ApplyActive(
            entry,
            active
        )
    end

    function KeybindList:SetVisible(
        state
    )

        Frame.Visible =
            state == true
    end

    function KeybindList:Destroy()

        if Gui then
            Gui:Destroy()
        end

        table.clear(
            Entries
        )
    end
end

KeybindList:SetVisible(true)

-- ============================================================
-- PAGES
-- ============================================================

local VisualsPage =
    Window:Page({

        Name =
            "Visuals",

        Icon =
            "rbxassetid://7734039122"  -- глаз
    })

local SilentAimPage =
    Window:Page({

        Name =
            "Silent Aim",

        Icon =
            "rbxassetid://7734053494"  -- шестерёнка
    })

local WeaponModsPage =
    Window:Page({

        Name =
            "Weapon Mods",

        Icon =
            "rbxassetid://7733769659"  -- меч (можно поменять)
    })

local SkinsPage =
    Window:Page({

        Name =
            "Skins",

        Icon =
            "rbxassetid://7734040000"  -- палитра
    })

local SettingsPage =
    Library:CreateSettingsPage(
        Window
    )

local UnloadPage =
    Window:Page({

        Name =
            "Unload",

        Icon =
            "rbxassetid://7743878857"  -- выключение
    })

-- ============================================================
-- ESP CONFIG
-- ============================================================

local espEnabled =
    false

local espConfig = {

    Boxes =
        true,

    BoxColor =
        Color3.fromRGB(
            255,
            50,
            50
        ),

    BoxThickness =
        1,

    Names =
        true,

    NameColor =
        Color3.fromRGB(
            255,
            255,
            255
        ),

    NameSize =
        13,

    Distance =
        true,

    DistanceColor =
        Color3.fromRGB(
            200,
            200,
            200
        ),

    DistanceSize =
        11,

    HealthBar =
        true,

    Tracers =
        false,

    TracerColor =
        Color3.fromRGB(
            255,
            50,
            50
        ),

    TracerThickness =
        1,

    TracerOnlyEnemy =
        false,

    TeamColor =
        false,

    HeadDots =
        false,

    HeadDotColor =
        Color3.fromRGB(
            255,
            255,
            255
        ),

    HeadDotRadius =
        3,

    MaxDistance =
        2500
}

-- ============================================================
-- ESP STORAGE
-- ============================================================

local espObjects =
    {}

local espConnections =
    {}

local espRenderConnection =
    nil

-- ============================================================
-- TEAM / PLAYER
-- ============================================================

local function GetPlayerFromModel(
    model
)

    if not model then
        return nil
    end

    local player =
        Players:FindFirstChild(
            model.Name
        )

    if player then
        return player
    end

    local userId =
        model:GetAttribute(
            "UserId"
        )

    if typeof(userId) ==
        "number" then

        local success,
            result =
            pcall(function()

                return
                    Players:GetPlayerByUserId(
                        userId
                    )
            end)

        if success and result then
            return result
        end
    end

    local playerName =
        model:GetAttribute(
            "PlayerName"
        )

    if playerName then

        local result =
            Players:FindFirstChild(
                tostring(playerName)
            )

        if result then
            return result
        end
    end

    return nil
end

local function GetTeamValue(
    instance
)

    if not instance then
        return nil
    end

    local teamID =
        instance:GetAttribute(
            "TeamID"
        )

    if teamID ~= nil then
        return tostring(teamID)
    end

    local team =
        instance:GetAttribute(
            "Team"
        )

    if team ~= nil then
        return tostring(team)
    end

    local mgTeam =
        instance:GetAttribute(
            "MG_Team"
        )

    if mgTeam ~= nil then
        return tostring(mgTeam)
    end

    local teamName =
        instance:GetAttribute(
            "TeamName"
        )

    if teamName ~= nil then
        return tostring(teamName)
    end

    local teamValue =
        instance:FindFirstChild(
            "Team"
        )

    if teamValue then

        if teamValue:IsA(
            "StringValue"
        )
        or teamValue:IsA(
            "IntValue"
        )
        or teamValue:IsA(
            "NumberValue"
        ) then

            return tostring(
                teamValue.Value
            )
        end
    end

    return nil
end

local function GetTeamKey(
    model
)

    if not model then
        return nil
    end

    local player =
        GetPlayerFromModel(
            model
        )

    if player then

        local team =
            GetTeamValue(
                player
            )

        if team then
            return team
        end

        if player.Team then

            return tostring(
                player.Team.Name
            )
        end
    end

    return GetTeamValue(
        model
    )
end

local function SameTeam(
    model
)

    local myTeam =
        GetTeamKey(
            LocalPlayer.Character
        )

    local theirTeam =
        GetTeamKey(
            model
        )

    if not myTeam
        or not theirTeam then

        return false
    end

    return tostring(myTeam) ==
        tostring(theirTeam)
end

-- ============================================================
-- CHARACTER HELPERS
-- ============================================================

local function IsPlayerModel(
    model
)

    if not model then
        return false
    end

    if not model:IsA(
        "Model"
    ) then

        return false
    end

    if model.Name ==
        LocalPlayer.Name then

        return false
    end

    local root =
        model:FindFirstChild(
            "HumanoidRootPart"
        )

    local head =
        model:FindFirstChild(
            "Head"
        )

    if not root
        and not head then

        return false
    end

    return true
end

local function GetRootPart(
    model
)

    if not model then
        return nil
    end

    return
        model:FindFirstChild(
            "HumanoidRootPart"
        )
        or model.PrimaryPart
        or model:FindFirstChild(
            "UpperTorso"
        )
        or model:FindFirstChild(
            "LowerTorso"
        )
        or model:FindFirstChild(
            "Torso"
        )
        or model:FindFirstChild(
            "Head"
        )
end

local function GetHead(
    model
)

    if not model then
        return nil
    end

    return model:FindFirstChild(
        "Head"
    )
end

-- ============================================================
-- HEALTH
-- ============================================================

local function GetHealth(
    model
)

    if not model then
        return nil, nil
    end

    local humanoid =
        model:FindFirstChildOfClass(
            "Humanoid"
        )

    if humanoid then

        return
            humanoid.Health,
            humanoid.MaxHealth
    end

    local health =
        model:GetAttribute(
            "Health"
        )

    local maxHealth =
        model:GetAttribute(
            "MaxHealth"
        )

    if typeof(health) ==
            "number"
        and typeof(maxHealth) ==
            "number" then

        return health,
            maxHealth
    end

    local healthValue =
        model:FindFirstChild(
            "Health",
            true
        )

    local maxHealthValue =
        model:FindFirstChild(
            "MaxHealth",
            true
        )

    if healthValue
        and (
            healthValue:IsA(
                "NumberValue"
            )
            or healthValue:IsA(
                "IntValue"
            )
        ) then

        local h =
            healthValue.Value

        local max =
            100

        if maxHealthValue
            and (
                maxHealthValue:IsA(
                    "NumberValue"
                )
                or maxHealthValue:IsA(
                    "IntValue"
                )
            ) then

            max =
                maxHealthValue.Value
        end

        return h, max
    end

    return nil, nil
end

-- ============================================================
-- DRAWING
-- ============================================================

local function CreateDrawing(
    drawingType,
    properties
)

    local object =
        Drawing.new(
            drawingType
        )

    for key, value in pairs(
        properties
    ) do

        object[key] =
            value
    end

    return object
end

local function HideDrawings(
    drawings
)

    if not drawings then
        return
    end

    for _, drawing in pairs(
        drawings
    ) do

        pcall(function()

            drawing.Visible =
                false
        end)
    end
end

-- ============================================================
-- CREATE ESP
-- ============================================================

local function CreateESPObject(
    model
)

    if espObjects[model] then
        return
    end

    if not IsPlayerModel(
        model
    ) then

        return
    end

    local drawings = {

        BoxOutline =
            CreateDrawing(
                "Square",
                {

                    Thickness =
                        espConfig.BoxThickness + 2,

                    Color =
                        Color3.fromRGB(
                            0,
                            0,
                            0
                        ),

                    Filled =
                        false,

                    Visible =
                        false
                }
            ),

        Box =
            CreateDrawing(
                "Square",
                {

                    Thickness =
                        espConfig.BoxThickness,

                    Color =
                        espConfig.BoxColor,

                    Filled =
                        false,

                    Visible =
                        false
                }
            ),

        Name =
            CreateDrawing(
                "Text",
                {

                    Size =
                        espConfig.NameSize,

                    Center =
                        true,

                    Outline =
                        true,

                    Color =
                        espConfig.NameColor,

                    Visible =
                        false
                }
            ),

        Distance =
            CreateDrawing(
                "Text",
                {

                    Size =
                        espConfig.DistanceSize,

                    Center =
                        true,

                    Outline =
                        true,

                    Color =
                        espConfig.DistanceColor,

                    Visible =
                        false
                }
            ),

        HealthBarOutline =
            CreateDrawing(
                "Line",
                {

                    Thickness =
                        3,

                    Color =
                        Color3.fromRGB(
                            0,
                            0,
                            0
                        ),

                    Visible =
                        false
                }
            ),

        HealthBar =
            CreateDrawing(
                "Line",
                {

                    Thickness =
                        1,

                    Visible =
                        false
                }
            ),

        Tracer =
            CreateDrawing(
                "Line",
                {

                    Thickness =
                        espConfig.TracerThickness,

                    Color =
                        espConfig.TracerColor,

                    Visible =
                        false
                }
            ),

        HeadDot =
            CreateDrawing(
                "Circle",
                {

                    Radius =
                        espConfig.HeadDotRadius,

                    Filled =
                        true,

                    Color =
                        espConfig.HeadDotColor,

                    Visible =
                        false
                }
            )
    }

    espObjects[model] =
        drawings
end

-- ============================================================
-- REMOVE ESP
-- ============================================================

local function RemoveESPObject(
    model
)

    local drawings =
        espObjects[model]

    if not drawings then
        return
    end

    HideDrawings(
        drawings
    )

    for _, drawing in pairs(
        drawings
    ) do

        pcall(function()

            drawing:Remove()

        end)
    end

    espObjects[model] =
        nil
end

-- ============================================================
-- SCAN CHARACTERS
-- ============================================================

local function ScanCharacters()

    if not CharactersFolder then
        return
    end

    for _, model in ipairs(
        CharactersFolder:GetChildren()
    ) do

        if IsPlayerModel(
            model
        ) then

            CreateESPObject(
                model
            )
        end
    end
end

-- ============================================================
-- ESP CONNECTIONS
-- ============================================================

local function StartESPConnections()

    if not CharactersFolder then
        return
    end

    for _, connection in ipairs(
        espConnections
    ) do

        pcall(function()

            connection:Disconnect()

        end)
    end

    table.clear(
        espConnections
    )

    ScanCharacters()

    table.insert(
        espConnections,

        CharactersFolder.ChildAdded:Connect(
            function(model)

                if isUnloaded then
                    return
                end

                task.spawn(function()

                    local started =
                        os.clock()

                    local timeout =
                        5

                    while not isUnloaded
                        and model.Parent
                        and os.clock() - started < timeout do

                        if IsPlayerModel(
                            model
                        ) then

                            CreateESPObject(
                                model
                            )

                            return
                        end

                        task.wait(
                            0.05
                        )
                    end

                    if not isUnloaded
                        and model.Parent
                        and IsPlayerModel(
                            model
                        ) then

                        CreateESPObject(
                            model
                        )
                    end
                end)
            end
        )
    )

    table.insert(
        espConnections,

        CharactersFolder.ChildRemoved:Connect(
            function(model)

                RemoveESPObject(
                    model
                )
            end
        )
    )
end

-- ============================================================
-- ESP RENDER
-- ============================================================

local function StartESP()

    if espRenderConnection then

        pcall(function()

            espRenderConnection:Disconnect()

        end)

        espRenderConnection =
            nil
    end

    espRenderConnection =
        RunService.RenderStepped:Connect(
            function()

                if isUnloaded then
                    return
                end

                local camera =
                    Workspace.CurrentCamera

                if not camera
                    or not CharactersFolder then

                    return
                end

                for _, model in ipairs(
                    CharactersFolder:GetChildren()
                ) do

                    if IsPlayerModel(
                        model
                    )
                        and not espObjects[model] then

                        CreateESPObject(
                            model
                        )
                    end
                end

                if not espEnabled then

                    for _, drawings in pairs(
                        espObjects
                    ) do

                        HideDrawings(
                            drawings
                        )
                    end

                    return
                end

                local cameraPosition =
                    camera.CFrame.Position

                local viewportSize =
                    camera.ViewportSize

                for model, drawings in pairs(
                    espObjects
                ) do

                    if not model
                        or not model.Parent then

                        RemoveESPObject(
                            model
                        )

                        continue
                    end

                    if not IsPlayerModel(
                        model
                    ) then

                        HideDrawings(
                            drawings
                        )

                        continue
                    end

                    local rootPart =
                        GetRootPart(
                            model
                        )

                    if not rootPart then

                        HideDrawings(
                            drawings
                        )

                        continue
                    end

                    local distance =
                        (
                            cameraPosition
                            - rootPart.Position
                        ).Magnitude

                    if distance >
                        espConfig.MaxDistance then

                        HideDrawings(
                            drawings
                        )

                        continue
                    end

                    local success,
                        boxCFrame,
                        boxSize =
                        pcall(function()

                            return
                                model:GetBoundingBox()

                        end)

                    if not success
                        or not boxCFrame
                        or not boxSize then

                        HideDrawings(
                            drawings
                        )

                        continue
                    end

                    local halfSize =
                        boxSize * 0.5

                    local corners = {

                        Vector3.new(
                            -halfSize.X,
                            -halfSize.Y,
                            -halfSize.Z
                        ),

                        Vector3.new(
                            -halfSize.X,
                            -halfSize.Y,
                            halfSize.Z
                        ),

                        Vector3.new(
                            -halfSize.X,
                            halfSize.Y,
                            -halfSize.Z
                        ),

                        Vector3.new(
                            -halfSize.X,
                            halfSize.Y,
                            halfSize.Z
                        ),

                        Vector3.new(
                            halfSize.X,
                            -halfSize.Y,
                            -halfSize.Z
                        ),

                        Vector3.new(
                            halfSize.X,
                            -halfSize.Y,
                            halfSize.Z
                        ),

                        Vector3.new(
                            halfSize.X,
                            halfSize.Y,
                            -halfSize.Z
                        ),

                        Vector3.new(
                            halfSize.X,
                            halfSize.Y,
                            halfSize.Z
                        )
                    }

                    local minX =
                        math.huge

                    local maxX =
                        -math.huge

                    local minY =
                        math.huge

                    local maxY =
                        -math.huge

                    local visibleCorner =
                        false

                    for _, corner in ipairs(
                        corners
                    ) do

                        local worldPoint =
                            boxCFrame:PointToWorldSpace(
                                corner
                            )

                        local screenPoint,
                            onScreen =
                            camera:WorldToViewportPoint(
                                worldPoint
                            )

                        if screenPoint.Z >
                            0 then

                            visibleCorner =
                                true

                            minX =
                                math.min(
                                    minX,
                                    screenPoint.X
                                )

                            maxX =
                                math.max(
                                    maxX,
                                    screenPoint.X
                                )

                            minY =
                                math.min(
                                    minY,
                                    screenPoint.Y
                                )

                            maxY =
                                math.max(
                                    maxY,
                                    screenPoint.Y
                                )
                        end
                    end

                    if not visibleCorner then

                        HideDrawings(
                            drawings
                        )

                        continue
                    end

                    local width =
                        maxX - minX

                    local height =
                        maxY - minY

                    if width <= 1
                        or height <= 1 then

                        HideDrawings(
                            drawings
                        )

                        continue
                    end

                    local teamSame =
                        SameTeam(
                            model
                        )

                    local boxColor =
                        espConfig.BoxColor

                    if espConfig.TeamColor then

                        if teamSame then

                            boxColor =
                                Color3.fromRGB(
                                    0,
                                    255,
                                    0
                                )

                        else

                            boxColor =
                                Color3.fromRGB(
                                    255,
                                    255,
                                    255
                                )
                        end
                    end

                    if espConfig.Boxes then

                        drawings.BoxOutline.Thickness =
                            espConfig.BoxThickness + 2

                        drawings.BoxOutline.Size =
                            Vector2.new(
                                width,
                                height
                            )

                        drawings.BoxOutline.Position =
                            Vector2.new(
                                minX,
                                minY
                            )

                        drawings.BoxOutline.Visible =
                            true

                        drawings.Box.Thickness =
                            espConfig.BoxThickness

                        drawings.Box.Size =
                            Vector2.new(
                                width,
                                height
                            )

                        drawings.Box.Position =
                            Vector2.new(
                                minX,
                                minY
                            )

                        drawings.Box.Color =
                            boxColor

                        drawings.Box.Visible =
                            true

                    else

                        drawings.BoxOutline.Visible =
                            false

                        drawings.Box.Visible =
                            false
                    end

                    if espConfig.Names then

                        drawings.Name.Size =
                            espConfig.NameSize

                        drawings.Name.Position =
                            Vector2.new(
                                (minX + maxX) * 0.5,
                                minY
                                    - espConfig.NameSize
                                    - 2
                            )

                        drawings.Name.Text =
                            tostring(
                                model.Name
                            )

                        drawings.Name.Color =
                            espConfig.NameColor

                        drawings.Name.Visible =
                            true

                    else

                        drawings.Name.Visible =
                            false
                    end

                    if espConfig.Distance then

                        drawings.Distance.Size =
                            espConfig.DistanceSize

                        drawings.Distance.Position =
                            Vector2.new(
                                (minX + maxX) * 0.5,
                                maxY + 2
                            )

                        drawings.Distance.Text =
                            string.format(
                                "[%d studs]",
                                math.floor(
                                    distance
                                )
                            )

                        drawings.Distance.Color =
                            espConfig.DistanceColor

                        drawings.Distance.Visible =
                            true

                    else

                        drawings.Distance.Visible =
                            false
                    end

                    if espConfig.HealthBar then

                        local health,
                            maxHealth =
                            GetHealth(
                                model
                            )

                        if health
                            and maxHealth
                            and maxHealth > 0 then

                            local healthPercent =
                                math.clamp(
                                    health / maxHealth,
                                    0,
                                    1
                                )

                            local barX =
                                minX - 5

                            drawings.HealthBarOutline.From =
                                Vector2.new(
                                    barX,
                                    minY
                                )

                            drawings.HealthBarOutline.To =
                                Vector2.new(
                                    barX,
                                    maxY
                                )

                            drawings.HealthBarOutline.Visible =
                                true

                            drawings.HealthBar.From =
                                Vector2.new(
                                    barX,
                                    maxY
                                )

                            drawings.HealthBar.To =
                                Vector2.new(
                                    barX,
                                    maxY
                                    -
                                    height
                                    * healthPercent
                                )

                            drawings.HealthBar.Color =
                                Color3.fromRGB(
                                    255
                                    -
                                    math.floor(
                                        healthPercent
                                        * 255
                                    ),

                                    math.floor(
                                        healthPercent
                                        * 255
                                    ),

                                    0
                                )

                            drawings.HealthBar.Visible =
                                true

                        else

                            drawings.HealthBarOutline.Visible =
                                false

                            drawings.HealthBar.Visible =
                                false
                        end

                    else

                        drawings.HealthBarOutline.Visible =
                            false

                        drawings.HealthBar.Visible =
                            false
                    end

                    if espConfig.Tracers then

                        local showTracer =
                            true

                        local tracerColor =
                            espConfig.TracerColor

                        if espConfig.TracerOnlyEnemy
                            and teamSame then

                            showTracer =
                                false

                        elseif espConfig.TeamColor then

                            if teamSame then

                                tracerColor =
                                    Color3.fromRGB(
                                        0,
                                        255,
                                        0
                                    )

                            else

                                tracerColor =
                                    Color3.fromRGB(
                                        255,
                                        255,
                                        255
                                    )
                            end
                        end

                        if showTracer then

                            drawings.Tracer.Thickness =
                                espConfig.TracerThickness

                            drawings.Tracer.From =
                                Vector2.new(
                                    viewportSize.X * 0.5,
                                    viewportSize.Y
                                )

                            drawings.Tracer.To =
                                Vector2.new(
                                    (minX + maxX) * 0.5,
                                    maxY
                                )

                            drawings.Tracer.Color =
                                tracerColor

                            drawings.Tracer.Visible =
                                true

                        else

                            drawings.Tracer.Visible =
                                false
                        end

                    else

                        drawings.Tracer.Visible =
                            false
                    end

                    if espConfig.HeadDots then

                        local head =
                            GetHead(
                                model
                            )

                        if head then

                            local headPosition,
                                headOnScreen =
                                camera:WorldToViewportPoint(
                                    head.Position
                                )

                            if headOnScreen
                                and headPosition.Z > 0 then

                                drawings.HeadDot.Position =
                                    Vector2.new(
                                        headPosition.X,
                                        headPosition.Y
                                    )

                                drawings.HeadDot.Radius =
                                    espConfig.HeadDotRadius

                                drawings.HeadDot.Color =
                                    espConfig.HeadDotColor

                                drawings.HeadDot.Visible =
                                    true

                            else

                                drawings.HeadDot.Visible =
                                    false
                            end

                        else

                            drawings.HeadDot.Visible =
                                false
                        end

                    else

                        drawings.HeadDot.Visible =
                            false
                    end
                end
            end
        )
end

-- ============================================================
-- SILENT AIM (исправленный, прямой метод)
-- ============================================================

local SilentAim = {

    Enabled = false,

    Config = {

        AimPart = "Head",

        FOV = 150,

        MaxDistance = 2500,

        TeamCheck = true,

        WallCheck = true,

        FOVVisible = false,

        FOVColor = Color3.fromRGB(255, 255, 255)
    },

    Target = nil,

    BulletModule = nil,

    OriginalPerformRaycast = nil,

    HookInstalled = false
}

-- ============================================================
-- SILENT AIM - AIM PART
-- ============================================================

local function GetSilentAimPart(
    model
)

    if not model then
        return nil
    end

    if SilentAim.Config.AimPart ==
        "Head" then

        return
            model:FindFirstChild(
                "Head"
            )
            or GetRootPart(
                model
            )

    elseif SilentAim.Config.AimPart ==
        "Torso" then

        return
            model:FindFirstChild(
                "UpperTorso"
            )
            or model:FindFirstChild(
                "LowerTorso"
            )
            or model:FindFirstChild(
                "Torso"
            )
            or GetRootPart(
                model
            )
    end

    return GetRootPart(
        model
    )
end

-- ============================================================
-- SILENT AIM - VISIBILITY
-- ============================================================

local function IsSilentAimVisible(
    targetPart,
    targetModel
)

    if not targetPart
        or not targetPart.Parent then

        return false
    end

    if not SilentAim.Config.WallCheck then
        return true
    end

    local camera =
        Workspace.CurrentCamera

    if not camera then
        return false
    end

    local origin =
        camera.CFrame.Position

    local direction =
        targetPart.Position
        - origin

    if direction.Magnitude <=
        0.001 then

        return true
    end

    local params =
        RaycastParams.new()

    params.FilterType =
        Enum.RaycastFilterType.Exclude

    local filter = {}

    if LocalPlayer.Character then

        table.insert(
            filter,
            LocalPlayer.Character
        )
    end

    params.FilterDescendantsInstances =
        filter

    params.IgnoreWater =
        true

    local result =
        Workspace:Raycast(
            origin,
            direction,
            params
        )

    if not result then
        return true
    end

    if targetModel
        and result.Instance:IsDescendantOf(
            targetModel
        ) then

        return true
    end

    return
        result.Instance:IsDescendantOf(
            targetPart.Parent
        )
end

-- ============================================================
-- SILENT AIM - VALID TARGET
-- ============================================================

local function IsValidSilentTarget(
    model,
    camera
)

    if not model
        or not camera then

        return nil
    end

    if not model.Parent then
        return nil
    end

    if not IsPlayerModel(
        model
    ) then

        return nil
    end

    if SilentAim.Config.TeamCheck
        and SameTeam(
            model
        ) then

        return nil
    end

    local targetPart =
        GetSilentAimPart(
            model
        )

    if not targetPart
        or not targetPart.Parent then

        return nil
    end

    local distance =
        (
            targetPart.Position
            - camera.CFrame.Position
        ).Magnitude

    if distance >
        SilentAim.Config.MaxDistance then

        return nil
    end

    if not IsSilentAimVisible(
        targetPart,
        model
    ) then

        return nil
    end

    local screenPosition,
        onScreen =
        camera:WorldToViewportPoint(
            targetPart.Position
        )

    if not onScreen
        or screenPosition.Z <= 0 then

        return nil
    end

    local viewport =
        camera.ViewportSize

    local center =
        Vector2.new(
            viewport.X * 0.5,
            viewport.Y * 0.5
        )

    local screenPoint =
        Vector2.new(
            screenPosition.X,
            screenPosition.Y
        )

    local fovDistance =
        (
            screenPoint
            - center
        ).Magnitude

    if fovDistance >
        SilentAim.Config.FOV then

        return nil
    end

    return
        targetPart,
        fovDistance,
        distance
end

-- ============================================================
-- SILENT AIM - GET TARGET
-- ============================================================

local function GetSilentAimTarget()

    local camera =
        Workspace.CurrentCamera

    if not camera
        or not CharactersFolder then

        return nil
    end

    local bestTarget =
        nil

    local bestScore =
        math.huge

    for _, model in ipairs(
        CharactersFolder:GetChildren()
    ) do

        local targetPart,
            fovDistance,
            distance =
            IsValidSilentTarget(
                model,
                camera
            )

        if targetPart then

            local score =
                fovDistance
                +
                (
                    distance
                    / math.max(
                        SilentAim.Config.MaxDistance,
                        1
                    )
                    * 0.05
                )

            if score <
                bestScore then

                bestScore =
                    score

                bestTarget =
                    targetPart
            end
        end
    end

    return bestTarget
end

-- ============================================================
-- SILENT AIM - INSTALL (ПРЯМАЯ ЗАМЕНА МЕТОДА, БЕЗ hookfunction)
-- ============================================================

local function InstallSilentAim()

    if SilentAim.HookInstalled then
        return true
    end

    local ok, Bullet =
        pcall(function()

            return require(
                ReplicatedStorage
                    :WaitForChild("Components")
                    :WaitForChild("Weapon")
                    :WaitForChild("Classes")
                    :WaitForChild("Bullet")
            )

        end)

    if not ok
        or not Bullet then

        return false
    end

    if type(
        Bullet._performRaycast
    ) ~= "function" then

        return false
    end

    SilentAim.BulletModule =
        Bullet

    SilentAim.OriginalPerformRaycast =
        Bullet._performRaycast

    Bullet._performRaycast =
        function(self, spread)

            local originalResult =
                SilentAim.OriginalPerformRaycast(
                    self,
                    spread
                )

            if not SilentAim.Enabled
                or isUnloaded then

                return originalResult
            end

            local target =
                SilentAim.Target

            if not target
                or not target.Parent then

                return originalResult
            end

            local origin =
                originalResult
                and originalResult.Origin

            if not origin then
                return originalResult
            end

            local targetPosition =
                target.Position

            local direction =
                targetPosition
                - origin

            if direction.Magnitude <=
                0.001 then

                return originalResult
            end

            local range =
                self.Properties.Range
                or 500

            local distance =
                direction.Magnitude

            if distance >
                range then

                return originalResult
            end

            originalResult.Direction =
                direction.Unit

            originalResult.Distance =
                distance

            originalResult.Hits = {

                {

                    Position =
                        targetPosition,

                    Instance =
                        target,

                    Material =
                        target.Material.Name,

                    Normal =
                        direction.Unit,

                    Exit =
                        false
                }
            }

            return originalResult
        end

    SilentAim.HookInstalled =
        true

    return true
end

-- ============================================================
-- SILENT AIM FOV
-- ============================================================

local silentAimFOVCircle =
    nil

pcall(function()

    silentAimFOVCircle =
        Drawing.new(
            "Circle"
        )

    silentAimFOVCircle.Visible =
        false

    silentAimFOVCircle.Filled =
        false

    silentAimFOVCircle.NumSides =
        64

    silentAimFOVCircle.Radius =
        SilentAim.Config.FOV

    silentAimFOVCircle.Thickness =
        1

    silentAimFOVCircle.Color =
        SilentAim.Config.FOVColor
end)

-- ============================================================
-- SILENT AIM RENDER
-- ============================================================

pcall(function()

    RunService:UnbindFromRenderStep(
        "JulyScripts_SilentAim"
    )

end)

RunService:BindToRenderStep(
    "JulyScripts_SilentAim",
    Enum.RenderPriority.Camera.Value + 1,
    function()

        if isUnloaded then
            return
        end

        local camera =
            Workspace.CurrentCamera

        if not camera then
            return
        end

        if silentAimFOVCircle then

            local viewport =
                camera.ViewportSize

            silentAimFOVCircle.Position =
                Vector2.new(
                    viewport.X * 0.5,
                    viewport.Y * 0.5
                )

            silentAimFOVCircle.Radius =
                SilentAim.Config.FOV

            silentAimFOVCircle.Thickness =
                1

            silentAimFOVCircle.Color =
                SilentAim.Config.FOVColor

            silentAimFOVCircle.Visible =
                SilentAim.Enabled
                and SilentAim.Config.FOVVisible
        end

        if not SilentAim.Enabled then

            SilentAim.Target =
                nil

            return
        end

        SilentAim.Target =
            GetSilentAimTarget()
    end
)

-- ============================================================
-- SILENT AIM UI
-- ============================================================

local SilentAimSection =
    SilentAimPage:Section({

        Name =
            "Silent Aim Settings",

        Side =
            1
    })

SilentAimSection:Toggle({

    Name =
        "Enable Silent Aim",

    Flag =
        "SilentAim",

    Default =
        false,

    Callback =
        function(state)

            if isUnloaded then
                return
            end

            SilentAim.Enabled =
                state == true

            if SilentAim.Enabled then

                if not SilentAim.HookInstalled then

                    local installed =
                        InstallSilentAim()

                    if not installed then

                        SilentAim.Enabled =
                            false
                    end
                end

            else

                SilentAim.Target =
                    nil
            end
        end
})

SilentAimSection:Dropdown({

    Name =
        "Aim Part",

    Flag =
        "SilentAimAimPart",

    Items = {

        "Head",
        "Torso"
    },

    Default =
        "Head",

    Multi =
        false,

    Callback =
        function(value)

            local selected =
                tostring(
                    value
                )

            if selected ==
                "Head"
                or selected ==
                "Torso" then

                SilentAim.Config.AimPart =
                    selected
            end
        end
})

SilentAimSection:Slider({

    Name =
        "FOV",

    Flag =
        "SilentAimFOV",

    Default =
        150,

    Min =
        10,

    Max =
        500,

    Rounding =
        0,

    Callback =
        function(value)

            SilentAim.Config.FOV =
                tonumber(value)
                or 150
        end
})

SilentAimSection:Toggle({

    Name =
        "Show FOV",

    Flag =
        "SilentAimShowFOV",

    Default =
        false,

    Callback =
        function(state)

            SilentAim.Config.FOVVisible =
                state == true
        end
})

SilentAimSection:Slider({

    Name =
        "Max Distance",

    Flag =
        "SilentAimMaxDistance",

    Default =
        2500,

    Min =
        100,

    Max =
        5000,

    Rounding =
        0,

    Callback =
        function(value)

            SilentAim.Config.MaxDistance =
                tonumber(value)
                or 2500
        end
})

SilentAimSection:Toggle({

    Name =
        "Team Check",

    Flag =
        "SilentAimTeamCheck",

    Default =
        true,

    Callback =
        function(state)

            SilentAim.Config.TeamCheck =
                state == true
        end
})

SilentAimSection:Toggle({

    Name =
        "Wall Check",

    Flag =
        "SilentAimWallCheck",

    Default =
        true,

    Callback =
        function(state)

            SilentAim.Config.WallCheck =
                state == true
        end
})

-- ============================================================
-- WEAPON MODS UI
-- ============================================================

local WeaponModsSection =
    WeaponModsPage:Section({

        Name =
            "Mods",

        Side =
            1
    })

WeaponModsSection:Toggle({

    Name =
        "No Spread",

    Flag =
        "NoSpread",

    Default =
        false,

    Callback =
        function(value)

            noSpreadEnabled =
                value == true

            if noSpreadEnabled
                and not noSpreadHookInstalled then

                InstallWeaponHooks()
            end
        end
})

WeaponModsSection:Toggle({

    Name =
        "No Recoil",

    Flag =
        "NoRecoil",

    Default =
        false,

    Callback =
        function(value)

            noRecoilEnabled =
                value == true

            if noRecoilEnabled
                and not noRecoilHookInstalled then

                InstallWeaponHooks()
            end
        end
})

WeaponModsSection:Toggle({
    Name =
        "Insta Revolver",

    Flag =
        "InstaRevolver",

    Default =
        false,

    Callback =
        function(value)

            if isUnloaded then
                return
            end

            instaRevolverEnabled =
                value == true

            if instaRevolverEnabled
                and not instaRevolverHookInstalled then

                InstallInstaRevolverHook()
            end
        end
})


-- ============================================================
-- VISUALS UI (ESP + Handchams + Weapon Chams + Player Chams)
-- ============================================================

local VisualsSection =
    VisualsPage:Section({

        Name =
            "ESP",

        Side =
            1
    })

VisualsSection:Toggle({

    Name =
        "Enable ESP",

    Flag =
        "ESP",

    Default =
        false,

    Callback =
        function(state)

            if isUnloaded then
                return
            end

            espEnabled =
                state == true

            if espEnabled then

                StartESPConnections()
                StartESP()

            else

                StopESP()
            end
        end
})

VisualsSection:Toggle({

    Name =
        "Boxes",

    Flag =
        "ESPBoxes",

    Default =
        true,

    Callback =
        function(state)

            espConfig.Boxes =
                state == true
        end
})

VisualsSection:Toggle({

    Name =
        "Names",

    Flag =
        "ESPNames",

    Default =
        true,

    Callback =
        function(state)

            espConfig.Names =
                state == true
        end
})

VisualsSection:Toggle({

    Name =
        "Distance",

    Flag =
        "ESPDistance",

    Default =
        true,

    Callback =
        function(state)

            espConfig.Distance =
                state == true
        end
})

VisualsSection:Toggle({

    Name =
        "Health Bar",

    Flag =
        "ESPHealthBar",

    Default =
        true,

    Callback =
        function(state)

            espConfig.HealthBar =
                state == true
        end
})

VisualsSection:Toggle({

    Name =
        "Tracers",

    Flag =
        "ESPTracers",

    Default =
        false,

    Callback =
        function(state)

            espConfig.Tracers =
                state == true
        end
})

VisualsSection:Toggle({

    Name =
        "Only Enemy",

    Flag =
        "ESPTracerOnlyEnemy",

    Default =
        false,

    Callback =
        function(state)

            espConfig.TracerOnlyEnemy =
                state == true
        end
})

VisualsSection:Toggle({

    Name =
        "Team Color",

    Flag =
        "ESPTeamColor",

    Default =
        false,

    Callback =
        function(state)

            espConfig.TeamColor =
                state == true
        end
})

VisualsSection:Toggle({

    Name =
        "Head Dots",

    Flag =
        "ESPHeadDots",

    Default =
        false,

    Callback =
        function(state)

            espConfig.HeadDots =
                state == true
        end
})

VisualsSection:Slider({

    Name =
        "Max Distance",

    Flag =
        "ESPMaxDistance",

    Default =
        2500,

    Min =
        100,

    Max =
        5000,

    Rounding =
        0,

    Callback =
        function(value)

            espConfig.MaxDistance =
                tonumber(value)
                or 2500
        end
})

VisualsSection:Slider({

    Name =
        "Box Thickness",

    Flag =
        "ESPBoxThickness",

    Default =
        1,

    Min =
        1,

    Max =
        3,

    Rounding =
        0,

    Callback =
        function(value)

            espConfig.BoxThickness =
                tonumber(value)
                or 1
        end
})

-- ============================================================
-- HANDCHAMS
-- ============================================================

local HandchamsSection =
    VisualsPage:Section({

        Name =
            "Hand Chams",

        Side =
            2
    })

local handchamsEnabled = false
local handchamsColor = Color3.fromRGB(0, 255, 0)
local handchamsMaterial = Enum.Material.Neon
local handchamsTransparency = 0
local handchamsOriginalData = {}

local function saveHandchamsOriginal(part)
    if not handchamsOriginalData[part] then
        handchamsOriginalData[part] = {
            Material = part.Material,
            Color = part.Color,
            Transparency = part.Transparency,
            TextureID = part:IsA("MeshPart") and part.TextureID or nil,
            SurfaceAppearance = part:FindFirstChildOfClass("SurfaceAppearance") and part:FindFirstChildOfClass("SurfaceAppearance"):Clone()
        }
    end
end

local function restoreHandchams()
    for part, data in pairs(handchamsOriginalData) do
        if part and part.Parent then
            part.Material = data.Material
            part.Color = data.Color
            part.Transparency = data.Transparency
            if part:IsA("MeshPart") then
                part.TextureID = data.TextureID or ""
            end
            local curSA = part:FindFirstChildOfClass("SurfaceAppearance")
            if curSA then curSA:Destroy() end
            if data.SurfaceAppearance then
                local newSA = data.SurfaceAppearance:Clone()
                newSA.Parent = part
            end
        end
    end
    table.clear(handchamsOriginalData)
end

local function findWeaponModel()
    local camera = Workspace.CurrentCamera
    if not camera then return nil end

    for _, child in ipairs(camera:GetChildren()) do
        if child:IsA("Model") then
            if child.Name == "CameraShake" or child.Name == "DummyParts" then
                continue
            end
            if child:FindFirstChild("Left Arm", true) or child:FindFirstChild("Right Arm", true) or child:FindFirstChild("Weapon", true) then
                return child
            end
        end
    end
    return nil
end

local function applyHandchams()
    if not handchamsEnabled then
        restoreHandchams()
        return
    end

    local weaponModel = findWeaponModel()
    if not weaponModel then return end

    local leftArm = weaponModel:FindFirstChild("Left Arm", true)
    local rightArm = weaponModel:FindFirstChild("Right Arm", true)

    if not leftArm and not rightArm then return end

    local partsToChange = {}

    local function collectParts(obj)
        if not obj then return end
        for _, part in ipairs(obj:GetDescendants()) do
            if part:IsA("BasePart") then
                local nameLower = part.Name:lower()
                if not (nameLower:find("light") or nameLower:find("camera") or nameLower:find("shake") or nameLower:find("dummy")) then
                    table.insert(partsToChange, part)
                end
            end
        end
        if obj:IsA("BasePart") then
            local nameLower = obj.Name:lower()
            if not (nameLower:find("light") or nameLower:find("camera") or nameLower:find("shake") or nameLower:find("dummy")) then
                table.insert(partsToChange, obj)
            end
        end
    end

    collectParts(leftArm)
    collectParts(rightArm)

    if #partsToChange == 0 then return end

    for _, part in ipairs(partsToChange) do
        saveHandchamsOriginal(part)
        local sa = part:FindFirstChildOfClass("SurfaceAppearance")
        if sa then sa:Destroy() end
        if part:IsA("MeshPart") then
            part.TextureID = ""
        end
        part.Material = handchamsMaterial
        part.Color = handchamsColor
        part.Transparency = handchamsTransparency
    end
end

HandchamsSection:Toggle({
    Name = "Enable Handchams",
    Flag = "Handchams",
    Default = false,
    Callback = function(state)
        handchamsEnabled = state
        if not handchamsEnabled then
            restoreHandchams()
        else
            applyHandchams()
        end
    end
})

local hcColorLabel = HandchamsSection:Label("Color")
hcColorLabel:Colorpicker({
    Flag = "HandchamsColor",
    Default = Color3.fromRGB(0, 255, 0),
    Callback = function(color)
        handchamsColor = color
        if handchamsEnabled then
            applyHandchams()
        end
    end
})

HandchamsSection:Dropdown({
    Name = "Material",
    Flag = "HandchamsMaterial",
    Items = {"Neon", "ForceField", "Glass", "SmoothPlastic", "Plastic"},
    Default = "Neon",
    Callback = function(value)
        local matMap = {
            Neon = Enum.Material.Neon,
            ForceField = Enum.Material.ForceField,
            Glass = Enum.Material.Glass,
            SmoothPlastic = Enum.Material.SmoothPlastic,
            Plastic = Enum.Material.Plastic
        }
        handchamsMaterial = matMap[value] or Enum.Material.Neon
        if handchamsEnabled then
            applyHandchams()
        end
    end
})

HandchamsSection:Slider({
    Name = "Transparency",
    Flag = "HandchamsTransparency",
    Default = 0,
    Min = 0,
    Max = 100,
    Rounding = 0,
    Suffix = "%",
    Callback = function(value)
        handchamsTransparency = value / 100
        if handchamsEnabled then
            applyHandchams()
        end
    end
})

-- ============================================================
-- WEAPON CHAMS
-- ============================================================

local WeaponChamsSection =
    VisualsPage:Section({

        Name =
            "Weapon Chams",

        Side =
            2
    })

local weaponChamsEnabled = false
local weaponChamsColor = Color3.fromRGB(255, 0, 0)
local weaponChamsMaterial = Enum.Material.Neon
local weaponChamsTransparency = 0
local weaponChamsOriginalData = {}

local function saveWeaponChamsOriginal(part)
    if not weaponChamsOriginalData[part] then
        weaponChamsOriginalData[part] = {
            Material = part.Material,
            Color = part.Color,
            Transparency = part.Transparency,
            TextureID = part:IsA("MeshPart") and part.TextureID or nil,
            SurfaceAppearance = part:FindFirstChildOfClass("SurfaceAppearance") and part:FindFirstChildOfClass("SurfaceAppearance"):Clone()
        }
    end
end

local function restoreWeaponChams()
    for part, data in pairs(weaponChamsOriginalData) do
        if part and part.Parent then
            part.Material = data.Material
            part.Color = data.Color
            part.Transparency = data.Transparency
            if part:IsA("MeshPart") then
                part.TextureID = data.TextureID or ""
            end
            local curSA = part:FindFirstChildOfClass("SurfaceAppearance")
            if curSA then curSA:Destroy() end
            if data.SurfaceAppearance then
                local newSA = data.SurfaceAppearance:Clone()
                newSA.Parent = part
            end
        end
    end
    table.clear(weaponChamsOriginalData)
end

local function applyWeaponChams()
    if not weaponChamsEnabled then
        restoreWeaponChams()
        return
    end

    local weaponModel = findWeaponModel()
    if not weaponModel then return end

    local leftArm = weaponModel:FindFirstChild("Left Arm", true)
    local rightArm = weaponModel:FindFirstChild("Right Arm", true)

    local partsToChange = {}

    for _, part in ipairs(weaponModel:GetDescendants()) do
        if part:IsA("BasePart") then
            local nameLower = part.Name:lower()
            if (leftArm and part:IsDescendantOf(leftArm)) or (rightArm and part:IsDescendantOf(rightArm)) then
                -- пропускаем
            elseif nameLower:find("hitbox") or nameLower:find("collision") or nameLower:find("light") or nameLower:find("camera") or nameLower:find("shake") or nameLower:find("dummy") then
                -- пропускаем
            else
                table.insert(partsToChange, part)
            end
        end
    end

    if #partsToChange == 0 then return end

    for _, part in ipairs(partsToChange) do
        saveWeaponChamsOriginal(part)
        local sa = part:FindFirstChildOfClass("SurfaceAppearance")
        if sa then sa:Destroy() end
        if part:IsA("MeshPart") then
            part.TextureID = ""
        end
        part.Material = weaponChamsMaterial
        part.Color = weaponChamsColor
        part.Transparency = weaponChamsTransparency
    end
end

WeaponChamsSection:Toggle({
    Name = "Enable Weapon Chams",
    Flag = "WeaponChams",
    Default = false,
    Callback = function(state)
        weaponChamsEnabled = state
        if not weaponChamsEnabled then
            restoreWeaponChams()
        else
            applyWeaponChams()
        end
    end
})

local wcColorLabel = WeaponChamsSection:Label("Color")
wcColorLabel:Colorpicker({
    Flag = "WeaponChamsColor",
    Default = Color3.fromRGB(255, 0, 0),
    Callback = function(color)
        weaponChamsColor = color
        if weaponChamsEnabled then
            applyWeaponChams()
        end
    end
})

WeaponChamsSection:Dropdown({
    Name = "Material",
    Flag = "WeaponChamsMaterial",
    Items = {"Neon", "ForceField", "Glass", "SmoothPlastic", "Plastic"},
    Default = "Neon",
    Callback = function(value)
        local matMap = {
            Neon = Enum.Material.Neon,
            ForceField = Enum.Material.ForceField,
            Glass = Enum.Material.Glass,
            SmoothPlastic = Enum.Material.SmoothPlastic,
            Plastic = Enum.Material.Plastic
        }
        weaponChamsMaterial = matMap[value] or Enum.Material.Neon
        if weaponChamsEnabled then
            applyWeaponChams()
        end
    end
})

WeaponChamsSection:Slider({
    Name = "Transparency",
    Flag = "WeaponChamsTransparency",
    Default = 0,
    Min = 0,
    Max = 100,
    Rounding = 0,
    Suffix = "%",
    Callback = function(value)
        weaponChamsTransparency = value / 100
        if weaponChamsEnabled then
            applyWeaponChams()
        end
    end
})

-- ============================================================
-- PLAYER CHAMS (исправленный, с безопасной обработкой DepthMode)
-- ============================================================

local PlayerChamsSection =
    VisualsPage:Section({

        Name =
            "Player Chams",

        Side =
            2
    })

local playerChamsEnabled = false
local playerChamsColor = Color3.fromRGB(0, 255, 255)
local playerChamsMaterial = Enum.Material.Neon
local playerChamsTransparency = 0
local playerChamsOnlyEnemy = false
local playerChamsWallhack = false
local playerChamsOriginalData = {}

local function savePlayerChamsOriginal(part, model)
    if not playerChamsOriginalData[model] then
        playerChamsOriginalData[model] = {}
    end
    if not playerChamsOriginalData[model][part] then
        local data = {
            Material = part.Material,
            Color = part.Color,
            Transparency = part.Transparency,
            TextureID = part:IsA("MeshPart") and part.TextureID or nil,
            SurfaceAppearance = part:FindFirstChildOfClass("SurfaceAppearance") and part:FindFirstChildOfClass("SurfaceAppearance"):Clone()
        }
        local hasDepthMode, depthMode = pcall(function()
            return part.DepthMode
        end)
        if hasDepthMode then
            data.DepthMode = depthMode
        end
        playerChamsOriginalData[model][part] = data
    end
end

local function restorePlayerChams()
    for model, data in pairs(playerChamsOriginalData) do
        if model and model.Parent then
            for part, orig in pairs(data) do
                if part and part.Parent then
                    part.Material = orig.Material
                    part.Color = orig.Color
                    part.Transparency = orig.Transparency
                    if part:IsA("MeshPart") then
                        part.TextureID = orig.TextureID or ""
                    end
                    if orig.DepthMode ~= nil then
                        pcall(function()
                            part.DepthMode = orig.DepthMode
                        end)
                    end
                    local curSA = part:FindFirstChildOfClass("SurfaceAppearance")
                    if curSA then curSA:Destroy() end
                    if orig.SurfaceAppearance then
                        local newSA = orig.SurfaceAppearance:Clone()
                        newSA.Parent = part
                    end
                end
            end
        else
            playerChamsOriginalData[model] = nil
        end
    end
    for model, _ in pairs(playerChamsOriginalData) do
        if not model or not model.Parent then
            playerChamsOriginalData[model] = nil
        end
    end
end

local function applyPlayerChams()
    if not playerChamsEnabled then
        restorePlayerChams()
        return
    end

    if not CharactersFolder then return end

    for _, model in ipairs(CharactersFolder:GetChildren()) do
        if not IsPlayerModel(model) then continue end

        if playerChamsOnlyEnemy and SameTeam(model) then
            continue
        end

        local partsToChange = {}
        for _, part in ipairs(model:GetDescendants()) do
            if part:IsA("BasePart") then
                table.insert(partsToChange, part)
            end
        end

        for _, part in ipairs(partsToChange) do
            savePlayerChamsOriginal(part, model)
            local sa = part:FindFirstChildOfClass("SurfaceAppearance")
            if sa then sa:Destroy() end
            if part:IsA("MeshPart") then
                part.TextureID = ""
            end
            part.Material = playerChamsMaterial
            part.Color = playerChamsColor
            part.Transparency = playerChamsTransparency
            if playerChamsWallhack then
                pcall(function()
                    part.DepthMode = Enum.DepthMode.AlwaysOnTop
                end)
            else
                if playerChamsOriginalData[model] and playerChamsOriginalData[model][part] then
                    local orig = playerChamsOriginalData[model][part]
                    if orig.DepthMode ~= nil then
                        pcall(function()
                            part.DepthMode = orig.DepthMode
                        end)
                    else
                        pcall(function()
                            part.DepthMode = Enum.DepthMode.Default
                        end)
                    end
                else
                    pcall(function()
                        part.DepthMode = Enum.DepthMode.Default
                    end)
                end
            end
        end
    end
end

local function onPlayerAdded(model)
    if isUnloaded then return end
    if playerChamsEnabled then
        applyPlayerChams()
    end
end

local function onPlayerRemoved(model)
    if isUnloaded then return end
    if playerChamsOriginalData[model] then
        playerChamsOriginalData[model] = nil
    end
end

if CharactersFolder then
    CharactersFolder.ChildAdded:Connect(onPlayerAdded)
    CharactersFolder.ChildRemoved:Connect(onPlayerRemoved)
end

PlayerChamsSection:Toggle({
    Name = "Enable Player Chams",
    Flag = "PlayerChams",
    Default = false,
    Callback = function(state)
        playerChamsEnabled = state
        if not playerChamsEnabled then
            restorePlayerChams()
        else
            applyPlayerChams()
        end
    end
})

local pcColorLabel = PlayerChamsSection:Label("Color")
pcColorLabel:Colorpicker({
    Flag = "PlayerChamsColor",
    Default = Color3.fromRGB(0, 255, 255),
    Callback = function(color)
        playerChamsColor = color
        if playerChamsEnabled then
            applyPlayerChams()
        end
    end
})

PlayerChamsSection:Dropdown({
    Name = "Material",
    Flag = "PlayerChamsMaterial",
    Items = {"Neon", "ForceField", "Glass", "SmoothPlastic", "Plastic"},
    Default = "Neon",
    Callback = function(value)
        local matMap = {
            Neon = Enum.Material.Neon,
            ForceField = Enum.Material.ForceField,
            Glass = Enum.Material.Glass,
            SmoothPlastic = Enum.Material.SmoothPlastic,
            Plastic = Enum.Material.Plastic
        }
        playerChamsMaterial = matMap[value] or Enum.Material.Neon
        if playerChamsEnabled then
            applyPlayerChams()
        end
    end
})

PlayerChamsSection:Slider({
    Name = "Transparency",
    Flag = "PlayerChamsTransparency",
    Default = 0,
    Min = 0,
    Max = 100,
    Rounding = 0,
    Suffix = "%",
    Callback = function(value)
        playerChamsTransparency = value / 100
        if playerChamsEnabled then
            applyPlayerChams()
        end
    end
})

PlayerChamsSection:Toggle({
    Name = "Only Enemy",
    Flag = "PlayerChamsOnlyEnemy",
    Default = false,
    Callback = function(state)
        playerChamsOnlyEnemy = state
        if playerChamsEnabled then
            applyPlayerChams()
        end
    end
})

PlayerChamsSection:Toggle({
    Name = "Visible Through Walls",
    Flag = "PlayerChamsWallhack",
    Default = false,
    Callback = function(state)
        playerChamsWallhack = state
        if playerChamsEnabled then
            applyPlayerChams()
        end
    end
})

-- ============================================================
-- ОБЩИЙ РЕНДЕР ДЛЯ ВСЕХ ЧЕЙМСОВ (руки, оружие, игроки)
-- ============================================================

local chamsRenderConn = nil

local function updateAllChams()
    applyHandchams()
    applyWeaponChams()
    applyPlayerChams()
end

chamsRenderConn = RunService.RenderStepped:Connect(function()
    if isUnloaded then return end
    updateAllChams()
end)

workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    if isUnloaded then return end
    updateAllChams()
end)

-- ============================================================
-- WEAPON SKIN CHANGER (для обычного оружия)
-- ============================================================

local WeaponSkinsDatabase = {
    ["AK-47"] = {"Aniki","Lore","Luminex","Midas","PinPoint","Rebellion","Red Baron","Sakura","Sovapid"},
    ["AUG"] = {"Anodized Red","Hero of Hell","Hot Rod","Overgrowth","Predator","Tension"},
    ["AWP"] = {"Beta","Bird Hunt","Freedom","HexPop","High Octane","Koi Pond","Lore","Metamorphosis","Overdrive","Railgun","Tekko","Typhon"},
    ["Desert Eagle"] = {"Bronze Elite","Circuit","Freedom","Hero of Hell","High Octane","Lore","Mercy","Paranoia","Permafrost","Punk","Racer8","Spectrum","Turbo","Velocity"},
    ["Dual Berettas"] = {"Choking Hazard","Gilded","Inked","Overclock","Tension","Vernal"},
    ["FAMAS"] = {"Arctic Camo","Heirloom","Medic","Mind","Wallpaper"},
    ["Five-SeveN"] = {"Control","Icecap","Mk II","NoMercy","X-Ray"},
    ["Galil AR"] = {"Feral","Irid","Irradiated","Limewire","Monochrome"},
    ["Glock-18"] = {"Aurora","Broken Tv","Canvas","Fade","Fuji","Hero of Hell","Midas","PinPoint","Yurei"},
    ["M4A1-S"] = {"Anodized Red","BlackOps","Bloggd","Castroil","Orchids","Phaseprint","Retro","SuperSoaked"},
    ["M4A4"] = {"B-Hop","BubblePop","Freedom","Hero of Hell","Ignition","Tekko","The Ambassador","Wrapped"},
    ["MAC-10"] = {"Air Mail","Daisies","Ivory","Midas","NGRAM","Nailgun","Parcel"},
    ["MAG-7"] = {"Ambulance","Vision7"},
    ["MP9"] = {"Anodized Red","Canyon","Choke Oil","Classified","Graffiti","Hibiki","High Octane","Paranoia","Patina","X-Ray"},
    ["Negev"] = {"Frostbloom","Noctiflora","Rotary Power","The Jungle"},
    ["Nova"] = {"Arctic Stripe","Flutter","Half+One","Heat","Huntsman","Mecha","Slime"},
    ["P250"] = {"B-250","Frutiger Aero","Glacial","Mindspill","Pulse","Zen"},
    ["P90"] = {"Big Cat","Chromatic","DRFT","Database","PinPoint","Synthwave","Visions"},
    ["R8 Revolver"] = {"Bloody8","Heatseeka","Regalia","Warui"},
    ["SG 553"] = {"Cryo","Dynasty","Frostline"},
    ["SSG 08"] = {"Desert Strike","GutterFreak","Labyrinth","Mindspill","Onyx","Prototype","Racer8"},
    ["Sawed-Off"] = {"Improvised","Memento","Orbit","Panthera","SuperSoaked"},
    ["Tec-9"] = {"Doodle","Medal.tv","Monarch","Striker","Timeless","Trajectory","Vice"},
    ["USP-S"] = {"Ajax","Heated","Luminex","SpecOps","SuperSoaked","Tekko","Tora","Wintergreen"},
    ["XM1014"] = {"Abstract","BloxoBlasto","Koi","Lilies","Office","Splatter"},
    ["Zeus x27"] = {"BitFyre","MedScan","Overcharge","Viperized"},
    ["LightSaber"] = {"Ren"},
    ["Butterfly Knife"] = {"Blackwidow","Damascus","Doodle","Fade","Lebron James","Midnight","Naval","Rusted","Safari","Scarlet","Tiger Stripes","Violet","Whiteout","Woodland"},
    ["CT Knife"] = {"Lebron James"},
    ["Flip Knife"] = {"Aurora","Blackwidow","Damascus","Doodle","Fade","Frostbite","Midnight","Naval","Noir","Rusted","Safari","Scarlet","Tiger Stripes","Violet","Whiteout","Woodland"},
    ["Gut Knife"] = {"Aurora","Blackwidow","Damascus","Doodle","Fade","Frostbite","Midnight","Naval","Noir","Rusted","Safari","Scarlet","Tiger Stripes","Violet","Whiteout","Woodland"},
    ["Karambit"] = {"Aurora","Blackwidow","Damascus","Doodle","Fade","Frostbite","Midnight","Naval","Noir","Rusted","Safari","Scarlet","Tiger Stripes","Violet","Wemby","Whiteout","Woodland"},
    ["M9 Bayonet"] = {"Blackwidow","Damascus","Doodle","Fade","Midnight","Naval","Rusted","Safari","Scarlet","Tiger Stripes","Violet","Whiteout","Woodland"},
    ["Skeleton Knife"] = {"Blackwidow","Fade","Midnight","Naval","Safari","Scarlet","Violet","Whiteout","Woodland"},
    ["Stiletto Knife"] = {"Blackwidow","Damascus","Doodle","Fade","Midnight","Naval","Rusted","Safari","Scarlet","Tiger Stripes","Violet","Whiteout","Woodland"},
    ["Driver Gloves"] = {"Cardinal","Cardinal Weave","Cobra","Gator","Leopard","Midnight Weave","Nomad","Snow Leopard","Tartan","Tuxedo"},
    ["Hand Wraps"] = {"Aztec","Bandage","Camouflage","Carpet","Checkers","Crime Scene","Hunter","Meander","Snakeskin","Taped"},
    ["Operator Gloves"] = {"Agent","Amber Fade","Black Widow","Bumblebee","Emerald Widow","Fade","Hellwire","Hunter","Reinforced","Smoke"},
    ["Sports Gloves"] = {"Blackout","Bumblebee","Dune","Freshmint","Hunter","Imperial","Labyrinth","Malibu","Racer","The Ambassador","Tidal"}
}

-- ============================================================
-- WEAPON SKIN CHANGER CLASS
-- ============================================================

local WeaponSkinChanger = {}
WeaponSkinChanger.__index = WeaponSkinChanger

function WeaponSkinChanger.new()
    local self = setmetatable({}, WeaponSkinChanger)
    self.active = false
    self.enabled = true
    self.skins = {}
    self.originalSurfaceAppearances = {}
    self.camera = Workspace.CurrentCamera
    self.renderConn = nil
    self.camConn = nil
    return self
end

function WeaponSkinChanger:getCamera()
    if not self.camera or not self.camera.Parent then
        self.camera = Workspace.CurrentCamera
    end
    return self.camera
end

function WeaponSkinChanger:getSkinFolder(weapon, skin)
    local assets = ReplicatedStorage:FindFirstChild("Assets")
    local root = (assets and assets:FindFirstChild("Skins")) or ReplicatedStorage:FindFirstChild("Skins")
    if not root or not skin or skin == "Stock" or skin == "Vanilla" then return nil end
    local weaponFolder = root:FindFirstChild(weapon)
    if not weaponFolder then return nil end
    local skinFolder = weaponFolder:FindFirstChild(skin)
    if not skinFolder then return nil end
    local cam = skinFolder:FindFirstChild("Camera") or skinFolder:FindFirstChild("Character")
    if not cam then return nil end
    return cam:FindFirstChild("Factory New") or cam:FindFirstChildWhichIsA("Folder")
end

function WeaponSkinChanger:saveOriginal(part)
    if self.originalSurfaceAppearances[part] ~= nil then return end
    local current = part:FindFirstChildOfClass("SurfaceAppearance")
    self.originalSurfaceAppearances[part] = current and current:Clone() or false
end

function WeaponSkinChanger:applySkin(model, folder)
    if not model or not folder then return end
    local list = {}
    for _, obj in ipairs(folder:GetChildren()) do
        if obj:IsA("SurfaceAppearance") then
            table.insert(list, obj)
        end
    end
    if #list == 0 then return end
    local matched = false
    for _, targetSA in ipairs(list) do
        local part = model:FindFirstChild(targetSA.Name, true)
        if part and part:IsA("MeshPart") and not part.Name:find("Light") then
            self:saveOriginal(part)
            local curSA = part:FindFirstChildOfClass("SurfaceAppearance")
            if not curSA or curSA.ColorMap ~= targetSA.ColorMap then
                if curSA then curSA:Destroy() end
                local newSA = targetSA:Clone()
                newSA.Parent = part
            end
            matched = true
        end
    end
    if not matched then
        local targetSA = list[1]
        for _, part in ipairs(model:GetDescendants()) do
            if part:IsA("MeshPart") and not part.Name:find("Light") and part.Name ~= "Right Arm" and part.Name ~= "Left Arm" and part.Name ~= "Glove" then
                self:saveOriginal(part)
                local curSA = part:FindFirstChildOfClass("SurfaceAppearance")
                if not curSA or curSA.ColorMap ~= targetSA.ColorMap then
                    if curSA then curSA:Destroy() end
                    local newSA = targetSA:Clone()
                    newSA.Parent = part
                end
            end
        end
    end
end

function WeaponSkinChanger:restoreWeapon(weapon)
    local camera = self:getCamera()
    if not camera then return end
    for part, original in pairs(self.originalSurfaceAppearances) do
        if not part or not part.Parent then
            self.originalSurfaceAppearances[part] = nil
        else
            if weapon then
                if not part:IsDescendantOf(camera) then continue end
            end
            local current = part:FindFirstChildOfClass("SurfaceAppearance")
            if current then current:Destroy() end
            if original and original ~= false then
                local restored = original:Clone()
                restored.Parent = part
            end
            self.originalSurfaceAppearances[part] = nil
        end
    end
end

function WeaponSkinChanger:render()
    if not self.enabled then return end
    local camera = self:getCamera()
    if not camera then return end
    for _, child in ipairs(camera:GetChildren()) do
        if child:IsA("Model") then
            local weapon = child.Name
            local skin = self.skins[weapon]
            if skin and skin ~= "Stock" and skin ~= "Vanilla" then
                local folder = self:getSkinFolder(weapon, skin)
                if folder then
                    self:applySkin(child, folder)
                end
            end
        end
    end
end

function WeaponSkinChanger:init()
    if self.active then return end
    self.active = true
    self.camConn = Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
        self.camera = Workspace.CurrentCamera
    end)
    self.renderConn = RunService.RenderStepped:Connect(function()
        if isUnloaded then return end
        self:render()
    end)
end

function WeaponSkinChanger:setSkin(weapon, skin)
    self.skins[weapon] = skin
end

function WeaponSkinChanger:getSkin(weapon)
    return self.skins[weapon]
end

function WeaponSkinChanger:clearSkin(weapon)
    self.skins[weapon] = nil
    self:restoreWeapon(weapon)
end

function WeaponSkinChanger:clearAll()
    table.clear(self.skins)
    self:restoreWeapon()
end

function WeaponSkinChanger:setEnabled(state)
    self.enabled = state == true
end

function WeaponSkinChanger:destroy()
    if not self.active then return end
    self.active = false
    self.enabled = false
    self:clearAll()
    if self.renderConn then
        self.renderConn:Disconnect()
        self.renderConn = nil
    end
    if self.camConn then
        self.camConn:Disconnect()
        self.camConn = nil
    end
    table.clear(self.skins)
    table.clear(self.originalSurfaceAppearances)
end

local SkinChanger = WeaponSkinChanger.new()
SkinChanger:init()

-- ============================================================
-- UI для обычного SKIN CHANGER
-- ============================================================

local SkinSection = SkinsPage:Section({Name = "Weapon Skins", Side = 1})
local WeaponItems = {}
for weaponName in pairs(WeaponSkinsDatabase) do
    table.insert(WeaponItems, weaponName)
end
table.sort(WeaponItems, function(a,b) return a:lower() < b:lower() end)
local SelectedWeapon = WeaponItems[1]
local SelectedSkin = WeaponSkinsDatabase[SelectedWeapon] and WeaponSkinsDatabase[SelectedWeapon][1]

SkinSection:Toggle({
    Name = "Enable Skin Changer",
    Flag = "SkinChangerEnabled",
    Default = true,
    Callback = function(state)
        if isUnloaded then return end
        SkinChanger:setEnabled(state == true)
    end
})

SkinSection:Dropdown({
    Name = "Weapon",
    Flag = "SkinWeapon",
    Items = WeaponItems,
    Default = SelectedWeapon,
    Multi = false,
    Callback = function(value)
        local selected = tostring(value)
        if WeaponSkinsDatabase[selected] then
            SelectedWeapon = selected
            local skins = WeaponSkinsDatabase[SelectedWeapon]
            SelectedSkin = skins and skins[1]
        end
    end
})

local SkinItems = {}
if SelectedWeapon and WeaponSkinsDatabase[SelectedWeapon] then
    for _, skinName in ipairs(WeaponSkinsDatabase[SelectedWeapon]) do
        table.insert(SkinItems, skinName)
    end
end
if #SkinItems == 0 then table.insert(SkinItems, "None") end

local SkinDropdown = SkinSection:Dropdown({
    Name = "Skin",
    Flag = "SkinName",
    Items = SkinItems,
    Default = SelectedSkin or SkinItems[1],
    Multi = false,
    Callback = function(value)
        SelectedSkin = tostring(value)
    end
})

SkinSection:Button({
    Name = "Apply Skin",
    Callback = function()
        if isUnloaded then return end
        if not SelectedWeapon or not SelectedSkin or SelectedSkin == "None" then return end
        SkinChanger:setSkin(SelectedWeapon, SelectedSkin)
        SkinChanger:render()
    end
})

SkinSection:Button({
    Name = "Clear Selected",
    Callback = function()
        if isUnloaded then return end
        if not SelectedWeapon then return end
        SkinChanger:clearSkin(SelectedWeapon)
    end
})

SkinSection:Button({
    Name = "Clear All",
    Callback = function()
        if isUnloaded then return end
        SkinChanger:clearAll()
    end
})


-- ============================================================
-- KNIFE SKIN CHANGER
-- ============================================================

local knife_db = {
    ["Karambit"] = {
        "Vanilla", "Fade", "Tiger Stripes", "Damascus", "Doodle",
        "Rusted", "Aurora", "Frostbite", "Noir", "Scarlet",
        "Violet", "Midnight", "Blackwidow", "Whiteout", "Naval",
        "Woodland", "Safari", "Wemby",
        "Nebula_PATTERN_1", "Nebula_PATTERN_2", "Nebula_PATTERN_3", "Nebula_PATTERN_4", "Nebula_PATTERN_5",
        "Nebula_PATTERN_6", "Nebula_PATTERN_7", "Nebula_PATTERN_8", "Nebula_PATTERN_9", "Nebula_PATTERN_10", "Nebula_PATTERN_11",
        "Viridian_PATTERN_1", "Viridian_PATTERN_2", "Viridian_PATTERN_3", "Viridian_PATTERN_4", "Viridian_PATTERN_5",
        "Viridian_PATTERN_6", "Viridian_PATTERN_7", "Viridian_PATTERN_8", "Viridian_PATTERN_9"
    },
    ["Butterfly Knife"] = {
        "Vanilla", "Fade", "Tiger Stripes", "Damascus", "Doodle",
        "Rusted", "Scarlet", "Violet", "Midnight", "Blackwidow",
        "Whiteout", "Naval", "Woodland", "Safari", "Lebron James",
        "Nebula_PATTERN_1", "Nebula_PATTERN_2", "Nebula_PATTERN_3", "Nebula_PATTERN_4", "Nebula_PATTERN_5",
        "Nebula_PATTERN_6", "Nebula_PATTERN_7", "Nebula_PATTERN_8", "Nebula_PATTERN_9", "Nebula_PATTERN_10", "Nebula_PATTERN_11",
        "Viridian_PATTERN_1", "Viridian_PATTERN_2", "Viridian_PATTERN_3", "Viridian_PATTERN_4", "Viridian_PATTERN_5",
        "Viridian_PATTERN_6", "Viridian_PATTERN_7", "Viridian_PATTERN_8", "Viridian_PATTERN_9"
    },
    ["M9 Bayonet"] = {
        "Vanilla", "Fade", "Tiger Stripes", "Damascus", "Doodle",
        "Rusted", "Scarlet", "Violet", "Midnight", "Blackwidow",
        "Whiteout", "Naval", "Woodland", "Safari",
        "Nebula_PATTERN_1", "Nebula_PATTERN_2", "Nebula_PATTERN_3", "Nebula_PATTERN_4", "Nebula_PATTERN_5",
        "Nebula_PATTERN_6", "Nebula_PATTERN_7", "Nebula_PATTERN_8", "Nebula_PATTERN_9", "Nebula_PATTERN_10", "Nebula_PATTERN_11",
        "Viridian_PATTERN_1", "Viridian_PATTERN_2", "Viridian_PATTERN_3", "Viridian_PATTERN_4", "Viridian_PATTERN_5",
        "Viridian_PATTERN_6", "Viridian_PATTERN_7", "Viridian_PATTERN_8", "Viridian_PATTERN_9"
    },
    ["Skeleton Knife"] = {
        "Vanilla", "Fade", "Blackwidow", "Midnight", "Naval",
        "Safari", "Scarlet", "Violet", "Whiteout", "Woodland"
    },
    ["Flip Knife"] = {
        "Vanilla", "Fade", "Tiger Stripes", "Damascus", "Doodle",
        "Rusted", "Aurora", "Frostbite", "Noir", "Scarlet",
        "Violet", "Midnight", "Blackwidow", "Whiteout", "Naval",
        "Woodland", "Safari"
    },
    ["Gut Knife"] = {
        "Vanilla", "Fade", "Tiger Stripes", "Damascus", "Doodle",
        "Rusted", "Aurora", "Frostbite", "Noir", "Scarlet",
        "Violet", "Midnight", "Blackwidow", "Whiteout", "Naval",
        "Woodland", "Safari",
        "Nebula_PATTERN_1", "Nebula_PATTERN_2", "Nebula_PATTERN_3", "Nebula_PATTERN_4", "Nebula_PATTERN_5",
        "Nebula_PATTERN_6", "Nebula_PATTERN_7", "Nebula_PATTERN_8", "Nebula_PATTERN_9", "Nebula_PATTERN_10", "Nebula_PATTERN_11",
        "Viridian_PATTERN_1", "Viridian_PATTERN_2", "Viridian_PATTERN_3", "Viridian_PATTERN_4", "Viridian_PATTERN_5",
        "Viridian_PATTERN_6", "Viridian_PATTERN_7", "Viridian_PATTERN_8", "Viridian_PATTERN_9"
    },
    ["Stiletto Knife"] = {
        "Vanilla", "Fade", "Tiger Stripes", "Damascus", "Doodle",
        "Rusted", "Scarlet", "Violet", "Midnight", "Blackwidow",
        "Whiteout", "Naval", "Woodland", "Safari"
    },
    ["CT Knife"] = {
        "Stock", "Lebron James"
    },
    ["T Knife"] = {
        "Stock"
    }
}

local knife_active = false
local cur_knife = "Karambit"
local cur_skin = "Fade"

local rs = ReplicatedStorage
local plrs = Players
local run = RunService
local lp = LocalPlayer

local rs_assets = rs:FindFirstChild("Assets")
local rs_skins = (rs_assets and rs_assets:FindFirstChild("Skins")) or rs:FindFirstChild("Skins")

local originalGrant = nil
local ok_ld, ld_cls = pcall(require, rs:WaitForChild("Classes"):WaitForChild("Loadout"))
if ok_ld and ld_cls and type(ld_cls.grantPlayerInventoryItem) == "function" then
    originalGrant = ld_cls.grantPlayerInventoryItem
    ld_cls.grantPlayerInventoryItem = function(self, slot, id, _id, wep, sk, fl, st, nt, own, ch, stk, cp)
        if knife_active and ((wep and (wep:find("Knife") or wep:find("Bayonet") or wep:find("Karambit"))) or slot == 3) then
            wep = cur_knife
            sk = (cur_skin == "Vanilla" or cur_skin == "Stock") and "Vanilla" or cur_skin
        end
        return originalGrant(self, slot, id, _id, wep, sk, fl, st, nt, own, ch, stk, cp)
    end
end

local function apply_sa(mdl, fld)
    if not mdl or not fld then return end
    local sa = fld:FindFirstChildOfClass("SurfaceAppearance") or fld:FindFirstChildWhichIsA("SurfaceAppearance", true)
    if not sa then return end
    for _, p in ipairs(mdl:GetDescendants()) do
        if p:IsA("MeshPart") and not p.Name:find("Light") and not p.Name:find("Arm") and not p.Name:find("Glove") then
            local cur = p:FindFirstChildOfClass("SurfaceAppearance")
            if not cur or cur.ColorMap ~= sa.ColorMap then
                if cur then cur:Destroy() end
                local cl = sa:Clone()
                cl.Parent = p
            end
        end
    end
end

local knifeRenderConn = nil
knifeRenderConn = run.RenderStepped:Connect(function()
    if not knife_active or not rs_skins then return end
    local c = workspace.CurrentCamera
    if not c then return end

    local sf = (rs_skins:FindFirstChild(cur_knife) and rs_skins[cur_knife]:FindFirstChild(cur_skin))
        or (rs_skins:FindFirstChild("Karambit") and rs_skins.Karambit:FindFirstChild(cur_skin))
    local cam_fn = sf and sf:FindFirstChild("Camera") and (sf.Camera:FindFirstChild("Factory New") or sf.Camera:FindFirstChildWhichIsA("Folder"))
    local chr_fn = sf and (sf:FindFirstChild("Character") or sf:FindFirstChild("Camera"))
    local chr_fld = chr_fn and (chr_fn:FindFirstChild("Factory New") or chr_fn:FindFirstChildWhichIsA("Folder"))

    for _, ch in ipairs(c:GetChildren()) do
        if ch:IsA("Model") and (ch.Name:find("Knife") or ch.Name:find("Bayonet") or ch.Name:find("Karambit")) then
            local w = ch:FindFirstChild("Weapon") or ch
            for _, p in ipairs(w:GetDescendants()) do
                if p:IsA("BasePart") then
                    if p.Name:find("Light") then
                        p.Transparency = 1
                    elseif p.Transparency > 0.5 and (p.Name == "Handle" or p.Name == "CameraModel6" or p.Name:find("Blade")) then
                        p.Transparency = 0
                    end
                end
            end
            if cam_fn then apply_sa(w, cam_fn) end
        end
    end

    local char = lp and lp.Character
    if char and chr_fld then
        local wm = char:FindFirstChild("WeaponModel")
        local list = wm and { wm } or char:GetChildren()
        for _, m in ipairs(list) do
            if m:IsA("Model") or m:IsA("Folder") then
                local is_k = m.Name:find("Knife") or m.Name:find("Bayonet") or m.Name:find("Karambit")
                if not is_k then
                    for _, p in ipairs(m:GetDescendants()) do
                        if p:IsA("BasePart") and (p.Name:find("Blade") or p.Name:find("Knife") or p.Name:find("Handle")) then
                            is_k = true
                            break
                        end
                    end
                end
                if is_k then apply_sa(m, chr_fld) end
            end
        end
    end
end)

local KnifeSkinSection = SkinsPage:Section({
    Name = "Knife Skin Changer",
    Side = 1
})

local knifeToggle = KnifeSkinSection:Toggle({
    Name = "Enable Knife Changer",
    Flag = "KnifeChangerEnabled",
    Default = false,
    Callback = function(state)
        knife_active = state
    end
})

local knifeNames = {}
for name in pairs(knife_db) do
    table.insert(knifeNames, name)
end
table.sort(knifeNames)

local defaultSkins = {}
local skinDropdown = KnifeSkinSection:Dropdown({
    Name = "Skin",
    Flag = "KnifeSkin",
    Items = defaultSkins,
    Default = nil,
    Multi = false,
    Callback = function(value)
        cur_skin = value
    end
})

local knifeDropdown = KnifeSkinSection:Dropdown({
    Name = "Knife Model",
    Flag = "KnifeModel",
    Items = knifeNames,
    Default = knifeNames[1],
    Multi = false,
    Callback = function(value)
        cur_knife = value
        local skins = knife_db[cur_knife] or {}
        skinDropdown:Refresh(skins)
        if #skins > 0 then
            cur_skin = skins[1]
            skinDropdown:Set(skins[1])
        end
    end
})

if #knifeNames > 0 then
    cur_knife = knifeNames[1]
    local skins = knife_db[cur_knife] or {}
    skinDropdown:Refresh(skins)
    if #skins > 0 then
        cur_skin = skins[1]
        skinDropdown:Set(skins[1])
    end
end

KnifeSkinSection:Button({
    Name = "Reapply Skin",
    Callback = function()
        print("Reapplying knife skin...")
    end
})

-- ===========================================================
-- SETTINGS
-- ============================================================

local KeybindSection = SettingsPage:Section({Name = "Keybinds", Side = 1})

local MenuKeybindLabel = KeybindSection:Label("Menu Key")
MenuKeybindLabel:Keybind({
    Flag = "MenuKeybind",
    Default = Enum.KeyCode.RightControl,
    Mode = "Toggle",
    Callback = function()
        local data = Library.Flags["MenuKeybind"]
        if type(data) == "table" and data.Key then
            Library.MenuKeybind = tostring(data.Key)
        end
    end
})

KeybindSection:Toggle({
    Name = "Keybind List",
    Flag = "KeybindListVisible",
    Default = true,
    Callback = function(state)
        KeybindList:SetVisible(state)
    end
})
KeybindList:Add("Silent Aim", "RMB", false) -- можно убрать

-- ============================================================
-- UNLOAD
-- ============================================================

local UnloadSection = UnloadPage:Section({Name = "Unload", Side = 1})
UnloadSection:Button({
    Name = "Unload Script",
    Callback = function()
        if isUnloaded then return end
        isUnloaded = true

        noSpreadEnabled = false
        noRecoilEnabled = false
        instaRevolverEnabled = false

        if OriginalStartRevolverCharge then
            pcall(function()
                local Weapon = require(
                    ReplicatedStorage
                        :WaitForChild("Components")
                        :WaitForChild("Weapon")
                )
                Weapon.startRevolverCharge = OriginalStartRevolverCharge
            end)
        end

        instaRevolverHookInstalled = false
       OriginalStartRevolverCharge = nil
SilentAim.Enabled = false
        SilentAim.Target = nil
        pcall(function()
            RunService:UnbindFromRenderStep("JulyScripts_SilentAim")
        end)
        if silentAimFOVCircle then
            pcall(function()
                silentAimFOVCircle.Visible = false
                silentAimFOVCircle:Remove()
            end)
            silentAimFOVCircle = nil
        end
        if SilentAim.BulletModule and SilentAim.OriginalPerformRaycast then
            pcall(function()
                SilentAim.BulletModule._performRaycast = SilentAim.OriginalPerformRaycast
            end)
        end
        SilentAim.HookInstalled = false

        pcall(function()
            SkinChanger:destroy()
        end)

        espEnabled = false
        pcall(function()
            StopESP()
        end)

        -- Восстановление всех чеймсов
        pcall(function()
            restoreHandchams()
            restoreWeaponChams()
            restorePlayerChams()
            if chamsRenderConn then
                chamsRenderConn:Disconnect()
                chamsRenderConn = nil
            end
        end)

        -- Восстановление Knife Skin Changer
        pcall(function()
            if originalGrant and ld_cls then
                ld_cls.grantPlayerInventoryItem = originalGrant
            end
            if knifeRenderConn then
                knifeRenderConn:Disconnect()
                knifeRenderConn = nil
            end
            knife_active = false
        end)

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
    end
})

-- ============================================================
-- INITIAL STATE
-- ============================================================

KeybindList:SetVisible(true)

-- ============================================================
-- END
-- ============================================================
