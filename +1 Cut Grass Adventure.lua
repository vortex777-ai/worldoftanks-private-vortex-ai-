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
    Footer = "+1 Cut Grass Adventure v1.1",
    Icon = "rbxassetid://116255434488074",
    NotifySide = "Right",
    ShowCustomCursor = true,
})

local Tabs = {
    Main = Window:AddTab("Main", "crosshair"),
    Player = Window:AddTab("Player", "user"),
    Visuals = Window:AddTab("Visuals", "eye"),
    ["UI Settings"] = Window:AddTab("UI", "wrench"),
}

local CONFIG = {
    ItemsToCollect = 3,
    ItemsBeforeSell = 3,
    HoldEDuration = 0.8,
    TeleportDelay = 0.3,
    MinRarity = "Epic",
    RebirthInterval = 5,
    UpgradeInterval = 30,
}

local LocalPlayer = game:GetService("Players").LocalPlayer
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local CollectionService = game:GetService("CollectionService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")


local LootRarities = {
    "Common", "Uncommon", "Rare", "Epic", "Legendary",
    "Mythic", "Secret", "Godly", "Divine", "Celestial",
    "Eternal", "Transcendent", "Cosmic", "Ascendant",
    "Primordial", "Empyrean", "Omniversal", "Singularity",
    "Exalted", "Infinite", "Genesis"
}

