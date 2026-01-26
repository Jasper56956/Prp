-- ==========================================
-- [ INVISIBLE + SAFE SPEED BYPASS ]
-- ==========================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LP = Players.LocalPlayer

-- ใช้ค่าจาก Global Config หากไม่มีให้ใช้ค่าเริ่มต้น
_G.InvisConfig = _G.InvisConfig or {
    SpeedMultiplier = 0.4,
    IsInvisible = false,
    IsSpeedActive = false
}

local function setInvisibility(status)
    local char = LP.Character
    if not char then return end
    
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") or part:IsA("Decal") then
            part.Transparency = status and 1 or 0
        end
    end
    
    local hum = char:FindFirstChild("Humanoid")
    if hum then
        hum.DisplayDistanceType = status and Enum.HumanoidDisplayDistanceType.None or Enum.HumanoidDisplayDistanceType.Viewer
    end
end

local function applySpeed()
    local char = LP.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChild("Humanoid")
    
    if hrp and hum and hum.MoveDirection.Magnitude > 0 and _G.InvisConfig.IsSpeedActive then
        hrp.CFrame = hrp.CFrame + (hum.MoveDirection * _G.InvisConfig.SpeedMultiplier)
    end
end

-- ตรวจสอบการเปลี่ยนสถานะล่องหน
task.spawn(function()
    local lastState = _G.InvisConfig.IsInvisible
    while task.wait(0.5) do
        if _G.InvisConfig.IsInvisible ~= lastState then
            lastState = _G.InvisConfig.IsInvisible
            setInvisibility(lastState)
        end
    end
end)

local connection
connection = RunService.Heartbeat:Connect(function()
    pcall(applySpeed)
end)

print("👻 InvisSpeed Module Ready")