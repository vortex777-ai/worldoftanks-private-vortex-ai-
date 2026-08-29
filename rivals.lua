-- Удалён блок с LPH_* функциями и вызов ERROR_HANDLING

pcall(function()
    if getgenv().setthreadidentity then
        getgenv().setthreadidentity(7)
    elseif getgenv().setidentity then
        getgenv().setidentity(7)
    elseif getgenv().setthreadcontext then
        getgenv().setthreadcontext(7)
    end
end)

local repo="https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library=loadstring(game:HttpGet(repo.."Library.lua"))()
local ThemeManager=loadstring(game:HttpGet(repo.."addons/ThemeManager.lua"))()
local SaveManager=loadstring(game:HttpGet(repo.."addons/SaveManager.lua"))()
if not Library then return end

local Options=Library.Options
Library.ForceCheckbox=false
Library.ShowToggleFrameInKeybinds=true

local Window=Library:CreateWindow({
    Title="JulyScripts",
    Footer="Rivals v1.0",
    Icon = "rbxassetid://116255434488074",
    NotifySide="Right",
    ShowCustomCursor=true,
})
Library:Notify("Welcome to JulyScripts, made by thet1x with love ❤️", 10)

local Tabs={
    Combat=Window:AddTab("Combat","crosshair"),
    Visuals=Window:AddTab("Visuals","eye"),
    Misc=Window:AddTab("Misc","rocket"),
    ["UI Settings"]=Window:AddTab("UI","wrench"),
}

local RunService=game:GetService("RunService")
local UserInputService=game:GetService("UserInputService")
local VirtualInputManager=game:GetService("VirtualInputManager")
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Workspace=game:GetService("Workspace")
local Lighting=game:GetService("Lighting")

local player=Players.LocalPlayer
local camera=workspace.CurrentCamera
local isUnloaded=false

local CameraController=nil

local function loadCameraController()
    local success,module=pcall(function()
        local playerScripts=player:FindFirstChild("PlayerScripts")
        if not playerScripts then
            playerScripts=player:WaitForChild("PlayerScripts",10)
        end
        if not playerScripts then return nil end

        local controllers=playerScripts:FindFirstChild("Controllers")
        if not controllers then
            controllers=playerScripts:WaitForChild("Controllers",10)
        end
        if not controllers then return nil end

        local controller=controllers:FindFirstChild("CameraController")
        if not controller then
            controller=controllers:WaitForChild("CameraController",10)
        end
        if not controller then return nil end

        return require(controller)
    end)

    if success then
        CameraController=module
    end

    return CameraController
end

loadCameraController()

local GunModule=nil
local originalIsFullyAiming=nil
local modsActive=false
local ItemLibrary=nil
local UtilityModule=nil

local function loadModules()
    local success,module=pcall(function()
        return require(player.PlayerScripts.Modules.ItemTypes.Gun)
    end)
    if success and module then
        GunModule=module
        originalIsFullyAiming=GunModule.IsFullyAiming
    else
    end

    local rsMods=ReplicatedStorage:FindFirstChild("Modules")
    if rsMods then
        local itemLibrary=rsMods:FindFirstChild("ItemLibrary")
        if itemLibrary then
            pcall(function()
                ItemLibrary=require(itemLibrary)
            end)
        end

        local utility=rsMods:FindFirstChild("Utility")
        if utility then
            pcall(function()
                UtilityModule=require(utility)
            end)
        end
    end
end

loadModules()

local character=nil
local humanoid=nil
local humanoidRootPart=nil

local function RefreshCharacter()
    character=player.Character

    if not character then
        humanoid=nil
        humanoidRootPart=nil
        return
    end

    humanoid=character:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        humanoid=character:WaitForChild("Humanoid",10)
    end

    humanoidRootPart=character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then
        humanoidRootPart=character:WaitForChild("HumanoidRootPart",10)
    end

    camera=workspace.CurrentCamera
end

RefreshCharacter()

local characterAddedConnection=player.CharacterAdded:Connect(function()
    RefreshCharacter()
end)

local teamCheck=true

local function GetPlayerTeamKey(plr)
    if not plr then return nil end

    local teamId=plr:GetAttribute("TeamID")
    if teamId~=nil then return teamId end

    local teamAttr=plr:GetAttribute("Team")
    if teamAttr~=nil then return teamAttr end

    if plr.Team then
        return plr.Team.Name or plr.Team
    end

    local mgTeam=plr:GetAttribute("MG_Team")
    if mgTeam~=nil then return mgTeam end

    return nil
end

local function SameTeam(plr)
    if not teamCheck then return false end

    local myTeam=GetPlayerTeamKey(player)
    local theirTeam=GetPlayerTeamKey(plr)

    if myTeam==nil or theirTeam==nil then
        return false
    end

    return myTeam==theirTeam
end

local function IsCharacterAlive(char)
    if not char then return false end

    local targetHumanoid=char:FindFirstChildOfClass("Humanoid")
    return targetHumanoid~=nil and targetHumanoid.Health>0
end

local function GetTargetPart(char,preferHead)
    if not char then return nil end

    if preferHead then
        local head=char:FindFirstChild("Head")
        if head and head:IsA("BasePart") then
            return head
        end
    end

    local root=char:FindFirstChild("HumanoidRootPart")
    if root and root:IsA("BasePart") then return root end

    local upperTorso=char:FindFirstChild("UpperTorso")
    if upperTorso and upperTorso:IsA("BasePart") then return upperTorso end

    local torso=char:FindFirstChild("Torso")
    if torso and torso:IsA("BasePart") then return torso end

    return nil
end

local wallCheck=true

local function IsTargetVisible(targetPart,wallCheckEnabled)
    if not wallCheckEnabled then return true end
    if not camera or not targetPart then return false end

    local targetCharacter=targetPart.Parent
    if not targetCharacter then return false end

    local origin=camera.CFrame.Position
    local targetPos=targetPart.Position

    local params=RaycastParams.new()
    params.FilterType=Enum.RaycastFilterType.Blacklist
    params.FilterDescendantsInstances={character,targetCharacter}
    params.IgnoreWater=true
    params.RespectCanCollide=true

    local direction=targetPos-origin
    local distance=direction.Magnitude

    if distance<=0.001 then return true end

    local result=workspace:Raycast(origin,direction,params)
    return result==nil
end

local noSpreadEnabled=false
local noRecoilEnabled=false

local function applyMods()
    if not GunModule then return end

    if not originalIsFullyAiming then
        originalIsFullyAiming=GunModule.IsFullyAiming
    end

    GunModule.IsFullyAiming=function(self)
        return true
    end

    modsActive=true
end

local function restoreMods()
    if not GunModule then return end

    if originalIsFullyAiming then
        GunModule.IsFullyAiming=originalIsFullyAiming
    end

    modsActive=false
end

local function updateMods()
    if noSpreadEnabled or noRecoilEnabled then
        if not modsActive then
            applyMods()
        end
    else
        if modsActive then
            restoreMods()
        end
    end
end

local function ToggleNoSpread(state)
    noSpreadEnabled=state
    updateMods()
end

local function ToggleNoRecoil(state)
    noRecoilEnabled=state
    updateMods()
end

local accuracyEnabled=false
local originalGunStats={}

local function ApplyAccuracy(state)
    if not ItemLibrary then return end

    local function traverse(tbl)
        for _,v in pairs(tbl) do
            if type(v)=="table" then
                if v.ShootSpread or v.ShootAccuracy or v.ShootRecoil then
                    if state then
                        if not originalGunStats[v] then
                            originalGunStats[v]={
                                ShootSpread=v.ShootSpread,
                                ShootAccuracy=v.ShootAccuracy,
                                ShootRecoil=v.ShootRecoil
                            }
                        end

                        v.ShootSpread,v.ShootAccuracy,v.ShootRecoil=0,0,0
                    elseif originalGunStats[v] then
                        v.ShootSpread=originalGunStats[v].ShootSpread
                        v.ShootAccuracy=originalGunStats[v].ShootAccuracy
                        v.ShootRecoil=originalGunStats[v].ShootRecoil
                    end
                end

                traverse(v)
            end
        end
    end

    traverse(ItemLibrary)
end

local SilentAim={
    active=false,
    maxDistance=2000,
    fovEnabled=false,
    fovRadius=150,
    fovColor=Color3.fromRGB(255,255,255),
    fovThickness=1,
    fovCircle=nil,
    target=nil,
    heartbeatConnection=nil,
    renderConnection=nil,
    originalStartShooting=nil
}

