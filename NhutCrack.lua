-- ==================== LOAD RAYFIELD UI ====================
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

-- ==================== WINDOW ====================
local Window = Rayfield:CreateWindow({
    Name = "NhutCrack",
    LoadingTitle = "ĐỤ MẸ CHỜ XÍU ĐI",
    LoadingSubtitle = "by NhutDZ",
    ConfigurationSaving = {Enabled = true, FolderName = "NhutCrack", FileName = "Settings"}
})

local MainTab = Window:CreateTab("Main", 4483362458)
local PlayersTab = Window:CreateTab("Players", 4483362458)
local VisualTab = Window:CreateTab("Visual", 4483362458) -- Gộp ESP & Hitbox

-- ==================== SETTINGS ====================
local Settings = {
    ESP = {Enabled = false, Tracers = true, Distance = true, TeamCheck = false},
    Hitbox = {Enabled = false, Size = 12, TeamCheck = false, OriginalSizes = {}},
    Aim = {Enabled = false, TeamCheck = false, Part = "HumanoidRootPart", Fov = 150, FovVisible = true, Smoothness = 1, IsTargeting = false},
    Speed = {Enabled = false, Value = 16},
    Fly = {Enabled = false, Speed = 80},
    Jump = {Enabled = false, Value = 50}
}

local FOLDER_NAME = "NhutESP"
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- FOV Circle
local FovCircle = Drawing.new("Circle")
FovCircle.Color = Color3.fromRGB(255, 0, 0)
FovCircle.Thickness = 1.5
FovCircle.NumSides = 64
FovCircle.Filled = false

-- ==================== FLY LOGIC - NEW ====================
local flying = false
local bv = nil
local bg = nil
local flyLoop = nil

local function StartFly()
    if flying then 
        StopFly()
        task.wait(0.1)
    end
    
    local char = LocalPlayer.Character
    if not char then
        task.wait(0.5)
        char = LocalPlayer.Character
        if not char then 
            warn("Không tìm thấy Character!")
            return 
        end
    end
    
    local hum = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    
    if not hum or not hrp then 
        warn("Không tìm thấy Humanoid hoặc HumanoidRootPart!")
        return 
    end
    
    print("🚀 BẬT FLY - Đang bay...")
    
    flying = true
    
    -- Tạo BodyVelocity
    bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    bv.Parent = hrp
    
    -- Tạo BodyGyro
    bg = Instance.new("BodyGyro")
    bg.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    bg.P = 10000
    bg.Parent = hrp
    
    -- Noclip
    hrp.CanCollide = false
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") and part ~= hrp then
            part.CanCollide = false
        end
    end
    
    -- Fly loop
    flyLoop = RunService.RenderStepped:Connect(function()
        if not Settings.Fly.Enabled then
            StopFly()
            return
        end
        
        local char = LocalPlayer.Character
        if not char or not char.Parent then
            StopFly()
            return
        end
        
        local hum = char:FindFirstChildOfClass("Humanoid")
        local hrp = char:FindFirstChild("HumanoidRootPart")
        
        if not hum or not hrp or not bv or not bg then
            StopFly()
            return
        end
        
        local cam = workspace.CurrentCamera
        local move = hum.MoveDirection
        
        bg.CFrame = cam.CFrame
        
        if move.Magnitude > 0 then
            local direction = Vector3.new(move.X, cam.CFrame.LookVector.Y, move.Z)
            bv.Velocity = direction.Unit * Settings.Fly.Speed
        else
            bv.Velocity = Vector3.zero
        end
        
        -- Giữ noclip
        hrp.CanCollide = false
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") and part ~= hrp then
                part.CanCollide = false
            end
        end
    end)
end

