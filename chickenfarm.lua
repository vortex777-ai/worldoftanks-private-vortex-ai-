
local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()
if not Library then return end

local Options = Library.Options
Library.ForceCheckbox = false
Library.ShowToggleFrameInKeybinds = true

local Window = Library:CreateWindow({
    Title = "JulyScripts",
    Footer = "Chicken Farm v1.0",
    Icon = "rbxassetid://116255434488074",
    NotifySide = "Right",
    ShowCustomCursor = true,
})
local Tabs = {
    Farm = Window:AddTab("Farm", "package"),
    Upgrades = Window:AddTab("Upgrades", "upload"),
    Player = Window:AddTab("Player", "user"),
    Visuals = Window:AddTab("Visuals", "eye"),
    ["UI Settings"] = Window:AddTab("UI", "wrench"),
}


local FarmGroup = Tabs.Farm:AddLeftGroupbox("Auto Collect Eggs", "zap")

local CONFIG_FARM = {
    TeleportDelay = 0.5,
    StayTime = 0.3,
}

local farmEnabled = false
local farmThread = nil
local LocalPlayer = game:GetService("Players").LocalPlayer
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local function getEggPosition(egg)
    if not egg then return nil end
    if egg.PrimaryPart then return egg.PrimaryPart.Position end
    local part = egg:FindFirstChild("Bitbox") or egg:FindFirstChild("Hitbox")
    if part and part:IsA("BasePart") then return part.Position end
    for _, child in ipairs(egg:GetChildren()) do
        if child:IsA("BasePart") then return child.Position end
    end
    local success, pivot = pcall(function() return egg:GetPivot() end)
    if success then return pivot.Position end
    return nil
end

local function startFarming()
    if farmThread then return end
    farmThread = task.spawn(function()
        while farmEnabled do
            pcall(function()
                local eggsFolder = Workspace:FindFirstChild("Eggs")
                if not eggsFolder then task.wait(1) return end
                local eggs = eggsFolder:GetChildren()
                if #eggs == 0 then task.wait(1) return end
                local char = LocalPlayer.Character
                if not char then task.wait(1) return end
                local root = char:FindFirstChild("HumanoidRootPart")
                if not root then task.wait(1) return end

                for _, egg in ipairs(eggs) do
                    if not farmEnabled then break end
                    if not egg or not egg.Parent then continue end
                    local pos = getEggPosition(egg)
                    if not pos then continue end
                    local targetPos = pos + Vector3.new(0, 2, 0)
                    root.CFrame = CFrame.new(targetPos)
                    task.wait(CONFIG_FARM.StayTime)
                    task.wait(CONFIG_FARM.TeleportDelay)
                end
                task.wait(1)
            end)
            task.wait(0.5)
        end
    end)
end

local function stopFarming()
    farmEnabled = false
    if farmThread then task.cancel(farmThread); farmThread = nil end
end

local function setFarming(state)
    farmEnabled = state
    if state then startFarming() else stopFarming() end
end

FarmGroup:AddToggle("FarmToggle", {
    Text = "Auto Collect Eggs",
    Default = false,
    Callback = function(value) setFarming(value) end,
})
FarmGroup:AddSlider("TeleportDelay", {
    Text = "Teleport Delay",
    Default = CONFIG_FARM.TeleportDelay,
    Min = 0.1,
    Max = 3,
    Rounding = 1,
    Callback = function(value) CONFIG_FARM.TeleportDelay = value end,
})
FarmGroup:AddSlider("StayTime", {
    Text = "Stay Time",
    Default = CONFIG_FARM.StayTime,
    Min = 0.1,
    Max = 2,
    Rounding = 1,
    Callback = function(value) CONFIG_FARM.StayTime = value end,
})

local RebirthGroup = Tabs.Farm:AddLeftGroupbox("Auto Rebirth", "sync")
local CONFIG_REBIRTH = { Interval = 60 }
local rebirthEnabled = false
local rebirthThread = nil

local function getRemote()
    return game:GetService("ReplicatedStorage"):WaitForChild("Paper"):WaitForChild("Remotes"):WaitForChild("__remotefunction")