function SilentAim:Init()
    local circle=Drawing.new("Circle")
    circle.Thickness=1
    circle.NumSides=64
    circle.Filled=false
    circle.Transparency=1
    circle.Visible=false
    self.fovCircle=circle

    self.renderConnection=RunService.RenderStepped:Connect(function()
        if not self.fovCircle then return end

        if self.active and self.fovEnabled and not isUnloaded then
            self.fovCircle.Position=UserInputService:GetMouseLocation()
            self.fovCircle.Radius=self.fovRadius
            self.fovCircle.Color=self.fovColor
            self.fovCircle.Thickness=self.fovThickness
            self.fovCircle.Visible=true
        else
            self.fovCircle.Visible=false
        end
    end)

    self.heartbeatConnection=RunService.Heartbeat:Connect(function()
        if not self.active or isUnloaded then return end
        self.target=self:FindTarget()
    end)

    if GunModule and GunModule.StartShooting and not self.originalStartShooting then
        self.originalStartShooting=GunModule.StartShooting

        GunModule.StartShooting=function(gunInstance,...)
            local results={self.originalStartShooting(gunInstance,...)}

            if not self.active or isUnloaded then
                return unpack(results)
            end

            if not gunInstance.ClientFighter or not gunInstance.ClientFighter.IsLocalPlayer then
                return unpack(results)
            end

            local shotData=results[3]
            if type(shotData)~="table" then
                return unpack(results)
            end

            local curTarget=self.target

            if not curTarget or not curTarget.Character then
                return unpack(results)
            end

            local head=curTarget.Character:FindFirstChild("Head")
            if not head then return unpack(results) end

            results[4]=true

            local headPos=head.Position
            local headCF=head.CFrame
            local targetPos=headPos-Vector3.new(0,5,0)
            local lookCF=CFrame.lookAt(targetPos,headPos)

            local localOffset=headCF:ToObjectSpace(
                CFrame.new(
                    headPos+Vector3.new(
                        math.random(),
                        math.random(),
                        math.random()
                    )
                )
            )

            if UtilityModule then
                pcall(function()
                    shotData[utf8.char(0)]=UtilityModule:EncodeCFrame(
                        CFrame.new(targetPos,headPos)*
                        CFrame.Angles(lookCF:ToOrientation())
                    )

                    shotData[utf8.char(1)]=UtilityModule:EncodeCFrame(
                        CFrame.new(headPos)*
                        CFrame.Angles(lookCF:ToOrientation())
                    )

                    shotData[utf8.char(2)]=head
                    shotData[utf8.char(3)]=UtilityModule:EncodeCFrame(localOffset)
                end)
            end

            return unpack(results)
        end
    end
end

function SilentAim:FindTarget()
    if not humanoidRootPart or not camera then return nil end

    local mousePos=UserInputService:GetMouseLocation()
    local bestPlr,bestDist=nil,self.maxDistance

    for _,plr in ipairs(Players:GetPlayers()) do
        if plr==player then continue end
        if teamCheck and SameTeam(plr) then continue end

        local char=plr.Character
        if not char or not IsCharacterAlive(char) then continue end

        local root=char:FindFirstChild("HumanoidRootPart")
        local head=char:FindFirstChild("Head")

        if not root or not head then continue end

        local dist=(humanoidRootPart.Position-root.Position).Magnitude
        if dist>self.maxDistance then continue end
        if not IsTargetVisible(root,wallCheck) then continue end

        if self.fovEnabled then
            local scr,onScreen=camera:WorldToViewportPoint(head.Position)

            if onScreen and scr.Z>0 then
                if (Vector2.new(scr.X,scr.Y)-mousePos).Magnitude<=self.fovRadius then
                    if dist<bestDist then
                        bestDist=dist
                        bestPlr=plr
                    end
                end
            end
        else
            if dist<bestDist then
                bestDist=dist
                bestPlr=plr
            end
        end
    end

    return bestPlr
end

function SilentAim:Shutdown()
    self.active=false

    if self.heartbeatConnection then
        self.heartbeatConnection:Disconnect()
        self.heartbeatConnection=nil
    end

    if self.renderConnection then
        self.renderConnection:Disconnect()
        self.renderConnection=nil
    end

    if self.fovCircle then
        pcall(function()
            self.fovCircle:Remove()
        end)

        self.fovCircle=nil
    end

    if self.originalStartShooting and GunModule then
        GunModule.StartShooting=self.originalStartShooting
        self.originalStartShooting=nil
    end
end

pcall(function()
    SilentAim:Init()
end)

local aimbotEnabled=false
local aimbotRange=3000
local aimbotFOVRadius=150
local aimAtHead=true
local aimbotSmoothness=0.3
local isAiming=false
local aimbotConnection=nil

local showFOVCircle=false
local fovCircleDrawing=nil
local fovCircleColor=Color3.fromRGB(255,255,255)
local fovCircleThickness=1

local function GetClosestTarget(overrideFOV)
    if not camera then return nil end

    if not character then
        RefreshCharacter()
        if not character then return nil end
    end

    local viewportSize=camera.ViewportSize
    local center=Vector2.new(
        viewportSize.X/2,
        viewportSize.Y/2
    )

    local fov=overrideFOV or aimbotFOVRadius
    local bestTarget=nil
    local bestScore=math.huge

    for _,plr in ipairs(Players:GetPlayers()) do
        if plr==player then continue end
        if teamCheck and SameTeam(plr) then continue end

        local char=plr.Character
        if not char or not IsCharacterAlive(char) then continue end

        local targetPart=GetTargetPart(char,aimAtHead)
        if not targetPart then continue end

        local distance=(targetPart.Position-camera.CFrame.Position).Magnitude
        if distance>aimbotRange then continue end
        if not IsTargetVisible(targetPart,wallCheck) then continue end

        local screenPos,onScreen=camera:WorldToViewportPoint(targetPart.Position)
        if not onScreen or screenPos.Z<=0 then continue end

        local screenPoint=Vector2.new(screenPos.X,screenPos.Y)
        local distFromCenter=(screenPoint-center).Magnitude

        if distFromCenter>fov then continue end

        local distancePenalty=(distance/math.max(aimbotRange,1))*0.05
        local score=distFromCenter+distancePenalty

        if score<bestScore then
            bestScore=score
            bestTarget=targetPart
        end
    end

    return bestTarget
end

local function AimAt(targetPart,dt)
    if not targetPart or not targetPart.Parent then return end
    if not camera then return end

    if not CameraController then
        loadCameraController()
    end

    if not CameraController then return end

    local targetCharacter=targetPart.Parent
    if not IsCharacterAlive(targetCharacter) then return end

    local origin=camera.CFrame.Position
    local targetPosition=targetPart.Position
    local direction=targetPosition-origin

    if direction.Magnitude<=0.001 then return end

    local targetCFrame=CFrame.lookAt(origin,targetPosition)
    local targetRotX,targetRotY,targetRotZ=targetCFrame:ToOrientation()
    local targetRotation=Vector2.new(targetRotX,targetRotY)
    local currentRotation=CameraController.Rotation

    local newRotation

    if aimbotSmoothness>0 then
        local alpha=1-math.exp(
            -math.clamp(aimbotSmoothness,0,1)*
            dt*
            12
        )

        alpha=math.clamp(alpha,0,1)
        newRotation=currentRotation:Lerp(targetRotation,alpha)
    else
        newRotation=targetRotation
    end

    pcall(function()
        CameraController:SetRotation(newRotation)
    end)
end

local function StopAimbot()
    isAiming=false

    if aimbotConnection then
        pcall(function()
            aimbotConnection:Disconnect()
        end)

        aimbotConnection=nil
    end
end

local function StartAimbot()
    StopAimbot()

    if not aimbotEnabled or isUnloaded then return end

    aimbotConnection=RunService.RenderStepped:Connect(function(dt)
        if isUnloaded or not aimbotEnabled then return end

        local keybind=Options.AimbotKey
        if not keybind then return end

        local state=false

        pcall(function()
            state=keybind:GetState()
        end)

        isAiming=state

        if not state then return end

        local target=GetClosestTarget()

        if target then
            AimAt(target,dt)
        end
    end)
end

local function updateFOVCircle()
    if not showFOVCircle or not aimbotEnabled or isUnloaded then
        if fovCircleDrawing then
            fovCircleDrawing.Visible=false
        end

        return
    end

    if not fovCircleDrawing then
        fovCircleDrawing=Drawing.new("Circle")
        fovCircleDrawing.Filled=false
        fovCircleDrawing.Thickness=fovCircleThickness
        fovCircleDrawing.Color=fovCircleColor
    end

    if camera then
        local viewportSize=camera.ViewportSize

        fovCircleDrawing.Position=Vector2.new(
            viewportSize.X/2,
            viewportSize.Y/2
        )

        fovCircleDrawing.Radius=aimbotFOVRadius
        fovCircleDrawing.Color=fovCircleColor
        fovCircleDrawing.Thickness=fovCircleThickness
        fovCircleDrawing.Visible=true
    end
