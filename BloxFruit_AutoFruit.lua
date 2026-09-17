--[[
  ╔══════════════════════════════════════════════════════════════╗
  ║           BLOX FRUIT - AUTO FRUIT SNIPER SCRIPT             ║
  ║       Scan → Fly → Grab → Store (3 retries) → Hop          ║
  ║              Built for LEARNING purposes only               ║
  ╚══════════════════════════════════════════════════════════════╝
  
  Based on patterns from REDZ HUB V2
  Features:
    • Scans workspace for devil fruits every tick
    • Tweens (flies) to the nearest fruit
    • Picks it up and tries to store it (3 attempts)
    • If store fails after 3 tries → server hops anyway
    • If store succeeds → server hops to find more
    • Anti-AFK to prevent kicks
    • No-clip so walls don't block the flight path
    • Fruit ESP to visualize fruits on the map
]]

-- ═══════════════════════════════════════════════════════════════
-- WAIT FOR GAME TO FULLY LOAD
-- ═══════════════════════════════════════════════════════════════
repeat task.wait() until game:IsLoaded()

-- ═══════════════════════════════════════════════════════════════
-- SERVICES
-- ═══════════════════════════════════════════════════════════════
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")
local VirtualUser       = game:GetService("VirtualUser")
local HttpService       = game:GetService("HttpService")
local TeleportService   = game:GetService("TeleportService")
local RunService        = game:GetService("RunService")

-- ═══════════════════════════════════════════════════════════════
-- CORE REFERENCES (same pattern as REDZ HUB V2)
-- ═══════════════════════════════════════════════════════════════
local Remotes = ReplicatedStorage:WaitForChild("Remotes", 9e9)
local CommF   = Remotes:WaitForChild("CommF_", 9e9)

local Player = Players.LocalPlayer

-- ═══════════════════════════════════════════════════════════════
-- CONFIGURATION (tweak these to your needs)
-- ═══════════════════════════════════════════════════════════════
getgenv().AutoFruitSniper   = true   -- Master toggle for the script
getgenv().FruitESP          = true   -- Show ESP on fruits
getgenv().TweenSpeed        = 300    -- Flight speed (studs/sec)
getgenv().StoreRetries      = 3      -- Max store attempts before giving up
getgenv().HopDelay          = 3      -- Seconds to wait before server hop
getgenv().ScanInterval      = 0.5    -- How often to scan for fruits (seconds)
getgenv().AntiAFK           = true   -- Prevent AFK kick

-- ═══════════════════════════════════════════════════════════════
-- IN-GAME GUI NOTIFICATION SYSTEM
-- Shows real-time status of every action on screen
-- ═══════════════════════════════════════════════════════════════

-- Remove old GUI if re-executing
local oldGui = Player:FindFirstChild("PlayerGui") and Player.PlayerGui:FindFirstChild("FruitSniperGUI")
if oldGui then oldGui:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "FruitSniperGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = Player:WaitForChild("PlayerGui")

-- Main container frame (top-left corner)
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 340, 0, 260)
MainFrame.Position = UDim2.new(0, 15, 0, 15)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
MainFrame.BackgroundTransparency = 0.15
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner", MainFrame)
MainCorner.CornerRadius = UDim.new(0, 10)

local MainStroke = Instance.new("UIStroke", MainFrame)
MainStroke.Color = Color3.fromRGB(100, 50, 255)
MainStroke.Thickness = 1.5
MainStroke.Transparency = 0.3

-- Title bar
local TitleBar = Instance.new("Frame")
TitleBar.Name = "TitleBar"
TitleBar.Size = UDim2.new(1, 0, 0, 36)
TitleBar.BackgroundColor3 = Color3.fromRGB(100, 50, 255)
TitleBar.BackgroundTransparency = 0.4
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame

local TitleCorner = Instance.new("UICorner", TitleBar)
TitleCorner.CornerRadius = UDim.new(0, 10)

