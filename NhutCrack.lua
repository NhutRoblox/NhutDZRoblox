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
local AimTab = Window:CreateTab("Aimbot", 4483362458)

-- ==================== SETTINGS ====================
local Settings = {
    ESP = {Enabled = false, Tracers = true, Distance = true, TeamCheck = false},
    Hitbox = {Enabled = false, Size = 12, TeamCheck = false, OriginalSizes = {}},
    Aim = {Enabled = false, TeamCheck = false, Part = "HumanoidRootPart", Fov = 150, FovVisible = true, Smoothness = 1, IsTargeting = false}
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

-- ==================== AIMBOT LOGIC (FORCE REWRITE) ====================
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

-- Nhận diện nhấn giữ chuột phải để Aimbot
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

-- Vòng lặp vẽ FOV cố định
RunService.RenderStepped:Connect(function()
    local centerScreen = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    FovCircle.Visible = Settings.Aim.Enabled and Settings.Aim.FovVisible
    FovCircle.Radius = Settings.Aim.Fov
    FovCircle.Position = centerScreen
end)

-- GIẢI PHÁP TRIỆT ĐỂ: Ép luồng ưu tiên Camera cao hơn hệ thống của Game (Bypass đè CFrame)
RunService:BindToRenderStep("NhutAimbotForce", Enum.RenderPriority.Camera.Value + 1, function()
    if Settings.Aim.Enabled and Settings.Aim.IsTargeting then
        local targetPlr = GetClosestPlayerToCenter()
        if targetPlr and targetPlr.Character then
            local targetPart = targetPlr.Character:FindFirstChild(Settings.Aim.Part)
            if targetPart then
                -- Tính toán hướng xoay ép thẳng vào mục tiêu
                local currentCFrame = Camera.CFrame
                local targetCFrame = CFrame.lookAt(currentCFrame.Position, targetPart.Position)
                
                -- Thực hiện Lerp mượt mà dựa trên độ ưu tiên cao hơn game
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

-- ==================== UI TAB MAIN ====================
MainTab:CreateToggle({Name = "ESP + Tia Chỉ", CurrentValue = false, Callback = function(v)
    Settings.ESP.Enabled = v
    for _, plr in ipairs(Players:GetPlayers()) do
        if not v and plr.Character and plr.Character:FindFirstChild(FOLDER_NAME) then plr.Character[FOLDER_NAME]:Destroy() else CreateESP(plr) end
    end
end})
MainTab:CreateToggle({Name = "Team Check (ESP)", CurrentValue = false, Callback = function(v) Settings.ESP.TeamCheck = v end})
MainTab:CreateToggle({Name = "Distance ESP", CurrentValue = true, Callback = function(v) Settings.ESP.Distance = v end})
MainTab:CreateToggle({Name = "Tracers", CurrentValue = true, Callback = function(v) Settings.ESP.Tracers = v end})
MainTab:CreateToggle({Name = "Hitbox Expander", CurrentValue = false, Callback = function(v) Settings.Hitbox.Enabled = v UpdateAllHitboxes() end})
MainTab:CreateSlider({Name = "Hitbox Size", Range = {5, 100}, Increment = 1, CurrentValue = 12, Callback = function(v) Settings.Hitbox.Size = v if Settings.Hitbox.Enabled then UpdateAllHitboxes() end end})
MainTab:CreateToggle({Name = "Hitbox Team Check", CurrentValue = false, Callback = function(v) Settings.Hitbox.TeamCheck = v UpdateAllHitboxes() end})

-- made by yee_kunkun(my roblox user name haha)
local fov = 136 -- Đây là FOV mặc định ban đầu
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local Cam = workspace.CurrentCamera
local Player = Players.LocalPlayer

local FOVring = Drawing.new("Circle")
FOVring.Visible = false
FOVring.Thickness = 2
FOVring.Color = Color3.fromRGB(128, 0, 128)
FOVring.Filled = false
FOVring.Radius = fov
FOVring.Position = Cam.ViewportSize / 2

local isAiming = false
local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Exclude

-- --- TẠO GIAO DIỆN (UI) ---
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Parent = game.CoreGui

-- Khung chứa chính để dễ dàng kéo thả cả cụm UI cùng lúc
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

-- --- THÀNH PHẦN THANH FOV MỚI ---
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
SliderButton.Position = UDim2.new(0.5, 0, 0.5, 0) -- Sẽ tự động tính toán lại vị trí dựa trên giá trị fov mặc định
SliderButton.BackgroundColor3 = Color3.fromRGB(128, 0, 128)
SliderButton.Text = ""
SliderButton.Parent = SliderTrack

-- Định nghĩa giới hạn FOV (Min / Max)
local minFov = 50
local maxFov = 300

-- Đặt vị trí nút trượt ban đầu dựa trên giá trị biến `fov`
local initialPercentage = math.clamp((fov - minFov) / (maxFov - minFov), 0, 1)
SliderButton.Position = UDim2.new(initialPercentage, 0, 0.5, 0)

-- --- LOGIC XỬ LÝ ---

-- Cập nhật kích thước vòng FOV theo màn hình
local function updateDrawings()
    FOVring.Position = Cam.ViewportSize / 2
    FOVring.Radius = fov * (Cam.ViewportSize.Y / 1080)
end

-- Dự đoán vị trí di chuyển (Prediction)
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

-- Tìm kiếm Người chơi gần tâm màn hình nhất
local function getTarget()
    local nearest = nil
    local minDistance = math.huge
    local viewportCenter = Cam.ViewportSize / 2
    
    if Player.Character then
        raycastParams.FilterDescendantsInstances = {Player.Character}
    end

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= Player and p.Character and p.Team ~= Player.Team then
            local char = p.Character
            local root = char:FindFirstChild("HumanoidRootPart")
            local hum = char:FindFirstChildOfClass("Humanoid")
            
            if root and hum and hum.Health > 0 then
                local predictedPos = predictPos(char)
                local screenPos, visible = Cam:WorldToViewportPoint(predictedPos)
                
                if visible and screenPos.Z > 0 then
                    local ray = workspace:Raycast(
                        Cam.CFrame.Position,
                        (predictedPos - Cam.CFrame.Position).Unit * 1000,
                        raycastParams
                    )
                    if ray and ray.Instance:IsDescendantOf(char) then
                        local distance = (Vector2.new(screenPos.X, screenPos.Y) - viewportCenter).Magnitude
                        -- Kiểm tra theo fov động vừa chỉnh
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

-- Di chuyển mượt Camera
local function aim(targetPosition)
    local currentCF = Cam.CFrame
    local targetDirection = (targetPosition - currentCF.Position).Unit
    local smoothFactor = 0.581
    local newLookVector = currentCF.LookVector:Lerp(targetDirection, smoothFactor)
    Cam.CFrame = CFrame.new(currentCF.Position, currentCF.Position + newLookVector)
end

-- Vòng lặp quét liên tục
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

-- Bật/Tắt bằng nút bấm
ToggleButton.MouseButton1Click:Connect(function()
    isAiming = not isAiming
    FOVring.Visible = isAiming
    ToggleButton.Text = "AIM PLAYER: " .. (isAiming and "ON" or "OFF")
    ToggleButton.TextColor3 = isAiming and Color3.fromRGB(50, 255, 50) or Color3.fromRGB(255, 50, 50)
end)

-- --- LOGIC DI CHUYỂN THANH TRƯỢT (SLIDER FOV) ---
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
        
        -- Tính toán phần trăm thanh trượt (0 đến 1)
        local percentage = math.clamp((mouseX - trackAbsolutePosition) / trackAbsoluteSize, 0, 1)
        SliderButton.Position = UDim2.new(percentage, 0, 0.5, 0)
        
        -- Cập nhật giá trị FOV thực tế dựa trên phần trăm công thức nội suy tuyến tính
        fov = math.floor(minFov + (percentage * (maxFov - minFov)))
        SliderLabel.Text = "FOV: " .. fov
    end
end)

-- --- GIỮ NGUYÊN CƠ CHẾ KÉO (DRAG) CHO CẢ KHUNG MENU ---
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
            if input.UserInputState == Enum.UserInputState.End then
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

-- Dọn dẹp bộ nhớ
Players.PlayerRemoving:Connect(function(p)
    if p == Player then
        FOVring:Remove()
        ScreenGui:Destroy()
    end
end)
