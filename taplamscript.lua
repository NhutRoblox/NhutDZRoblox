local TweenService = game:GetService("TweenService")

local gui = script.Parent
local openButton = gui.OpenButton
local mainFrame = gui.MainFrame
local closeButton = mainFrame.CloseButton

-- Vị trí đóng và mở
local closedPos = UDim2.new(-0.35, 0, 0.25, 0)
local openedPos = UDim2.new(0.05, 0, 0.25, 0)

mainFrame.Position = closedPos
mainFrame.Visible = true

local tweenInfo = TweenInfo.new(
    0.4,
    Enum.EasingStyle.Quad,
    Enum.EasingDirection.Out
)

local function openMenu()
    TweenService:Create(mainFrame, tweenInfo, {
        Position = openedPos
    }):Play()
end

local function closeMenu()
    TweenService:Create(mainFrame, tweenInfo, {
        Position = closedPos
    }):Play()
end

openButton.MouseButton1Click:Connect(openMenu)
closeButton.MouseButton1Click:Connect(closeMenu)