end

local function getRemoteEvent()
    return game:GetService("ReplicatedStorage"):WaitForChild("Paper"):WaitForChild("Remotes"):WaitForChild("__remoteevent")
end

local function startRebirth()
    if rebirthThread then return end
    rebirthThread = task.spawn(function()
        while rebirthEnabled do
            pcall(function()
                local remote = getRemote()
                if remote then
                    remote:InvokeServer("Rebirth")
                end
            end)
            task.wait(CONFIG_REBIRTH.Interval)
        end
    end)
end
local function stopRebirth()
    rebirthEnabled = false
    if rebirthThread then task.cancel(rebirthThread); rebirthThread = nil end
end
local function setRebirth(state)
    rebirthEnabled = state
    if state then startRebirth() else stopRebirth() end
end

RebirthGroup:AddToggle("RebirthToggle", {
    Text = "Auto Rebirth",
    Default = false,
    Callback = function(value) setRebirth(value) end,
})
RebirthGroup:AddSlider("RebirthInterval", {
    Text = "Interval",
    Default = CONFIG_REBIRTH.Interval,
    Min = 1,
    Max = 300,
    Rounding = 0,
    Callback = function(value) CONFIG_REBIRTH.Interval = value end,
})
local CashGroup = Tabs.Farm:AddRightGroupbox("Auto Cash Collect", "coins")

local CONFIG_CASH = { Interval = 30 }
local cashEnabled = false
local cashThread = nil

local function startCashCollect()
    if cashThread then return end
    cashThread = task.spawn(function()
        while cashEnabled do
            pcall(function()
                local remote = getRemote()
                if remote then
                    remote:InvokeServer("Collect Cash")
                end
            end)
            task.wait(CONFIG_CASH.Interval)
        end
    end)
end
local function stopCashCollect()
    cashEnabled = false
    if cashThread then task.cancel(cashThread); cashThread = nil end
end
local function setCashCollect(state)
    cashEnabled = state
    if state then startCashCollect() else stopCashCollect() end
end

CashGroup:AddToggle("CashToggle", {
    Text = "Auto Collect Cash",
    Default = false,
    Callback = function(value) setCashCollect(value) end,
})
CashGroup:AddSlider("CashInterval", {
    Text = "Interval",
    Default = CONFIG_CASH.Interval,
    Min = 1,
    Max = 120,
    Rounding = 0,
    Callback = function(value) CONFIG_CASH.Interval = value end,
})

local UpgradesTab = Tabs.Upgrades

local DepositGroup = UpgradesTab:AddLeftGroupbox("Deposit", "upload")
local CONFIG_DEP = { Interval = 10 }
local depEnabled = false
local depThread = nil

local function startDeposit()
    if depThread then return end
    depThread = task.spawn(function()
        while depEnabled do
            pcall(function()
                local remote = getRemote()
                if remote then
                    remote:InvokeServer("Deposit Eggs")
                end
            end)
            task.wait(CONFIG_DEP.Interval)
        end
    end)
end
local function stopDeposit()
    depEnabled = false
    if depThread then task.cancel(depThread); depThread = nil end
end
local function setDeposit(state)
    depEnabled = state
    if state then startDeposit() else stopDeposit() end
end

DepositGroup:AddToggle("DepositToggle", {
    Text = "Auto Deposit Eggs",
    Default = false,
    Callback = function(value) setDeposit(value) end,
})
DepositGroup:AddSlider("DepositInterval", {
    Text = "Interval",
    Default = CONFIG_DEP.Interval,
    Min = 1,
    Max = 60,
    Rounding = 0,
    Callback = function(value) CONFIG_DEP.Interval = value end,
})

local BuyGroup = UpgradesTab:AddLeftGroupbox("Buy", "shopping-cart")
local CONFIG_BUY = { Interval = 15 }
local buyEnabled = false
local buyThread = nil
local buy5Enabled = false
local buy5Thread = nil
local buy25Enabled = false
local buy25Thread = nil
local buy100Enabled = false
local buy100Thread = nil

