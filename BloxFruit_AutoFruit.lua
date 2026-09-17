-- PUFF SCRIPT — UI ONLY
-- Delta-compatible Lua
-- Visual/console interface; no Blox Fruits remote exploitation.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Player = Players.LocalPlayer

local Gui = Instance.new("ScreenGui")
Gui.Name = "PuffScript"
Gui.ResetOnSpawn = false
Gui.Parent = Player:WaitForChild("PlayerGui")

local Main = Instance.new("Frame")
Main.Size = UDim2.fromOffset(720, 430)
Main.Position = UDim2.new(.5, -360, .5, -215)
Main.BackgroundColor3 = Color3.fromRGB(5, 8, 5)
Main.BorderSizePixel = 0
Main.Parent = Gui

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 10)
Corner.Parent = Main

local Stroke = Instance.new("UIStroke")
Stroke.Color = Color3.fromRGB(0, 255, 100)
Stroke.Thickness = 1
Stroke.Parent = Main

-- Title bar
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 42)
Title.BackgroundTransparency = 1
Title.Text = "⚡ PUFF SCRIPT"
Title.TextColor3 = Color3.fromRGB(0, 255, 100)
Title.TextSize = 22
Title.Font = Enum.Font.Code
Title.Parent = Main

-- Status
local Status = Instance.new("TextLabel")
Status.Position = UDim2.fromOffset(20, 50)
Status.Size = UDim2.fromOffset(300, 30)
Status.BackgroundTransparency = 1
Status.Text = "● ONLINE  |  " .. Player.Name
Status.TextColor3 = Color3.fromRGB(0, 255, 100)
Status.TextXAlignment = Enum.TextXAlignment.Left
Status.Font = Enum.Font.Code
Status.TextSize = 15
Status.Parent = Main

-- Terminal
local Terminal = Instance.new("ScrollingFrame")
Terminal.Position = UDim2.fromOffset(20, 95)
Terminal.Size = UDim2.new(1, -40, 1, -155)
Terminal.BackgroundColor3 = Color3.fromRGB(2, 4, 2)
Terminal.BorderSizePixel = 0
Terminal.ScrollBarThickness = 3
Terminal.Parent = Main

local Layout = Instance.new("UIListLayout")
Layout.Padding = UDim.new(0, 3)
Layout.Parent = Terminal

local function log(text)
    local Line = Instance.new("TextLabel")
    Line.Size = UDim2.new(1, -10, 0, 24)
    Line.BackgroundTransparency = 1
    Line.Text = "> " .. text
    Line.TextColor3 = Color3.fromRGB(0, 255, 100)
    Line.TextXAlignment = Enum.TextXAlignment.Left
    Line.Font = Enum.Font.Code
    Line.TextSize = 14
    Line.Parent = Terminal

    task.wait()
    Terminal.CanvasPosition = Vector2.new(
        0,
        math.max(0, Layout.AbsoluteContentSize.Y)
    )
end

-- Command box
local Input = Instance.new("TextBox")
Input.Position = UDim2.new(0, 20, 1, -50)
Input.Size = UDim2.new(1, -40, 0, 35)
Input.BackgroundColor3 = Color3.fromRGB(8, 15, 8)
Input.BorderSizePixel = 0
Input.PlaceholderText = "Enter command..."
Input.PlaceholderColor3 = Color3.fromRGB(80, 150, 80)
Input.Text = ""
Input.TextColor3 = Color3.fromRGB(0, 255, 100)
Input.Font = Enum.Font.Code
Input.TextSize = 14
Input.ClearTextOnFocus = false
Input.Parent = Main

Instance.new("UICorner", Input).CornerRadius = UDim.new(0, 6)

-- Boot sequence
local boot = {
    "PUFF_SYSTEM BOOTING...",
    "Initializing Matrix layer...",
    "Loading interface...",
    "Loading terminal...",
    "Loading notification service...",
    "Loading admin framework...",
    "Connection established.",
    "SYSTEM READY_"
}

for _, message in ipairs(boot) do
    log(message)
    task.wait(.18)
end

-- Local UI commands
Input.FocusLost:Connect(function(enterPressed)
    if not enterPressed then return end

    local command = Input.Text
    Input.Text = ""

    if command == "" then return end

    log(command)

    local cmd = command:lower()

    if cmd == "help" then
        log("Available UI commands:")
        log("help")
        log("clear")
        log("info")
        log("status")

    elseif cmd == "clear" then
        for _, child in ipairs(Terminal:GetChildren()) do
            if child:IsA("TextLabel") then
                child:Destroy()
            end
        end

    elseif cmd == "info" then
        log("Puff Script loaded successfully.")
        log("Player: " .. Player.Name)

    elseif cmd == "status" then
        log("SYSTEM ONLINE")

    else
        log("Unknown command. Type 'help'.")
    end
end)

-- Dragging
local UserInputService = game:GetService("UserInputService")

local dragging = false
local dragStart
local startPosition

Title.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPosition = Main.Position
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

        Main.Position = UDim2.new(
            startPosition.X.Scale,
            startPosition.X.Offset + delta.X,
            startPosition.Y.Scale,
            startPosition.Y.Offset + delta.Y
        )
    end
end)

-- Open animation
Main.Size = UDim2.fromOffset(0, 0)

TweenService:Create(
    Main,
    TweenInfo.new(.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
    {
        Size = UDim2.fromOffset(720, 430)
    }
):Play()