local LootItems = {
    ["01_Button"] = { Rarity = "Common" },
    ["02_Rusty_Nail"] = { Rarity = "Common" },
    ["03_Old_Coin"] = { Rarity = "Common" },
    ["04_Pocket_Watch"] = { Rarity = "Uncommon" },
    ["05_Copper_Gear"] = { Rarity = "Uncommon" },
    ["06_Silver_Spoon"] = { Rarity = "Uncommon" },
    ["07_Medallion"] = { Rarity = "Rare" },
    ["08_Broken_Compass"] = { Rarity = "Rare" },
    ["09_Dew_Crystal"] = { Rarity = "Rare" },
    ["10_Key"] = { Rarity = "Rare" },
    ["11_Moon_Flower"] = { Rarity = "Epic" },
    ["12_Horseshoe"] = { Rarity = "Epic" },
    ["13_Violet_Shard"] = { Rarity = "Epic" },
    ["14_Royal_Brooch"] = { Rarity = "Epic" },
    ["15_Flaming_Ring"] = { Rarity = "Legendary" },
    ["16_Ancient_Goblet"] = { Rarity = "Legendary" },
    ["17_Golden_Feather"] = { Rarity = "Legendary" },
    ["18_Dragon_Tooth"] = { Rarity = "Legendary" },
    ["19_Obelisk"] = { Rarity = "Legendary" },
    ["20_Sun_Idol"] = { Rarity = "Legendary" },
    ["21_Black_Crystal"] = { Rarity = "Mythic" },
    ["22_Hourglass"] = { Rarity = "Mythic" },
    ["23_Retro_Radio"] = { Rarity = "Mythic" },
    ["24_Ruby_Leaf"] = { Rarity = "Mythic" },
    ["25_Clover_Prism"] = { Rarity = "Mythic" },
    ["26_Sealed_Scroll"] = { Rarity = "Secret" },
    ["27_Tiny_Portal"] = { Rarity = "Secret" },
    ["28_Angel_Wing"] = { Rarity = "Secret" },
    ["29_Comet_Heart"] = { Rarity = "Secret" },
    ["30_Dawn_Diadem"] = { Rarity = "Secret" },
    ["31_Celestial_Star"] = { Rarity = "Godly" },
    ["32_Moon_Fragment"] = { Rarity = "Godly" },
    ["33_Living_Star"] = { Rarity = "Godly" },
    ["34_Amber_Beetle"] = { Rarity = "Godly" },
    ["35_Shaman_Mask"] = { Rarity = "Godly" },
    ["36_Eternal_Flower"] = { Rarity = "Godly" },
    ["37_Universe_Core"] = { Rarity = "Godly" },
    ["38_Divine_Seal"] = { Rarity = "Divine" },
    ["39_Light_Blade"] = { Rarity = "Divine" },
    ["40_Chest"] = { Rarity = "Divine" },
    ["41_Nebula_Rose"] = { Rarity = "Celestial" },
    ["42_Wishstone"] = { Rarity = "Celestial" },
    ["43_Genesis_Leaf"] = { Rarity = "Celestial" },
    ["44_Starlight_Dandelion"] = { Rarity = "Celestial" },
    ["45_Star_Nectar"] = { Rarity = "Celestial" },
    ["46_Aurora_Egg"] = { Rarity = "Celestial" },
    ["47_Rainbow_Snail"] = { Rarity = "Eternal" },
    ["48_Sunfire_Orb"] = { Rarity = "Eternal" },
    ["49_Seraph_Bell"] = { Rarity = "Eternal" },
    ["50_Storm_Seed"] = { Rarity = "Eternal" },
    ["51_Rune_Mushroom"] = { Rarity = "Eternal" },
    ["52_Celestial_Antler"] = { Rarity = "Eternal" },
    ["53_Spider_Charm"] = { Rarity = "Transcendent" },
    ["54_Spirit_Feather"] = { Rarity = "Transcendent" },
    ["55_Chrono_Moth"] = { Rarity = "Transcendent" },
    ["56_Moondew_Pearl"] = { Rarity = "Transcendent" },
    ["57_Fate_Dice"] = { Rarity = "Transcendent" },
    ["58_Rift_Scythe"] = { Rarity = "Cosmic" },
    ["59_Nova_Gauntlet"] = { Rarity = "Cosmic" },
    ["60_Astral_Map"] = { Rarity = "Cosmic" },
    ["61_Moonfish_Idol"] = { Rarity = "Cosmic" },
    ["62_Zero_Compass"] = { Rarity = "Cosmic" },
    ["63_Star_Sail"] = { Rarity = "Cosmic" },
    ["64_Phoenix_Harp"] = { Rarity = "Ascendant" },
    ["65_Rebirth_Mask"] = { Rarity = "Ascendant" },
    ["66_Soul_Anchor"] = { Rarity = "Ascendant" },
    ["67_Infinity_Blade"] = { Rarity = "Ascendant" },
    ["68_Evernight_Owl"] = { Rarity = "Ascendant" },
    ["69_Timewheel"] = { Rarity = "Ascendant" },
    ["70_Titan_Hammer"] = { Rarity = "Primordial" },
    ["71_Origin_Chalice"] = { Rarity = "Primordial" },
    ["72_Leviathan_Scale"] = { Rarity = "Primordial" },
    ["73_Skyforge_Anvil"] = { Rarity = "Primordial" },
    ["74_Genesis_Gate"] = { Rarity = "Primordial" },
    ["75_Void_Telescope"] = { Rarity = "Empyrean" },
    ["76_Meteor_Boots"] = { Rarity = "Empyrean" },
    ["77_Orbit_Drum"] = { Rarity = "Empyrean" },
    ["78_Nebula_Parasol"] = { Rarity = "Empyrean" },
    ["79_Starcatcher_Net"] = { Rarity = "Empyrean" },
    ["80_Lunar_Knight"] = { Rarity = "Empyrean" },
    ["81_Verdant_Shield"] = { Rarity = "Omniversal" },
    ["82_Rebirth_Bow"] = { Rarity = "Omniversal" },
    ["83_Spirit_Pagoda"] = { Rarity = "Omniversal" },
    ["84_Chrono_Codex"] = { Rarity = "Omniversal" },
    ["85_Emerald_Warhorn"] = { Rarity = "Omniversal" },
    ["86_Guardian_Scarab"] = { Rarity = "Omniversal" },
    ["87_Abyss_Trident"] = { Rarity = "Singularity" },
    ["88_Dawn_Throne"] = { Rarity = "Singularity" },
    ["89_Colossus_Helm"] = { Rarity = "Singularity" },
    ["90_World_Cauldron"] = { Rarity = "Singularity" },
    ["91_Dragonbone_Totem"] = { Rarity = "Singularity" },
    ["92_Reality_Loom"] = { Rarity = "Singularity" },
    ["93_Astral_Goggles"] = { Rarity = "Exalted" },
    ["94_Chrono Camera"] = { Rarity = "Exalted" },
    ["95_Comet Boomerang"] = { Rarity = "Exalted" },
    ["96_Constellation_Kite"] = { Rarity = "Exalted" },
    ["97_Evergreen_Scepter"] = { Rarity = "Exalted" },
    ["98_Leviathan Jaw"] = { Rarity = "Exalted" },
    ["99_Magma_Locomotive"] = { Rarity = "Infinite" },
    ["100_Moon_Cradle"] = { Rarity = "Infinite" },
    ["101_Nebula_Music_Box"] = { Rarity = "Infinite" },
    ["102_Oracle_Mirror"] = { Rarity = "Infinite" },
    ["103_Quantum_Abacus"] = { Rarity = "Infinite" },
    ["104_Sky_Citadel"] = { Rarity = "Infinite" },
    ["105_Solar_Chariot"] = { Rarity = "Genesis" },
    ["106_Soul_Censer"] = { Rarity = "Genesis" },
    ["107_Spirit_Violin"] = { Rarity = "Genesis" },
    ["108_Tempest_Cannon"] = { Rarity = "Genesis" },
    ["109_Titan_Hand"] = { Rarity = "Genesis" },
    ["110_Vine_Grappler"] = { Rarity = "Genesis" },
}