local function startBuy()
    if buyThread then return end
    buyThread = task.spawn(function()
        while buyEnabled do
            pcall(function()
                local remote = getRemote()
                if remote then
                    remote:InvokeServer("Buy Chickens", 1)
                end
            end)
            task.wait(CONFIG_BUY.Interval)
        end
    end)
end
local function stopBuy()
    buyEnabled = false
    if buyThread then task.cancel(buyThread); buyThread = nil end
end
local function setBuy(state)
    buyEnabled = state
    if state then startBuy() else stopBuy() end
end

-- Покупка 5
local function startBuy5()
    if buy5Thread then return end
    buy5Thread = task.spawn(function()
        while buy5Enabled do
            pcall(function()
                local remote = getRemote()
                if remote then
                    remote:InvokeServer("Buy Chickens", 5)
                end
            end)
            task.wait(CONFIG_BUY.Interval)
        end
    end)
end
local function stopBuy5()
    buy5Enabled = false
    if buy5Thread then task.cancel(buy5Thread); buy5Thread = nil end
end
local function setBuy5(state)
    buy5Enabled = state
    if state then startBuy5() else stopBuy5() end
end

-- Покупка 25
local function startBuy25()
    if buy25Thread then return end
    buy25Thread = task.spawn(function()
        while buy25Enabled do
            pcall(function()
                local remote = getRemote()
                if remote then
                    remote:InvokeServer("Buy Chickens", 25)
                end
            end)
            task.wait(CONFIG_BUY.Interval)
        end
    end)
end
local function stopBuy25()
    buy25Enabled = false
    if buy25Thread then task.cancel(buy25Thread); buy25Thread = nil end
end
local function setBuy25(state)
    buy25Enabled = state
    if state then startBuy25() else stopBuy25() end
end

-- Покупка 100
local function startBuy100()
    if buy100Thread then return end
    buy100Thread = task.spawn(function()
        while buy100Enabled do
            pcall(function()
                local remote = getRemote()
                if remote then
                    remote:InvokeServer("Buy Chickens", 100)
                end
            end)
            task.wait(CONFIG_BUY.Interval)
        end
    end)
end
local function stopBuy100()
    buy100Enabled = false
    if buy100Thread then task.cancel(buy100Thread); buy100Thread = nil end
end
local function setBuy100(state)
    buy100Enabled = state
    if state then startBuy100() else stopBuy100() end
end

BuyGroup:AddToggle("BuyToggle", {
    Text = "Auto Buy Chickens (1)",
    Default = false,
    Callback = function(value) setBuy(value) end,
})
BuyGroup:AddToggle("Buy5Toggle", {
    Text = "Auto Buy Chickens (5)",
    Default = false,
    Callback = function(value) setBuy5(value) end,
})
BuyGroup:AddToggle("Buy25Toggle", {
    Text = "Auto Buy Chickens (25)",
    Default = false,
    Callback = function(value) setBuy25(value) end,
})
BuyGroup:AddToggle("Buy100Toggle", {
    Text = "Auto Buy Chickens (100)",
    Default = false,
    Callback = function(value) setBuy100(value) end,
})
BuyGroup:AddSlider("BuyInterval", {
    Text = "Interval",
    Default = CONFIG_BUY.Interval,
    Min = 1,
    Max = 60,
    Rounding = 0,
    Callback = function(value) CONFIG_BUY.Interval = value end,
})

local UpgradeTierGroup = UpgradesTab:AddLeftGroupbox("Upgrade Tier", "level-up")
local CONFIG_UPGRADE_TIER = { Interval = 30 }
local upgradeTierEnabled = false
local upgradeTierThread = nil

local function startUpgradeTier()
    if upgradeTierThread then return end
    upgradeTierThread = task.spawn(function()
        while upgradeTierEnabled do
            pcall(function()
                local remote = getRemote()
                if remote then
                    remote:InvokeServer("Upgrade Buy Tier Level")
                end
            end)
            task.wait(CONFIG_UPGRADE_TIER.Interval)
        end
    end)
