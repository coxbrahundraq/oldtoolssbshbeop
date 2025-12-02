

-- load Rayfield
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

-- create Window
local Window = Rayfield:CreateWindow({
    Name = "sbs Hbe menu",
    LoadingTitle = "Loading...",
    LoadingSubtitle = "best hbe ever",
    ConfigurationSaving = { Enabled = false },
    KeySystem = false,
    Theme = "Sirius"
})

-- Tabs
local SbsTab = Window:CreateTab("SBS Features")
local MiscTab = Window:CreateTab("Misc")

--// ⚽ Ball Resize
local function ResizeBalls(size)
    for _, ball in pairs(workspace:GetChildren()) do
        if ball:IsA("BasePart") and ball.Name == "Ball" then
            ball.Size = size
        end
    end
end

local BallConnection
local function WatchBalls(size)
    if BallConnection then BallConnection:Disconnect() end
    BallConnection = workspace.ChildAdded:Connect(function(child)
        if child:IsA("BasePart") and child.Name == "Ball" then
            child.Size = size
        end
    end)
end

SbsTab:CreateInput({
    Name = "Ball HBE (Custom Size)",
    PlaceholderText = "Enter size as X,Y,Z (e.g. 250,50,2)",
    RemoveTextAfterFocusLost = false,
    Callback = function(input)
        local rs = game.ReplicatedStorage
        if rs:FindFirstChild("PrivateServerRemotes") and rs.PrivateServerRemotes:FindFirstChild("ls") then
            rs.PrivateServerRemotes.ls.Value = true
        end
        if rs:FindFirstChild("AntiCheatTrigger") then
            rs.AntiCheatTrigger:Destroy()
        end

        local x, y, z = input:match("(%d+),(%d+),(%d+)")
        if x and y and z then
            local customSize = Vector3.new(tonumber(x), tonumber(y), tonumber(z))
            ResizeBalls(customSize)
            WatchBalls(customSize)
        else
            warn(" Invalid input format. Use X,Y,Z like 250,50,2")
        end
    end
})

SbsTab:CreateButton({
    Name = "Reset Ball Size",
    Callback = function()
        local defaultSize = Vector3.new(2, 2, 2)
        ResizeBalls(defaultSize)
        WatchBalls(defaultSize)
    end
})

--// limb arm hbe
local function resizeArms(char, size, transparency)
    if not char then return end

    -- Detect rig type
    local rightArm = char:FindFirstChild("Right Arm") or char:FindFirstChild("RightHand")
    local leftArm  = char:FindFirstChild("Left Arm")  or char:FindFirstChild("LeftHand")

    -- defensive: avoid zero dimensions
    if size.X <= 0 or size.Y <= 0 or size.Z <= 0 then
        warn("❌ Invalid arm size: " .. tostring(size))
        return
    end

    -- Aaply changes
    if rightArm and rightArm:IsA("BasePart") then
        rightArm.Size = size
        rightArm.Transparency = transparency
        print("✅ Right arm resized to", size)
    end
    if leftArm and leftArm:IsA("BasePart") then
        leftArm.Size = size
        leftArm.Transparency = transparency
        print("✅ Left arm resized to", size)
    end
end

-- arm HBE Button
SbsTab:CreateButton({
    Name = "ARM HBE",
    Callback = function()
        local player = game.Players.LocalPlayer
        local targetSize = Vector3.new(6, 6, 0.05) -- fixed Z dimension
        local transparency = 0.7

        if player.Character then
            resizeArms(player.Character, targetSize, transparency)
        end

        player.CharacterAdded:Connect(function(newChar)
            resizeArms(newChar, targetSize, transparency)
        end)
    end
})

-- reset Arms Button
SbsTab:CreateButton({
    Name = "Reset Arms",
    Callback = function()
        local player = game.Players.LocalPlayer
        local defaultSize = Vector3.new(1, 2, 1)
        local transparency = 0

        if player.Character then
            resizeArms(player.Character, defaultSize, transparency)
        end

        player.CharacterAdded:Connect(function(newChar)
            resizeArms(newChar, defaultSize, transparency)
        end)
    end
})