local RarityOrder = {}
for i, r in ipairs(LootRarities) do
    RarityOrder[r] = i
end

local function getItemDataByModelName(modelName)
    local data = LootItems[modelName]
    if data then return data end
    local withoutNumber = modelName:gsub("^%d+_", "")
    data = LootItems[withoutNumber]
    if data then return data end
    local withSpaces = withoutNumber:gsub("_", " ")
    return LootItems[withSpaces]
end


local ClickRequestedEvent = ReplicatedStorage:WaitForChild("Packages"):WaitForChild("_Index"):WaitForChild("acecateer_knit@1.7.2"):WaitForChild("knit"):WaitForChild("Services"):WaitForChild("StrengthService"):WaitForChild("RE"):WaitForChild("ClickRequested")
local RebirthEvent = ReplicatedStorage:WaitForChild("Packages"):WaitForChild("_Index"):WaitForChild("acecateer_knit@1.7.2"):WaitForChild("knit"):WaitForChild("Services"):WaitForChild("RebirtService"):WaitForChild("RE"):WaitForChild("RebirthButtonClicked")
local CarryButtonClicked = ReplicatedStorage:WaitForChild("Packages"):WaitForChild("_Index"):WaitForChild("acecateer_knit@1.7.2"):WaitForChild("knit"):WaitForChild("Services"):WaitForChild("UpgradesService"):WaitForChild("RE"):WaitForChild("CarryButtonClicked")
local TeleportToWorld = ReplicatedStorage:WaitForChild("Packages"):WaitForChild("_Index"):WaitForChild("acecateer_knit@1.7.2"):WaitForChild("knit"):WaitForChild("Services"):WaitForChild("WorldService"):WaitForChild("RF"):WaitForChild("TeleportToWorld")
local SellFunction = ReplicatedStorage:WaitForChild("Packages"):WaitForChild("_Index"):WaitForChild("acecateer_knit@1.7.2"):WaitForChild("knit"):WaitForChild("Services"):WaitForChild("DataService"):WaitForChild("RF"):WaitForChild("SellAllBackpackLoot")
local TeleportToSpawn = ReplicatedStorage:WaitForChild("Packages"):WaitForChild("_Index"):WaitForChild("acecateer_knit@1.7.2"):WaitForChild("knit"):WaitForChild("Services"):WaitForChild("BaseTeleportService"):WaitForChild("RF"):WaitForChild("TeleportToSpawn")

local strengthFarmEnabled = false
local strengthFarmThread = nil