end
local function stopUpgradeTier()
    upgradeTierEnabled = false
    if upgradeTierThread then task.cancel(upgradeTierThread); upgradeTierThread = nil end
end
local function setUpgradeTier(state)
    upgradeTierEnabled = state
    if state then startUpgradeTier() else stopUpgradeTier() end
end

UpgradeTierGroup:AddToggle("UpgradeTierToggle", {
    Text = "Auto Upgrade Tier",
    Default = false,
    Callback = function(value) setUpgradeTier(value) end,
})
UpgradeTierGroup:AddSlider("UpgradeTierInterval", {
    Text = "Interval",
    Default = CONFIG_UPGRADE_TIER.Interval,
    Min = 1,
    Max = 300,
    Rounding = 0,
    Callback = function(value) CONFIG_UPGRADE_TIER.Interval = value end,
})


local MergeGroup = UpgradesTab:AddRightGroupbox("Merge", "merge")
local CONFIG_MERGE = { Interval = 20 }
local mergeEnabled = false
local mergeThread = nil

local function startMerge()
    if mergeThread then return end
    mergeThread = task.spawn(function()
        while mergeEnabled do
            pcall(function()
                local remote = getRemote()
                if remote then
                    remote:InvokeServer("Merge Chickens")
                end
            end)
            task.wait(CONFIG_MERGE.Interval)
        end
    end)
end
local function stopMerge()
    mergeEnabled = false
    if mergeThread then task.cancel(mergeThread); mergeThread = nil end
end
local function setMerge(state)
    mergeEnabled = state
    if state then startMerge() else stopMerge() end
end

MergeGroup:AddToggle("MergeToggle", {
    Text = "Auto Merge Chickens",
    Default = false,
    Callback = function(value) setMerge(value) end,
})
MergeGroup:AddSlider("MergeInterval", {
    Text = "Interval",
    Default = CONFIG_MERGE.Interval,
    Min = 1,
    Max = 60,
    Rounding = 0,
    Callback = function(value) CONFIG_MERGE.Interval = value end,
})

local LuckyGroup = UpgradesTab:AddRightGroupbox("Lucky Blocks", "gift")
local CONFIG_LUCKY = { Interval = 30 }
local openEnabled = false
local openThread = nil
local discardEnabled = false
local discardThread = nil

local function startOpen()
    if openThread then return end
    openThread = task.spawn(function()
        while openEnabled do
            pcall(function()
                local remote = getRemote()
                if remote then
                    remote:InvokeServer("Open Lucky Block")
                end
            end)
            task.wait(CONFIG_LUCKY.Interval)
        end
    end)
end
local function stopOpen()
    openEnabled = false
    if openThread then task.cancel(openThread); openThread = nil end
end
local function setOpen(state)
    openEnabled = state
    if state then startOpen() else stopOpen() end
end

local function startDiscard()
    if discardThread then return end
    discardThread = task.spawn(function()
        while discardEnabled do
            pcall(function()
                local remoteEvent = getRemoteEvent()
                if remoteEvent then
                    remoteEvent:FireServer("Discard Lucky Block")
                end
            end)
            task.wait(CONFIG_LUCKY.Interval)
        end
    end)
end
local function stopDiscard()
    discardEnabled = false
    if discardThread then task.cancel(discardThread); discardThread = nil end
end
local function setDiscard(state)
    discardEnabled = state
    if state then startDiscard() else stopDiscard() end
end

LuckyGroup:AddToggle("LuckyOpenToggle", {
    Text = "Auto Open Lucky Block",
    Default = false,
    Callback = function(value) setOpen(value) end,
})
LuckyGroup:AddToggle("LuckyDiscardToggle", {
    Text = "Auto Discard Lucky Block",
    Default = false,
    Callback = function(value) setDiscard(value) end,
})
LuckyGroup:AddSlider("LuckyInterval", {
    Text = "Interval",
    Default = CONFIG_LUCKY.Interval,
    Min = 1,
    Max = 120,
    Rounding = 0,
    Callback = function(value) CONFIG_LUCKY.Interval = value end,
})


