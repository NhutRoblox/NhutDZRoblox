local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
    Name = "NhutCrack",
    LoadingTitle = "ĐỤ MẸ CHỜ XÍU ĐI",
    LoadingSubtitle = "by NhutDZ",
    ConfigurationSaving = {Enabled = true, FolderName = "NhutCrack", FileName = "Settings"}
})

local MainTab = Window:CreateTab("Main", 4483362458)

-- ==================== ESP & HITBOX ====================
local ESP = {
    Enabled = false,
    Tracers = true,
    Distance = true,
    TeamCheck = false,
    HitboxEnabled = false,
    HitboxSize = 10  -- Kích thước hitbox (càng lớn càng dễ bắn)
}

local FolderName = "NhutESP"
local HitboxConnections = {}

local function CreateESP(plr)
    if plr == game.Players.LocalPlayer then return end
    
    local function Apply(Character)
        if not Character or not Character:FindFirstChild("HumanoidRootPart") then return end
        if ESP.TeamCheck and plr.Team == game.Players.LocalPlayer.Team then return end

        if Character:FindFirstChild(FolderName) then Character[FolderName]:Destroy() end

        local Folder = Instance.new("Folder")
        Folder.Name = FolderName
        Folder.Parent = Character

        local Root = Character.HumanoidRootPart
        local LocalRoot = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

        -- Highlight đỏ
        local HL = Instance.new("Highlight", Folder)
        HL.FillColor = Color3.fromRGB(255, 0, 0)
        HL.OutlineColor = Color3.fromRGB(255, 100, 100)
        HL.FillTransparency = 0.4
        HL.OutlineTransparency = 0
        HL.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop

        -- Chams đỏ
        for _, part in ipairs(Character:GetChildren()) do
            if part:IsA("BasePart") and part.Name \~= "HumanoidRootPart" then
                local chams = Instance.new("BoxHandleAdornment")
                chams.Name = "RedChams"
                chams.Adornee = part
                chams.Color3 = Color3.fromRGB(255, 0, 0)
                chams.Transparency = 0.3
                chams.AlwaysOnTop = true
                chams.Size = part.Size + Vector3.new(0.1, 0.1, 0.1)
                chams.ZIndex = 10
                chams.Parent = Folder
            end
        end

        -- Tracer
        if ESP.Tracers and LocalRoot then
            local A0 = Instance.new("Attachment", LocalRoot)
            local A1 = Instance.new("Attachment", Root)
            local Beam = Instance.new("Beam", Folder)
            Beam.Attachment0 = A0
            Beam.Attachment1 = A1
            Beam.Color = ColorSequence.new(Color3.fromRGB(255, 0, 0))
            Beam.Transparency = NumberSequence.new(0.25)
            Beam.Width0 = 0.2
            Beam.Width1 = 0.15
            Beam.Segments = 3
            Beam.LightEmission = 1
        end

        -- Distance
        if ESP.Distance then
            local BG = Instance.new("BillboardGui", Folder)
            BG.Adornee = Root
            BG.Size = UDim2.new(0, 120, 0, 30)
            BG.StudsOffset = Vector3.new(0, 3, 0)
            BG.AlwaysOnTop = true

            local Txt = Instance.new("TextLabel", BG)
            Txt.Size = UDim2.new(1,0,1,0)
            Txt.BackgroundTransparency = 1
            Txt.TextColor3 = Color3.new(1,1,1)
            Txt.TextStrokeTransparency = 0
            Txt.TextStrokeColor3 = Color3.new(0,0,0)
            Txt.TextScaled = false
            Txt.TextSize = 14
            Txt.Font = Enum.Font.GothamBold

            game:GetService("RunService").RenderStepped:Connect(function()
                if not ESP.Enabled or not Character:FindFirstChild("HumanoidRootPart") then return end
                local dist = (Root.Position - (LocalRoot and LocalRoot.Position or Vector3.new())).Magnitude
                Txt.Text = string.format("[%d]", math.floor(dist))
            end)
        end

        -- Hitbox Expander
        if ESP.HitboxEnabled then
            local oldSize = Root.Size
            Root.Size = Vector3.new(ESP.HitboxSize, ESP.HitboxSize, ESP.HitboxSize)
            Root.Transparency = 0.7  -- Làm trong hơn một chút để dễ nhìn

            -- Lưu connection để reset khi tắt
            HitboxConnections[plr] = function()
                if Root and Root.Parent then
                    Root.Size = oldSize
                    Root.Transparency = 0
                end
            end
        end
    end

    if plr.Character then Apply(plr.Character) end
    plr.CharacterAdded:Connect(Apply)