local function startStrengthFarm()
    if strengthFarmThread then return end
    strengthFarmThread = task.spawn(function()
        while strengthFarmEnabled do
            pcall(function()
                ClickRequestedEvent:FireServer()
            end)
            task.wait(0.08)
        end
    end)
end

local function stopStrengthFarm()
    strengthFarmEnabled = false
    if strengthFarmThread then
        task.cancel(strengthFarmThread)
        strengthFarmThread = nil
    end
end

local function setStrengthFarm(state)
    strengthFarmEnabled = state
    if state then startStrengthFarm() else stopStrengthFarm() end
end

local autoRebirthEnabled = false
local autoRebirthThread = nil

local function startAutoRebirth()
    if autoRebirthThread then return end
    autoRebirthThread = task.spawn(function()
        while autoRebirthEnabled do
            pcall(function()
                RebirthEvent:FireServer()
            end)
            task.wait(CONFIG.RebirthInterval)
        end
    end)
end

local function stopAutoRebirth()
    autoRebirthEnabled = false
    if autoRebirthThread then
        task.cancel(autoRebirthThread)
        autoRebirthThread = nil
    end
end

local function setAutoRebirth(state)
    autoRebirthEnabled = state
    if state then startAutoRebirth() else stopAutoRebirth() end
end

local autoBackpackEnabled = false
local autoBackpackThread = nil

local function startAutoBackpack()
    if autoBackpackThread then return end
    autoBackpackThread = task.spawn(function()
        while autoBackpackEnabled do
            pcall(function()
                CarryButtonClicked:FireServer()
            end)
            task.wait(CONFIG.UpgradeInterval)
        end
    end)
end

local function stopAutoBackpack()
    autoBackpackEnabled = false
    if autoBackpackThread then
        task.cancel(autoBackpackThread)
        autoBackpackThread = nil
    end
end

local function setAutoBackpack(state)
    autoBackpackEnabled = state
    if state then startAutoBackpack() else stopAutoBackpack() end
end

local autoWorld2Enabled = false
local autoWorld2Thread = nil
local autoWorld3Enabled = false
local autoWorld3Thread = nil
local autoWorld4Enabled = false
local autoWorld4Thread = nil
local autoWorld5Enabled = false
local autoWorld5Thread = nil

local function startAutoWorld2()
    if autoWorld2Thread then return end
    autoWorld2Thread = task.spawn(function()
        while autoWorld2Enabled do
            pcall(function()
                TeleportToWorld:InvokeServer(2)
            end)
            task.wait(CONFIG.UpgradeInterval)
        end
    end)
end

local function stopAutoWorld2()
    autoWorld2Enabled = false
    if autoWorld2Thread then
        task.cancel(autoWorld2Thread)
        autoWorld2Thread = nil
    end
end

local function setAutoWorld2(state)
    autoWorld2Enabled = state
    if state then startAutoWorld2() else stopAutoWorld2() end
end

local function startAutoWorld3()
    if autoWorld3Thread then return end
    autoWorld3Thread = task.spawn(function()
        while autoWorld3Enabled do
            pcall(function()
                TeleportToWorld:InvokeServer(3)
            end)
            task.wait(CONFIG.UpgradeInterval)
        end
    end)
end

local function stopAutoWorld3()
    autoWorld3Enabled = false
    if autoWorld3Thread then
        task.cancel(autoWorld3Thread)
        autoWorld3Thread = nil
    end
end

local function setAutoWorld3(state)
    autoWorld3Enabled = state
    if state then startAutoWorld3() else stopAutoWorld3() end
end

local function startAutoWorld4()
    if autoWorld4Thread then return end
    autoWorld4Thread = task.spawn(function()
        while autoWorld4Enabled do
            pcall(function()
                TeleportToWorld:InvokeServer(4)
            end)
            task.wait(CONFIG.UpgradeInterval)
        end
    end)
end

local function stopAutoWorld4()
    autoWorld4Enabled = false
    if autoWorld4Thread then
        task.cancel(autoWorld4Thread)
        autoWorld4Thread = nil
    end