local function StopFly()
    if not flying then return end
    print("🛑 TẮT FLY")
    
    flying = false
    
    if flyLoop then
        flyLoop:Disconnect()
        flyLoop = nil
    end
    
    local char = LocalPlayer.Character
    if char then
        local hrp = char:FindFirstChild("HumanoidRootPart")
        
        if bv then
            bv:Destroy()
            bv = nil
        end
        
        if bg then
            bg:Destroy()
            bg = nil
        end
        
        if hrp then
            hrp.CanCollide = true
            hrp.Velocity = Vector3.new(0, 0, 0)
            hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        end
        
        -- Reset collision
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = true
            end
        end
    end
end

-- Xử lý respawn
LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(1)
    if Settings.Fly.Enabled then
        StartFly()
    end
end)

LocalPlayer.CharacterRemoving:Connect(function()
    StopFly()
end)

-- ==================== UTILITY ====================
local function GetLocalRoot()
    local char = LocalPlayer.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function GetRoot(character)
    return character and character:FindFirstChild("HumanoidRootPart")
end

local function IsTeammate(plr)
    if not Settings.ESP.TeamCheck and not Settings.Hitbox.TeamCheck and not Settings.Aim.TeamCheck then return false end
    if not plr or not LocalPlayer then return false end
    return LocalPlayer.Team == plr.Team and LocalPlayer.Team ~= nil
end

-- ==================== SPEED & JUMP LOGIC ====================
task.spawn(function()
    while task.wait(0.1) do
        pcall(function()
            local char = LocalPlayer.Character
            local humanoid = char and char:FindFirstChildOfClass("Humanoid")
            if humanoid and not Settings.Fly.Enabled then
                -- Speed
                if Settings.Speed.Enabled then
                    humanoid.WalkSpeed = Settings.Speed.Value
                elseif humanoid.WalkSpeed ~= 16 then
                    humanoid.WalkSpeed = 16
                end
                
                -- Jump
                if Settings.Jump.Enabled then
                    humanoid.JumpPower = Settings.Jump.Value
                elseif humanoid.JumpPower ~= 50 then
                    humanoid.JumpPower = 50
                end
            end
        end)
    end
end)

-- ==================== AIMBOT LOGIC ====================
local function GetClosestPlayerToCenter()
    local closestPlayer = nil
    local shortestDistance = Settings.Aim.Fov
    local centerScreen = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and not IsTeammate(plr) then
            local targetPart = plr.Character:FindFirstChild(Settings.Aim.Part)
            local humanoid = plr.Character:FindFirstChildOfClass("Humanoid")
            
            if targetPart and humanoid and humanoid.Health > 0 then
                local pos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                if onScreen then
                    local distance = (Vector2.new(pos.X, pos.Y) - centerScreen).Magnitude
                    if distance < shortestDistance then
                        closestPlayer = plr
                        shortestDistance = distance
                    end
                end
            end
        end
    end
    return closestPlayer
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        Settings.Aim.IsTargeting = true
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        Settings.Aim.IsTargeting = false
    end
end)

RunService.RenderStepped:Connect(function()
    local centerScreen = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    FovCircle.Visible = Settings.Aim.Enabled and Settings.Aim.FovVisible
    FovCircle.Radius = Settings.Aim.Fov
    FovCircle.Position = centerScreen
end)

RunService:BindToRenderStep("NhutAimbotForce", Enum.RenderPriority.Camera.Value + 1, function()
    if Settings.Aim.Enabled and Settings.Aim.IsTargeting then
        local targetPlr = GetClosestPlayerToCenter()
        if targetPlr and targetPlr.Character then
            local targetPart = targetPlr.Character:FindFirstChild(Settings.Aim.Part)
            if targetPart then
                local currentCFrame = Camera.CFrame
                local targetCFrame = CFrame.lookAt(currentCFrame.Position, targetPart.Position)
                Camera.CFrame = currentCFrame:Lerp(targetCFrame, 1 / Settings.Aim.Smoothness)
            end
        end
    end
end)

-- ==================== CLEANUP ====================
local function CleanupPlayer(plr)
    if plr.Character and plr.Character:FindFirstChild(FOLDER_NAME) then
        plr.Character[FOLDER_NAME]:Destroy()
    end
    Settings.Hitbox.OriginalSizes[plr] = nil
