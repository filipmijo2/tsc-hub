-- TSC HUB (Thunder Scientific) — hook-frei: nur Lighting-Props + eigene GUI/Adornments in CoreGui
-- Start: loadstring(readfile("tsc_hub.lua"))()   Toggle GUI: RightShift

-- altes Hub komplett killen
if _G.__TSC_HUB and _G.__TSC_HUB.kill then pcall(_G.__TSC_HUB.kill) end
local H = { conns = {}, alive = true }
_G.__TSC_HUB = H

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local CoreGui = game:GetService("CoreGui")
local lp = Players.LocalPlayer
local cam = workspace.CurrentCamera

local function con(sig, fn) local c = sig:Connect(fn) table.insert(H.conns, c) return c end

local state = { fullbright = false, esp = false, espDist = 1500, espFade = 0.4, markId = nil, markName = nil }
H.state = state

-- ================= GUI =================
local gui = Instance.new("ScreenGui")
gui.Name = "TSC_HUB"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true; gui.DisplayOrder = 999
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = CoreGui

local espFolder = Instance.new("Folder"); espFolder.Name = "TSC_ESP"; espFolder.Parent = gui

local main = Instance.new("Frame")
main.Size = UDim2.fromOffset(260, 614); main.Position = UDim2.fromOffset(40, 200)
main.BackgroundColor3 = Color3.fromRGB(20, 22, 28); main.BorderSizePixel = 0; main.Active = true
main.Parent = gui
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 8)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 30); title.BackgroundColor3 = Color3.fromRGB(35, 90, 200); title.BorderSizePixel = 0
title.Text = "  TSC HUB   [RightShift]"; title.TextXAlignment = Enum.TextXAlignment.Left
title.Font = Enum.Font.GothamBold; title.TextSize = 14; title.TextColor3 = Color3.new(1, 1, 1)
title.Parent = main
Instance.new("UICorner", title).CornerRadius = UDim.new(0, 8)