end

local fovRenderConnection=RunService.RenderStepped:Connect(function()
    updateFOVCircle()
end)

local autoShootEnabled=false
local autoShootDelay=100
local autoShootLastShot=0
local autoShootConnection=nil
local autoShootFOVRadius=15

local function DoShoot()
    if mouse1click then
        pcall(mouse1click)
        return
    end

    if VirtualInputManager then
        pcall(function()
            local mousePos=UserInputService:GetMouseLocation()

            VirtualInputManager:SendMouseButtonEvent(
                Enum.UserInputType.MouseButton1,
                true,
                mousePos.X,
                mousePos.Y
            )

            task.wait(0.05)

            VirtualInputManager:SendMouseButtonEvent(
                Enum.UserInputType.MouseButton1,
                false,
                mousePos.X,
                mousePos.Y
            )
        end)
    end
end

local function StartAutoShoot()
    if autoShootConnection then return end

    autoShootConnection=RunService.Heartbeat:Connect(function()
        if not autoShootEnabled or isUnloaded then return end

        if not character or not humanoid or humanoid.Health<=0 then
            return
        end

        local target=GetClosestTarget(autoShootFOVRadius)

        if target then
            local now=tick()*1000

            if now-autoShootLastShot>=autoShootDelay then
                autoShootLastShot=now
                DoShoot()
            end
        end
    end)
end

local function StopAutoShoot()
    if autoShootConnection then
        autoShootConnection:Disconnect()
        autoShootConnection=nil
    end
end

local espEnabled=false

local espConfig={
    Boxes=true,
    BoxColor=Color3.fromRGB(255,50,50),
    BoxThickness=1,
    Names=true,
    NameColor=Color3.fromRGB(255,255,255),
    NameSize=13,
    Distance=true,
    DistanceColor=Color3.fromRGB(200,200,200),
    DistanceSize=11,
    HealthBar=true,
    Tracers=false,
    TracerColor=Color3.fromRGB(255,50,50),
    TracerThickness=1,
    TracerOnlyEnemy=false,
    HeadDots=false,
    HeadDotColor=Color3.fromRGB(255,255,255),
    HeadDotRadius=3,
    MaxDistance=2500,
    TeamColor=false
}

local espObjects={}
local espConnections={}
local espRenderConnection=nil

local function createDrawing(type,props)
    local obj=Drawing.new(type)

    for k,v in pairs(props) do
        obj[k]=v
    end

    return obj
end

local function registerESPPlayer(plr)
    if espObjects[plr] or plr==player or not plr then
        return
    end

    local drawings={
        BoxOutline=createDrawing("Square",{
            Thickness=espConfig.BoxThickness+2,
            Color=Color3.fromRGB(0,0,0),
            Filled=false,
            Visible=false
        }),
        Box=createDrawing("Square",{
            Thickness=espConfig.BoxThickness,
            Color=espConfig.BoxColor,
            Filled=false,
            Visible=false
        }),
        Name=createDrawing("Text",{
            Size=espConfig.NameSize,
            Center=true,
            Outline=true,
            Color=espConfig.NameColor,
            Visible=false
        }),
        Distance=createDrawing("Text",{
            Size=espConfig.DistanceSize,
            Center=true,
            Outline=true,
            Color=espConfig.DistanceColor,
            Visible=false
        }),
        HealthBarOutline=createDrawing("Line",{
            Thickness=3,
            Color=Color3.fromRGB(0,0,0),
            Visible=false
        }),
        HealthBar=createDrawing("Line",{
            Thickness=1,
            Visible=false
        }),
        Tracer=createDrawing("Line",{
            Thickness=espConfig.TracerThickness,
            Color=espConfig.TracerColor,
            Visible=false
        }),
        HeadDot=createDrawing("Circle",{
            Radius=espConfig.HeadDotRadius,
            Filled=true,
            Color=espConfig.HeadDotColor,
            Visible=false
        })
    }

    espObjects[plr]=drawings
end

local function removeESPPlayer(plr)
    local drawings=espObjects[plr]
    if not drawings then return end

    for _,d in pairs(drawings) do
        d.Visible=false

        pcall(function()
            d:Remove()
        end)
    end

    espObjects[plr]=nil
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

    local humanoid=model:FindFirstChildOfClass("Humanoid")
    return humanoid and humanoid.Health>0 and humanoid.Parent
end

local function startESP()
    if espRenderConnection then
        pcall(function()
            espRenderConnection:Disconnect()
        end)

        espRenderConnection=nil
    end

    espRenderConnection=RunService.RenderStepped:Connect(function()
        if not espEnabled or isUnloaded then
            for _,drawings in pairs(espObjects) do
                for _,d in pairs(drawings) do
                    d.Visible=false
                end
            end

            return
        end

        local camPos=camera.CFrame.Position
        local viewportSize=camera.ViewportSize

        for plr,drawings in pairs(espObjects) do
            local targetCharacter=plr.Character

            if not targetCharacter or not isAlive(targetCharacter) then
                for _,d in pairs(drawings) do
                    d.Visible=false
                end

                continue
            end

            local rootPart=getRootPart(targetCharacter)

            if not rootPart then
                for _,d in pairs(drawings) do
                    d.Visible=false
                end

                continue
            end

            local dist=(camPos-rootPart.Position).Magnitude

            if dist>espConfig.MaxDistance then
                for _,d in pairs(drawings) do
                    d.Visible=false
                end

                continue
            end

            local isR15=targetCharacter:FindFirstChildOfClass("Humanoid").RigType==Enum.HumanoidRigType.R15

            local topPoint=rootPart.Position+Vector3.new(
                0,
                isR15 and 3.2 or 2.5,
                0
            )

            local botPoint=rootPart.Position-Vector3.new(
                0,
                isR15 and 3.4 or 2.8,
                0
            )

            local topPos,topOn=camera:WorldToViewportPoint(topPoint)
            local botPos,botOn=camera:WorldToViewportPoint(botPoint)

            if (topOn or botOn) and topPos.Z>0 then
                local height=math.abs(topPos.Y-botPos.Y)
                local width=height*0.6
                local posX=topPos.X-width*0.5
                local posY=topPos.Y

                drawings.BoxOutline.Thickness=espConfig.BoxThickness+2
                drawings.Box.Thickness=espConfig.BoxThickness
                drawings.Name.Size=espConfig.NameSize
                drawings.Distance.Size=espConfig.DistanceSize
                drawings.Tracer.Thickness=espConfig.TracerThickness
                drawings.HeadDot.Radius=espConfig.HeadDotRadius

                local boxColor=espConfig.BoxColor

                if espConfig.TeamColor then
                    boxColor=SameTeam(plr)
                        and Color3.fromRGB(0,255,0)
                        or Color3.fromRGB(255,255,255)
                end

                if espConfig.Boxes then
                    drawings.BoxOutline.Size=Vector2.new(width,height)
                    drawings.BoxOutline.Position=Vector2.new(posX,posY)
                    drawings.BoxOutline.Visible=true

                    drawings.Box.Size=Vector2.new(width,height)
                    drawings.Box.Position=Vector2.new(posX,posY)
                    drawings.Box.Color=boxColor
                    drawings.Box.Visible=true
                else
                    drawings.BoxOutline.Visible=false
                    drawings.Box.Visible=false
                end

                if espConfig.Names then
                    drawings.Name.Position=Vector2.new(
                        topPos.X,
                        posY-espConfig.NameSize-2
                    )

                    drawings.Name.Text=plr.DisplayName
                    drawings.Name.Color=espConfig.NameColor
                    drawings.Name.Visible=true
                else
                    drawings.Name.Visible=false
                end

                if espConfig.Distance then
                    drawings.Distance.Position=Vector2.new(
                        topPos.X,
                        botPos.Y+2
                    )

                    drawings.Distance.Text=string.format(
                        "[%d studs]",
                        math.floor(dist)
                    )

                    drawings.Distance.Color=espConfig.DistanceColor
                    drawings.Distance.Visible=true
                else
                    drawings.Distance.Visible=false
                end

                if espConfig.HealthBar then
                    local hum=targetCharacter:FindFirstChildOfClass("Humanoid")
                    local maxHp=hum.MaxHealth
                    local hp=maxHp>0 and math.clamp(hum.Health/maxHp,0,1) or 1
                    local barX=posX-5

                    drawings.HealthBarOutline.From=Vector2.new(
                        barX,
                        posY
                    )

                    drawings.HealthBarOutline.To=Vector2.new(
                        barX,
                        posY+height
                    )

                    drawings.HealthBarOutline.Visible=true

                    drawings.HealthBar.From=Vector2.new(
                        barX,
                        posY+height
                    )

                    drawings.HealthBar.To=Vector2.new(
                        barX,
                        posY+height-(height*hp)
                    )

                    drawings.HealthBar.Color=Color3.fromRGB(
                        255-math.floor(hp*255),
                        math.floor(hp*255),
                        0
                    )

                    drawings.HealthBar.Visible=true
                else
                    drawings.HealthBarOutline.Visible=false
                    drawings.HealthBar.Visible=false
                end

                if espConfig.Tracers then
                    local showTracer=true
                    local tracerColor=espConfig.TracerColor

                    if espConfig.TracerOnlyEnemy then
                        if SameTeam(plr) then
                            showTracer=false
                        else
                            tracerColor=Color3.fromRGB(255,255,255)
                        end
                    else
                        tracerColor=SameTeam(plr)
                            and Color3.fromRGB(0,255,0)
                            or Color3.fromRGB(255,255,255)
                    end

                    if showTracer then
                        drawings.Tracer.From=Vector2.new(
                            viewportSize.X*0.5,
                            viewportSize.Y
                        )

                        drawings.Tracer.To=Vector2.new(
                            topPos.X,
                            botPos.Y
                        )

                        drawings.Tracer.Color=tracerColor
                        drawings.Tracer.Visible=true
                    else
                        drawings.Tracer.Visible=false
                    end
                else
                    drawings.Tracer.Visible=false
                end

                if espConfig.HeadDots then
                    local head=targetCharacter:FindFirstChild("Head")

                    if head then
                        local headPos,headOn=
                            camera:WorldToViewportPoint(head.Position)

                        if headOn and headPos.Z>0 then
                            drawings.HeadDot.Position=Vector2.new(
                                headPos.X,
                                headPos.Y
                            )

                            drawings.HeadDot.Color=espConfig.HeadDotColor
                            drawings.HeadDot.Visible=true
                        else
                            drawings.HeadDot.Visible=false
                        end
                    else
                        drawings.HeadDot.Visible=false
                    end
                else
                    drawings.HeadDot.Visible=false
                end
            else
                for _,d in pairs(drawings) do
                    d.Visible=false
                end
            end
        end
    end)