end

-- ==================== HITBOX ====================
local function ApplyHitbox(character, plr)
    if not character or not plr or plr == LocalPlayer then return end
    local root = GetRoot(character)
    if not root then return end
    
    if not Settings.Hitbox.OriginalSizes[plr] then
        Settings.Hitbox.OriginalSizes[plr] = root.Size
    end
    
    if Settings.Hitbox.Enabled and not (Settings.Hitbox.TeamCheck and IsTeammate(plr)) then
        root.Size = Vector3.new(Settings.Hitbox.Size, Settings.Hitbox.Size, Settings.Hitbox.Size)
        root.Transparency = 0.6
        root.CanCollide = false
        root.Color = Color3.fromRGB(255, 0, 0)
    else
        if Settings.Hitbox.OriginalSizes[plr] then
            root.Size = Settings.Hitbox.OriginalSizes[plr]
        end
        root.Transparency = 1
        root.CanCollide = true
        root.Color = Color3.fromRGB(27, 42, 53)
    end
end

local function UpdateAllHitboxes()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr.Character then ApplyHitbox(plr.Character, plr) end
    end
end

-- ==================== ESP ====================
local function CreateESP(plr)
    if plr == LocalPlayer then return end
    
    local function Apply(character)
        if not character or not Settings.ESP.Enabled then return end
        if Settings.ESP.TeamCheck and IsTeammate(plr) then return end
        
        local root = GetRoot(character)
        if not root then return end
        
        if character:FindFirstChild(FOLDER_NAME) then character[FOLDER_NAME]:Destroy() end
        local folder = Instance.new("Folder", character)
        folder.Name = FOLDER_NAME
        
        local highlight = Instance.new("Highlight", folder)
        highlight.Adornee = character
        highlight.FillColor = Color3.fromRGB(255, 0, 0)
        highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
        highlight.FillTransparency = 0.5
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        
        if Settings.ESP.Tracers then
            local line = Instance.new("LineHandleAdornment", folder)
            line.Name = "TracerLine"
            line.Thickness = 3
            line.Color3 = Color3.fromRGB(255, 0, 0)
            line.AlwaysOnTop = true
            line.Adornee = workspace
        end
        
        if Settings.ESP.Distance then
            local billboard = Instance.new("BillboardGui", folder)
            billboard.Adornee = root
            billboard.Size = UDim2.new(0, 120, 0, 30)
            billboard.StudsOffset = Vector3.new(0, 3, 0)
            billboard.AlwaysOnTop = true
            
            local label = Instance.new("TextLabel", billboard)
            label.Size = UDim2.new(1, 0, 1, 0)
            label.BackgroundTransparency = 1
            label.TextColor3 = Color3.new(1, 1, 1)
            label.TextStrokeTransparency = 0
            label.TextSize = 14
            label.Font = Enum.Font.GothamBold
            label.Text = "[0]"
            label.Name = "DistanceLabel"
        end
    end
    
    if plr.Character then Apply(plr.Character) end
    plr.CharacterAdded:Connect(function(char)
        task.wait(0.5)
        Apply(char)
        UpdateAllHitboxes()
    end)
end

RunService.RenderStepped:Connect(function()
    local myRoot = GetLocalRoot()
    if not myRoot then return end
    
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local folder = plr.Character:FindFirstChild(FOLDER_NAME)
            local root = GetRoot(plr.Character)
            
            if folder and root then
                if Settings.ESP.Enabled and Settings.ESP.Distance then
                    local label = folder:FindFirstChild("DistanceLabel", true)
                    if label then
                        label.Text = string.format("[%d]", math.floor((root.Position - myRoot.Position).Magnitude))
                    end
                end
                
                local line = folder:FindFirstChild("TracerLine")
                if line and line:IsA("LineHandleAdornment") then
                    if Settings.ESP.Enabled and Settings.ESP.Tracers then
                        local startPos = myRoot.Position - Vector3.new(0, 2, 0)
                        line.CFrame = CFrame.new(startPos, root.Position)
                        line.Length = (root.Position - startPos).Magnitude
                    else
                        line.Length = 0
                    end
                end
            end
        end
    end
end)

