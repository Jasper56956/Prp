-- [[ HEADLESS ESP MODULE (GITHUB / LOADER READY) ]]
if getgenv and getgenv().VD_Visualizer_Cleanup then
    pcall(getgenv().VD_Visualizer_Cleanup)
end

local P = game:GetService("Players")
local W = game:GetService("Workspace")
local RS = game:GetService("RunService")
local CS = game:GetService("CollectionService")
local CG = game:GetService("CoreGui")
local lp = P.LocalPlayer

local C = {
    P = Color3.fromRGB(46, 204, 113),
    K = Color3.fromRGB(231, 76, 60),
    G = Color3.fromRGB(52, 152, 219),
    Dist = 2500,
    Int = 0.2
}

local function getParent()
    if gethui then return gethui() end
    local ok, c = pcall(function() return CG end)
    return (ok and c) or lp:WaitForChild("PlayerGui")
end

local parent = getParent()
local old = parent:FindFirstChild("VD_ESP_Folder")
if old then pcall(function() old:Destroy() end) end

local ct = Instance.new("Folder")
ct.Name = "VD_ESP_Folder"
ct.Parent = parent

local reg = {}

local function getRoot(inst)
    if not inst then return end
    if inst:IsA("Model") then
        return inst.PrimaryPart or inst:FindFirstChild("HumanoidRootPart") or inst:FindFirstChild("Torso") or inst:FindFirstChild("UpperTorso") or inst:FindFirstChildWhichIsA("BasePart")
    elseif inst:IsA("BasePart") then
        return inst
    end
end

local function remove(target)
    local r = reg[target]
    if r then
        if r.H then pcall(function() r.H:Destroy() end) end
        if r.B then pcall(function() r.B:Destroy() end) end
        if r.Bg then pcall(function() r.Bg:Destroy() end) end
        if r.Conn then pcall(function() r.Conn:Disconnect() end) end
        reg[target] = nil
    end
end

local function update(target, cat, name, extra)
    if not target or not target.Parent then return end
    local root = getRoot(target)
    if not root then return end

    local col = C[cat] or Color3.fromRGB(255, 255, 255)
    local r = reg[target]

    if not r then
        local ok, newR = pcall(function()
            local h = Instance.new("Highlight")
            h.Name = "H_" .. target.Name
            h.FillColor, h.OutlineColor = col, col
            h.FillTransparency, h.OutlineTransparency = 0.65, 0.1
            h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            h.Adornee = target
            h.Parent = ct

            local b = Instance.new("SelectionBox")
            b.Name = "B_" .. target.Name
            b.Color3, b.SurfaceColor3 = col, col
            b.SurfaceTransparency, b.LineThickness = 0.9, 0.05
            b.Adornee = root
            b.Parent = ct

            local bg = Instance.new("BillboardGui")
            bg.Name = "T_" .. target.Name
            bg.Size = UDim2.new(0, 160, 0, 42)
            bg.StudsOffset = Vector3.new(0, 3.2, 0)
            bg.AlwaysOnTop = true
            bg.Adornee = root
            bg.Parent = ct

            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(1, 0, 1, 0)
            lbl.BackgroundTransparency = 1
            lbl.Font = Enum.Font.GothamBold
            lbl.TextSize = 12
            lbl.TextColor3 = col
            lbl.TextStrokeColor3 = Color3.fromRGB(15, 15, 18)
            lbl.TextStrokeTransparency = 0.2
            lbl.Parent = bg

            local conn = target.AncestryChanged:Connect(function(_, p)
                if not p then remove(target) end
            end)

            return {H = h, B = b, Bg = bg, L = lbl, Conn = conn}
        end)
        if ok and newR then r = newR; reg[target] = r else return end
    end

    if r and root then
        local myRoot = lp.Character and getRoot(lp.Character)
        local d = myRoot and math.floor((root.Position - myRoot.Position).Magnitude) or 0
        if d > C.Dist then
            r.H.Enabled, r.B.Visible, r.Bg.Enabled = false, false, false
            return
        else
            r.H.Enabled, r.B.Visible, r.Bg.Enabled = true, true, true
        end

        local txt = name .. string.format(" [%d studs]", d)
        if extra and extra ~= "" then txt = txt .. "\n" .. extra end
        r.L.Text = txt
    end
end

local KNAMES = {"stalker", "killer", "hidden", "abysswalker", "veil", "slasher", "masked", "cure", "general", "enemy", "boss", "monster", "npc", "beast", "hunter"}