--// time Control Slider
SbsTab:CreateSlider({
    Name = "Set Time of Day",
    Range = {0, 24},
    Increment = 0.5,
    Suffix = "Hour",
    CurrentValue = 14,
    Callback = function(value)
        local hour = math.floor(value)
        local minute = math.floor((value - hour) * 60)
        local timeString = string.format("%02d:%02d:00", hour, minute)
        game.Lighting.TimeOfDay = timeString
    end
})

--// gravity Ball Slider (0–500 + Default Info)
SbsTab:CreateSlider({
    Name = "Gravity Ball (0–500)",
    Range = {0, 500},
    Increment = 10,
    Suffix = "Gravity",
    CurrentValue = workspace.Gravity,
    Callback = function(value)
        workspace.Gravity = value
        print("🌍 Gravity set to:", value)
        if value == 196.2 then
            print("✅ This is Roblox's default gravity.")
        elseif value < 196.2 then
            print("🪐 Lower than normal — expect floaty physics!")
        elseif value > 196.2 then
            print("💥 Higher than normal — expect heavy impacts!")
        end
    end
})

--// toggleable Anti-Collision (Fixed for heads + accessories)
local AntiCollisionEnabled = false
local Player = game.Players.LocalPlayer
local Connections = {}

local function noCollide(part1, part2)
    if part1:IsA("BasePart") and part2:IsA("BasePart") then
        -- Prevent duplicates
        for _, child in pairs(part1:GetChildren()) do
            if child:IsA("NoCollisionConstraint") and child.Part0 == part1 and child.Part1 == part2 then
                return
            end
        end
        local ncc = Instance.new("NoCollisionConstraint")
        ncc.Part0 = part1
        ncc.Part1 = part2
        ncc.Parent = part1
    end
end

local function getCollisionParts(char)
    local parts = {}
    for _, obj in pairs(char:GetDescendants()) do
        if obj:IsA("BasePart") then
            table.insert(parts, obj)
        elseif obj:IsA("Accessory") and obj:FindFirstChild("Handle") then
            table.insert(parts, obj.Handle)
        end
    end
    return parts
end

local function applyAntiCollision(char)
    local myParts = getCollisionParts(char)
    for _, otherPlayer in pairs(game.Players:GetPlayers()) do
        if otherPlayer ~= Player and otherPlayer.Character then
            local theirParts = getCollisionParts(otherPlayer.Character)
            for _, myPart in pairs(myParts) do
                for _, theirPart in pairs(theirParts) do
                    noCollide(myPart, theirPart)
                end
            end
        end
    end
end

local function removeAntiCollision(char)
    for _, part in pairs(getCollisionParts(char)) do
        for _, child in pairs(part:GetChildren()) do
            if child:IsA("NoCollisionConstraint") then
                child:Destroy()
            end
        end
    end
end

SbsTab:CreateToggle({
    Name = "Walk Through Players",
    CurrentValue = false,
    Callback = function(state)
        AntiCollisionEnabled = state
        if state then
            if Player.Character then applyAntiCollision(Player.Character) end
            table.insert(Connections, Player.CharacterAdded:Connect(function(char)
                task.wait(1)
                applyAntiCollision(char)
            end))
        else
            if Player.Character then removeAntiCollision(Player.Character) end
            for _, conn in pairs(Connections) do
                conn:Disconnect()
            end
            Connections = {}
        end
    end
})

--// 🛠 misc
MiscTab:CreateButton({
    Name = "Disable Bubble Chat",
    Callback = function()
        local TextChatService = game:GetService("TextChatService")
        if TextChatService and TextChatService.BubbleChatConfiguration then
            TextChatService.BubbleChatConfiguration.Enabled = false
        end

        local ChatService = game:GetService("Chat")
        local bubbleChat = ChatService:FindFirstChild("BubbleChat")
        if bubbleChat then bubbleChat.Enabled = false end

        local pg = game.Players.LocalPlayer:WaitForChild("PlayerGui")
        local bubbleGui = pg:FindFirstChild("BubbleChat")
        if bubbleGui then bubbleGui.Enabled = false end
    end
})