-- Fix bottom corners of title bar
local TitleFix = Instance.new("Frame")
TitleFix.Size = UDim2.new(1, 0, 0, 12)
TitleFix.Position = UDim2.new(0, 0, 1, -12)
TitleFix.BackgroundColor3 = Color3.fromRGB(100, 50, 255)
TitleFix.BackgroundTransparency = 0.4
TitleFix.BorderSizePixel = 0
TitleFix.Parent = TitleBar

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Name = "Title"
TitleLabel.Size = UDim2.new(1, -10, 1, 0)
TitleLabel.Position = UDim2.new(0, 10, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "🍎 FRUIT SNIPER"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.TextSize = 16
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = TitleBar

-- Status label (big current status)
local StatusLabel = Instance.new("TextLabel")
StatusLabel.Name = "Status"
StatusLabel.Size = UDim2.new(1, -20, 0, 28)
StatusLabel.Position = UDim2.new(0, 10, 0, 42)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "⏳ Initializing..."
StatusLabel.TextColor3 = Color3.fromRGB(255, 200, 50)
StatusLabel.TextSize = 14
StatusLabel.Font = Enum.Font.GothamBold
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.TextWrapped = true
StatusLabel.Parent = MainFrame

-- Log scroll frame
local LogFrame = Instance.new("ScrollingFrame")
LogFrame.Name = "LogFrame"
LogFrame.Size = UDim2.new(1, -20, 1, -80)
LogFrame.Position = UDim2.new(0, 10, 0, 74)
LogFrame.BackgroundColor3 = Color3.fromRGB(5, 5, 15)
LogFrame.BackgroundTransparency = 0.3
LogFrame.BorderSizePixel = 0
LogFrame.ScrollBarThickness = 4
LogFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 50, 255)
LogFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
LogFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
LogFrame.Parent = MainFrame

local LogCorner = Instance.new("UICorner", LogFrame)
LogCorner.CornerRadius = UDim.new(0, 6)

local LogLayout = Instance.new("UIListLayout", LogFrame)
LogLayout.SortOrder = Enum.SortOrder.LayoutOrder
LogLayout.Padding = UDim.new(0, 2)

local LogPadding = Instance.new("UIPadding", LogFrame)
LogPadding.PaddingTop = UDim.new(0, 4)
LogPadding.PaddingLeft = UDim.new(0, 6)
LogPadding.PaddingRight = UDim.new(0, 6)

-- Color presets for different message types
local MSG_COLORS = {
  success = Color3.fromRGB(80, 255, 80),
  error   = Color3.fromRGB(255, 80, 80),
  warn    = Color3.fromRGB(255, 200, 50),
  info    = Color3.fromRGB(150, 180, 255),
  action  = Color3.fromRGB(0, 200, 255),
  fruit   = Color3.fromRGB(255, 100, 200),
  hop     = Color3.fromRGB(180, 130, 255),
}

local logOrder = 0

-- Notify function: updates status + adds to scrolling log
local function Notify(message, msgType, isStatus)
  msgType = msgType or "info"
  local color = MSG_COLORS[msgType] or MSG_COLORS.info
  
  -- Update the big status label if flagged
  if isStatus then
    StatusLabel.Text = message
    StatusLabel.TextColor3 = color
  end
  
  -- Add to scrolling log
  logOrder = logOrder + 1
  local LogEntry = Instance.new("TextLabel")
  LogEntry.Name = "Log_" .. logOrder
  LogEntry.LayoutOrder = logOrder
  LogEntry.Size = UDim2.new(1, 0, 0, 16)
  LogEntry.BackgroundTransparency = 1
  LogEntry.Text = os.date("%H:%M:%S") .. "  " .. message
  LogEntry.TextColor3 = color
  LogEntry.TextSize = 11
  LogEntry.Font = Enum.Font.Gotham
  LogEntry.TextXAlignment = Enum.TextXAlignment.Left
  LogEntry.TextWrapped = true
  LogEntry.AutomaticSize = Enum.AutomaticSize.Y
  LogEntry.Parent = LogFrame
  
  -- Auto-scroll to bottom
  task.defer(function()
    LogFrame.CanvasPosition = Vector2.new(0, LogFrame.AbsoluteCanvasSize.Y)
  end)
  
  -- Also print to console
  print("[FruitSniper] " .. message)
  
  -- Keep log from getting too long (max 50 entries)
  local children = LogFrame:GetChildren()
  local labels = {}
  for _, child in pairs(children) do
    if child:IsA("TextLabel") then
      table.insert(labels, child)
    end
  end
  if #labels > 50 then
    table.sort(labels, function(a, b) return a.LayoutOrder < b.LayoutOrder end)
    labels[1]:Destroy()
  end
end