-- Drag
do
	local dragging, startPos, startMouse
	con(title.InputBegan, function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true; startPos = main.Position; startMouse = i.Position end
	end)
	con(UIS.InputChanged, function(i)
		if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
			local d = i.Position - startMouse
			main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
		end
	end)
	con(UIS.InputEnded, function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
end

local function mkToggle(y, label, key, onChange)
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(1, -16, 0, 28); b.Position = UDim2.fromOffset(8, y)
	b.BorderSizePixel = 0; b.Font = Enum.Font.Gotham; b.TextSize = 14; b.TextColor3 = Color3.new(1, 1, 1)
	b.Parent = main
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
	local function paint()
		b.Text = label .. ": " .. (state[key] and "AN" or "AUS")
		b.BackgroundColor3 = state[key] and Color3.fromRGB(40, 150, 70) or Color3.fromRGB(55, 58, 68)
	end
	paint()
	con(b.MouseButton1Click, function() state[key] = not state[key]; paint(); task.spawn(onChange, state[key]) end)
	return b
end

-- ================= FULLBRIGHT =================
local origLight = {}
local LPROPS = { Brightness = 2, ClockTime = 14, FogEnd = 1e6, FogStart = 1e6, GlobalShadows = false,
	Ambient = Color3.new(1, 1, 1), OutdoorAmbient = Color3.new(1, 1, 1), ExposureCompensation = 0 }
local disabledFx = {}
local function applyFB()
	for k, v in pairs(LPROPS) do
		if origLight[k] == nil then origLight[k] = Lighting[k] end
		if Lighting[k] ~= v then pcall(function() Lighting[k] = v end) end
	end
	for _, o in ipairs(Lighting:GetChildren()) do
		if o:IsA("Atmosphere") then
			if not disabledFx[o] then disabledFx[o] = { Density = o.Density, Haze = o.Haze } end
			o.Density = 0; o.Haze = 0
		elseif (o:IsA("ColorCorrectionEffect") or o:IsA("BloomEffect") or o:IsA("BlurEffect")) and o.Enabled then
			if not disabledFx[o] then disabledFx[o] = { Enabled = true } end
			o.Enabled = false
		end
	end
end
local function restoreFB()
	for k, v in pairs(origLight) do pcall(function() Lighting[k] = v end) end
	origLight = {}
	for o, t in pairs(disabledFx) do if o.Parent then for k, v in pairs(t) do pcall(function() o[k] = v end) end end end
	disabledFx = {}
end
mkToggle(38, "Fullbright", "fullbright", function(on) if on then applyFB() else restoreFB() end end)
-- Spiel setzt Lighting per Zone neu -> periodisch nachziehen
task.spawn(function()
	while H.alive do
		if state.fullbright then pcall(applyFB) end
		task.wait(0.5)
	end
end)

-- ================= ESP =================
local espObjs = {} -- [player] = {bb=, lbl=}
local function teamColor(p) return (p.Team and p.TeamColor.Color) or Color3.new(1, 1, 1) end

local function removeEsp(p)
	local e = espObjs[p]
	if e then pcall(function() e.bb:Destroy() end) espObjs[p] = nil end
end

local function ensureEsp(p)
	local e = espObjs[p]
	if not e then
		local bb = Instance.new("BillboardGui")
		bb.Name = "E_" .. p.UserId; bb.AlwaysOnTop = true; bb.Size = UDim2.fromOffset(200, 34)
		bb.StudsOffset = Vector3.new(0, 3.2, 0); bb.LightInfluence = 0; bb.ResetOnSpawn = false
		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.fromScale(1, 1); lbl.BackgroundTransparency = 1; lbl.Font = Enum.Font.GothamBold
		lbl.TextSize = 12; lbl.TextStrokeTransparency = 0.3; lbl.Parent = bb
		bb.Parent = espFolder
		e = { bb = bb, lbl = lbl }
		espObjs[p] = e
	end
	return e
end

mkToggle(72, "ESP (Name/Team/Dist)", "esp", function(on)
	if not on then for p in pairs(espObjs) do removeEsp(p) end end
end)

-- Slider-Helper: Label bei y, Balken darunter; onSet(v) liefert Anzeigetext
local function mkSlider(y, minV, maxV, init, color, onSet)
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, -16, 0, 14); lbl.Position = UDim2.fromOffset(8, y)
	lbl.BackgroundTransparency = 1; lbl.Font = Enum.Font.Gotham; lbl.TextSize = 12
	lbl.TextColor3 = Color3.fromRGB(220, 220, 220); lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Parent = main
	local bar = Instance.new("Frame")
	bar.Size = UDim2.new(1, -16, 0, 10); bar.Position = UDim2.fromOffset(8, y + 18)
	bar.BackgroundColor3 = Color3.fromRGB(55, 58, 68); bar.BorderSizePixel = 0; bar.Active = true; bar.Parent = main
	Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)
	local fill = Instance.new("Frame")
	fill.BackgroundColor3 = color; fill.BorderSizePixel = 0; fill.Parent = bar
	Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
	local function set(v)
		v = math.clamp(v, minV, maxV)
		fill.Size = UDim2.new((v - minV) / (maxV - minV), 0, 1, 0)
		lbl.Text = onSet(v)
	end
	set(init)
	local sliding = false
	local function fromX(x) set(minV + (x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X * (maxV - minV)) end
	con(bar.InputBegan, function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then sliding = true; fromX(i.Position.X) end
	end)
	con(UIS.InputChanged, function(i)
		if sliding and i.UserInputType == Enum.UserInputType.MouseMovement then fromX(i.Position.X) end
	end)
	con(UIS.InputEnded, function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then sliding = false end end)
end

-- Helligkeit (Fullbright): 0..10 -> Brightness + ExposureCompensation
mkSlider(104, 0, 10, 2, Color3.fromRGB(255, 200, 60), function(v)
	LPROPS.Brightness = v
	-- unter 2: Ambient + Belichtung mit absenken -> bis fast schwarz runterregelbar
	if v < 2 then
		local g = v / 2
		LPROPS.Ambient = Color3.new(g, g, g); LPROPS.OutdoorAmbient = Color3.new(g, g, g)
		LPROPS.ExposureCompensation = -3 * (1 - g)
	else
		LPROPS.Ambient = Color3.new(1, 1, 1); LPROPS.OutdoorAmbient = Color3.new(1, 1, 1)
		LPROPS.ExposureCompensation = math.clamp((v - 2) / 3, 0, 2.5)
	end
	if state.fullbright then pcall(applyFB) end
	return ("Helligkeit: %.1f"):format(v)
end)

-- ESP-Reichweite + Fade-Zone (letzte X % der Reichweite blenden aus)
mkSlider(138, 25, 3000, state.espDist, Color3.fromRGB(80, 170, 255), function(v)
	state.espDist = math.floor(v)
	return "ESP-Reichweite: " .. state.espDist .. "m"
end)
mkSlider(172, 0, 100, state.espFade * 100, Color3.fromRGB(150, 110, 255), function(v)
	state.espFade = v / 100
	return ("ESP-Fade: letzte %d%% der Reichweite"):format(math.floor(v))
end)

-- ================= ITEM-ESP (gedroppte Tools) =================
-- Spiel-Logik (PromptToolPickup): Tool direkt in workspace + Handle + CanBeDropped = aufhebbar
state.items = false
local itemObjs = {} -- [tool] = {bb=, lbl=}
local function isDropped(t) return t:IsA("Tool") and t.Parent == workspace and t:FindFirstChild("Handle") ~= nil end
local function clearItem(t) local o = itemObjs[t] if o then pcall(function() o.bb:Destroy() end) itemObjs[t] = nil end end
mkToggle(240, "Dropped Items", "items", function(on) if not on then for t in pairs(itemObjs) do clearItem(t) end end end)
con(workspace.ChildRemoved, function(t) clearItem(t) end)

-- ================= PERFORMANCE =================
-- Stufe 0 aus | 1 Schatten/Post-FX/Terrain-Deko aus | 2 + Partikel/Trails/Beams/Decals/Texturen weg | 3 + alles SmoothPlastic, Qualität min
state.perf = 0; state.updInt = 0.2
local perfCur, perfOrig = 0, setmetatable({}, { __mode = "k" })
local function setp(o, k, v)
	local t = perfOrig[o]
	if not t then t = {} perfOrig[o] = t end
	if t[k] == nil then t[k] = o[k] end
	if o[k] ~= v then o[k] = v end
end
local FX2 = { ParticleEmitter = true, Trail = true, Beam = true, Smoke = true, Fire = true, Sparkles = true }
local function perfOne(d, lvl)
	if lvl >= 2 then
		if FX2[d.ClassName] then setp(d, "Enabled", false)
		elseif d:IsA("Decal") then setp(d, "Transparency", 1) end -- Texture erbt von Decal
	end
	if lvl >= 3 and d:IsA("BasePart") then
		setp(d, "Material", Enum.Material.SmoothPlastic); setp(d, "Reflectance", 0); setp(d, "CastShadow", false)
	end
end
local function perfLighting(lvl)
	if lvl < 1 then return end
	setp(Lighting, "GlobalShadows", false)
	for _, o in ipairs(Lighting:GetChildren()) do
		if (o:IsA("SunRaysEffect") or o:IsA("DepthOfFieldEffect") or o:IsA("BloomEffect") or o:IsA("BlurEffect")) and o.Enabled then setp(o, "Enabled", false) end
	end
	local ter = workspace:FindFirstChildOfClass("Terrain")
	if ter then pcall(function() setp(ter, "Decoration", false); setp(ter, "WaterWaveSize", 0); setp(ter, "WaterReflectance", 0) end) end
	if lvl >= 3 then pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end) end