task.spawn(function()
    while task.wait(0.3) do
        if Settings.Hitbox.Enabled then UpdateAllHitboxes() end
    end
end)

Players.PlayerAdded:Connect(function(plr)
    CreateESP(plr)
    plr.CharacterAdded:Connect(function() task.wait(0.5) UpdateAllHitboxes() end)
end)
Players.PlayerRemoving:Connect(CleanupPlayer)

-- ==================== UI ====================
-- TAB MAIN
MainTab:CreateToggle({
    Name = "Fly", 
    CurrentValue = false, 
    Callback = function(v)
        Settings.Fly.Enabled = v
        if v then
            StartFly()
        else
            StopFly()
        end
    end
})

MainTab:CreateSlider({
    Name = "Fly Speed", 
    Range = {10, 250}, 
    Increment = 5, 
    CurrentValue = 80, 
    Callback = function(v)
        Settings.Fly.Speed = v
    end
})

-- TAB PLAYERS
PlayersTab:CreateToggle({
    Name = "Speed Hack", 
    CurrentValue = false, 
    Callback = function(v)
        Settings.Speed.Enabled = v
        local char = LocalPlayer.Character
        local humanoid = char and char:FindFirstChildOfClass("Humanoid")
        if humanoid and not Settings.Fly.Enabled then
            humanoid.WalkSpeed = v and Settings.Speed.Value or 16
        end
    end
})

PlayersTab:CreateSlider({
    Name = "Speed Value", 
    Range = {16, 250}, 
    Increment = 1, 
    CurrentValue = 16, 
    Callback = function(v)
        Settings.Speed.Value = v
        local char = LocalPlayer.Character
        local humanoid = char and char:FindFirstChildOfClass("Humanoid")
        if humanoid and Settings.Speed.Enabled and not Settings.Fly.Enabled then
            humanoid.WalkSpeed = v
        end
    end
})

PlayersTab:CreateToggle({
    Name = "Jump Hack", 
    CurrentValue = false, 
    Callback = function(v)
        Settings.Jump.Enabled = v
        local char = LocalPlayer.Character
        local humanoid = char and char:FindFirstChildOfClass("Humanoid")
        if humanoid and not Settings.Fly.Enabled then
            humanoid.JumpPower = v and Settings.Jump.Value or 50
        end
    end
})

PlayersTab:CreateSlider({
    Name = "Jump Power", 
    Range = {50, 500}, 
    Increment = 5, 
    CurrentValue = 50, 
    Callback = function(v)
        Settings.Jump.Value = v
        local char = LocalPlayer.Character
        local humanoid = char and char:FindFirstChildOfClass("Humanoid")
        if humanoid and Settings.Jump.Enabled and not Settings.Fly.Enabled then
            humanoid.JumpPower = v
        end
    end
})

-- TAB VISUAL (ESP + HITBOX)
VisualTab:CreateToggle({
    Name = "ESP", 
    CurrentValue = false, 
    Callback = function(v)
        Settings.ESP.Enabled = v
        for _, plr in ipairs(Players:GetPlayers()) do
            if not v and plr.Character and plr.Character:FindFirstChild(FOLDER_NAME) then 
                plr.Character[FOLDER_NAME]:Destroy() 
            else 
                CreateESP(plr) 
            end
        end
    end
})

VisualTab:CreateToggle({
    Name = "Team Check (ESP)", 
    CurrentValue = false, 
    Callback = function(v) 
        Settings.ESP.TeamCheck = v 
    end
})

VisualTab:CreateToggle({
    Name = "Distance ESP", 
    CurrentValue = true, 
    Callback = function(v) 
        Settings.ESP.Distance = v 
    end
})