end

local function startESPConnections()
    for _,plr in ipairs(Players:GetPlayers()) do
        if plr~=player then
            registerESPPlayer(plr)
        end
    end

    if not espConnections.PlayerAdded then
        espConnections.PlayerAdded=Players.PlayerAdded:Connect(function(plr)
            if plr~=player and not isUnloaded then
                task.wait(0.5)
                registerESPPlayer(plr)
            end
        end)
    end

    if not espConnections.PlayerRemoving then
        espConnections.PlayerRemoving=Players.PlayerRemoving:Connect(function(plr)
            removeESPPlayer(plr)
        end)
    end
end

local function stopESP()
    if espRenderConnection then
        pcall(function()
            espRenderConnection:Disconnect()
        end)

        espRenderConnection=nil
    end

    for _,drawings in pairs(espObjects) do
        for _,d in pairs(drawings) do
            d.Visible=false

            pcall(function()
                d:Remove()
            end)
        end
    end

    espObjects={}

    for _,conn in pairs(espConnections) do
        pcall(function()
            conn:Disconnect()
        end)
    end

    espConnections={}
end

local playerChamsEnabled=false
local playerChamsColor=Color3.fromRGB(0,255,0)
local playerChamsObjects={}
local playerChamsPlayerAddedConn=nil
local playerChamsPlayerRemovingConn=nil
local playerChamsCharAddedConns={}
local playerChamsCharRemovingConns={}

local function removePlayerChamsForPlayer(plr)
    local highlight=playerChamsObjects[plr]

    if highlight then
        highlight:Destroy()
        playerChamsObjects[plr]=nil
    end
end

local function createPlayerChamsForPlayer(plr)
    if plr==player then return end

    removePlayerChamsForPlayer(plr)

    local char=plr.Character
    if not char then return end

    local highlight=Instance.new("Highlight")
    highlight.FillColor=playerChamsColor
    highlight.OutlineColor=Color3.new(1,1,1)
    highlight.FillTransparency=0.3
    highlight.OutlineTransparency=0.2
    highlight.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent=char

    playerChamsObjects[plr]=highlight
end

local function refreshPlayerChams()
    if playerChamsEnabled then
        for _,plr in ipairs(Players:GetPlayers()) do
            if plr~=player then
                createPlayerChamsForPlayer(plr)
            end
        end
    else
        for plr,_ in pairs(playerChamsObjects) do
            removePlayerChamsForPlayer(plr)
        end

        playerChamsObjects={}
    end
end

local function setupPlayerChamsConnections()
    if playerChamsPlayerAddedConn then
        playerChamsPlayerAddedConn:Disconnect()
    end

    if playerChamsPlayerRemovingConn then
        playerChamsPlayerRemovingConn:Disconnect()
    end

    for _,conn in pairs(playerChamsCharAddedConns) do
        conn:Disconnect()
    end

    for _,conn in pairs(playerChamsCharRemovingConns) do
        conn:Disconnect()
    end

    playerChamsCharAddedConns={}
    playerChamsCharRemovingConns={}

    playerChamsPlayerAddedConn=Players.PlayerAdded:Connect(function(plr)
        if playerChamsEnabled and plr~=player then
            local addedConn=plr.CharacterAdded:Connect(function()
                createPlayerChamsForPlayer(plr)
            end)

            table.insert(
                playerChamsCharAddedConns,
                addedConn
            )

            local removingConn=plr.CharacterRemoving:Connect(function()
                removePlayerChamsForPlayer(plr)
            end)

            table.insert(
                playerChamsCharRemovingConns,
                removingConn
            )

            createPlayerChamsForPlayer(plr)
        end
    end)

    playerChamsPlayerRemovingConn=Players.PlayerRemoving:Connect(function(plr)
        removePlayerChamsForPlayer(plr)
    end)

    for _,plr in ipairs(Players:GetPlayers()) do
        if plr~=player then
            local addedConn=plr.CharacterAdded:Connect(function()
                createPlayerChamsForPlayer(plr)
            end)

            table.insert(
                playerChamsCharAddedConns,
                addedConn
            )

            local removingConn=plr.CharacterRemoving:Connect(function()
                removePlayerChamsForPlayer(plr)
            end)

            table.insert(
                playerChamsCharRemovingConns,
                removingConn
            )

            createPlayerChamsForPlayer(plr)
        end
    end
end

local function stopPlayerChams()
    playerChamsEnabled=false

    for plr,_ in pairs(playerChamsObjects) do
        removePlayerChamsForPlayer(plr)
    end

    playerChamsObjects={}

    if playerChamsPlayerAddedConn then
        playerChamsPlayerAddedConn:Disconnect()
    end

    if playerChamsPlayerRemovingConn then
        playerChamsPlayerRemovingConn:Disconnect()
    end

    for _,conn in pairs(playerChamsCharAddedConns) do
        conn:Disconnect()
    end

    for _,conn in pairs(playerChamsCharRemovingConns) do
        conn:Disconnect()
    end

    playerChamsCharAddedConns={}
    playerChamsCharRemovingConns={}
end

local function TogglePlayerChams(state)
    playerChamsEnabled=state

    if state then
        setupPlayerChamsConnections()
        refreshPlayerChams()
    else
        stopPlayerChams()
    end
end

local function SetPlayerChamsColor(color)
    playerChamsColor=color

    for _,highlight in pairs(playerChamsObjects) do
        if highlight then
            highlight.FillColor=color
        end
    end
end

local customHandsEnabled=false
local customHandsColor=Color3.fromRGB(255,0,255)
local customHandsMaterial=Enum.Material.ForceField
local customHandsConnection=nil

local function applyCustomHands()
    if not customHandsEnabled or isUnloaded then
        if customHandsConnection then
            customHandsConnection:Disconnect()
            customHandsConnection=nil
        end

        return
    end

    if not customHandsConnection then
        customHandsConnection=RunService.RenderStepped:Connect(function()
            if not customHandsEnabled or isUnloaded then return end

            local vm=workspace:FindFirstChild("ViewModels")
            local fp=vm and vm:FindFirstChild("FirstPerson")

            if not fp then return end

            for _,model in ipairs(fp:GetChildren()) do
                for _,part in ipairs(model:GetDescendants()) do
                    if part:IsA("BasePart") then
                        local nameLower=part.Name:lower()

                        if not nameLower:find("arm")
                            and not nameLower:find("hand") then

                            part.Color=customHandsColor
                            part.Material=customHandsMaterial
                        end
                    end
                end
            end
        end)
    end
end