end
local function perfRestore(chunked)
	local old = perfOrig
	perfOrig = setmetatable({}, { __mode = "k" })
	local i = 0
	for o, t in pairs(old) do
		if o.Parent then for k, v in pairs(t) do pcall(function() o[k] = v end) end end
		i = i + 1
		if chunked and i % 1500 == 0 then task.wait() end
	end
	pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic end)
end
mkSlider(274, 0, 3, 0, Color3.fromRGB(90, 220, 140), function(v)
	state.perf = math.floor(v + 0.5)
	return "Performance-Stufe: " .. state.perf .. ({ " (aus)", " (Schatten/FX)", " (+Partikel/Decals)", " (+Materialien)" })[state.perf + 1]
end)
mkSlider(308, 0.05, 1, state.updInt, Color3.fromRGB(200, 200, 200), function(v)
	state.updInt = v
	return ("Hub-Update: %.1f/s (weniger = mehr FPS)"):format(1 / v)
end)
-- Worker: Stufe wechseln (in Chunks, kein Freeze) + neue Instanzen (Regionen laden nach) mitnehmen
con(workspace.DescendantAdded, function(d)
	if perfCur >= 2 then task.defer(function() pcall(perfOne, d, perfCur) end) end
end)
task.spawn(function()
	while H.alive do
		if state.perf ~= perfCur then
			local want = state.perf
			perfRestore(true)
			perfCur = want
			if want >= 2 then
				local all = workspace:GetDescendants()
				for i = 1, #all do
					if not H.alive or state.perf ~= want then break end
					pcall(perfOne, all[i], want)
					if i % 3000 == 0 then task.wait() end
				end
			end
		end
		pcall(perfLighting, perfCur)
		task.wait(1)
	end
end)