end

-- Reset hitbox khi tắt
local function ResetAllHitbox()
    for _, conn in pairs(HitboxConnections) do
        pcall(conn)
    end
    HitboxConnections = {}
end

-- ==================== UI ====================

MainTab:CreateToggle({
    Name = "ESP + Tia Chỉ",
    CurrentValue = false,
    Callback = function(v)
        ESP.Enabled = v
        if v then
            for _, p in ipairs(game.Players:GetPlayers()) do CreateESP(p) end
            game.Players.PlayerAdded:Connect(CreateESP)
        else
            ResetAllHitbox()
            for _, p in ipairs(game.Players:GetPlayers()) do
                if p.Character and p.Character:FindFirstChild(FolderName) then
                    p.Character[FolderName]:Destroy()
                end
            end
        end
    end
})

MainTab:CreateToggle({
    Name = "Hitbox Expander",
    CurrentValue = false,
    Callback = function(v)
        ESP.HitboxEnabled = v
        if v then
            for _, p in ipairs(game.Players:GetPlayers()) do
                if p.Character then CreateESP(p) end
            end
        else
            ResetAllHitbox()
            -- Refresh ESP nếu đang bật
            if ESP.Enabled then
                for _, p in ipairs(game.Players:GetPlayers()) do
                    if p.Character and p.Character:FindFirstChild(FolderName) then
                        p.Character[FolderName]:Destroy()
                    end
                    CreateESP(p)
                end
            end
        end
    end
})

MainTab:CreateSlider({
    Name = "Hitbox Size",
    Range = {5, 30},
    Increment = 1,
    CurrentValue = 10,
    Callback = function(v)
        ESP.HitboxSize = v
        if ESP.HitboxEnabled then
            for _, p in ipairs(game.Players:GetPlayers()) do
                if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                    local root = p.Character.HumanoidRootPart
                    root.Size = Vector3.new(v, v, v)
                end
            end
        end
    end
})

MainTab:CreateToggle({Name = "Team Check", CurrentValue = false, Callback = function(v)
    ESP.TeamCheck = v
    if ESP.Enabled then
        for _, p in ipairs(game.Players:GetPlayers()) do
            if p.Character and p.Character:FindFirstChild(FolderName) then p.Character[FolderName]:Destroy() end
            CreateESP(p)
        end
    end
end})

MainTab:CreateToggle({Name = "Distance ESP", CurrentValue = true, Callback = function(v)
    ESP.Distance = v
    if ESP.Enabled then
        for _, p in ipairs(game.Players:GetPlayers()) do
            if p.Character and p.Character:FindFirstChild(FolderName) then p.Character[FolderName]:Destroy() end
            CreateESP(p)
        end
    end
end})

MainTab:CreateToggle({Name = "Tracers", CurrentValue = true, Callback = function(v)
    ESP.Tracers = v
    if ESP.Enabled then
        for _, p in ipairs(game.Players:GetPlayers()) do
            if p.Character and p.Character:FindFirstChild(FolderName) then p.Character[FolderName]:Destroy() end
            CreateESP(p)
        end
    end
end})

-- Các chức năng cũ
MainTab:CreateButton({Name = "Cặc", Callback = function()
    Rayfield:Notify({Title = "Thông báo", Content = "Nhìn gì đấy!", Duration = 3})
end})

MainTab:CreateSlider({Name = "WalkSpeed", Range = {16,100}, Increment = 1, CurrentValue = 16, Callback = function(v)
    local hum = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("Humanoid")
    if hum then hum.WalkSpeed = v end
end})