-- Правая группа: Upgrade Process
local UpgradeProcessGroup = UpgradesTab:AddRightGroupbox("Upgrade Process", "rocket")
local CONFIG_UPGRADE = { Interval = 25 }
local upgradeEnabled = false
local upgradeThread = nil

local function startUpgrade()
    if upgradeThread then return end
    upgradeThread = task.spawn(function()
        while upgradeEnabled do
            pcall(function()
                local remote = getRemote()
                if remote then
                    remote:InvokeServer("Upgrade Process Level")
                end
            end)
            task.wait(CONFIG_UPGRADE.Interval)
        end
    end)
end
local function stopUpgrade()
    upgradeEnabled = false
    if upgradeThread then task.cancel(upgradeThread); upgradeThread = nil end
end
local function setUpgrade(state)
    upgradeEnabled = state
    if state then startUpgrade() else stopUpgrade() end
end

UpgradeProcessGroup:AddToggle("UpgradeToggle", {
    Text = "Auto Upgrade Process",
    Default = false,
    Callback = function(value) setUpgrade(value) end,
})
UpgradeProcessGroup:AddSlider("UpgradeInterval", {
    Text = "Interval",
    Default = CONFIG_UPGRADE.Interval,
    Min = 1,
    Max = 120,
    Rounding = 0,
    Callback = function(value) CONFIG_UPGRADE.Interval = value end,
})

local PlayerGroup = Tabs.Player:AddLeftGroupbox("Player Controls", "user")

local flyEnabled = false
local flyBodyVelocity = nil
local flyConnection = nil
local flySpeed = 20

local function toggleFly(state)
    flyEnabled = state
    local char = LocalPlayer.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not root or not humanoid then return end
    if flyEnabled then
        Workspace.Gravity = 0
        humanoid.PlatformStand = true
        humanoid.AutoRotate = false
        flyBodyVelocity = Instance.new("BodyVelocity")
        flyBodyVelocity.MaxForce = Vector3.new(1e6, 1e6, 1e6)
        flyBodyVelocity.Velocity = Vector3.new(0, 0, 0)
        flyBodyVelocity.Parent = root
        flyConnection = RunService.Heartbeat:Connect(function()
            if not flyEnabled then return end
            if not root or not root.Parent then return end
            local forward = (UserInputService:IsKeyDown(Enum.KeyCode.W) and 1) or (UserInputService:IsKeyDown(Enum.KeyCode.S) and -1) or 0
            local right = (UserInputService:IsKeyDown(Enum.KeyCode.D) and 1) or (UserInputService:IsKeyDown(Enum.KeyCode.A) and -1) or 0
            local up = (UserInputService:IsKeyDown(Enum.KeyCode.Space) and 1) or (UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) and -1) or 0
            local cam = workspace.CurrentCamera
            local moveDir = (cam.CFrame.LookVector * forward + cam.CFrame.RightVector * right + cam.CFrame.UpVector * up)
            if moveDir.Magnitude > 0 then
                moveDir = moveDir.Unit * flySpeed
            end
            flyBodyVelocity.Velocity = moveDir
        end)
    else
        if flyConnection then flyConnection:Disconnect(); flyConnection = nil end
        if flyBodyVelocity then flyBodyVelocity:Destroy(); flyBodyVelocity = nil end
        Workspace.Gravity = 196.2
        humanoid.PlatformStand = false
        humanoid.AutoRotate = true
        root.Velocity = Vector3.new(0, 0, 0)
    end
end

local speedHackEnabled = false
local speedMultiplier = 1.5

local function toggleSpeedHack(state)
    speedHackEnabled = state
    local char = LocalPlayer.Character
    if char then
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.WalkSpeed = speedHackEnabled and (16 * speedMultiplier) or 16
        end
    end
end

local noclipEnabled = false
local noclipParts = {}

local function applyNoclip(state)
    local char = LocalPlayer.Character
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            if state then
                noclipParts[part] = part.CanCollide
                part.CanCollide = false
            else
                part.CanCollide = noclipParts[part] or true
                noclipParts[part] = nil
            end
        end
    end