-- ================= MARKER =================
local markHL = Instance.new("Highlight")
markHL.Name = "TSC_MARK_HL"; markHL.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
markHL.FillColor = Color3.fromRGB(255, 40, 40); markHL.FillTransparency = 0.55
markHL.OutlineColor = Color3.fromRGB(255, 220, 60); markHL.OutlineTransparency = 0
markHL.Enabled = false; markHL.Parent = gui

local markBB = Instance.new("BillboardGui")
markBB.Name = "TSC_MARK_BB"; markBB.AlwaysOnTop = true; markBB.Size = UDim2.fromOffset(220, 40)
markBB.StudsOffset = Vector3.new(0, 5, 0); markBB.LightInfluence = 0; markBB.Enabled = false; markBB.Parent = gui
local markLbl = Instance.new("TextLabel")
markLbl.Size = UDim2.fromScale(1, 1); markLbl.BackgroundColor3 = Color3.fromRGB(0, 0, 0); markLbl.BackgroundTransparency = 1
markLbl.Font = Enum.Font.GothamBlack; markLbl.TextSize = 15; markLbl.TextColor3 = Color3.fromRGB(255, 90, 90)
markLbl.TextStrokeTransparency = 0.2
markLbl.Parent = markBB


-- Randpfeil, wenn Ziel off-screen / hinter mir
local arrow = Instance.new("TextLabel")
arrow.Size = UDim2.fromOffset(160, 40); arrow.AnchorPoint = Vector2.new(0.5, 0.5); arrow.BackgroundTransparency = 1
arrow.Font = Enum.Font.GothamBlack; arrow.TextSize = 16; arrow.TextColor3 = Color3.fromRGB(255, 60, 60)
arrow.TextStrokeTransparency = 0; arrow.Visible = false; arrow.Parent = gui

local markInfo = Instance.new("TextLabel")
markInfo.Size = UDim2.new(1, -16, 0, 20); markInfo.Position = UDim2.fromOffset(8, 342)
markInfo.BackgroundTransparency = 1; markInfo.Font = Enum.Font.Gotham; markInfo.TextSize = 13
markInfo.TextColor3 = Color3.fromRGB(255, 120, 120); markInfo.TextXAlignment = Enum.TextXAlignment.Left
markInfo.Text = "Marker: -"; markInfo.Parent = main

