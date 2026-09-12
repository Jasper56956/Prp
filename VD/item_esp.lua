-- [[ FIXED HEADLESS ESP MODULE ]]
if getgenv and getgenv().VD_Visualizer_Cleanup then pcall(getgenv().VD_Visualizer_Cleanup) end

local P, W, RS, CS, CG = game:GetService("Players"), game:GetService("Workspace"), game:GetService("RunService"), game:GetService("CollectionService"), game:GetService("CoreGui")
local lp = P.LocalPlayer

local M = {
    Cfg = { On = true, P = true, K = true, G = true, Dist = true, MaxD = 2500, Int = 0.15 }
}

local colors = {
    P = Color3.fromRGB(46, 204, 113),
    K = Color3.fromRGB(231, 76, 60),
    G = Color3.fromRGB(52, 152, 219)
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

local function isCatEnabled(cat)
    if not M.Cfg.On then return false end
    if cat == "P" then return M.Cfg.P ~= false and M.Cfg.Players ~= false end
    if cat == "K" then return M.Cfg.K ~= false and M.Cfg.Killers ~= false end
    if cat == "G" then return M.Cfg.G ~= false and M.Cfg.Generators ~= false end
    return true
end

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

function M.ClearAll()
    for target, _ in pairs(reg) do
        remove(target)
    end
    reg = {}
    if ct then pcall(function() ct:ClearAllChildren() end) end
end

local function update(target, cat, name, extra)
    if not isCatEnabled(cat) or not target or not target.Parent then
        remove(target)
        return
    end

    local root = getRoot(target)
    if not root then return end

    local col = colors[cat] or Color3.fromRGB(255, 255, 255)
    local r = reg[target]

    if not r then
        local ok, newR = pcall(function()
            local h = Instance.new("Highlight")
            h.Name, h.FillColor, h.OutlineColor = "H_"..target.Name, col, col
            h.FillTransparency, h.OutlineTransparency = 0.65, 0.1
            h.DepthMode, h.Adornee, h.Parent = Enum.HighlightDepthMode.AlwaysOnTop, target, ct

            local b = Instance.new("SelectionBox")
            b.Name, b.Color3, b.SurfaceColor3 = "B_"..target.Name, col, col
            b.SurfaceTransparency, b.LineThickness = 0.9, 0.05
            b.Adornee, b.Parent = root, ct

            local bg = Instance.new("BillboardGui")
            bg.Name, bg.Size, bg.StudsOffset, bg.AlwaysOnTop = "T_"..target.Name, UDim2.new(0, 160, 0, 42), Vector3.new(0, 3.2, 0), true
            bg.Adornee, bg.Parent = root, ct

            local lbl = Instance.new("TextLabel")
            lbl.Size, lbl.BackgroundTransparency, lbl.Font, lbl.TextSize = UDim2.new(1, 0, 1, 0), 1, Enum.Font.GothamBold, 12
            lbl.TextColor3, lbl.TextStrokeColor3, lbl.TextStrokeTransparency = col, Color3.fromRGB(15, 15, 18), 0.2
            lbl.Parent = bg

            local conn = target.AncestryChanged:Connect(function(_, p) if not p then remove(target) end end)
            return {H = h, B = b, Bg = bg, L = lbl, Conn = conn, Cat = cat}
        end)
        if ok and newR then r = newR; reg[target] = r else return end
    end

    if r and root then
        local myRoot = lp.Character and getRoot(lp.Character)
        local d = myRoot and math.floor((root.Position - myRoot.Position).Magnitude) or 0
        if d > M.Cfg.MaxD then
            r.H.Enabled, r.B.Visible, r.Bg.Enabled = false, false, false
            return
        else
            r.H.Enabled, r.B.Visible, r.Bg.Enabled = true, true, true
        end

        local showDist = M.Cfg.Dist ~= false and M.Cfg.ShowDistance ~= false
        local txt = name
        if showDist then txt = txt .. string.format(" [%dm]", d) end
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
        for _, k in ipairs(KNAMES) do if string.find(n, k) then return true end end
    end
    return false
end

local function scan(disc)
    if not M.Cfg.On then return end
    
    if isCatEnabled("P") or isCatEnabled("K") then
        for _, p in ipairs(P:GetPlayers()) do
            if p ~= lp then
                local isK = p.Team and string.find(string.lower(p.Team.Name), "killer")
                local char = p.Character
                if char and char.Parent and char:FindFirstChild("HumanoidRootPart") then
                    local hum = char:FindFirstChildOfClass("Humanoid")
                    if hum and hum.Health > 0 then
                        if isK and isCatEnabled("K") then
                            disc[char] = {cat = "K", name = "🔪 " .. p.DisplayName .. " [Killer]", extra = string.format("HP: %d/%d", math.floor(hum.Health), math.floor(hum.MaxHealth))}
                        elseif not isK and isCatEnabled("P") then
                            disc[char] = {cat = "P", name = "👤 " .. p.DisplayName, extra = string.format("HP: %d/%d", math.floor(hum.Health), math.floor(hum.MaxHealth))}
                        end
                    end
                end
            end
        end
    end

    if isCatEnabled("K") then
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
                if obj:IsA("Model") and not disc[obj] then disc[obj] = {cat = "K", name = "⚠️ Fake: " .. obj.Name, extra = ""} end
            end
        end
    end

    if isCatEnabled("G") then
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
                        local nl, fp = string.lower(child.Name), string.lower(child:GetFullName())
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
end

local last = 0
local hb = RS.Heartbeat:Connect(function()
    local t = os.clock()
    if t - last < M.Cfg.Int then return end
    last = t

    task.spawn(function()
        if not M.Cfg.On then
            M.ClearAll()
            return
        end

        local disc = {}
        scan(disc)
        for target, info in pairs(disc) do update(target, info.cat, info.name, info.extra) end
        for target, r in pairs(reg) do
            if not disc[target] or not target.Parent or not isCatEnabled(r.Cat) then
                remove(target)
            end
        end
    end)
end)

local ca = lp.CharacterAdded:Connect(function()
    task.wait(1)
    M.ClearAll()
end)

function M.Cleanup()
    if hb then hb:Disconnect() end
    if ca then ca:Disconnect() end
    M.ClearAll()
    if ct then pcall(function() ct:Destroy() end) end
end

if getgenv then getgenv().VD_Visualizer_Cleanup = M.Cleanup end
return M