VisualTab:CreateToggle({
    Name = "Tracers", 
    CurrentValue = true, 
    Callback = function(v) 
        Settings.ESP.Tracers = v 
    end
})

VisualTab:CreateToggle({
    Name = "Hitbox Expander", 
    CurrentValue = false, 
    Callback = function(v) 
        Settings.Hitbox.Enabled = v 
        UpdateAllHitboxes() 
    end
})

VisualTab:CreateSlider({
    Name = "Hitbox Size", 
    Range = {5, 100}, 
    Increment = 1, 
    CurrentValue = 12, 
    Callback = function(v) 
        Settings.Hitbox.Size = v 
        if Settings.Hitbox.Enabled then 
            UpdateAllHitboxes() 
        end 
    end
})

VisualTab:CreateToggle({
    Name = "Hitbox Team Check", 
    CurrentValue = false, 
    Callback = function(v) 
        Settings.Hitbox.TeamCheck = v 
        UpdateAllHitboxes() 
    end
})

-- ==================== AIM GUI ====================
local fov = 136
local FOVring = Drawing.new("Circle")
FOVring.Visible = false
FOVring.Thickness = 2
FOVring.Color = Color3.fromRGB(128, 0, 128)
FOVring.Filled = false
FOVring.Radius = fov
FOVring.Position = Camera.ViewportSize / 2

local isAiming = false
local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Exclude

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Parent = game.CoreGui

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 150, 0, 95)
MainFrame.Position = UDim2.new(0, 10, 0, 10)
MainFrame.BackgroundTransparency = 1
MainFrame.Parent = ScreenGui

local ToggleButton = Instance.new("TextButton")
ToggleButton.Size = UDim2.new(1, 0, 0, 40)
ToggleButton.Position = UDim2.new(0, 0, 0, 0)
ToggleButton.Text = "AIM PLAYER: OFF"
ToggleButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
ToggleButton.TextColor3 = Color3.fromRGB(255, 50, 50)
ToggleButton.Font = Enum.Font.GothamBold
ToggleButton.TextSize = 14
ToggleButton.Parent = MainFrame

local SliderBackground = Instance.new("Frame")
SliderBackground.Size = UDim2.new(1, 0, 0, 45)
SliderBackground.Position = UDim2.new(0, 0, 0, 45)
SliderBackground.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
SliderBackground.BorderSizePixel = 0
SliderBackground.Parent = MainFrame

local SliderLabel = Instance.new("TextLabel")
SliderLabel.Size = UDim2.new(1, 0, 0, 20)
SliderLabel.Position = UDim2.new(0, 0, 0, 2)
SliderLabel.Text = "FOV: " .. fov
SliderLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
SliderLabel.BackgroundTransparency = 1
SliderLabel.Font = Enum.Font.Gotham
SliderLabel.TextSize = 12
SliderLabel.Parent = SliderBackground

local SliderTrack = Instance.new("Frame")
SliderTrack.Size = UDim2.new(0.85, 0, 0, 6)
SliderTrack.Position = UDim2.new(0.075, 0, 0, 28)
SliderTrack.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
SliderTrack.BorderSizePixel = 0
SliderTrack.Parent = SliderBackground

local SliderButton = Instance.new("TextButton")
SliderButton.Size = UDim2.new(0, 14, 0, 14)
SliderButton.AnchorPoint = Vector2.new(0.5, 0.5)
SliderButton.Position = UDim2.new(0.5, 0, 0.5, 0)
SliderButton.BackgroundColor3 = Color3.fromRGB(128, 0, 128)
SliderButton.Text = ""
SliderButton.Parent = SliderTrack

local minFov = 50
local maxFov = 300

local initialPercentage = math.clamp((fov - minFov) / (maxFov - minFov), 0, 1)
SliderButton.Position = UDim2.new(initialPercentage, 0, 0.5, 0)

local function updateDrawings()
    FOVring.Position = Camera.ViewportSize / 2
    FOVring.Radius = fov * (Camera.ViewportSize.Y / 1080)