local function ToggleCustomHands(state)
    customHandsEnabled=state

    if state then
        applyCustomHands()
    else
        if customHandsConnection then
            customHandsConnection:Disconnect()
            customHandsConnection=nil
        end
    end
end

local function SetCustomHandsColor(color)
    customHandsColor=color
end

local function SetCustomHandsMaterial(material)
    customHandsMaterial=material
end

local aspectRatioEnabled=false
local selectedAspectRatio="16:9"

local aspectRatioPresets={
    ["4:3"]={Width=4,Height=3},
    ["5:4"]={Width=5,Height=4},
    ["16:9"]={Width=16,Height=9},
    ["21:9"]={Width=21,Height=9}
}

local originalAspectFOV=nil
local originalAspectFOVMode=nil

local customFOVEnabled=false
local customFOV=70

local function SaveOriginalAspectSettings()
    if not camera then
        camera=workspace.CurrentCamera
    end

    if not camera then return end

    if originalAspectFOV==nil then
        originalAspectFOV=camera.FieldOfView
    end

    if originalAspectFOVMode==nil then
        originalAspectFOVMode=camera.FieldOfViewMode
    end
end

local function GetCurrentViewportAspect()
    if not camera then
        camera=workspace.CurrentCamera
    end

    if not camera then return 16/9 end

    local viewport=camera.ViewportSize

    if viewport.Y<=0 then
        return 16/9
    end

    return viewport.X/viewport.Y
end

local function GetBaseFOV()
    if customFOVEnabled then
        return customFOV
    end

    return originalAspectFOV or 70
end

local function CalculateAspectFOV(targetAspect)
    local currentAspect=GetCurrentViewportAspect()
    local baseFOV=GetBaseFOV()

    local baseVerticalRadians=math.rad(baseFOV)

    local baseHorizontalRadians=
        2*math.atan(
            math.tan(baseVerticalRadians/2)*
            currentAspect
        )

    local targetVerticalRadians=
        2*math.atan(
            math.tan(baseHorizontalRadians/2)/
            targetAspect
        )

    return math.clamp(
        math.deg(targetVerticalRadians),
        1,
        120
    )
end

local ApplyCustomFOV
local ApplyAspectRatio

ApplyCustomFOV=function()
    if not camera then
        camera=workspace.CurrentCamera
    end

    if not camera then return end
    if isUnloaded then return end

    if not customFOVEnabled then
        if not aspectRatioEnabled and originalAspectFOV then
            pcall(function()
                camera.FieldOfView=originalAspectFOV
                camera.FieldOfViewMode=originalAspectFOVMode
            end)
        end

        return
    end

    if aspectRatioEnabled then
        local preset=aspectRatioPresets[selectedAspectRatio]

        if preset then
            pcall(function()
                camera.FieldOfViewMode=Enum.FieldOfViewMode.Vertical
                camera.FieldOfView=CalculateAspectFOV(
                    preset.Width/preset.Height
                )
            end)
        end
    else
        pcall(function()
            camera.FieldOfView=math.clamp(
                customFOV,
                1,
                120
            )
        end)
    end
end

ApplyAspectRatio=function()
    if isUnloaded then return end

    if not camera then
        camera=workspace.CurrentCamera
    end

    if not camera then return end

    SaveOriginalAspectSettings()

    if not aspectRatioEnabled then
        if customFOVEnabled then
            ApplyCustomFOV()
        else
            if originalAspectFOV then
                camera.FieldOfView=originalAspectFOV
            end

            if originalAspectFOVMode then
                pcall(function()
                    camera.FieldOfViewMode=originalAspectFOVMode
                end)
            end
        end

        return
    end

    local preset=aspectRatioPresets[selectedAspectRatio]
    if not preset then return end

    local targetAspect=preset.Width/preset.Height

    pcall(function()
        camera.FieldOfViewMode=Enum.FieldOfViewMode.Vertical
        camera.FieldOfView=CalculateAspectFOV(targetAspect)
    end)
end

local function SetCustomFOVEnabled(state)
    SaveOriginalAspectSettings()
    customFOVEnabled=state

    if aspectRatioEnabled then
        ApplyAspectRatio()
    else
        ApplyCustomFOV()
    end
end

local function SetCustomFOV(value)
    customFOV=math.clamp(value,1,120)

    if customFOVEnabled then
        if aspectRatioEnabled then
            ApplyAspectRatio()
        else
            ApplyCustomFOV()
        end
    end
end

local function SetAspectRatioEnabled(state)
    aspectRatioEnabled=state

    if state then
        SaveOriginalAspectSettings()
    end

    ApplyAspectRatio()
end

local function SetAspectRatioPreset(value)
    if not aspectRatioPresets[value] then return end

    selectedAspectRatio=value

    if aspectRatioEnabled then
        ApplyAspectRatio()
    end
end

local aspectRatioConnection=RunService.RenderStepped:Connect(function()
    if isUnloaded then return end

    local currentCamera=workspace.CurrentCamera

    if currentCamera~=camera then
        camera=currentCamera
        SaveOriginalAspectSettings()
    end

    if aspectRatioEnabled then
        ApplyAspectRatio()
    elseif customFOVEnabled then
        ApplyCustomFOV()
    end
end)

local customAmbientEnabled=false
local customAmbientColor=Color3.fromRGB(128,128,128)
local originalAmbient=Lighting.Ambient
local originalOutdoorAmbient=Lighting.OutdoorAmbient

local function ApplyCustomAmbient()
    if isUnloaded then return end

    if customAmbientEnabled then
        Lighting.Ambient=customAmbientColor
        Lighting.OutdoorAmbient=customAmbientColor
    else
        Lighting.Ambient=originalAmbient
        Lighting.OutdoorAmbient=originalOutdoorAmbient
    end
end

local function SetCustomAmbient(state)
    customAmbientEnabled=state
    ApplyCustomAmbient()
end

local function SetCustomAmbientColor(color)
    customAmbientColor=color

    if customAmbientEnabled then
        ApplyCustomAmbient()
    end
end

-- ============ CFrame Fly ============
local flyEnabled = false
local flyModeEnabled = false
local flySpeed = 50
local flyConnection = nil
local flyKeyConnection = nil

local function startFly()
    if flyEnabled then
        return
    end
    if not character or not humanoidRootPart then
        return
    end
    flyEnabled = true

    if humanoid then
        for _, state in pairs(Enum.HumanoidStateType:GetEnumItems()) do
            humanoid:SetStateEnabled(state, false)
        end
    end

    flyConnection = RunService.Heartbeat:Connect(function(dt)
        if not flyEnabled or isUnloaded then
            stopFly()
            return
        end
        if not character or not humanoidRootPart or not camera then
            return
        end

        local moveVector = Vector3.new(0, 0, 0)
        local forward = camera.CFrame.LookVector
        local right = camera.CFrame.RightVector
        local up = camera.CFrame.UpVector

        if UserInputService:IsKeyDown(Enum.KeyCode.W) then
            moveVector = moveVector + forward
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then
            moveVector = moveVector - forward
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then
            moveVector = moveVector - right
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then
            moveVector = moveVector + right
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            moveVector = moveVector + up
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
            moveVector = moveVector - up
        end

        if moveVector.Magnitude > 0 then
            moveVector = moveVector.Unit * flySpeed * dt
            humanoidRootPart.CFrame = humanoidRootPart.CFrame + moveVector
        end

        if humanoidRootPart:IsA("BasePart") then
            humanoidRootPart.Velocity = Vector3.new(0, 0, 0)
            humanoidRootPart.RotVelocity = Vector3.new(0, 0, 0)
        end
    end)
end

local function stopFly()
    if not flyEnabled then
        return
    end
    flyEnabled = false

    if flyConnection then
        flyConnection:Disconnect()
        flyConnection = nil
    end

    if humanoid then
        for _, state in pairs(Enum.HumanoidStateType:GetEnumItems()) do
            humanoid:SetStateEnabled(state, true)
        end
    end
    if humanoidRootPart and humanoidRootPart:IsA("BasePart") then
        humanoidRootPart.Velocity = Vector3.new(0, 0, 0)
        humanoidRootPart.RotVelocity = Vector3.new(0, 0, 0)
    end
end

local function toggleFly(state)
    flyModeEnabled = state
    if not state and flyEnabled then
        stopFly()
    end
end

local function startFlyKeyListener()
    if flyKeyConnection then
        return
    end

    if not Options.FlyKey then
        return
    end

    flyKeyConnection = RunService.RenderStepped:Connect(function()
        if isUnloaded then
            if flyKeyConnection then
                flyKeyConnection:Disconnect()
                flyKeyConnection = nil
            end
            return
        end

        local keybind = Options.FlyKey
        if not keybind then
            return
        end

        local keyState = false
        pcall(function() keyState = keybind:GetState() end)

        local shouldFly = flyModeEnabled and keyState

        if shouldFly and not flyEnabled then
            startFly()
        elseif not shouldFly and flyEnabled then
            stopFly()
        end
    end)
