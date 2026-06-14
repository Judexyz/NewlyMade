local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

local Window = Fluent:CreateWindow({
    Title = "Testing UI",
    SubTitle = "Remote Tester",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Dark"
})

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

local NpcRemoteEvent = ReplicatedStorage:WaitForChild("NpcRemoteEvent")

-- ============================================
-- MAIN TAB
-- ============================================
local MainTab = Window:AddTab({ Title = "Main", Icon = "sword" })

local AutoTrain = {
    Strength = false,
    Durability = false,
    Psychic = false,
    Energy = false
}

local function startAutoTrain(statName)
    task.spawn(function()
        while AutoTrain[statName] do
            local args = { statName }
            ReplicatedStorage:WaitForChild("Remote"):WaitForChild("Training"):WaitForChild("Train"):FireServer(unpack(args))
            task.wait(0.1)
        end
    end)
end

MainTab:AddToggle("AutoStrength", {
    Title = "Auto Strength",
    Default = false,
    Callback = function(Value)
        AutoTrain.Strength = Value
        if Value then startAutoTrain("Strength") end
    end
})

MainTab:AddToggle("AutoDurability", {
    Title = "Auto Durability",
    Default = false,
    Callback = function(Value)
        AutoTrain.Durability = Value
        if Value then startAutoTrain("Durability") end
    end
})

MainTab:AddToggle("AutoPsychic", {
    Title = "Auto Psychic",
    Default = false,
    Callback = function(Value)
        AutoTrain.Psychic = Value
        if Value then startAutoTrain("Psychic") end
    end
})

MainTab:AddToggle("AutoEnergy", {
    Title = "Auto Energy",
    Default = false,
    Callback = function(Value)
        AutoTrain.Energy = Value
        if Value then startAutoTrain("Energy") end
    end
})

-- ============================================
-- TELEPORT TAB
-- ============================================
local TeleportTab = Window:AddTab({ Title = "Teleport", Icon = "map-pin" })

local teleportLocations = {
    { Title = "Teleport to Spawn", CFrame = CFrame.new(-62.8898811340332, 4124.103515625, -281.61328125) },
    { Title = "Teleport to Strength x5", CFrame = CFrame.new(-130.37973022460938, 4123.4755859375, -197.55227661132812) },
    { Title = "Teleport to Strength x10", CFrame = CFrame.new(-164.88043212890625, 4160.943359375, -654.781005859375) },
    { Title = "Teleport to Strength x20", CFrame = CFrame.new(-89.26599884033203, 4106.9560546875, -1115.471923828125) },
    { Title = "Teleport to Durability x5", CFrame = CFrame.new(-89.00398254394531, 4124.09326171875, -505.293212890625) },
    { Title = "Teleport to Durability x10", CFrame = CFrame.new(154.11917114257812, 4105.09814453125, -795.0398559570312) },
    { Title = "Teleport to Psychic x5", CFrame = CFrame.new(-345.4157409667969, 4133.87451171875, -496.7674255371094) },
}

for _, loc in ipairs(teleportLocations) do
    TeleportTab:AddButton({
        Title = loc.Title,
        Callback = function()
            local char = player.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                char.HumanoidRootPart.CFrame = loc.CFrame
            end
        end
    })
end

-- ============================================
-- KILL AURA TAB
-- ============================================
local KillAuraTab = Window:AddTab({ Title = "Kill Aura", Icon = "crosshair" })

local KillAura = {
    Enabled = false,
    Range = 50,
    Interval = 0.1,
    MaxTargets = 3,
    lastAttack = 0,
    Debug = false
}

local npcList = {}

local StatusParagraph = KillAuraTab:AddParagraph({
    Title = "Status",
    Content = "Ready"
})

KillAuraTab:AddToggle("KillAuraToggle", {
    Title = "Enable Kill Aura",
    Default = false,
    Callback = function(Value)
        KillAura.Enabled = Value
        StatusParagraph:SetTitle("Status: " .. (Value and "Active" or "Idle"))
    end
})

KillAuraTab:AddSlider("KillAuraRange", {
    Title = "Range",
    Description = "Attack range in studs",
    Default = 50,
    Min = 10,
    Max = 200,
    Rounding = 0,
    Callback = function(Value)
        KillAura.Range = Value
    end
})

KillAuraTab:AddSlider("KillAuraInterval", {
    Title = "Attack Interval",
    Description = "Seconds between attacks",
    Default = 0.1,
    Min = 0.05,
    Max = 2,
    Rounding = 2,
    Callback = function(Value)
        KillAura.Interval = Value
    end
})

KillAuraTab:AddSlider("KillAuraMaxTargets", {
    Title = "Max Targets",
    Description = "NPCs to hit per cycle",
    Default = 3,
    Min = 1,
    Max = 5,
    Rounding = 0,
    Callback = function(Value)
        KillAura.MaxTargets = Value
    end
})

KillAuraTab:AddToggle("KillAuraDebug", {
    Title = "Debug Mode",
    Default = false,
    Callback = function(Value)
        KillAura.Debug = Value
    end
})

