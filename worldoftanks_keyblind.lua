-- ==================== KEYBIND LIST (в стиле Stellar) ====================
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

    -- Drag
    local dragging, dragStart, startPos
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
    game:GetService("UserInputService").InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            Frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    local Entries = {}

    function KeybindList:Add(name, keyText)
        if Entries[name] then
            Entries[name].Key.Text = keyText or "None"
            return
        end

        local Row = Instance.new("Frame")
        Row.Size = UDim2.new(1, 0, 0, 18)
        Row.BackgroundTransparency = 1
        Row.Parent = Frame

        local NameLabel = Instance.new("TextLabel")
        NameLabel.Size = UDim2.new(0.6, 0, 1, 0)
        NameLabel.BackgroundTransparency = 1
        NameLabel.Text = name
        NameLabel.TextColor3 = Theme.Text
        NameLabel.TextTransparency = 0.2
        NameLabel.FontFace = Font
        NameLabel.TextSize = 13
        NameLabel.TextXAlignment = Enum.TextXAlignment.Left
        NameLabel.Parent = Row

        local KeyLabel = Instance.new("TextLabel")
        KeyLabel.Size = UDim2.new(0.4, 0, 1, 0)
        KeyLabel.Position = UDim2.new(0.6, 0, 0, 0)
        KeyLabel.BackgroundTransparency = 1
        KeyLabel.Text = keyText or "None"
        KeyLabel.TextColor3 = Theme.Accent
        KeyLabel.FontFace = Font
        KeyLabel.TextSize = 13
        KeyLabel.TextXAlignment = Enum.TextXAlignment.Right
        KeyLabel.Parent = Row

        Entries[name] = { Row = Row, Key = KeyLabel }
    end

    function KeybindList:Set(name, keyText)
        if Entries[name] then
            Entries[name].Key.Text = keyText or "None"
        else
            self:Add(name, keyText)
        end
    end

    function KeybindList:Remove(name)
        if Entries[name] then
            Entries[name].Row:Destroy()
            Entries[name] = nil
        end
    end

    function KeybindList:SetVisible(v)
        Frame.Visible = v
    end

    function KeybindList:Destroy()
        Gui:Destroy()
    end
end