end

-- ============ CFrame Speed ============
local speedEnabled = false
local speedModeEnabled = false
local speedValue = 100
local speedConnection = nil
local speedKeyConnection = nil

local function startSpeed()
    if speedEnabled then
        return
    end

    if not character or not humanoidRootPart or not humanoid then
        return
    end

    speedEnabled = true

    speedConnection = RunService.Heartbeat:Connect(function(dt)
        if not speedEnabled or isUnloaded then
            stopSpeed()
            return
        end

        if not character or not humanoidRootPart or not humanoid then
            return
        end

        if humanoid.Health <= 0 then
            return
        end

        local moveDirection = humanoid.MoveDirection

        if moveDirection.Magnitude > 0.001 then
            local horizontalDirection = Vector3.new(
                moveDirection.X,
                0,
                moveDirection.Z
            )

            if horizontalDirection.Magnitude > 0.001 then
                horizontalDirection = horizontalDirection.Unit

                local offset = horizontalDirection * speedValue * dt

                pcall(function()
                    humanoidRootPart.CFrame =
                        humanoidRootPart.CFrame + offset
                end)
            end
        end
    end)
end

local function stopSpeed()
    if not speedEnabled then
        return
    end

    speedEnabled = false

    if speedConnection then
        speedConnection:Disconnect()
        speedConnection = nil
    end
end

local function toggleSpeed(state)
    speedModeEnabled = state

    if not state and speedEnabled then
        stopSpeed()
    end
end

local function startSpeedKeyListener()
    if speedKeyConnection then
        return
    end

    if not Options.SpeedKey then
        return
    end

    speedKeyConnection = RunService.RenderStepped:Connect(function()
        if isUnloaded then
            if speedKeyConnection then
                speedKeyConnection:Disconnect()
                speedKeyConnection = nil
            end
            return
        end

        local keybind = Options.SpeedKey
        if not keybind then
            return
        end

        local keyState = false
        pcall(function()
            keyState = keybind:GetState()
        end)

        local shouldSpeed = speedModeEnabled and keyState

        if shouldSpeed and not speedEnabled then
            startSpeed()
        elseif not shouldSpeed and speedEnabled then
            stopSpeed()
        end
    end)
end
-- ========================================================

local SilentGroup=Tabs.Combat:AddGroupbox({
    Side="Left",
    Name="Silent Aim",
    IconName="crosshair"
})

SilentGroup:AddToggle("SilentAimToggle",{
    Text="Enabled",
    Default=false,
    Callback=function(state)
        if isUnloaded then return end
        SilentAim.active=state
    end,
}):AddKeyPicker("SilentAimKey",{
    Default="None",
    SyncToggleState=true,
    Mode="Toggle",
    Text="Silent Aim Key",
})

SilentGroup:AddSlider("SilentFOVRadius",{
    Text="FOV",
    Default=150,
    Min=10,
    Max=600,
    Rounding=0,
    Callback=function(v)
        SilentAim.fovRadius=v

        if SilentAim.fovCircle then
            SilentAim.fovCircle.Radius=v
        end
    end,
})

SilentGroup:AddToggle("SilentFOVToggle",{
    Text="FOV Circle",
    Default=false,
    Callback=function(state)
        if isUnloaded then return end
        SilentAim.fovEnabled=state
    end,
})

SilentGroup:AddDropdown("SilentFOVColor",{
    Text="Circle Color",
    Values={"White","Red","Green","Blue","Yellow","Cyan","Magenta"},
    Default="White",
    Callback=function(v)
        local colorMap={
            White=Color3.fromRGB(255,255,255),
            Red=Color3.fromRGB(255,0,0),
            Green=Color3.fromRGB(0,255,0),
            Blue=Color3.fromRGB(0,0,255),
            Yellow=Color3.fromRGB(255,255,0),
            Cyan=Color3.fromRGB(0,255,255),
            Magenta=Color3.fromRGB(255,0,255)
        }

        SilentAim.fovColor=colorMap[v] or Color3.fromRGB(255,255,255)

        if SilentAim.fovCircle then
            SilentAim.fovCircle.Color=SilentAim.fovColor
        end
    end,
})

SilentGroup:AddSlider("SilentAimRange",{
    Text="Distance",
    Default=2000,
    Min=50,
    Max=3000,
    Rounding=0,
    Callback=function(v)
        SilentAim.maxDistance=v
    end,
})


local AimGroup=Tabs.Combat:AddGroupbox({
    Side="Left",
    Name="Aimbot",
    IconName="eye"
})

AimGroup:AddToggle("EnableAimbot",{
    Text="Enable Aimbot",
    Default=false,
    Callback=function(state)
        if isUnloaded then return end

        aimbotEnabled=state

        if state then
            StartAimbot()
        else
            StopAimbot()
        end

        updateFOVCircle()
    end,
})

AimGroup:AddSlider("Range",{
    Text="Range",
    Default=3000,
    Min=50,
    Max=3000,
    Rounding=0,
    Callback=function(v)
        aimbotRange=v
    end,
})

AimGroup:AddSlider("FOVRadius",{
    Text="FOV Radius",
    Default=150,
    Min=10,
    Max=500,
    Rounding=0,
    Callback=function(v)
        aimbotFOVRadius=v
        updateFOVCircle()
    end,
})

AimGroup:AddToggle("AimAtHead",{
    Text="Aim at Head",
    Default=true,
    Callback=function(v)
        aimAtHead=v
    end,
})

AimGroup:AddToggle("TeamCheck",{
    Text="Team Check",
    Default=true,
    Callback=function(v)
        teamCheck=v
    end,
})

AimGroup:AddToggle("WallCheck",{
    Text="Wall Check",
    Default=true,
    Callback=function(v)
        wallCheck=v
    end,
})

AimGroup:AddSlider("Smoothness",{
    Text="Smoothness",
    Default=0.3,
    Min=0,
    Max=1,
    Rounding=2,
    Callback=function(v)
        aimbotSmoothness=v
    end,
})

AimGroup:AddDivider()

AimGroup:AddToggle("ShowFOVCircle",{
    Text="Show FOV Circle",
    Default=false,
    Callback=function(state)
        if isUnloaded then return end

        showFOVCircle=state
        updateFOVCircle()
    end,
})

AimGroup:AddDropdown("FOVCircleColor",{
    Text="Circle Color",
    Values={"White","Red","Green","Blue","Yellow","Cyan","Magenta"},
    Default="White",
    Callback=function(value)
        local colorMap={
            White=Color3.fromRGB(255,255,255),
            Red=Color3.fromRGB(255,0,0),
            Green=Color3.fromRGB(0,255,0),
            Blue=Color3.fromRGB(0,0,255),
            Yellow=Color3.fromRGB(255,255,0),
            Cyan=Color3.fromRGB(0,255,255),
            Magenta=Color3.fromRGB(255,0,255)
        }

        fovCircleColor=colorMap[value] or Color3.fromRGB(255,255,255)
        updateFOVCircle()
    end,
})

AimGroup:AddSlider("FOVCircleThickness",{
    Text="Thickness",
    Default=1,
    Min=1,
    Max=3,
    Rounding=0,
    Callback=function(v)
        fovCircleThickness=v
        updateFOVCircle()
    end,
})

AimGroup:AddDivider()

AimGroup:AddLabel("Aimbot Key"):AddKeyPicker("AimbotKey",{
    Default="MB2",
    Mode="Hold",
    NoUI=false,
    Text="Aimbot Key",
})

local AutoGroup=Tabs.Combat:AddGroupbox({
    Side="Right",
    Name="AutoShoot",
    IconName="target"
})

AutoGroup:AddToggle("AutoShootToggle",{
    Text="Enable AutoShoot",
    Default=false,
    Callback=function(state)
        if isUnloaded then return end

        autoShootEnabled=state

        if state then
            StartAutoShoot()
        else
            StopAutoShoot()
        end
    end,
})

AutoGroup:AddSlider("AutoShootDelay",{
    Text="Delay (ms)",
    Default=0,
    Min=0,
    Max=500,
    Rounding=0,
    Callback=function(v)
        autoShootDelay=v
    end,
})

AutoGroup:AddSlider("AutoShootFOV",{
    Text="AutoShoot FOV",
    Default=15,
    Min=1,
    Max=100,
    Rounding=0,
    Callback=function(v)
        autoShootFOVRadius=v
    end,
})

local VisualGroup=Tabs.Visuals:AddGroupbox({
    Side="Left",
    Name="ESP Settings",
    IconName="eye"
})