-- Intro animation: fade in the main frame
MainFrame.BackgroundTransparency = 1
TitleBar.BackgroundTransparency = 1
TitleFix.BackgroundTransparency = 1
TitleLabel.TextTransparency = 1
StatusLabel.TextTransparency = 1
LogFrame.BackgroundTransparency = 1

task.spawn(function()
  local fadeIn = TweenService:Create(MainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {BackgroundTransparency = 0.15})
  local fadeTitle = TweenService:Create(TitleBar, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {BackgroundTransparency = 0.4})
  local fadeTitleFix = TweenService:Create(TitleFix, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {BackgroundTransparency = 0.4})
  local fadeTitleText = TweenService:Create(TitleLabel, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {TextTransparency = 0})
  local fadeStatus = TweenService:Create(StatusLabel, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {TextTransparency = 0})
  local fadeLog = TweenService:Create(LogFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {BackgroundTransparency = 0.3})
  fadeIn:Play() fadeTitle:Play() fadeTitleFix:Play() fadeTitleText:Play() fadeStatus:Play() fadeLog:Play()
end)

-- ═══════════════════════════════════════════════════════════════
-- FRUIT NAME → STORE ID MAPPING (from REDZ HUB V2)
-- ═══════════════════════════════════════════════════════════════
local function Get_Fruit(Fruit)
  if Fruit == "Rocket Fruit" then
    return "Rocket-Rocket"
  elseif Fruit == "Spin Fruit" then
    return "Spin-Spin"
  elseif Fruit == "Chop Fruit" then
    return "Chop-Chop"
  elseif Fruit == "Spring Fruit" then
    return "Spring-Spring"
  elseif Fruit == "Bomb Fruit" then
    return "Bomb-Bomb"
  elseif Fruit == "Smoke Fruit" then
    return "Smoke-Smoke"
  elseif Fruit == "Spike Fruit" then
    return "Spike-Spike"
  elseif Fruit == "Flame Fruit" then
    return "Flame-Flame"
  elseif Fruit == "Falcon Fruit" then
    return "Falcon-Falcon"
  elseif Fruit == "Ice Fruit" then
    return "Ice-Ice"
  elseif Fruit == "Sand Fruit" then
    return "Sand-Sand"
  elseif Fruit == "Dark Fruit" then
    return "Dark-Dark"
  elseif Fruit == "Ghost Fruit" then
    return "Ghost-Ghost"
  elseif Fruit == "Diamond Fruit" then
    return "Diamond-Diamond"
  elseif Fruit == "Light Fruit" then
    return "Light-Light"
  elseif Fruit == "Rubber Fruit" then
    return "Rubber-Rubber"
  elseif Fruit == "Barrier Fruit" then
    return "Barrier-Barrier"
  elseif Fruit == "Magma Fruit" then
    return "Magma-Magma"
  elseif Fruit == "Quake Fruit" then
    return "Quake-Quake"
  elseif Fruit == "Buddha Fruit" then
    return "Buddha-Buddha"
  elseif Fruit == "Love Fruit" then
    return "Love-Love"
  elseif Fruit == "Spider Fruit" then
    return "Spider-Spider"
  elseif Fruit == "Sound Fruit" then
    return "Sound-Sound"
  elseif Fruit == "Phoenix Fruit" then
    return "Phoenix-Phoenix"
  elseif Fruit == "Portal Fruit" then
    return "Portal-Portal"
  elseif Fruit == "Rumble Fruit" then
    return "Rumble-Rumble"
  elseif Fruit == "Pain Fruit" then
    return "Pain-Pain"
  elseif Fruit == "Blizzard Fruit" then
    return "Blizzard-Blizzard"
  elseif Fruit == "Gravity Fruit" then
    return "Gravity-Gravity"
  elseif Fruit == "Mammoth Fruit" then
    return "Mammoth-Mammoth"
  elseif Fruit == "T-Rex Fruit" then
    return "T-Rex-T-Rex"
  elseif Fruit == "Dough Fruit" then
    return "Dough-Dough"
  elseif Fruit == "Shadow Fruit" then
    return "Shadow-Shadow"
  elseif Fruit == "Venom Fruit" then
    return "Venom-Venom"
  elseif Fruit == "Control Fruit" then
    return "Control-Control"
  elseif Fruit == "Spirit Fruit" then
    return "Spirit-Spirit"
  elseif Fruit == "Dragon Fruit" then
    return "Dragon-Dragon"
  elseif Fruit == "Leopard Fruit" then
    return "Leopard-Leopard"
  elseif Fruit == "Kitsune Fruit" then
    return "Kitsune-Kitsune"
  end