local clearBtn = Instance.new("TextButton")
clearBtn.Size = UDim2.fromOffset(60, 20); clearBtn.Position = UDim2.new(1, -68, 0, 342)
clearBtn.BackgroundColor3 = Color3.fromRGB(120, 40, 40); clearBtn.BorderSizePixel = 0; clearBtn.Font = Enum.Font.Gotham
clearBtn.TextSize = 12; clearBtn.TextColor3 = Color3.new(1, 1, 1); clearBtn.Text = "weg"; clearBtn.Parent = main
Instance.new("UICorner", clearBtn).CornerRadius = UDim.new(0, 5)

local search = Instance.new("TextBox")
search.Size = UDim2.new(1, -16, 0, 24); search.Position = UDim2.fromOffset(8, 368)
search.BackgroundColor3 = Color3.fromRGB(40, 42, 50); search.BorderSizePixel = 0; search.Font = Enum.Font.Gotham
search.TextSize = 13; search.TextColor3 = Color3.new(1, 1, 1); search.PlaceholderText = "Spieler suchen..."
search.Text = ""; search.ClearTextOnFocus = false; search.Parent = main
Instance.new("UICorner", search).CornerRadius = UDim.new(0, 5)

local list = Instance.new("ScrollingFrame")
list.Size = UDim2.new(1, -16, 1, -406); list.Position = UDim2.fromOffset(8, 398)
list.BackgroundColor3 = Color3.fromRGB(28, 30, 36); list.BorderSizePixel = 0; list.ScrollBarThickness = 5
list.AutomaticCanvasSize = Enum.AutomaticSize.Y; list.CanvasSize = UDim2.new(); list.Parent = main
local lay = Instance.new("UIListLayout", list); lay.Padding = UDim.new(0, 2); lay.SortOrder = Enum.SortOrder.Name

local function markedPlayer()
	if not state.markId then return nil end
	return Players:GetPlayerByUserId(state.markId)
end

local rebuildList
local function setMark(p)
	if p then state.markId = p.UserId; state.markName = p.Name else state.markId = nil; state.markName = nil end
	rebuildList()
end
con(clearBtn.MouseButton1Click, function() setMark(nil) end)

