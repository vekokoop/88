-- Tribes 3v3 VIP Script Hub v2 (Auto-Teleport + Floating Button + Fixed Aimbot)

-- 1. حفظ السكربت ليعمل تلقائياً عند الانتقال بين اللوبي والماب
local queue_on_teleport = (syn and syn.queue_on_teleport) or queue_on_teleport or (fluxus and fluxus.queue_on_teleport)
if queue_on_teleport then
    queue_on_teleport('loadstring(game:HttpGet("https://raw.githubusercontent.com/vekokoop/3v3/refs/heads/main/script.lua", true))()')
end

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()
local Window = Library.CreateLib("Tribes 3v3 - VIP Hub 👑", "Midnight")

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

---------------------------------------------------------
-- إنشاء الأيقونة العائمة المتحركة (Floating Toggle Button)
---------------------------------------------------------
local ScreenGui = Instance.new("ScreenGui")
local ToggleButton = Instance.new("TextButton")
local UICorner = Instance.new("UICorner")

ScreenGui.Name = "VIP_FloatingUI"
ScreenGui.Parent = (gethui and gethui()) or game:GetService("CoreGui") or LocalPlayer:WaitForChild("PlayerGui")

ToggleButton.Name = "ToggleButton"
ToggleButton.Parent = ScreenGui
ToggleButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
ToggleButton.Position = UDim2.new(0.05, 0, 0.4, 0)
ToggleButton.Size = UDim2.new(0, 50, 0, 50)
ToggleButton.Font = Enum.Font.SourceSansBold
ToggleButton.Text = "👑 VIP"
ToggleButton.TextColor3 = Color3.fromRGB(255, 215, 0)
ToggleButton.TextSize = 16.0
ToggleButton.Active = true
ToggleButton.Draggable = true -- جعل الأيقونة قابلة للتحريك والسحب بالأصبع

UICorner.CornerRadius = UDim.new(1, 0) -- شكل دائري
UICorner.Parent = ToggleButton

-- فتح وإغلاق القائمة عند الضغط على الأيقونة
ToggleButton.MouseButton1Click:Connect(function()
    Library:ToggleUI()
end)

---------------------------------------------------------
-- TAB 1: الحركة والتعديلات
---------------------------------------------------------
local MainTab = Window:NewTab("اللاعب والحركة")
local MainSection = MainTab:NewSection("تعديل الخصائص")

MainSection:NewSlider("السرعة (WalkSpeed)", "تغيير سرعة مشي اللاعب", 150, 16, function(s)
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.WalkSpeed = s
    end
end)

MainSection:NewSlider("قوة القفز (JumpPower)", "تغيير قوة القفز", 200, 50, function(s)
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.JumpPower = s
    end
end)

---------------------------------------------------------
-- TAB 2: كشف الأعداء (ESP)
---------------------------------------------------------
local VisualTab = Window:NewTab("كشف الأعداء")
local VisualSection = VisualTab:NewSection("تعديلات الرؤية")

VisualSection:NewButton("تفعيل كشف الأعداء (ESP)", "إظهار المنافسين خلف الجدران", function()
    for _, v in pairs(Players:GetPlayers()) do
        if v ~= LocalPlayer and v.Character and not v.Character:FindFirstChild("ESP_Highlight") then
            local highlight = Instance.new("Highlight")
            highlight.Name = "ESP_Highlight"
            highlight.Parent = v.Character
            highlight.FillColor = Color3.fromRGB(255, 0, 0)
            highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
        end
    end
end)

---------------------------------------------------------
-- TAB 3: الأيم بوت المصحح والـ FOV
---------------------------------------------------------
local AimbotTab = Window:NewTab("مساعد التصويب")
local AimbotSection = AimbotTab:NewSection("إعدادات الأيم بوت")

local AimbotEnabled = false
local FOV_Radius = 150

local Drawing = Drawing or import("drawing_lib")
local fovCircle = nil

if Drawing then
    fovCircle = Drawing.new("Circle")
    fovCircle.Visible = false
    fovCircle.Radius = FOV_Radius
    fovCircle.Color = Color3.fromRGB(255, 215, 0)
    fovCircle.Thickness = 1.5
    fovCircle.Filled = false
    fovCircle.Transparency = 0.8
    fovCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    RunService.RenderStepped:Connect(function()
        if fovCircle then
            fovCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        end
    end)
end

AimbotSection:NewToggle("تفعيل دائرة الـ FOV", "إظهار/إخفاء الدائرة", function(state)
    if fovCircle then
        fovCircle.Visible = state
    end
end)

AimbotSection:NewToggle("تفعيل الأيم بوت (Auto Lock)", "التوجيه تلقائياً للأعداء", function(state)
    AimbotEnabled = state
end)

AimbotSection:NewSlider("حجم الدائرة (FOV Size)", "تحديد مساحة الاستشعار", 350, 50, function(s)
    FOV_Radius = s
    if fovCircle then
        fovCircle.Radius = s
    end
end)

-- دالة تصويب محسنة ومباشرة
local function getClosestTarget()
    local closestTarget = nil
    local maxDistance = FOV_Radius

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            -- التأكد من وجود الرأس أو الجذع وأن اللاعب حي
            local targetPart = player.Character:FindFirstChild("Head") or player.Character:FindFirstChild("HumanoidRootPart")
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")

            if targetPart and humanoid and humanoid.Health > 0 then
                -- التحقق من الفريق إن وجد
                local isEnemy = true
                if player.Team and LocalPlayer.Team and player.Team == LocalPlayer.Team then
                    isEnemy = false
                end

                if isEnemy then
                    local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                    if onScreen then
                        local centerScreen = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
                        local dist = (Vector2.new(screenPos.X, screenPos.Y) - centerScreen).Magnitude

                        if dist < maxDistance then
                            maxDistance = dist
                            closestTarget = targetPart
                        end
                    end
                end
            end
        end
    end
    return closestTarget
end

-- حلقة التوجيه المستمرة
RunService.RenderStepped:Connect(function()
    if AimbotEnabled then
        local target = getClosestTarget()
        if target then
            -- توجيه الكاميرا بنعومة ونسبة استجابة عالية
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, target.Position)
        end
    end
end)

print("تم تحديث السكربت بنجاح!")