end

-- ═══════════════════════════════════════════════════════════════
-- UTILITY: Fire Remote (same as REDZ HUB V2)
-- ═══════════════════════════════════════════════════════════════
local function FireRemote(...)
  return CommF:InvokeServer(...)
end

-- ═══════════════════════════════════════════════════════════════
-- INVISIBLE PLATFORM (keeps player in air while tweening)
-- Same pattern as REDZ HUB V2's "player platform ............."
-- ═══════════════════════════════════════════════════════════════
local block = Instance.new("Part", workspace)
block.Size         = Vector3.new(1, 1, 1)
block.Name         = "FruitSniper_Platform"
block.Anchored     = true
block.CanCollide   = false
block.CanTouch     = false
block.Transparency = 1

-- Clean up duplicate platforms
local existingBlock = workspace:FindFirstChild(block.Name)
if existingBlock and existingBlock ~= block then
  existingBlock:Destroy()
end

-- ═══════════════════════════════════════════════════════════════
-- NO-CLIP + POSITION SYNC (same pattern as REDZ HUB V2)
-- Keeps character glued to the invisible platform
-- ═══════════════════════════════════════════════════════════════
local IsFarming = false

task.spawn(function()
  repeat task.wait()
  until Player.Character and Player.Character.PrimaryPart
  block.CFrame = Player.Character.PrimaryPart.CFrame
  
  while task.wait() do
    pcall(function()
      if IsFarming then
        if block and block.Parent == workspace then
          local plrPP = Player.Character and Player.Character.PrimaryPart
          
          if plrPP and (plrPP.Position - block.Position).Magnitude <= 200 then
            plrPP.CFrame = block.CFrame
          else
            block.CFrame = plrPP.CFrame
          end
        end
        -- No-clip: disable collision on all character parts
        local plrChar = Player.Character
        if plrChar then
          for _, part in pairs(plrChar:GetChildren()) do
            if part:IsA("BasePart") then
              part.CanCollide = false
            end
          end
          -- Clear stun/busy states so we can move freely
          if plrChar:FindFirstChild("Stun") and plrChar.Stun.Value ~= 0 then
            plrChar.Stun.Value = 0
          end
          if plrChar:FindFirstChild("Busy") and plrChar.Busy.Value then
            plrChar.Busy.Value = false
          end
        end
      else
        -- Re-enable collisions when not farming
        local plrChar = Player.Character
        if plrChar then
          for _, part in pairs(plrChar:GetChildren()) do
            if part:IsA("BasePart") then
              part.CanCollide = true
            end
          end
        end
      end
    end)
  end
end)

-- ═══════════════════════════════════════════════════════════════
-- TWEEN / FLY TO POSITION (same pattern as REDZ HUB V2)
-- ═══════════════════════════════════════════════════════════════
local function TweenToPosition(targetCFrame)
  local plrPP = Player.Character and Player.Character.PrimaryPart
  if not plrPP then return end
  
  local distance = (plrPP.Position - targetCFrame.p).Magnitude
  local speed = getgenv().TweenSpeed or 300
  local tweenTime = distance / speed
  
  -- Clamp minimum tween time
  if tweenTime < 0.1 then tweenTime = 0.1 end
  
  local tween = TweenService:Create(
    block,
    TweenInfo.new(tweenTime, Enum.EasingStyle.Linear),
    {CFrame = targetCFrame}
  )
  tween:Play()
  tween.Completed:Wait()
end