end

local function setAutoWorld4(state)
    autoWorld4Enabled = state
    if state then startAutoWorld4() else stopAutoWorld4() end
end

local function startAutoWorld5()
    if autoWorld5Thread then return end
    autoWorld5Thread = task.spawn(function()
        while autoWorld5Enabled do
            pcall(function()
                TeleportToWorld:InvokeServer(5)
            end)
            task.wait(CONFIG.UpgradeInterval)
        end
    end)
end

local function stopAutoWorld5()
    autoWorld5Enabled = false
    if autoWorld5Thread then
        task.cancel(autoWorld5Thread)
        autoWorld5Thread = nil
    end
end

local function setAutoWorld5(state)
    autoWorld5Enabled = state
    if state then startAutoWorld5() else stopAutoWorld5() end
end

local function teleportTo(pos)
    local char = LocalPlayer.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if root then
        root.CFrame = CFrame.new(pos)
    end
end

local function isItemWorthCollecting(itemData)
    if not itemData then return false end
    local minRarityIndex = RarityOrder[CONFIG.MinRarity] or 1
    local itemRarityIndex = RarityOrder[itemData.Rarity] or 0
    return itemRarityIndex >= minRarityIndex
end

local function getInventoryCount()
    local inventory = LocalPlayer:FindFirstChild("_HiddenLootTools")
    if not inventory then return 0 end
    local total = 0
    for _, child in ipairs(inventory:GetChildren()) do
        if child.Name == "OP Potion" or child.Name == "" then continue end
        local stack = child:GetAttribute("StackCount")
        if type(stack) == "number" and stack > 0 then
            total = total + stack
        else
            total = total + 1
        end
    end
    return total
end

local function findNearestLoot()
    local char = LocalPlayer.Character
    if not char then return nil end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return nil end
    local pos = root.Position
    local tagged = CollectionService:GetTagged("SpawnedLoot")
    if #tagged == 0 then return nil end
    local nearest = nil
    local minDist = math.huge
    for _, obj in ipairs(tagged) do
        if not obj then continue end
        local model = nil
        local targetPos = nil
        if obj:IsA("BasePart") then
            model = obj.Parent
            targetPos = obj.Position
        elseif obj:IsA("Model") then
            model = obj
            if obj.PrimaryPart then
                targetPos = obj.PrimaryPart.Position
            else
                local success, pivot = pcall(function() return obj:GetPivot() end)
                if success then targetPos = pivot.Position end
            end
        end
        if not model or not targetPos then continue end
        local modelName = model.Name
        local itemData = getItemDataByModelName(modelName)
        if not itemData then
            if model.Parent and model.Parent:IsA("Model") then
                modelName = model.Parent.Name
                itemData = getItemDataByModelName(modelName)
            end
        end
        if not itemData then continue end
        if not isItemWorthCollecting(itemData) then continue end
        local dist = (targetPos - pos).Magnitude
        if dist < minDist then
            minDist = dist
            nearest = {Object = obj, Position = targetPos}
        end
    end
    return nearest
end

local function pressE(holdTime)
    pcall(function()
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
        task.wait(holdTime or 0.8)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
    end)
end

local function collectItems(count)
    local collected = 0
    while collected < count do
        local target = findNearestLoot()
        if not target then break end
        teleportTo(target.Position + Vector3.new(0, 1.5, 0))
        task.wait(CONFIG.TeleportDelay)
        pressE(CONFIG.HoldEDuration)
        collected = collected + 1
        local invCount = getInventoryCount()
        if invCount >= CONFIG.ItemsBeforeSell then
            return collected, true
        end
        task.wait(0.2)
    end
    return collected, false
end

local function sellAll()
    local char = LocalPlayer.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local currentPos = root.Position
    pcall(function() TeleportToSpawn:InvokeServer() end)
    task.wait(1.0)
    pcall(function() SellFunction:InvokeServer() end)
    task.wait(1.0)
    teleportTo(currentPos)
end

local farmEnabled = false
local farmThread = nil