end

local function toggleNoclip(state)
    noclipEnabled = state
    applyNoclip(state)
end

LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    if noclipEnabled then applyNoclip(true) end
    if flyEnabled then
        toggleFly(false)
        toggleFly(true)
    end
    if speedHackEnabled then
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if humanoid then humanoid.WalkSpeed = 16 * speedMultiplier end
    end
end)

PlayerGroup:AddToggle("FlyToggle", {
    Text = "Fly",
    Default = false,
    Callback = function(value) toggleFly(value) end,
})
PlayerGroup:AddSlider("FlySpeed", {
    Text = "Fly Speed",
    Default = 20,
    Min = 5,
    Max = 100,
    Callback = function(value) flySpeed = value end,
})
PlayerGroup:AddDivider()
PlayerGroup:AddToggle("SpeedToggle", {
    Text = "Speed Hack",
    Default = false,
    Callback = function(value) toggleSpeedHack(value) end,
})
PlayerGroup:AddSlider("SpeedMultiplier", {
    Text = "Speed Multiplier",
    Default = 1.5,
    Min = 1.0,
    Max = 20,
    Increment = 0.1,
    Callback = function(value)
        speedMultiplier = value
        if speedHackEnabled then
            local char = LocalPlayer.Character
            if char then
                local humanoid = char:FindFirstChildOfClass("Humanoid")
                if humanoid then humanoid.WalkSpeed = 16 * speedMultiplier end
            end
        end
    end,
})
PlayerGroup:AddDivider()
PlayerGroup:AddToggle("NoclipToggle", {
    Text = "NoClip",
    Default = false,
    Callback = function(value) toggleNoclip(value) end,
})


Tabs.Visuals:AddLeftGroupbox("Visuals", "eye"):AddLabel(" None")


local UISettingsTab = Tabs["UI Settings"]
local MenuGroup = UISettingsTab:AddLeftGroupbox("Menu", "wrench")
MenuGroup:AddToggle("KeybindMenuOpen", {
    Default = Library.KeybindFrame.Visible,
    Text = "Open Keybind Menu",
    Callback = function(v) Library.KeybindFrame.Visible = v end
})
MenuGroup:AddToggle("ShowCustomCursor", {
    Text = "Custom Cursor",
    Default = Library.ShowCustomCursor,
    Callback = function(v) Library.ShowCustomCursor = v end
})
MenuGroup:AddToggle("AlwaysOnTop", {
    Text = "Always On Top",
    Default = Window.AlwaysOnTop,
    Callback = function(v) Window:SetAlwaysOnTop(v) end
})
MenuGroup:AddDropdown("NotificationSide", {
    Values = {"Left", "Right"},
    Default = "Right",
    Text = "Notification Side",
    Callback = function(v) Library:SetNotifySide(v) end
})
MenuGroup:AddSlider("DPISlider", {
    Text = "DPI Scale",
    Default = 100,
    Min = 50,
    Max = 200,
    Rounding = 0,
    Callback = function(v) Library:SetDPIScale(v) end
})
MenuGroup:AddSlider("UICornerSlider", {
    Text = "Corner Radius",
    Default = Library.CornerRadius,
    Min = 0,
    Max = 20,
    Rounding = 0,
    Callback = function(v) Window:SetCornerRadius(v) end
})
MenuGroup:AddDivider()
MenuGroup:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", {
    Default = "RightControl",
    NoUI = true,
    Text = "Menu keybind"
})
MenuGroup:AddDivider()