function rebuildList()
	for _, c in ipairs(list:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
	local q = search.Text:lower()
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= lp and (q == "" or p.Name:lower():find(q, 1, true) or p.DisplayName:lower():find(q, 1, true)) then
			local b = Instance.new("TextButton")
			b.Name = p.Name:lower(); b.Size = UDim2.new(1, -6, 0, 22); b.BorderSizePixel = 0
			b.BackgroundColor3 = (state.markId == p.UserId) and Color3.fromRGB(150, 40, 40) or Color3.fromRGB(45, 48, 58)
			b.Font = Enum.Font.Gotham; b.TextSize = 12; b.TextXAlignment = Enum.TextXAlignment.Left
			b.TextColor3 = teamColor(p)
			b.Text = "  " .. p.DisplayName .. " (@" .. p.Name .. ")  " .. (p.Team and p.Team.Name or "")
			b.Parent = list
			b.MouseButton1Click:Connect(function()
				if state.markId == p.UserId then setMark(nil) else setMark(p) end
			end)
		end
	end
end
con(search:GetPropertyChangedSignal("Text"), function() rebuildList() end)
con(Players.PlayerAdded, function() rebuildList() end)
con(Players.PlayerRemoving, function(p) removeEsp(p); task.defer(rebuildList) end)
rebuildList()

-- ================= UPDATE-LOOPS =================
local function rootOf(p)
	local c = p.Character
	return c and (c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("Head") or c.PrimaryPart), c
end

-- ESP-Text ~5 Hz (120 Spieler)
task.spawn(function()
	while H.alive do
		if state.esp then
			local myRoot = rootOf(lp)
			local myPos = myRoot and myRoot.Position or cam.CFrame.Position
			for _, p in ipairs(Players:GetPlayers()) do
				if p ~= lp then
					local r, c = rootOf(p)
					if r then
						local d = (r.Position - myPos).Magnitude
						if d <= state.espDist then
							local e = ensureEsp(p)
							if e.bb.Adornee ~= r then e.bb.Adornee = r end
							local hum = c:FindFirstChildOfClass("Humanoid")
							local hp = hum and math.floor(hum.Health) or 0
							e.lbl.TextColor3 = teamColor(p)
							-- Fade: ab (1-espFade)*Reichweite linear ausblenden
							local fs = state.espDist * (1 - state.espFade)
							local a = (d > fs and state.espDist > fs) and math.clamp((d - fs) / (state.espDist - fs), 0, 1) or 0
							e.lbl.TextTransparency = a * 0.95
							e.lbl.TextStrokeTransparency = 0.3 + 0.7 * a
							e.lbl.Text = p.DisplayName .. " [" .. (p.Team and p.Team.Name or "?") .. "]\n" .. math.floor(d) .. "m  HP " .. hp
						else
							removeEsp(p)
						end
					else
						removeEsp(p)
					end
				end
			end
		end
		-- Dropped Items
		if state.items then
			local myRoot = rootOf(lp)
			local myPos = myRoot and myRoot.Position or cam.CFrame.Position
			for _, t in ipairs(workspace:GetChildren()) do
				if isDropped(t) then
					local h = t.Handle
					local d = (h.Position - myPos).Magnitude
					if d <= state.espDist then
						local o = itemObjs[t]
						if not o then
							local bb = Instance.new("BillboardGui")
							bb.AlwaysOnTop = true; bb.Size = UDim2.fromOffset(160, 26); bb.StudsOffset = Vector3.new(0, 1.5, 0)
							bb.LightInfluence = 0; bb.Parent = espFolder
							local l = Instance.new("TextLabel")
							l.Size = UDim2.fromScale(1, 1); l.BackgroundTransparency = 1; l.Font = Enum.Font.GothamBold
							l.TextSize = 12; l.TextColor3 = Color3.fromRGB(120, 255, 140); l.TextStrokeTransparency = 0.3; l.Parent = bb
							o = { bb = bb, lbl = l }
							itemObjs[t] = o
						end
						if o.bb.Adornee ~= h then o.bb.Adornee = h end
						o.lbl.Text = "▣ " .. t.Name .. "  " .. math.floor(d) .. "m"
						local fs = state.espDist * (1 - state.espFade)
						local a = (d > fs and state.espDist > fs) and math.clamp((d - fs) / (state.espDist - fs), 0, 1) or 0
						o.lbl.TextTransparency = a * 0.95
					else
						clearItem(t)
					end
				end
			end
		end
		task.wait(state.updInt)
	end
end)

-- Marker jeden Frame
con(RunService.RenderStepped, function()
	local p = markedPlayer()
	if not p then
		markHL.Enabled = false; markBB.Enabled = false; arrow.Visible = false
		markInfo.Text = state.markName and ("Marker: " .. state.markName .. " (offline)") or "Marker: -"
		return
	end
	local r, c = rootOf(p)
	if not r then
		markHL.Enabled = false; markBB.Enabled = false; arrow.Visible = false
		markInfo.Text = "Marker: " .. p.Name .. " (kein Char/nicht gestreamt)"
		return
	end
	if markHL.Adornee ~= c then markHL.Adornee = c end
	if markBB.Adornee ~= r then markBB.Adornee = r end
	markHL.Enabled = true; markBB.Enabled = true
	local myRoot = rootOf(lp)
	local d = myRoot and math.floor((r.Position - myRoot.Position).Magnitude) or 0
	markLbl.Text = "◆ " .. p.DisplayName .. " ◆\n" .. d .. "m"
	markInfo.Text = "Marker: " .. p.Name .. "  " .. d .. "m"

	local vp = cam.ViewportSize
	local sp, onScreen = cam:WorldToViewportPoint(r.Position)
	if onScreen and sp.Z > 0 then
		arrow.Visible = false
	else
		local center = vp / 2
		local dir = Vector2.new(sp.X, sp.Y) - center
		if sp.Z < 0 then dir = -dir end
		if dir.Magnitude < 1 then dir = Vector2.new(0, -1) end
		dir = dir.Unit
		local m = 60
		local sx = (center.X - m) / math.max(math.abs(dir.X), 1e-3)
		local sy = (center.Y - m) / math.max(math.abs(dir.Y), 1e-3)
		local pos = center + dir * math.min(sx, sy)
		arrow.Position = UDim2.fromOffset(pos.X, pos.Y)
		arrow.Text = "➤ " .. p.DisplayName .. " " .. d .. "m"
		arrow.Rotation = 0
		arrow.Visible = true
	end
end)

-- ================= STAFF-RADAR =================
-- Gruppe 11577231: Rang >= 90 = Staff (External Command, Intern, Dept-Admin, Contractor, Devs);
-- plrUniqueTag_txt-Attribut = Staff-Tag (QA etc.). Panel oben mittig, immer sichtbar (auch wenn Hub zu).
local GROUP_ID, STAFF_MIN = 11577231, 90
local rankCache = {} -- [userId] = {rank=, role=}
local function fetchRank(p)
	if rankCache[p.UserId] then return end
	rankCache[p.UserId] = { rank = -1, role = "?" }
	task.spawn(function()
		local ok, r = pcall(function() return p:GetRankInGroup(GROUP_ID) end)
		local ok2, role = pcall(function() return p:GetRoleInGroup(GROUP_ID) end)
		rankCache[p.UserId] = { rank = ok and r or -1, role = ok2 and role or "?" }
	end)
end
local function staffInfo(p)
	local rc = rankCache[p.UserId]
	local tag = p:GetAttribute("plrUniqueTag_txt")
	if rc and rc.rank >= STAFF_MIN then return rc.role .. (tag and (" | " .. tag) or ""), true end
	if tag and tag ~= "" then return tostring(tag), false end
	return nil
end
for _, p in ipairs(Players:GetPlayers()) do fetchRank(p) end

local staffPanel = Instance.new("TextLabel")
staffPanel.AnchorPoint = Vector2.new(0.5, 0); staffPanel.Position = UDim2.new(0.5, 0, 0, 44)
staffPanel.Size = UDim2.fromOffset(420, 20); staffPanel.AutomaticSize = Enum.AutomaticSize.Y
staffPanel.BackgroundColor3 = Color3.fromRGB(15, 15, 20); staffPanel.BackgroundTransparency = 0.35
staffPanel.Font = Enum.Font.GothamBold; staffPanel.TextSize = 13; staffPanel.RichText = true
staffPanel.TextColor3 = Color3.new(1, 1, 1); staffPanel.TextXAlignment = Enum.TextXAlignment.Left
staffPanel.TextYAlignment = Enum.TextYAlignment.Top; staffPanel.Visible = false; staffPanel.Parent = gui
Instance.new("UICorner", staffPanel).CornerRadius = UDim.new(0, 6)
local pad = Instance.new("UIPadding", staffPanel)
pad.PaddingLeft = UDim.new(0, 8); pad.PaddingTop = UDim.new(0, 4); pad.PaddingBottom = UDim.new(0, 4)

state.staff = true
mkToggle(206, "Staff-Radar", "staff", function() end)

local staffObjs = {} -- [player] = {bb=, lbl=, box=}
local function clearStaffObj(p)
	local o = staffObjs[p]
	if o then pcall(function() o.bb:Destroy() end) pcall(function() o.box:Destroy() end) staffObjs[p] = nil end
end
con(Players.PlayerAdded, function(p) fetchRank(p) end)
con(Players.PlayerRemoving, function(p) clearStaffObj(p) end)

local function isInvisible(c)
	local any, vis = false, false
	for _, d in ipairs(c:GetDescendants()) do
		if d:IsA("BasePart") and d.Name ~= "HumanoidRootPart" then
			any = true
			if d.Transparency < 0.9 then vis = true break end
		end
	end
	return any and not vis
end

local function esc(s) return (tostring(s):gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;")) end

task.spawn(function()
	while H.alive do
		local lines, n = {}, 0
		local myRoot = rootOf(lp)
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= lp then
				local info, isStaff = staffInfo(p)
				if info and state.staff then
					n = n + 1
					local c = p.Character
					local r = c and c:FindFirstChild("HumanoidRootPart")
					local status, col
					if not c then
						status, col = "KEIN CHAR (Spectate/Menü?)", "#ff4040"
					elseif not c.Parent then
						status, col = "nicht geladen (anderer Bereich)", "#aaaaaa"
					elseif isInvisible(c) then
						status, col = "UNSICHTBAR", "#ff4040"
					else
						status, col = "sichtbar", "#80ff80"
					end
					local dist = (r and myRoot) and math.floor((r.Position - myRoot.Position).Magnitude) or nil
					if dist and c and c.Parent and dist < 60 and status ~= "sichtbar" then col = "#ff00ff" end
					if p:GetAttribute("InMenu") then status = status .. " [InMenu]" end
					lines[#lines + 1] = ('<font color="%s">%s %s</font>  <font color="#9ab">%s</font>  %s%s'):format(
						isStaff and "#ffcc40" or "#8fd0ff", isStaff and "★" or "•", esc(p.Name), esc(info),
						('<font color="%s">%s</font>'):format(col, status), dist and ("  " .. dist .. "m") or "")
					-- Welt-Marker (auch für unsichtbare): Box am Root + Label, ignoriert ESP-Reichweite
					if r and c.Parent then
						local o = staffObjs[p]
						if not o then
							local bb = Instance.new("BillboardGui")
							bb.AlwaysOnTop = true; bb.Size = UDim2.fromOffset(220, 30); bb.StudsOffset = Vector3.new(0, 3.6, 0)
							bb.LightInfluence = 0; bb.Parent = gui
							local l = Instance.new("TextLabel")
							l.Size = UDim2.fromScale(1, 1); l.BackgroundTransparency = 1; l.Font = Enum.Font.GothamBold
							l.TextSize = 13; l.TextStrokeTransparency = 0.2; l.Parent = bb
							local box = Instance.new("BoxHandleAdornment")
							box.AlwaysOnTop = true; box.ZIndex = 5; box.Size = Vector3.new(2.2, 5, 1.4)
							box.Transparency = 0.6; box.Parent = gui
							o = { bb = bb, lbl = l, box = box }
							staffObjs[p] = o
						end
						o.bb.Adornee = r; o.box.Adornee = r
						o.box.Color3 = isStaff and Color3.fromRGB(255, 200, 40) or Color3.fromRGB(120, 200, 255)
						o.lbl.TextColor3 = o.box.Color3
						o.lbl.Text = (isStaff and "★ STAFF " or "• ") .. p.Name .. (status ~= "sichtbar" and (" [" .. status .. "]") or "")
					else
						clearStaffObj(p)
					end
				else
					clearStaffObj(p)
				end
			end
		end
		if state.staff and n > 0 then
			staffPanel.Text = ('<font color="#ffcc40">STAFF IM SERVER: %d</font>\n'):format(n) .. table.concat(lines, "\n")
			staffPanel.Visible = true
		else
			staffPanel.Visible = false
		end
		task.wait(math.max(0.5, state.updInt))
	end
end)

-- Toggle GUI
con(UIS.InputBegan, function(i, gp)
	if not gp and i.KeyCode == Enum.KeyCode.RightShift then main.Visible = not main.Visible end
end)

function H.kill()
	H.alive = false
	for _, c in ipairs(H.conns) do pcall(function() c:Disconnect() end) end
	H.conns = {}
	pcall(restoreFB)
	pcall(perfRestore)
	pcall(function() gui:Destroy() end)
end

return "TSC HUB geladen"