local function startFarming()
    if farmThread then return end
    farmThread = task.spawn(function()
        while farmEnabled do
            local collected, shouldSell = collectItems(CONFIG.ItemsToCollect)
            if shouldSell then
                sellAll()
                task.wait(0.5)
            end
            if collected == 0 then
                task.wait(5)
            end
            task.wait(1)
        end
    end)
end

local function stopFarming()
    farmEnabled = false
    if farmThread then
        task.cancel(farmThread)
        farmThread = nil
    end
end

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
            local forward = 0
            local right = 0
            local up = 0
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then forward = 1 end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then forward = -1 end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then right = -1 end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then right = 1 end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then up = 1 end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then up = -1 end
            local cam = workspace.CurrentCamera
            local forwardVec = cam.CFrame.LookVector
            local rightVec = cam.CFrame.RightVector
            local upVec = cam.CFrame.UpVector
            local moveDir = (forwardVec * forward + rightVec * right + upVec * up)
            if moveDir.Magnitude > 0 then
                moveDir = moveDir.Unit * flySpeed
            end
            flyBodyVelocity.Velocity = moveDir
        end)
    else
        if flyConnection then
            flyConnection:Disconnect()
            flyConnection = nil
        end
        if flyBodyVelocity then
            flyBodyVelocity:Destroy()
            flyBodyVelocity = nil
        end
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
            if speedHackEnabled then
                humanoid.WalkSpeed = 16 * speedMultiplier
            else
                humanoid.WalkSpeed = 16
            end
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
                if noclipParts[part] ~= nil then
                    part.CanCollide = noclipParts[part]
                    noclipParts[part] = nil
                else
                    part.CanCollide = true
                end
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
    if noclipEnabled then
        applyNoclip(true)
    end
    if flyEnabled then
        toggleFly(false)
        toggleFly(true)
    end
    if speedHackEnabled then
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.WalkSpeed = 16 * speedMultiplier
        end
    end
end)

-- ===== GUI =====
local StrengthGroup = Tabs.Main:AddGroupbox({ Side = "Left", Name = "Strength Farm", IconName = "zap" })
StrengthGroup:AddToggle("StrengthFarmToggle", {
    Text = "Strength Farm",
    Default = false,
    Callback = function(value)
        setStrengthFarm(value)
    end,
})

local RebirthGroup = Tabs.Main:AddGroupbox({ Side = "Left", Name = "Auto Rebirth", IconName = "refresh" })
RebirthGroup:AddToggle("AutoRebirthToggle", {
    Text = "Auto Rebirth",
    Default = false,
    Callback = function(value)
        setAutoRebirth(value)
    end,
})

local UpgradeGroup = Tabs.Main:AddGroupbox({ Side = "Left", Name = "Auto Upgrades", IconName = "upload" })
UpgradeGroup:AddToggle("AutoBackpackToggle", {
    Text = "Auto Backpack",
    Default = false,
    Callback = function(value)
        setAutoBackpack(value)
    end,
})
UpgradeGroup:AddDivider()
UpgradeGroup:AddToggle("AutoWorld2Toggle", {
    Text = "Auto World 2",
    Default = false,
    Callback = function(value)
        setAutoWorld2(value)
    end,
})
UpgradeGroup:AddDivider()
UpgradeGroup:AddToggle("AutoWorld3Toggle", {
    Text = "Auto World 3",
    Default = false,
    Callback = function(value)
        setAutoWorld3(value)
    end,
})
UpgradeGroup:AddDivider()
UpgradeGroup:AddToggle("AutoWorld4Toggle", {
    Text = "Auto World 4",
    Default = false,
    Callback = function(value)
        setAutoWorld4(value)
    end,
})
UpgradeGroup:AddDivider()
UpgradeGroup:AddToggle("AutoWorld5Toggle", {
    Text = "Auto World 5",
    Default = false,
    Callback = function(value)
        setAutoWorld5(value)
    end,
})