end

local function predictPos(targetChar)
    local rootPart = targetChar:FindFirstChild("HumanoidRootPart")
    local head = targetChar:FindFirstChild("Head")
    if not rootPart or not head then
        return head and head.Position or rootPart and rootPart.Position
    end
    local velocity = rootPart.Velocity
    local predictionTime = 0.02
    local basePosition = rootPart.Position + velocity * predictionTime
    local headOffset = head.Position - rootPart.Position
    return basePosition + headOffset
end

local function getTarget()
    local nearest = nil
    local minDistance = math.huge
    local viewportCenter = Camera.ViewportSize / 2
    
    if LocalPlayer.Character then
        raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
    end

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Team ~= LocalPlayer.Team then
            local char = p.Character
            local root = char:FindFirstChild("HumanoidRootPart")
            local hum = char:FindFirstChildOfClass("Humanoid")
            
            if root and hum and hum.Health > 0 then
                local predictedPos = predictPos(char)
                local screenPos, visible = Camera:WorldToViewportPoint(predictedPos)
                
                if visible and screenPos.Z > 0 then
                    local ray = workspace:Raycast(
                        Camera.CFrame.Position,
                        (predictedPos - Camera.CFrame.Position).Unit * 1000,
                        raycastParams
                    )
                    if ray and ray.Instance:IsDescendantOf(char) then
                        local distance = (Vector2.new(screenPos.X, screenPos.Y) - viewportCenter).Magnitude
                        if distance < minDistance and distance < fov then
                            minDistance = distance
                            nearest = char
                        end
                    end
                end
            end
        end
    end
    return nearest
end

local function aim(targetPosition)
    local currentCF = Camera.CFrame
    local targetDirection = (targetPosition - currentCF.Position).Unit
    local smoothFactor = 0.581
    local newLookVector = currentCF.LookVector:Lerp(targetDirection, smoothFactor)
    Camera.CFrame = CFrame.new(currentCF.Position, currentCF.Position + newLookVector)
end

RunService.Heartbeat:Connect(function()
    updateDrawings()
    if isAiming then
        local target = getTarget()
        if target then
            local predictedPosition = predictPos(target)
            aim(predictedPosition)
        end
    end
end)

ToggleButton.MouseButton1Click:Connect(function()
    isAiming = not isAiming
    FOVring.Visible = isAiming
    ToggleButton.Text = "AIM PLAYER: " .. (isAiming and "ON" or "OFF")
    ToggleButton.TextColor3 = isAiming and Color3.fromRGB(50, 255, 50) or Color3.fromRGB(255, 50, 50)
end)

local sliderDragging = false

SliderButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        sliderDragging = true
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        sliderDragging = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if sliderDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local trackAbsoluteSize = SliderTrack.AbsoluteSize.X
        local trackAbsolutePosition = SliderTrack.AbsolutePosition.X
        local mouseX = input.Position.X
        
        local percentage = math.clamp((mouseX - trackAbsolutePosition) / trackAbsoluteSize, 0, 1)
        SliderButton.Position = UDim2.new(percentage, 0, 0.5, 0)
        
        fov = math.floor(minFov + (percentage * (maxFov - minFov)))
        SliderLabel.Text = "FOV: " .. fov
    end
end)

local dragging, dragInput, dragStart, startPos

local function update(input)
    local delta = input.Position - dragStart
    MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end

ToggleButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.InputUserState.End then
                dragging = false
            end
        end)
    end
end)

ToggleButton.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        update(input)
    end
end)

Players.PlayerRemoving:Connect(function(p)
    if p == LocalPlayer then
        FOVring:Remove()
        ScreenGui:Destroy()
    end
end)

print("=== LOADED SUCCESSFULLY ===")
print("Bật Fly trong tab Main để bay!")
print("WASD: Di chuyển | Space: Lên | Shift: Xuống")
print("Đã gộp ESP và Hitbox vào tab Visual!")
