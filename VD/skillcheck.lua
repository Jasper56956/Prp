local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local SkillCheckMod = {
	Cfg = {
		On = true,             -- เปิด/ปิด Auto Skillcheck
		Mode = "Great",        -- "Great" (กดสมบูรณ์แบบ/ต้นโซน) หรือ "Good" (กดผ่านธรรมดา/กลางโซน)
		AutoSpace = true,      -- จำลองการกดปุ่ม Spacebar
		Offset = 0,            -- ปรับระยะชดเชย Ping/Delay (องศา)
	}
}

local hasPressed = false

-- จำลองการกดปุ่ม Spacebar
local function pressSpace()
	VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
	task.wait(0.03)
	VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
end

-- ปรับองศาให้อยู่ในช่วง 0 - 360
local function normalizeAngle(angle)
	angle = angle % 360
	if angle < 0 then angle = angle + 360 end
	return angle
end

-- ตรวจสอบ SkillCheck ทุกเฟรมเรนเดอร์ (RenderStepped)
RunService.RenderStepped:Connect(function()
	if not SkillCheckMod.Cfg.On then return end

	local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
	if not playerGui then return end

	-- รองรับทั้ง PC (SkillCheckPromptGui) และ Console (SkillCheckPromptGui-con)
	local gui = playerGui:FindFirstChild("SkillCheckPromptGui") or playerGui:FindFirstChild("SkillCheckPromptGui-con")
	if not gui or not gui.Enabled then
		hasPressed = false
		return
	end

	local checkFrame = gui:FindFirstChild("Check")
	if not checkFrame or not checkFrame.Visible then
		hasPressed = false
		return
	end

	local line = checkFrame:FindFirstChild("Line")
	local goal = checkFrame:FindFirstChild("Goal")

	if not line or not goal or not line.Visible or not goal.Visible then
		hasPressed = false
		return
	end

	-- คำนวณองศา
	local lineRot = normalizeAngle(line.Rotation)
	local goalRot = normalizeAngle(goal.Rotation)

	-- ผลต่างองศาระหว่างเข็มกับเป้าหมาย
	local diff = normalizeAngle(lineRot - goalRot)

	-- กำหนดช่วงองศาที่จะกดปุ่ม
	local targetMin = 0
	local targetMax = 15

	if SkillCheckMod.Cfg.Mode == "Good" then
		targetMin = 15
		targetMax = 35
	end

	-- ปรับ Offset ชดเชยความล่าช้า (Ping/FPS)
	targetMin = targetMin + SkillCheckMod.Cfg.Offset
	targetMax = targetMax + SkillCheckMod.Cfg.Offset

	-- เมื่อเข็มหมุนถึงช่วงเป้าหมาย ให้กดปุ่ม Spacebar 1 ครั้ง
	if diff >= targetMin and diff <= targetMax then
		if not hasPressed then
			hasPressed = true
			pressSpace()
		end
	end
end)

return SkillCheckMod