local AutoFarmGroup = Tabs.Main:AddGroupbox({ Side = "Right", Name = "Auto Farm (Loot)", IconName = "package" })
AutoFarmGroup:AddToggle("FarmToggle", {
    Text = "Start Farm",
    Default = false,
    Callback = function(value)
        farmEnabled = value
        if value then startFarming() else stopFarming() end
    end,
})

local SettingsGroup = Tabs.Main:AddGroupbox({ Side = "Right", Name = "Auto Farm Settings", IconName = "sliders" })
local raritySliderValue = 4
local rarityLabel = SettingsGroup:AddLabel("Selected rarity: " .. CONFIG.MinRarity)
SettingsGroup:AddSlider("RaritySlider", {
    Text = "Minimum Rarity",
    Default = raritySliderValue,
    Min = 1,
    Max = #LootRarities,
    Callback = function(value)
        local index = math.floor(value)
        if index < 1 then index = 1 end
        if index > #LootRarities then index = #LootRarities end
        CONFIG.MinRarity = LootRarities[index]
        rarityLabel:SetText("Selected rarity: " .. CONFIG.MinRarity)
    end,
})
SettingsGroup:AddDivider()
SettingsGroup:AddSlider("ItemsBeforeSell", {
    Text = "Items before sell",
    Default = 3,
    Min = 1,
    Max = 40,
    Rounding = 0,
    Callback = function(v)
        CONFIG.ItemsBeforeSell = v
    end,
})
SettingsGroup:AddDivider()
SettingsGroup:AddLabel("1=" .. LootRarities[1] .. ", " .. #LootRarities .. "=" .. LootRarities[#LootRarities])

local PlayerGroup = Tabs.Player:AddGroupbox({ Side = "Left", Name = "Player Controls", IconName = "user" })
PlayerGroup:AddToggle("FlyToggle", {
    Text = "Fly",
    Default = false,
    Callback = function(value)
        toggleFly(value)
    end,
})
PlayerGroup:AddSlider("FlySpeed", {
    Text = "Fly Speed",
    Default = 20,
    Min = 5,
    Max = 100,
    Callback = function(value)
        flySpeed = value
    end,
})
PlayerGroup:AddDivider()
PlayerGroup:AddToggle("SpeedToggle", {
    Text = "Speed Hack",
    Default = false,
    Callback = function(value)
        toggleSpeedHack(value)
    end,
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
                if humanoid then
                    humanoid.WalkSpeed = 16 * speedMultiplier
                end
            end
        end
    end,
})
PlayerGroup:AddDivider()
PlayerGroup:AddToggle("NoclipToggle", {
    Text = "NoClip",
    Default = false,
    Callback = function(value)
        toggleNoclip(value)
    end,
})

local VisualsGroup = Tabs.Visuals:AddGroupbox({ Side = "Left", Name = "Visuals", IconName = "eye" })
VisualsGroup:AddLabel(" None")

local UISettingsTab = Tabs["UI Settings"]
local MenuGroup = UISettingsTab:AddGroupbox({ Side = "Left", Name = "Menu", IconName = "wrench" })
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
    Default = "RightShift",
    NoUI = true,
    Text = "Menu keybind"
})
MenuGroup:AddDivider()

local UnloadGroup = UISettingsTab:AddGroupbox({ Side = "Right", Name = "Unload", IconName = "power" })
UnloadGroup:AddButton({
    Text = "Unload Script",
    Func = function()
        farmEnabled = false
        if farmThread then task.cancel(farmThread); farmThread = nil end
        strengthFarmEnabled = false
        if strengthFarmThread then task.cancel(strengthFarmThread); strengthFarmThread = nil end
        autoRebirthEnabled = false
        if autoRebirthThread then task.cancel(autoRebirthThread); autoRebirthThread = nil end
        autoBackpackEnabled = false
        if autoBackpackThread then task.cancel(autoBackpackThread); autoBackpackThread = nil end
        autoWorld2Enabled = false
        if autoWorld2Thread then task.cancel(autoWorld2Thread); autoWorld2Thread = nil end
        autoWorld3Enabled = false
        if autoWorld3Thread then task.cancel(autoWorld3Thread); autoWorld3Thread = nil end
        autoWorld4Enabled = false
        if autoWorld4Thread then task.cancel(autoWorld4Thread); autoWorld4Thread = nil end
        autoWorld5Enabled = false
        if autoWorld5Thread then task.cancel(autoWorld5Thread); autoWorld5Thread = nil end
        if flyEnabled then toggleFly(false) end
        if noclipEnabled then toggleNoclip(false) end
        local char = LocalPlayer.Character
        if char then
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            if humanoid then humanoid.WalkSpeed = 16 end
        end
        Workspace.Gravity = 196.2
        Library:Unload()
    end,
    Risky = true
})