VisualGroup:AddToggle("ESP",{
    Text="Enable ESP",
    Default=false,
    Callback=function(state)
        if isUnloaded then return end

        espEnabled=state

        if state then
            startESPConnections()
            startESP()
        else
            stopESP()
        end
    end
})

VisualGroup:AddToggle("ESPBoxes",{
    Text="Boxes",
    Default=true,
    Callback=function(state)
        espConfig.Boxes=state
    end
})

VisualGroup:AddToggle("ESPNames",{
    Text="Names",
    Default=true,
    Callback=function(state)
        espConfig.Names=state
    end
})

VisualGroup:AddToggle("ESPDistance",{
    Text="Distance",
    Default=true,
    Callback=function(state)
        espConfig.Distance=state
    end
})

VisualGroup:AddToggle("ESPHealthBar",{
    Text="Health Bar",
    Default=true,
    Callback=function(state)
        espConfig.HealthBar=state
    end
})

VisualGroup:AddToggle("ESPTracers",{
    Text="Tracers",
    Default=false,
    Callback=function(state)
        espConfig.Tracers=state
    end
})

VisualGroup:AddToggle("ESPTracerOnlyEnemy",{
    Text="Only Enemy",
    Default=false,
    Callback=function(state)
        espConfig.TracerOnlyEnemy=state
    end
})

VisualGroup:AddToggle("ESPHeadDots",{
    Text="Head Dots",
    Default=false,
    Callback=function(state)
        espConfig.HeadDots=state
    end
})

VisualGroup:AddToggle("ESPTeamColor",{
    Text="Team Color",
    Default=false,
    Callback=function(state)
        espConfig.TeamColor=state
    end
})

VisualGroup:AddSlider("ESPMaxDistance",{
    Text="Max Distance",
    Default=2500,
    Min=100,
    Max=5000,
    Rounding=0,
    Callback=function(v)
        espConfig.MaxDistance=v
    end
})

VisualGroup:AddSlider("ESPBoxThickness",{
    Text="Box Thickness",
    Default=1,
    Min=1,
    Max=3,
    Rounding=0,
    Callback=function(v)
        espConfig.BoxThickness=v
    end
})

VisualGroup:AddSlider("ESPNameSize",{
    Text="Name Size",
    Default=13,
    Min=10,
    Max=20,
    Rounding=0,
    Callback=function(v)
        espConfig.NameSize=v
    end
})

VisualGroup:AddSlider("ESPDistanceSize",{
    Text="Distance Size",
    Default=11,
    Min=10,
    Max=18,
    Rounding=0,
    Callback=function(v)
        espConfig.DistanceSize=v
    end
})

local AspectGroup=Tabs.Visuals:AddGroupbox({
    Side="Right",
    Name="Aspect Ratio",
    IconName="maximize"
})

AspectGroup:AddToggle("AspectRatioToggle",{
    Text="Enable Aspect Ratio",
    Default=false,
    Callback=function(state)
        if isUnloaded then return end
        SetAspectRatioEnabled(state)
    end,
})

AspectGroup:AddDropdown("AspectRatioPreset",{
    Text="Aspect Ratio",
    Values={"4:3","5:4","16:9","21:9"},
    Default="16:9",
    Callback=function(value)
        SetAspectRatioPreset(value)
    end,
})

local FOVGroup=Tabs.Visuals:AddGroupbox({
    Side="Left",
    Name="Custom FOV",
    IconName="scan"
})

FOVGroup:AddToggle("CustomFOVToggle",{
    Text="Enable Custom FOV",
    Default=false,
    Callback=function(state)
        if isUnloaded then return end
        SetCustomFOVEnabled(state)
    end,
})

FOVGroup:AddSlider("CustomFOVValue",{
    Text="FOV",
    Default=70,
    Min=1,
    Max=120,
    Rounding=0,
    Callback=function(value)
        SetCustomFOV(value)
    end,
})

FOVGroup:AddLabel("Range: 1 - 120")

local AmbientGroup=Tabs.Visuals:AddGroupbox({
    Side="Right",
    Name="Custom Ambient",
    IconName="sun"
})

AmbientGroup:AddToggle("CustomAmbientToggle",{
    Text="Enable Custom Ambient",
    Default=false,
    Callback=function(state)
        if isUnloaded then return end
        SetCustomAmbient(state)
    end,
}):AddColorPicker("CustomAmbientColor",{
    Default=customAmbientColor,
    Title="Ambient Color",
    Callback=function(color)
        SetCustomAmbientColor(color)
    end,
})


local ChamsGroup=Tabs.Visuals:AddGroupbox({
    Side="Right",
    Name="Player Chams",
    IconName="box"
})

ChamsGroup:AddToggle("PlayerChamsToggle",{
    Text="Enable Player Chams",
    Default=false,
    Callback=function(state)
        if isUnloaded then return end
        TogglePlayerChams(state)
    end,
})

ChamsGroup:AddDropdown("PlayerChamsColor",{
    Text="Chams Color",
    Values={"Red","Blue","Green","Yellow","Cyan","Magenta","White","Orange","Purple"},
    Default="Green",
    Callback=function(value)
        local colorMap={
            Red=Color3.fromRGB(255,0,0),
            Blue=Color3.fromRGB(0,0,255),
            Green=Color3.fromRGB(0,255,0),
            Yellow=Color3.fromRGB(255,255,0),
            Cyan=Color3.fromRGB(0,255,255),
            Magenta=Color3.fromRGB(255,0,255),
            White=Color3.fromRGB(255,255,255),
            Orange=Color3.fromRGB(255,165,0),
            Purple=Color3.fromRGB(128,0,128)
        }

        SetPlayerChamsColor(
            colorMap[value] or
            Color3.fromRGB(0,255,0)
        )
    end,
})

local HandsGroup=Tabs.Visuals:AddGroupbox({
    Side="Right",
    Name="Custom Hands",
    IconName="hand"
})

HandsGroup:AddToggle("CustomHandsToggle",{
    Text="Enable Custom Hands",
    Default=false,
    Callback=function(state)
        if isUnloaded then return end
        ToggleCustomHands(state)
    end,
})

HandsGroup:AddDropdown("HandsColor",{
    Text="Hands Color",
    Values={"Red","Blue","Green","Yellow","Cyan","Magenta","White","Orange","Purple"},
    Default="Magenta",
    Callback=function(value)
        local colorMap={
            Red=Color3.fromRGB(255,0,0),
            Blue=Color3.fromRGB(0,0,255),
            Green=Color3.fromRGB(0,255,0),
            Yellow=Color3.fromRGB(255,255,0),
            Cyan=Color3.fromRGB(0,255,255),
            Magenta=Color3.fromRGB(255,0,255),
            White=Color3.fromRGB(255,255,255),
            Orange=Color3.fromRGB(255,165,0),
            Purple=Color3.fromRGB(128,0,128)
        }

        SetCustomHandsColor(
            colorMap[value] or
            Color3.fromRGB(255,0,255)
        )
    end,
})

HandsGroup:AddDropdown("HandsMaterial",{
    Text="Material",
    Values={
        "ForceField",
        "Neon",
        "SmoothPlastic",
        "Glass",
        "Metal",
        "Wood",
        "Granite",
        "Sandstone"
    },
    Default="ForceField",
    Callback=function(value)
        local matMap={
            ForceField=Enum.Material.ForceField,
            Neon=Enum.Material.Neon,
            SmoothPlastic=Enum.Material.SmoothPlastic,
            Glass=Enum.Material.Glass,
            Metal=Enum.Material.Metal,
            Wood=Enum.Material.Wood,
            Granite=Enum.Material.Granite,
            Sandstone=Enum.Material.Sandstone
        }

        SetCustomHandsMaterial(
            matMap[value] or
            Enum.Material.ForceField
        )
    end,
})

-- === MISС TAB ===
local MiscGroup = Tabs.Misc:AddGroupbox({
    Side = "Left",
    Name = "Flight",
    IconName = "plane"
})

MiscGroup:AddToggle("FlyToggle", {
    Text = "Enable Fly",
    Default = false,
    Callback = function(state)
        if isUnloaded then return end
        toggleFly(state)
    end,
})

MiscGroup:AddSlider("FlySpeed", {
    Text = "Fly Speed",
    Default = 50,
    Min = 10,
    Max = 200,
    Rounding = 0,
    Callback = function(v)
        flySpeed = v
    end,
})

MiscGroup:AddLabel("Fly Key"):AddKeyPicker("FlyKey", {
    Default = "None",
    Mode = "Hold",
    NoUI = false,
    Text = "Fly Key",
})


-- === Speed Group ===
local SpeedGroup = Tabs.Misc:AddGroupbox({
    Side = "Left",
    Name = "Speed Hack",
    IconName = "zap"
})

