-- OrionLibrary (ModuleScript)
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Orion = {}
Orion.__index = Orion

-- Helper functions
local function create(class, props)
    local inst = Instance.new(class)
    if props then
        for k,v in pairs(props) do
            inst[k] = v
        end
    end
    return inst
end

local function twn(instance, props, info)
    info = info or TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    TweenService:Create(instance, info, props):Play()
end

-- Top-level: MakeWindow
function Orion:MakeWindow(title, opts)
    opts = opts or {}
    local size = opts.Size or UDim2.new(0, 700, 0, 420)

    -- ScreenGui
    local screenGui = create("ScreenGui", {Name = "OrionGUI", ResetOnSpawn = false})
    screenGui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")

    -- Main frame
    local main = create("Frame", {
        Name = "Main",
        Size = size,
        Position = UDim2.new(0.5, -(size.X.Offset/2), 0.5, -(size.Y.Offset/2)),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Color3.fromRGB(24,24,24),
        BorderSizePixel = 0,
        Parent = screenGui,
        ClipsDescendants = true
    })

    -- UI Corner & shadow (simple)
    local uic = create("UICorner", {CornerRadius = UDim.new(0, 10), Parent = main})

    -- Title bar
    local titleBar = create("Frame", {
        Name = "TitleBar",
        Size = UDim2.new(1,0,0,34),
        BackgroundTransparency = 1,
        Parent = main
    })
    local titleLabel = create("TextLabel", {
        Name = "Title",
        Size = UDim2.new(1, -100, 1, 0),
        Position = UDim2.new(0,12,0,0),
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = title or "Orion",
        TextSize = 18,
        Font = Enum.Font.SourceSansSemibold,
        TextColor3 = Color3.fromRGB(235,235,235),
        Parent = titleBar
    })

    -- Tabs list (left)
    local tabsList = create("Frame", {
        Name = "Tabs",
        Size = UDim2.new(0, 160, 1, 0),
        Position = UDim2.new(0,0,0,34),
        BackgroundColor3 = Color3.fromRGB(18,18,18),
        Parent = main
    })
    create("UICorner", {Parent = tabsList, CornerRadius = UDim.new(0,8)})
    local tabsLayout = create("UIListLayout", {Parent = tabsList, Padding = UDim.new(0,4)})

    -- Content area (right)
    local content = create("Frame", {
        Name = "Content",
        Size = UDim2.new(1, -170, 1, -34),
        Position = UDim2.new(0,170,0,34),
        BackgroundColor3 = Color3.fromRGB(12,12,12),
        Parent = main
    })
    create("UICorner", {Parent = content, CornerRadius = UDim.new(0,8)})
    local pages = create("Folder", {Name = "Pages", Parent = content})

    -- Dragging main window
    do
        local dragging, dragInput, dragStart, startPos
        local function update(input)
            local delta = input.Position - dragStart
            main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
        titleBar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                dragStart = input.Position
                startPos = main.Position
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                    end
                end)
            end
        end)
        titleBar.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement then
                dragInput = input
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if input == dragInput and dragging then
                update(input)
            end
        end)
    end

    -- window object to return
    local window = {}
    window._gui = screenGui
    window._tabsFrame = tabsList
    window._pages = pages
    window._pageRecords = {} -- name -> page frame
    window._buttons = {}

    -- AddTab
    function window:AddTab(name)
        -- tab button
        local btn = create("TextButton", {
            Name = "Tab_"..name,
            Size = UDim2.new(1, -12, 0, 36),
            BackgroundColor3 = Color3.fromRGB(20,20,20),
            BorderSizePixel = 0,
            Text = name,
            TextSize = 15,
            Font = Enum.Font.SourceSans,
            TextColor3 = Color3.fromRGB(220,220,220),
            Parent = self._tabsFrame
        })
        create("UICorner", {Parent = btn, CornerRadius = UDim.new(0,6)})

        -- page
        local page = create("ScrollingFrame", {
            Name = "Page_"..name,
            Size = UDim2.new(1, -8, 1, -8),
            Position = UDim2.new(0,4,0,4),
            BackgroundTransparency = 1,
            CanvasSize = UDim2.new(0,0,0,0),
            ScrollBarThickness = 6,
            Parent = self._pages
        })
        local layout = create("UIListLayout", {Parent = page, Padding = UDim.new(0,8)})
        layout.SortOrder = Enum.SortOrder.LayoutOrder

        -- when clicked, show page and hide others
        btn.MouseButton1Click:Connect(function()
            for _,p in pairs(self._pages:GetChildren()) do
                if p:IsA("ScrollingFrame") then
                    p.Visible = (p == page)
                end
            end
            -- small tween for selection
            twn(btn, {BackgroundColor3 = Color3.fromRGB(34,34,34)})
            delay(0.2, function() twn(btn, {BackgroundColor3 = Color3.fromRGB(20,20,20)}) end)
        end)

        -- default select first created
        if #self._pages:GetChildren() == 1 then
            page.Visible = true
        else
            page.Visible = false
        end

        local tabObj = {}
        tabObj._page = page

        -- AddSection inside tab
        function tabObj:AddSection(title)
            local section = create("Frame", {
                Name = "Section_"..title,
                Size = UDim2.new(1, -12, 0, 32),
                BackgroundTransparency = 1,
                Parent = self._page
            })
            local header = create("TextLabel", {
                Name = "SectionTitle",
                Size = UDim2.new(1,0,0,20),
                BackgroundTransparency = 1,
                Text = title,
                Font = Enum.Font.SourceSansBold,
                TextSize = 15,
                TextColor3 = Color3.fromRGB(230,230,230),
                TextXAlignment = Enum.TextXAlignment.Left,
                Position = UDim2.new(0,6,0,0),
                Parent = section
            })
            local container = create("Frame", {
                Name = "Container",
                Size = UDim2.new(1,0,0,0),
                Position = UDim2.new(0,0,0,22),
                BackgroundTransparency = 1,
                Parent = section
            })
            local contLayout = create("UIListLayout", {Parent = container, Padding = UDim.new(0,6)})
            contLayout.SortOrder = Enum.SortOrder.LayoutOrder

            -- helpers to resize section according to children
            local function updateSize()
                section.Size = UDim2.new(1, -12, 0, 22 + container.AbsoluteSize.Y)
            end
            contLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateSize)

            local sec = {}

            function sec:AddButton(text, callback)
                local b = create("TextButton", {
                    Name = "Button",
                    Size = UDim2.new(1, -12, 0, 34),
                    BackgroundColor3 = Color3.fromRGB(28,28,28),
                    BorderSizePixel = 0,
                    Text = text,
                    Font = Enum.Font.SourceSans,
                    TextSize = 14,
                    TextColor3 = Color3.fromRGB(230,230,230),
                    Parent = container
                })
                create("UICorner",{Parent = b, CornerRadius = UDim.new(0,6)})
                b.MouseButton1Click:Connect(function()
                    pcall(function() callback() end)
                    twn(b, {BackgroundColor3 = Color3.fromRGB(38,38,38)})
                    delay(0.15, function() twn(b, {BackgroundColor3 = Color3.fromRGB(28,28,28)}) end)
                end)
                return b
            end

            function sec:AddToggle(text, default, callback)
                default = default or false
                local frame = create("Frame", {
                    Name = "Toggle_"..text,
                    Size = UDim2.new(1, -12, 0, 34),
                    BackgroundColor3 = Color3.fromRGB(28,28,28),
                    BorderSizePixel = 0,
                    Parent = container
                })
                create("UICorner",{Parent = frame, CornerRadius = UDim.new(0,6)})
                local lbl = create("TextLabel", {
                    Name = "Label",
                    Size = UDim2.new(1, -44, 1, 0),
                    Position = UDim2.new(0,8,0,0),
                    BackgroundTransparency = 1,
                    Text = text,
                    Font = Enum.Font.SourceSans,
                    TextSize = 14,
                    TextColor3 = Color3.fromRGB(230,230,230),
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = frame
                })
                local box = create("Frame", {
                    Name = "Box",
                    Size = UDim2.new(0,28,0,20),
                    Position = UDim2.new(1,-36,0,7),
                    BackgroundColor3 = default and Color3.fromRGB(100,210,100) or Color3.fromRGB(70,70,70),
                    Parent = frame
                })
                create("UICorner",{Parent = box, CornerRadius = UDim.new(0,6)})

                local state = default
                frame.MouseButton1Click = frame.MouseButton1Click or frame.MouseButton1Click -- ensure no error if not button
                frame.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        state = not state
                        if state then
                            twn(box, {BackgroundColor3 = Color3.fromRGB(100,210,100)})
                        else
                            twn(box, {BackgroundColor3 = Color3.fromRGB(70,70,70)})
                        end
                        pcall(function() callback(state) end)
                    end
                end)
                -- make clickable by overlaying TextButton so InputBegan works
                local overlay = create("TextButton",{BackgroundTransparency=1, Size=UDim2.new(1,0,1,0), Parent=frame, Text = ""})
                overlay.MouseButton1Click:Connect(function()
                    state = not state
                    if state then
                        twn(box, {BackgroundColor3 = Color3.fromRGB(100,210,100)})
                    else
                        twn(box, {BackgroundColor3 = Color3.fromRGB(70,70,70)})
                    end
                    pcall(function() callback(state) end)
                end)
                return {Frame = frame, Get = function() return state end, Set = function(s) state = s; twn(box, {BackgroundColor3 = s and Color3.fromRGB(100,210,100) or Color3.fromRGB(70,70,70)}) end}
            end

            function sec:AddSlider(text, min, max, default, callback)
                min = min or 0; max = max or 100; default = default or min
                local frame = create("Frame", {
                    Name = "Slider_"..text,
                    Size = UDim2.new(1, -12, 0, 50),
                    BackgroundColor3 = Color3.fromRGB(28,28,28),
                    BorderSizePixel = 0,
                    Parent = container
                })
                create("UICorner",{Parent = frame, CornerRadius = UDim.new(0,6)})
                local lbl = create("TextLabel", {
                    Name = "Label",
                    Size = UDim2.new(1, -12, 0, 18),
                    Position = UDim2.new(0,6,0,4),
                    BackgroundTransparency = 1,
                    Text = text .. " ("..tostring(default)..")",
                    Font = Enum.Font.SourceSans,
                    TextSize = 14,
                    TextColor3 = Color3.fromRGB(230,230,230),
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = frame
                })
                local barBg = create("Frame", {
                    Name = "BarBg",
                    Size = UDim2.new(1, -12, 0, 12),
                    Position = UDim2.new(0,6,0,28),
                    BackgroundColor3 = Color3.fromRGB(45,45,45),
                    Parent = frame
                })
                create("UICorner",{Parent = barBg, CornerRadius = UDim.new(0,6)})
                local fill = create("Frame", {
                    Name = "Fill",
                    Size = UDim2.new((default - min)/(max - min), 0, 1, 0),
                    BackgroundColor3 = Color3.fromRGB(100,200,120),
                    Parent = barBg
                })
                create("UICorner",{Parent = fill, CornerRadius = UDim.new(0,6)})

                local dragging = false
                local function updateFill(absx)
                    local rel = math.clamp((absx - barBg.AbsolutePosition.X) / barBg.AbsoluteSize.X, 0, 1)
                    fill.Size = UDim2.new(rel, 0, 1, 0)
                    local val = math.floor(min + (max - min) * rel + 0.5)
                    lbl.Text = text .. " ("..tostring(val)..")"
                    pcall(function() callback(val) end)
                end

                barBg.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        dragging = true
                        updateFill(input.Position.X)
                    end
                end)
                barBg.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        dragging = false
                    end
                end)
                UserInputService.InputChanged:Connect(function(input)
                    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                        updateFill(input.Position.X)
                    end
                end)

                return {Frame = frame, Get = function()
                    local rel = fill.Size.X.Scale
                    return math.floor(min + (max - min) * rel + 0.5)
                end}
            end

            return sec
        end

        table.insert(self._buttons, btn)
        self._pageRecords[name] = page

        return tabObj
    end

    return window
end

-- Allow require() style: Orion:MakeWindow -> use Orion module table as object
local module = setmetatable({}, {__index = Orion})
return module