Library.ToggleKeybind = Options.MenuKeybind
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({"MenuKeybind"})
ThemeManager:SetFolder("CutGrassFarm")
SaveManager:SetFolder("CutGrassFarm")
SaveManager:SetSubFolder("settings")
SaveManager:BuildConfigSection(UISettingsTab)
ThemeManager:ApplyToTab(UISettingsTab)
SaveManager:LoadAutoloadConfig()

if Options.StrengthFarmToggle and Options.StrengthFarmToggle.Value then
    strengthFarmEnabled = true
    startStrengthFarm()
end
if Options.AutoRebirthToggle and Options.AutoRebirthToggle.Value then
    autoRebirthEnabled = true
    startAutoRebirth()
end
if Options.AutoBackpackToggle and Options.AutoBackpackToggle.Value then
    autoBackpackEnabled = true
    startAutoBackpack()
end
if Options.AutoWorld2Toggle and Options.AutoWorld2Toggle.Value then
    autoWorld2Enabled = true
    startAutoWorld2()
end
if Options.AutoWorld3Toggle and Options.AutoWorld3Toggle.Value then
    autoWorld3Enabled = true
    startAutoWorld3()
end
if Options.AutoWorld4Toggle and Options.AutoWorld4Toggle.Value then
    autoWorld4Enabled = true
    startAutoWorld4()
end
if Options.AutoWorld5Toggle and Options.AutoWorld5Toggle.Value then
    autoWorld5Enabled = true
    startAutoWorld5()
end
if Options.FarmToggle and Options.FarmToggle.Value then
    farmEnabled = true
    startFarming()
end
if Options.FlyToggle and Options.FlyToggle.Value then
    flyEnabled = true
    toggleFly(true)
end
if Options.SpeedToggle and Options.SpeedToggle.Value then
    speedHackEnabled = true
    toggleSpeedHack(true)
end
if Options.NoclipToggle and Options.NoclipToggle.Value then
    noclipEnabled = true
    toggleNoclip(true)
end

Library:OnUnload(function()
    farmEnabled = false
    if farmThread then task.cancel(farmThread); farmThread = nil end
    strengthFarmEnabled = false
    if strengthFarmThread then task.cancel(strengthFarmThread); strengthFarmThread = nil end
    autoRebirthEnabled = false
    if autoRebirthThread then task.cancel(autoRebirthThread); autoRebirthThread = nil end
    autoBackpackEnabled = false
    if autoBackpackThread then task.cancel(autoBackpackThread); autoBackpackThread = nil end
    autoWorld2Enabled = false
    if autoWorld2Thread then task.cancel(autoWorld2Thread); autoWorld2Thread = nil end
    autoWorld3Enabled = false
    if autoWorld3Thread then task.cancel(autoWorld3Thread); autoWorld3Thread = nil end
    autoWorld4Enabled = false
    if autoWorld4Thread then task.cancel(autoWorld4Thread); autoWorld4Thread = nil end
    autoWorld5Enabled = false
    if autoWorld5Thread then task.cancel(autoWorld5Thread); autoWorld5Thread = nil end
    if flyEnabled then toggleFly(false) end
    if noclipEnabled then toggleNoclip(false) end
    local char = LocalPlayer.Character
    if char then
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if humanoid then humanoid.WalkSpeed = 16 end
    end
    Workspace.Gravity = 196.2
end)