local function isHostile(m, p)
    if p and p.Team and string.find(string.lower(p.Team.Name), "killer") then return true end
    if m then
        if m:GetAttribute("IsKiller") or m:GetAttribute("Killer") then return true end
        local n = string.lower(m.Name)
        for _, k in ipairs(KNAMES) do
            if string.find(n, k) then return true end
        end
    end
    return false
end

local function scan(disc)
    for _, p in ipairs(P:GetPlayers()) do
        if p ~= lp then
            local isK = p.Team and string.find(string.lower(p.Team.Name), "killer")
            local char = p.Character
            if char and char.Parent and char:FindFirstChild("HumanoidRootPart") then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 then
                    if isK then
                        disc[char] = {cat = "K", name = "🔪 " .. p.DisplayName .. " [Killer]", extra = string.format("HP: %d/%d", math.floor(hum.Health), math.floor(hum.MaxHealth))}
                    else
                        disc[char] = {cat = "P", name = "👤 " .. p.DisplayName, extra = string.format("HP: %d/%d", math.floor(hum.Health), math.floor(hum.MaxHealth))}
                    end
                end
            end
        end
    end

    for _, obj in ipairs(W:GetChildren()) do
        if obj:IsA("Model") and obj ~= lp.Character and not disc[obj] then
            local hum = obj:FindFirstChildOfClass("Humanoid")
            local hrp = obj:FindFirstChild("HumanoidRootPart") or obj.PrimaryPart
            if hum and hrp and hum.Health > 0 and isHostile(obj, nil) then
                disc[obj] = {cat = "K", name = "⚠️ " .. obj.Name, extra = string.format("HP: %d", math.floor(hum.Health))}
            end
        end
    end

    local fc = W:FindFirstChild("FakeCharacters")
    if fc then
        for _, obj in ipairs(fc:GetChildren()) do
            if obj:IsA("Model") and not disc[obj] then
                disc[obj] = {cat = "K", name = "⚠️ Fake: " .. obj.Name, extra = ""}
            end
        end
    end

    for _, tag in ipairs(CS:GetTagged("GeneratorPoint")) do
        local g = tag.Parent or tag
        if not disc[g] then
            local prog = g:GetAttribute("RepairProgress") or 0
            disc[g] = {cat = "G", name = "⚡ Generator", extra = string.format("Progress: %d%%", math.floor(prog))}
        end
    end

    local containers = {W, W:FindFirstChild("Map"), W:FindFirstChild("Interractables")}
    for _, c in ipairs(containers) do
        if c then
            for _, child in ipairs(c:GetChildren()) do
                if not disc[child] and (child:IsA("Model") or child:IsA("BasePart")) then
                    local nl = string.lower(child.Name)
                    local fp = string.lower(child:GetFullName())
                    if not string.find(fp, "powerlines") and not string.find(fp, "powerpole") then
                        if CS:HasTag(child, "GeneratorPoint") or child:GetAttribute("Generator") ~= nil or child:GetAttribute("RepairProgress") ~= nil or string.find(nl, "generator") or string.match(nl, "%f[%a]gen%f[%A]") or string.find(nl, "engine") then
                            local prog = child:GetAttribute("RepairProgress")
                            disc[child] = {cat = "G", name = "⚡ " .. child.Name, extra = prog and string.format("Progress: %d%%", math.floor(prog)) or ""}
                        end
                    end
                end
            end
        end
    end
end

local last = 0
local hb = RS.Heartbeat:Connect(function()
    local t = os.clock()
    if t - last < C.Int then return end
    last = t

    task.spawn(function()
        local disc = {}
        scan(disc)
        for target, info in pairs(disc) do
            update(target, info.cat, info.name, info.extra)
        end
        for target, _ in pairs(reg) do
            if not disc[target] or not target.Parent then
                remove(target)
            end
        end
    end)
end)

local ca = lp.CharacterAdded:Connect(function()
    task.wait(1)
    for target, _ in pairs(reg) do remove(target) end
end)

local function cleanup()
    if hb then hb:Disconnect() end
    if ca then ca:Disconnect() end
    for target, _ in pairs(reg) do remove(target) end
    if ct then pcall(function() ct:Destroy() end) end
end

if getgenv then getgenv().VD_Visualizer_Cleanup = cleanup end
return cleanup