-- ═══════════════════════════════════════════════════════════════
-- FRUIT FINDER (same pattern as REDZ HUB V2's FruitFind)
-- Scans workspace for the nearest devil fruit
-- ═══════════════════════════════════════════════════════════════
local function FruitFind()
  local fruits = workspace:GetChildren()
  local FruitDistance = math.huge
  local FoundFruit = nil
  
  for _, fruit in pairs(fruits) do
    local plrPP = Player and Player.Character and Player.Character.PrimaryPart
    -- Check 1: it's a Tool with a Handle (fruit on ground)
    local isTool = fruit and fruit:IsA("Tool") and fruit:FindFirstChild("Handle")
    -- Check 2: name contains "Fruit" with a Handle
    local isFruitNamed = fruit and string.find(fruit.Name, "Fruit") and fruit:FindFirstChild("Handle")
    
    if plrPP and isTool and (plrPP.Position - isTool.Position).Magnitude <= FruitDistance then
      FruitDistance = (plrPP.Position - isTool.Position).Magnitude
      FoundFruit = fruit
    elseif plrPP and isFruitNamed and (plrPP.Position - isFruitNamed.Position).Magnitude <= FruitDistance then
      FruitDistance = (plrPP.Position - isFruitNamed.Position).Magnitude
      FoundFruit = fruit
    end
  end
  
  return FoundFruit
end

-- ═══════════════════════════════════════════════════════════════
-- FRUIT ESP (same pattern as REDZ HUB V2's AddESP)
-- Draws a red ESP marker on fruits in workspace
-- ═══════════════════════════════════════════════════════════════
local function AddESP(Part, ESPColor)
  if Part and Part:FindFirstChild("ESP_FruitSniper") then return end
  
  local Folder = Instance.new("Folder", Part)
  Folder.Name = "ESP_FruitSniper"
  
  local BBG = Instance.new("BillboardGui", Folder)
  BBG.Adornee = Part
  BBG.Size = UDim2.new(0, 120, 0, 50)
  BBG.StudsOffset = Vector3.new(0, 3, 0)
  BBG.AlwaysOnTop = true
  
  local TL = Instance.new("TextLabel", BBG)
  TL.BackgroundTransparency = 1
  TL.Size = UDim2.new(1, 0, 1, 0)
  TL.TextSize = 14
  TL.Font = Enum.Font.GothamBold
  TL.TextColor3 = ESPColor or Color3.fromRGB(255, 0, 0)
  TL.TextStrokeTransparency = 0
  TL.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
  TL.Text = "..."
  TL.ZIndex = 15
  
  task.spawn(function()
    while task.wait(0.5) do
      pcall(function()
        if not Part or not Part.Parent then
          Folder:Destroy()
          return
        end
        local plrPP = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
        if plrPP and Part then
          local distance = math.floor((plrPP.Position - Part.Position).Magnitude)
          local fruitName = Part.Parent and Part.Parent.Name or "Unknown"
          TL.Text = "🍎 " .. fruitName .. " [" .. tostring(distance) .. " studs]"
        end
      end)
    end
  end)
end

local function RemoveESP(Part)
  if Part and Part:FindFirstChild("ESP_FruitSniper") then
    Part.ESP_FruitSniper:Destroy()
  end
end

-- Fruit ESP loop
task.spawn(function()
  while getgenv().AutoFruitSniper do task.wait(1)
    if getgenv().FruitESP then
      for _, obj in pairs(workspace:GetChildren()) do
        pcall(function()
          if obj and obj:IsA("Tool") and obj:FindFirstChild("Handle") then
            AddESP(obj.Handle, Color3.fromRGB(255, 50, 50))
          elseif obj and string.find(obj.Name, "Fruit") and obj:FindFirstChild("Handle") then
            AddESP(obj.Handle, Color3.fromRGB(255, 50, 50))
          end
        end)
      end
    end
  end
end)

-- ═══════════════════════════════════════════════════════════════
-- CHECK IF FRUIT IS IN INVENTORY (backpack or character)
-- ═══════════════════════════════════════════════════════════════
local function FindFruitInInventory()
  local plrChar = Player and Player.Character
  local plrBag  = Player and Player.Backpack
  
  -- Check character (equipped)
  if plrChar then
    for _, tool in pairs(plrChar:GetChildren()) do
      if tool:IsA("Tool") and tool:FindFirstChild("Fruit") then
        return tool
      end
    end
  end
  -- Check backpack
  if plrBag then
    for _, tool in pairs(plrBag:GetChildren()) do
      if tool:IsA("Tool") and tool:FindFirstChild("Fruit") then
        return tool
      end
    end
  end
  
  return nil
end

-- ═══════════════════════════════════════════════════════════════
-- STORE FRUIT WITH 3 RETRIES (core feature)
-- Uses the same "StoreFruit" remote as REDZ HUB V2
-- Returns true if stored, false if all retries failed
-- ═══════════════════════════════════════════════════════════════
local function StoreFruitWithRetry(fruitTool)
  local maxRetries = getgenv().StoreRetries or 3
  local fruitId = Get_Fruit(fruitTool.Name)
  
  if not fruitId then
    Notify("❌ Unknown fruit: " .. fruitTool.Name, "error")
    return false
  end
  
  Notify("📦 Storing: " .. fruitTool.Name .. " (" .. fruitId .. ")", "action", true)
  
  for attempt = 1, maxRetries do
    Notify("📦 Store attempt " .. attempt .. "/" .. maxRetries .. "...", "warn", true)
    
    local success, result = pcall(function()
      return CommF:InvokeServer("StoreFruit", fruitId, fruitTool)
    end)
    
    if success and result == true then
      Notify("✅ STORED " .. fruitTool.Name .. " on attempt " .. attempt .. "!", "success", true)
      return true
    else
      Notify("❌ Attempt " .. attempt .. " failed: " .. tostring(result), "error")
      task.wait(1)
    end
  end
  
  Notify("⚠️ All " .. maxRetries .. " store attempts FAILED", "error", true)
  return false
end

-- ═══════════════════════════════════════════════════════════════
-- SEA DETECTION
-- Blox Fruits uses sub-places for each sea. The PlaceId changes
-- depending on which sea you are in. Using game.PlaceId with
-- TeleportService:Teleport() guarantees you stay in the SAME sea.
-- ═══════════════════════════════════════════════════════════════
local CurrentPlaceId = game.PlaceId
local CurrentSea = "Unknown"

-- Old Place IDs (legacy, for reference)
local OLD_SEA_IDS = {
  [2753915549] = "Sea 1",
  [4442272183] = "Sea 2",
  [7449423635] = "Sea 3"
}

-- Try to detect sea from old IDs first
if OLD_SEA_IDS[CurrentPlaceId] then
  CurrentSea = OLD_SEA_IDS[CurrentPlaceId]
else
  -- New/updated Place IDs — detect sea from in-game data
  -- The game knows which sea you're in via workspace markers
  pcall(function()
    local Locations = workspace:FindFirstChild("_WorldOrigin") and workspace._WorldOrigin:FindFirstChild("Locations")
    if Locations then
      -- Check for Sea 3 unique islands
      if Locations:FindFirstChild("Hydra Island") or Locations:FindFirstChild("Floating Turtle") or Locations:FindFirstChild("Castle on the Sea") then
        CurrentSea = "Sea 3"
      -- Check for Sea 2 unique islands
      elseif Locations:FindFirstChild("Kingdom of Rose") or Locations:FindFirstChild("Green Zone") or Locations:FindFirstChild("Graveyard") then
        CurrentSea = "Sea 2"
      -- Otherwise it's Sea 1
      else
        CurrentSea = "Sea 1"
      end
    end
  end)
  -- Fallback: check PlaceId magnitude (new IDs are much larger numbers)
  if CurrentSea == "Unknown" then
    CurrentSea = "Sea (ID: " .. CurrentPlaceId .. ")"
  end
end

print("[FruitSniper] 🌊 Detected: " .. CurrentSea .. " (PlaceId: " .. CurrentPlaceId .. ")")

-- ═══════════════════════════════════════════════════════════════
-- SERVER HOP (BLOX FRUITS NATIVE METHOD)
-- 
-- WHY ERROR 773 HAPPENED:
--   Blox Fruits actually RESTRICTS standard Roblox client-side 
--   teleportation (TeleportService) to prevent exploiters from 
--   bypassing server limits or joining restricted instances.
--
-- THE REAL FIX:
--   Blox Fruits has a built-in "Server Browser" GUI. We must use
--   their internal RemoteFunction ("__ServerBrowser") to request
--   a teleport to the JobId. The game's server will validate it
--   and teleport us safely, completely bypassing Error 773!
-- ═══════════════════════════════════════════════════════════════
local function ServerHop()
  Notify("🔄 Starting server hop loop...", "hop", true)
  
  -- Queue script to auto-execute after teleport
  pcall(function()
    local queueteleport = (syn and syn.queue_on_teleport) 
      or queue_on_teleport 
      or (fluxus and fluxus.queue_on_teleport)
    if queueteleport then
      queueteleport('loadstring(readfile("BloxFruit_AutoFruit.lua"))()')
      Notify("📋 Script queued for next server", "info")
    end
  end)
  
  -- Infinite retry loop
  while true do
    Notify("🔍 Searching " .. CurrentSea .. " servers...", "hop")
    
    -- We can use CurrentPlaceId because we are using the native ServerBrowser
    local apiUrl = "https://games.roblox.com/v1/games/" .. CurrentPlaceId .. "/servers/Public?sortOrder=Desc&excludeFullGames=true&limit=100"
    
    local function ListServers(cursor)
      local raw = game:HttpGet(apiUrl .. ((cursor and "&cursor=" .. cursor) or ""))
      return HttpService:JSONDecode(raw)
    end
    
    local Server, Next
    local pageAttempts = 0
    local maxPages = 5
    
    local apiSuccess = pcall(function()
      repeat task.wait(0.5)
        pageAttempts = pageAttempts + 1
        local Servers = ListServers(Next)
        
        if Servers and Servers.data then
          for _, server in pairs(Servers.data) do
            -- Skip current server, and skip full servers
            if server.id ~= game.JobId and server.playing and server.maxPlayers 
               and server.playing < (server.maxPlayers - 1) then
              Server = server
              break
            end
          end
          Next = Servers.nextPageCursor
        end
      until Server or not Next or pageAttempts >= maxPages
    end)
    
    if Server then
      Notify("🌐 Found server: " .. Server.playing .. "/" .. Server.maxPlayers, "success")
      Notify("✈️ Teleporting via __ServerBrowser...", "success", true)
      
      local teleportSuccess, teleportErr = pcall(function()
        -- THIS IS THE MAGIC FIX: Using Blox Fruits' own teleport remote!
        return game:GetService("ReplicatedStorage"):WaitForChild("__ServerBrowser"):InvokeServer("teleport", Server.id)
      end)
      
      if not teleportSuccess then
        Notify("⚠️ Native hop failed: " .. tostring(teleportErr), "error", true)
        Notify("🔄 Using fallback Teleport...", "warn")
        task.wait(2)
        pcall(function()
          TeleportService:TeleportToPlaceInstance(CurrentPlaceId, Server.id, Player)
        end)
        task.wait(5)
      else
        -- Teleport triggered successfully
        task.wait(15)
        Notify("⚠️ Still here? Retrying hop...", "warn", true)
      end
    else
      Notify("⚠️ API failed to find valid server.", "error", true)
      Notify("🔄 Using random Teleport fallback...", "warn")
      
      pcall(function()
        TeleportService:Teleport(CurrentPlaceId, Player)
      end)
      
      task.wait(15)
      Notify("🔄 Restarting hop process...", "warn", true)
    end
  end
end

-- ═══════════════════════════════════════════════════════════════
-- ANTI-AFK (same pattern as many exploit scripts)
-- ═══════════════════════════════════════════════════════════════
task.spawn(function()
  while getgenv().AntiAFK do task.wait(60)
    pcall(function()
      VirtualUser:CaptureController()
      VirtualUser:ClickButton2(Vector2.new())
    end)
  end
end)

-- ═══════════════════════════════════════════════════════════════
-- CHARACTER RESPAWN HANDLER
-- Waits for character to fully load after death/respawn
-- ═══════════════════════════════════════════════════════════════
local function WaitForCharacter()
  local char = Player.Character or Player.CharacterAdded:Wait()
  repeat task.wait()
  until char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Humanoid")
  task.wait(1) -- extra safety delay
  block.CFrame = char.HumanoidRootPart.CFrame
  return char
end

-- ═══════════════════════════════════════════════════════════════
-- ███  MAIN LOOP: SCAN → FLY → GRAB → STORE → HOP  ███
-- ═══════════════════════════════════════════════════════════════

-- Show startup success message
Notify("✅ Script Successfully Executed!", "success", true)
task.wait(0.5)
Notify("🌊 Sea: " .. CurrentSea, "info")
Notify("🆔 PlaceId: " .. tostring(CurrentPlaceId), "info")
Notify("⚡ Speed: " .. tostring(getgenv().TweenSpeed) .. " studs/sec", "info")
Notify("🔄 Store Retries: " .. tostring(getgenv().StoreRetries), "info")
Notify("👁️ ESP: " .. (getgenv().FruitESP and "ON" or "OFF"), "info")
Notify("──────────────────────────────", "info")
task.wait(1)

task.spawn(function()
  while getgenv().AutoFruitSniper do
    
    -- Make sure we have a character
    Notify("⏳ Waiting for character...", "info", true)
    WaitForCharacter()
    Notify("✅ Character loaded!", "success")
    
    -- ─────────────────────────────────────────────────
    -- PHASE 1: SCAN FOR FRUITS
    -- ─────────────────────────────────────────────────
    Notify("🔍 Scanning for fruits...", "action", true)
    local fruit = FruitFind()
    
    if fruit then
      -- A fruit exists in this server!
      local fruitHandle = fruit:FindFirstChild("Handle")
      Notify("🍎 FRUIT FOUND: " .. fruit.Name, "fruit", true)
      Notify("📍 Location: " .. tostring(fruitHandle.Position), "fruit")
      task.wait(0.5)
      
      -- ─────────────────────────────────────────────────
      -- PHASE 2: FLY TO THE FRUIT
      -- ─────────────────────────────────────────────────
      IsFarming = true
      Notify("✈️ Flying to " .. fruit.Name .. "...", "action", true)
      
      -- Tween to slightly above the fruit, then down to it
      local aboveFruit = CFrame.new(fruitHandle.Position + Vector3.new(0, 5, 0))
      TweenToPosition(aboveFruit)
      task.wait(0.3)
      Notify("📍 Approaching fruit...", "action")
      TweenToPosition(fruitHandle.CFrame)
      task.wait(0.5)
      Notify("✅ Arrived at fruit!", "success")
      
      -- ─────────────────────────────────────────────────
      -- PHASE 3: PICK UP THE FRUIT
      -- ─────────────────────────────────────────────────
      Notify("🤚 Grabbing " .. fruit.Name .. "...", "action", true)
      
      -- Touch the fruit by teleporting directly onto it
      local plrPP = Player.Character and Player.Character.PrimaryPart
      if plrPP and fruitHandle then
        for i = 1, 10 do
          if not fruit.Parent or fruit.Parent ~= workspace then
            Notify("✅ Fruit picked up!", "success")
            break
          end
          plrPP.CFrame = fruitHandle.CFrame
          block.CFrame = fruitHandle.CFrame
          task.wait(0.2)
        end
      end
      
      task.wait(1)
      
      -- ─────────────────────────────────────────────────
      -- PHASE 4: STORE THE FRUIT (3 retries)
      -- ─────────────────────────────────────────────────
      local inventoryFruit = FindFruitInInventory()
      
      if inventoryFruit then
        Notify("📦 Fruit in inventory! Storing...", "action", true)
        local stored = StoreFruitWithRetry(inventoryFruit)
        
        if stored then
          Notify("✅ Fruit stored successfully!", "success", true)
        else
          Notify("⚠️ Store failed after 3 tries. Hopping anyway...", "warn", true)
        end
      else
        -- Retry once more
        task.wait(0.5)
        local retryFruit = FindFruitInInventory()
        if retryFruit then
          Notify("📦 Found fruit on retry! Storing...", "action")
          StoreFruitWithRetry(retryFruit)
        else
          Notify("⚠️ Fruit not in inventory. Pickup may have failed.", "warn", true)
        end
      end
      
      IsFarming = false
      
      -- ─────────────────────────────────────────────────
      -- PHASE 5: SERVER HOP
      -- ─────────────────────────────────────────────────
      Notify("⏳ Hopping in " .. getgenv().HopDelay .. "s...", "hop", true)
      task.wait(getgenv().HopDelay)
      ServerHop()
      
      task.wait(9e9)
      
    else
      -- ─────────────────────────────────────────────────
      -- NO FRUIT FOUND → SERVER HOP
      -- ─────────────────────────────────────────────────
      Notify("❌ No fruit found in this server", "error", true)
      Notify("⏳ Hopping in " .. getgenv().HopDelay .. "s...", "hop")
      task.wait(getgenv().HopDelay)
      ServerHop()
      
      task.wait(9e9)
    end
  end
end)

-- ═══════════════════════════════════════════════════════════════
-- CLEANUP ON SCRIPT STOP
-- ═══════════════════════════════════════════════════════════════
Player.CharacterRemoving:Connect(function()
  IsFarming = false
end)

Notify("🚀 Auto Fruit Sniper is RUNNING!", "success")