SpeedGroup:AddToggle("SpeedToggle", {
    Text = "Enable Speed",
    Default = false,
    Callback = function(state)
        if isUnloaded then return end
        toggleSpeed(state)
    end,
})

SpeedGroup:AddSlider("SpeedValue", {
    Text = "Speed",
    Default = 100,
    Min = 20,
    Max = 500,
    Rounding = 0,
    Callback = function(v)
        speedValue = v
    end,
})

SpeedGroup:AddLabel("Speed Key"):AddKeyPicker("SpeedKey", {
    Default = "None",
    Mode = "Hold",
    NoUI = false,
    Text = "Speed Key",
})

-- === Weapon Mods ===
local ModsGroup = Tabs.Misc:AddGroupbox({
    Side = "Right",
    Name = "Weapon Mods",
    IconName = "crosshair"
})

ModsGroup:AddToggle("NoSpread",{
    Text="No Spread",
    Default=false,
    Callback=function(state)
        if isUnloaded then return end
        ToggleNoSpread(state)
    end,
})

ModsGroup:AddToggle("NoRecoil",{
    Text="No Recoil",
    Default=false,
    Callback=function(state)
        if isUnloaded then return end
        ToggleNoRecoil(state)
    end,
})

ModsGroup:AddToggle("PerfectAccuracy",{
    Text="Accuracy",
    Default=false,
    Callback=function(state)
        if isUnloaded then return end
        accuracyEnabled=state
        ApplyAccuracy(state)
    end,
})
-- ==================

local UISettingsTab=Tabs["UI Settings"]

local MenuGroup=UISettingsTab:AddGroupbox({
    Side="Left",
    Name="Menu",
    IconName="wrench"
})

MenuGroup:AddToggle("KeybindMenuOpen",{
    Default=Library.KeybindFrame.Visible,
    Text="Open Keybind Menu",
    Callback=function(v)
        if not isUnloaded then
            Library.KeybindFrame.Visible=v
        end
    end
})

MenuGroup:AddToggle("ShowCustomCursor",{
    Text="Custom Cursor",
    Default=Library.ShowCustomCursor,
    Callback=function(v)
        if not isUnloaded then
            Library.ShowCustomCursor=v
        end
    end
})

MenuGroup:AddToggle("AlwaysOnTop",{
    Text="Always On Top",
    Default=Window.AlwaysOnTop,
    Callback=function(v)
        if not isUnloaded then
            Window:SetAlwaysOnTop(v)
        end
    end
})

MenuGroup:AddDropdown("NotificationSide",{
    Values={"Left","Right"},
    Default="Right",
    Text="Notification Side",
    Callback=function(v)
        if not isUnloaded then
            Library:SetNotifySide(v)
        end
    end
})

MenuGroup:AddSlider("DPISlider",{
    Text="DPI Scale",
    Default=100,
    Min=50,
    Max=200,
    Rounding=0,
    Callback=function(v)
        if not isUnloaded then
            Library:SetDPIScale(v)
        end
    end
})

MenuGroup:AddSlider("UICornerSlider",{
    Text="Corner Radius",
    Default=Library.CornerRadius,
    Min=0,
    Max=20,
    Rounding=0,
    Callback=function(v)
        if not isUnloaded then
            Window:SetCornerRadius(v)
        end
    end
})

MenuGroup:AddDivider()

MenuGroup:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind",{
    Default="RightShift",
    NoUI=true,
    Text="Menu keybind"
})

MenuGroup:AddDivider()

local UnloadGroup=UISettingsTab:AddGroupbox({
    Side="Right",
    Name="Unload",
    IconName="power"
})

UnloadGroup:AddButton({
    Text="Unload Script",
    Func=function()
        Library:Unload()
    end,
    Risky=true
})

Library.ToggleKeybind=Options.MenuKeybind

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({"MenuKeybind"})

ThemeManager:SetFolder("JulyVisualsCombat")
SaveManager:SetFolder("JulyVisualsCombat")
SaveManager:SetSubFolder("settings")

SaveManager:BuildConfigSection(UISettingsTab)
ThemeManager:ApplyToTab(UISettingsTab)
SaveManager:LoadAutoloadConfig()

-- Восстанавливаем сохранённые состояния
if Options.ESP and Options.ESP.Value then
    espEnabled=true
    startESPConnections()
    startESP()
end

if Options.PlayerChamsToggle and Options.PlayerChamsToggle.Value then
    TogglePlayerChams(true)
end

if Options.CustomHandsToggle and Options.CustomHandsToggle.Value then
    ToggleCustomHands(true)
end

if Options.EnableAimbot and Options.EnableAimbot.Value then
    aimbotEnabled=true
    StartAimbot()
end

if Options.SilentAimToggle and Options.SilentAimToggle.Value then
    SilentAim.active=true
end

if Options.AutoShootToggle and Options.AutoShootToggle.Value then
    autoShootEnabled=true
    StartAutoShoot()
end

if Options.NoSpread and Options.NoSpread.Value then
    ToggleNoSpread(true)
end

if Options.NoRecoil and Options.NoRecoil.Value then
    ToggleNoRecoil(true)
end

if Options.PerfectAccuracy and Options.PerfectAccuracy.Value then
    accuracyEnabled=true
    ApplyAccuracy(true)
end

if Options.ShowFOVCircle and Options.ShowFOVCircle.Value then
    showFOVCircle=true
    updateFOVCircle()
end

if Options.SilentFOVToggle and Options.SilentFOVToggle.Value then
    SilentAim.fovEnabled=true
end

if Options.AspectRatioPreset and Options.AspectRatioPreset.Value then
    selectedAspectRatio=Options.AspectRatioPreset.Value
end

if Options.AspectRatioToggle and Options.AspectRatioToggle.Value then
    aspectRatioEnabled=true
    SaveOriginalAspectSettings()
    ApplyAspectRatio()
end

if Options.CustomFOVValue and Options.CustomFOVValue.Value then
    customFOV=Options.CustomFOVValue.Value
end

if Options.CustomFOVToggle and Options.CustomFOVToggle.Value then
    customFOVEnabled=true
    SaveOriginalAspectSettings()

    if aspectRatioEnabled then
        ApplyAspectRatio()
    else
        ApplyCustomFOV()
    end
end

if Options.CustomAmbientColor and Options.CustomAmbientColor.Value then
    pcall(function()
        customAmbientColor=Options.CustomAmbientColor.Value
    end)
end

if Options.CustomAmbientToggle and Options.CustomAmbientToggle.Value then
    customAmbientEnabled=true
    ApplyCustomAmbient()
end

-- Запускаем слушатели для Fly и Speed
startFlyKeyListener()
startSpeedKeyListener()

-- Восстанавливаем скорость
if Options.FlySpeed and Options.FlySpeed.Value then
    flySpeed = Options.FlySpeed.Value
end
if Options.SpeedValue and Options.SpeedValue.Value then
    speedValue = Options.SpeedValue.Value
end

Library:OnUnload(function()
    if isUnloaded then return end
    isUnloaded=true

    stopFly()
    if flyKeyConnection then
        flyKeyConnection:Disconnect()
        flyKeyConnection = nil
    end

    stopSpeed()
    if speedKeyConnection then
        speedKeyConnection:Disconnect()
        speedKeyConnection = nil
    end

    SilentAim:Shutdown()

    aimbotEnabled=false
    StopAimbot()

    autoShootEnabled=false
    StopAutoShoot()

    ApplyAccuracy(false)

    if GunModule and originalIsFullyAiming then
        GunModule.IsFullyAiming=originalIsFullyAiming
    end

    espEnabled=false
    stopESP()

    playerChamsEnabled=false
    stopPlayerChams()

    customHandsEnabled=false

    if customHandsConnection then
        customHandsConnection:Disconnect()
        customHandsConnection=nil
    end

    if fovCircleDrawing then
        fovCircleDrawing.Visible=false

        pcall(function()
            fovCircleDrawing:Remove()
        end)

        fovCircleDrawing=nil
    end

    if aspectRatioConnection then
        aspectRatioConnection:Disconnect()
        aspectRatioConnection=nil
    end

    if originalAspectFOV and camera then
        pcall(function()
            camera.FieldOfView=originalAspectFOV
        end)
    end

    if originalAspectFOVMode and camera then
        pcall(function()
            camera.FieldOfViewMode=originalAspectFOVMode
        end)
    end

    pcall(function()
        Lighting.Ambient=originalAmbient
        Lighting.OutdoorAmbient=originalOutdoorAmbient
    end)

    if fovRenderConnection then
        fovRenderConnection:Disconnect()
        fovRenderConnection=nil
    end

    if characterAddedConnection then
        characterAddedConnection:Disconnect()
        characterAddedConnection=nil
    end
end)