KillAuraTab:AddButton({
    Title = "Scan NPCs",
    Description = "Check tracked NPCs",
    Callback = function()
        StatusParagraph:SetTitle("Tracking " .. #npcList .. " NPCs")
        for _, npc in ipairs(npcList) do
            print(string.format("[KillAura] %s | npcId: %s | Health: %s",
                npc.Name, tostring(npc:GetAttribute("npcId")), tostring(npc.Humanoid.Health)))
        end
    end
})

local function isValidNPC(obj)
    return obj:IsA("Model")
        and obj ~= character
        and obj:FindFirstChild("Humanoid")
        and obj:FindFirstChild("HumanoidRootPart")
        and obj:GetAttribute("npcId") ~= nil
end

local function addNPC(obj)
    if not isValidNPC(obj) then return end
    for _, existing in ipairs(npcList) do
        if existing == obj then return end
    end
    table.insert(npcList, obj)
    if KillAura.Debug then print("[KillAura] Added:", obj.Name, "| npcId:", obj:GetAttribute("npcId")) end
end

local function removeNPC(obj)
    for i, npc in ipairs(npcList) do
        if npc == obj then
            table.remove(npcList, i)
            if KillAura.Debug then print("[KillAura] Removed:", obj.Name) end
            break
        end
    end
end

local function cleanDeadNPCs()
    for i = #npcList, 1, -1 do
        local npc = npcList[i]
        if not npc.Parent or not npc:FindFirstChild("Humanoid") or npc.Humanoid.Health <= 0 then
            table.remove(npcList, i)
        end
    end
end

task.spawn(function()
    local descendants = workspace:GetDescendants()
    local batchSize = 100
    for i = 1, #descendants, batchSize do
        for j = i, math.min(i + batchSize - 1, #descendants) do
            addNPC(descendants[j])
        end
        RunService.Heartbeat:Wait()
    end
    print("[KillAura] Initial scan complete | NPCs:", #npcList)
end)

workspace.DescendantAdded:Connect(addNPC)
workspace.DescendantRemoving:Connect(removeNPC)

function getNearbyNPCs()
    local nearby = {}
    if not humanoidRootPart then return nearby end

    local rootPos = humanoidRootPart.Position

    for _, npc in ipairs(npcList) do
        local hrp = npc:FindFirstChild("HumanoidRootPart")
        local humanoid = npc:FindFirstChild("Humanoid")
        if not hrp or not humanoid or humanoid.Health <= 0 then continue end

        local dist = (hrp.Position - rootPos).Magnitude
        if dist <= KillAura.Range then
            table.insert(nearby, {
                Model = npc,
                HRP = hrp,
                Distance = dist,
                Id = npc:GetAttribute("npcId")
            })
        end
    end

    table.sort(nearby, function(a, b) return a.Distance < b.Distance end)
    return nearby
end

function attackNPC(npcData)
    local dir = (npcData.HRP.Position - humanoidRootPart.Position).Unit
    if dir.Magnitude == 0 then dir = Vector3.new(0, 0, -1) end

    local args = {
        {
            npcId = npcData.Id,
            id = "NpcHit",
            dir = Vector3.new(dir.X, 0, dir.Z)
        }
    }

    NpcRemoteEvent:FireServer(unpack(args))

    if KillAura.Debug then
        print(string.format("[KillAura] HIT %s | npcId:%s | Dist:%.1f",
            npcData.Model.Name, tostring(npcData.Id), npcData.Distance))
    end
end

RunService.Heartbeat:Connect(function()
    if not KillAura.Enabled then return end
    if not humanoidRootPart then return end

    local now = tick()
    if now - KillAura.lastAttack < KillAura.Interval then return end

    cleanDeadNPCs()
    local npcs = getNearbyNPCs()

    if #npcs == 0 then
        if KillAura.Debug then StatusParagraph:SetTitle("Status: No targets in range") end
        return
    end

    local hitCount = 0
    for i = 1, math.min(KillAura.MaxTargets, #npcs) do
        attackNPC(npcs[i])
        hitCount = hitCount + 1
    end

    KillAura.lastAttack = now
    StatusParagraph:SetTitle(string.format("Status: Hit %d NPC%s", hitCount, hitCount == 1 and "" or "s"))
end)

player.CharacterAdded:Connect(function(newChar)
    character = newChar
    humanoidRootPart = newChar:WaitForChild("HumanoidRootPart", 3)
end)

print("[KillAura] Loaded | Fluent UI | Event-driven tracking")

-- ============================================
-- MISC TAB
-- ============================================
local MISCTab = Window:AddTab({ Title = "MISC", Icon = "settings" })

-- NoClip
local Noclip = false
local noclipConnection

MISCTab:AddToggle("NoClip", {
    Title = "No Clip",
    Default = false,
    Callback = function(Value)
        Noclip = Value
        
        if Noclip then
            noclipConnection = RunService.Stepped:Connect(function()
                if not player.Character then return end
                for _, part in pairs(player.Character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end)
        else
            if noclipConnection then
                noclipConnection:Disconnect()
                noclipConnection = nil
            end
            if player.Character then
                for _, part in pairs(player.Character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = true
                    end
                end
            end
        end
    end
})

-- Select first tab
Window:SelectTab(1)