local UnloadGroup = UISettingsTab:AddRightGroupbox("Unload", "power")
UnloadGroup:AddButton({
    Text = "Unload Script",
    Func = function()
        if flyEnabled then toggleFly(false) end
        if speedHackEnabled then toggleSpeedHack(false) end
        if noclipEnabled then toggleNoclip(false) end
        if farmEnabled then setFarming(false) end
        if rebirthEnabled then setRebirth(false) end
        if cashEnabled then setCashCollect(false) end
        if depEnabled then setDeposit(false) end
        if buyEnabled then setBuy(false) end
        if buy5Enabled then setBuy5(false) end
        if buy25Enabled then setBuy25(false) end
        if buy100Enabled then setBuy100(false) end
        if upgradeTierEnabled then setUpgradeTier(false) end
        if mergeEnabled then setMerge(false) end
        if openEnabled then setOpen(false) end
        if discardEnabled then setDiscard(false) end
        if upgradeEnabled then setUpgrade(false) end
        Workspace.Gravity = 196.2
        local char = LocalPlayer.Character
        if char then
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            if humanoid then humanoid.WalkSpeed = 16 end
        end
        Library:Unload()
    end,
    Risky = true
})

Library.ToggleKeybind = Options.MenuKeybind
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({"MenuKeybind"})
ThemeManager:SetFolder("ChickenFarmHub")
SaveManager:SetFolder("ChickenFarmHub")
SaveManager:SetSubFolder("settings")
SaveManager:BuildConfigSection(UISettingsTab)
ThemeManager:ApplyToTab(UISettingsTab)
SaveManager:LoadAutoloadConfig()

if Options.FlyToggle and Options.FlyToggle.Value then toggleFly(true) end
if Options.SpeedToggle and Options.SpeedToggle.Value then toggleSpeedHack(true) end
if Options.NoclipToggle and Options.NoclipToggle.Value then toggleNoclip(true) end
if Options.FarmToggle and Options.FarmToggle.Value then
    farmEnabled = true
    startFarming()
end
if Options.RebirthToggle and Options.RebirthToggle.Value then
    rebirthEnabled = true
    startRebirth()
end
if Options.CashToggle and Options.CashToggle.Value then
    cashEnabled = true
    startCashCollect()
end
if Options.DepositToggle and Options.DepositToggle.Value then
    depEnabled = true
    startDeposit()
end
if Options.BuyToggle and Options.BuyToggle.Value then
    buyEnabled = true
    startBuy()
end
if Options.Buy5Toggle and Options.Buy5Toggle.Value then
    buy5Enabled = true
    startBuy5()
end
if Options.Buy25Toggle and Options.Buy25Toggle.Value then
    buy25Enabled = true
    startBuy25()
end
if Options.Buy100Toggle and Options.Buy100Toggle.Value then
    buy100Enabled = true
    startBuy100()
end
if Options.UpgradeTierToggle and Options.UpgradeTierToggle.Value then
    upgradeTierEnabled = true
    startUpgradeTier()
end
if Options.MergeToggle and Options.MergeToggle.Value then
    mergeEnabled = true
    startMerge()
end
if Options.LuckyOpenToggle and Options.LuckyOpenToggle.Value then
    openEnabled = true
    startOpen()
end
if Options.LuckyDiscardToggle and Options.LuckyDiscardToggle.Value then
    discardEnabled = true
    startDiscard()
end
if Options.UpgradeToggle and Options.UpgradeToggle.Value then
    upgradeEnabled = true
    startUpgrade()
end

Library:OnUnload(function()
    if flyEnabled then toggleFly(false) end
    if speedHackEnabled then toggleSpeedHack(false) end
    if noclipEnabled then toggleNoclip(false) end
    if farmEnabled then setFarming(false) end
    if rebirthEnabled then setRebirth(false) end
    if cashEnabled then setCashCollect(false) end
    if depEnabled then setDeposit(false) end
    if buyEnabled then setBuy(false) end
    if buy5Enabled then setBuy5(false) end
    if buy25Enabled then setBuy25(false) end
    if buy100Enabled then setBuy100(false) end
    if upgradeTierEnabled then setUpgradeTier(false) end
    if mergeEnabled then setMerge(false) end
    if openEnabled then setOpen(false) end
    if discardEnabled then setDiscard(false) end
    if upgradeEnabled then setUpgrade(false) end
    Workspace.Gravity = 196.2
    local char = LocalPlayer.Character
    if char then
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if humanoid then humanoid.WalkSpeed = 16 end
    end
end)
