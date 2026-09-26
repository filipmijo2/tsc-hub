-- TSC HUB (Thunder Scientific) — hook-frei: nur Lighting-Props + eigene GUI/Adornments in CoreGui
-- Start: loadstring(readfile("tsc_hub.lua"))()   Toggle GUI: RightShift (umbelegbar unter Settings)

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

-- Persistenz: Einstellungen in tsc_hub_settings.json (überlebt Re-Execute/Rejoin)
local HttpService = game:GetService("HttpService")
local SAVE_FILE = "tsc_hub_settings.json"
local saved = {}
pcall(function() if isfile(SAVE_FILE) then saved = HttpService:JSONDecode(readfile(SAVE_FILE)) end end)
if type(saved) ~= "table" then saved = {} end
local function sv(k, def) if saved[k] ~= nil then return saved[k] end return def end
local function kc(n, def) local ok, k = pcall(function() return Enum.KeyCode[n] end) return (ok and k) or def end
local SAVE_KEYS = { "fullbright", "esp", "espDist", "espFade", "bright", "items", "perf", "updInt", "nofall", "staff", "markId", "markName",
	"vent", "ventPred", "ventLog", "ventBias" }

local state = { fullbright = sv("fullbright", false), esp = sv("esp", false), espDist = sv("espDist", 1500),
	espFade = sv("espFade", 0.4), bright = sv("bright", 2), markId = sv("markId", nil), markName = sv("markName", nil),
	keys = { menu = kc(sv("keyMenu", "RightShift"), Enum.KeyCode.RightShift), vent = kc(sv("keyVent", "End"), Enum.KeyCode.End) } }
H.state = state

-- ================= THEME / GUI-BAUKASTEN (Matcha-Stil) =================
local T = {
	bg = Color3.fromRGB(17, 17, 17), panel = Color3.fromRGB(23, 23, 23), stroke = Color3.fromRGB(40, 40, 40),
	edge = Color3.fromRGB(52, 52, 52), track = Color3.fromRGB(38, 38, 38), off = Color3.fromRGB(48, 48, 48),
	accent = Color3.fromRGB(245, 168, 222), text = Color3.fromRGB(232, 232, 232), dim = Color3.fromRGB(118, 118, 118),
	font = Enum.Font.Code, ts = 13,
}

local gui = Instance.new("ScreenGui")
gui.Name = "TSC_HUB"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true; gui.DisplayOrder = 999
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = CoreGui

local espFolder = Instance.new("Folder"); espFolder.Name = "TSC_ESP"; espFolder.Parent = gui

local function stroke(o, c) local s = Instance.new("UIStroke"); s.Color = c or T.stroke; s.Thickness = 1
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; s.Parent = o; return s end
local function corner(o, r) Instance.new("UICorner", o).CornerRadius = UDim.new(0, r or 3) end
local function txt(parent, text, size, color)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1; l.Font = T.font; l.TextSize = T.ts; l.TextColor3 = color or T.text
	l.Text = text; l.TextXAlignment = Enum.TextXAlignment.Left; l.Size = size; l.Parent = parent
	return l
end

local main = Instance.new("Frame")
main.Size = UDim2.fromOffset(540, 470); main.Position = UDim2.fromOffset(sv("guiX", 40), sv("guiY", 160))
main.Visible = sv("guiVisible", true)
main.BackgroundColor3 = T.bg; main.BorderSizePixel = 0; main.Active = true
main.Parent = gui
corner(main, 4); stroke(main, T.edge)

local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 26); titleBar.BackgroundTransparency = 1; titleBar.Active = true; titleBar.Parent = main
txt(titleBar, "◆", UDim2.fromOffset(14, 26), T.accent).Position = UDim2.fromOffset(10, 0)
txt(titleBar, "TSC Hub - " .. lp.Name, UDim2.new(1, -40, 1, 0)).Position = UDim2.fromOffset(28, 0)

-- Drag
do
	local dragging, startPos, startMouse
	con(titleBar.InputBegan, function(i)
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

-- Tabs
local tabBar = Instance.new("Frame")
tabBar.Size = UDim2.new(1, -20, 0, 18); tabBar.Position = UDim2.fromOffset(10, 26); tabBar.BackgroundTransparency = 1; tabBar.Parent = main
local tl = Instance.new("UIListLayout", tabBar); tl.FillDirection = Enum.FillDirection.Horizontal; tl.Padding = UDim.new(0, 12)
tl.SortOrder = Enum.SortOrder.LayoutOrder

local content = Instance.new("Frame")
content.Size = UDim2.new(1, -16, 1, -56); content.Position = UDim2.fromOffset(8, 48); content.BackgroundTransparency = 1
content.Parent = main

local pages, tabBtns = {}, {}
local function selectTab(name)
	for n, pg in pairs(pages) do pg.Visible = (n == name) end
	for n, b in pairs(tabBtns) do b.TextColor3 = (n == name) and T.text or T.dim end
end
local function mkCol(page, right)
	local c = Instance.new("ScrollingFrame")
	c.BackgroundTransparency = 1; c.BorderSizePixel = 0; c.ScrollBarThickness = 2; c.ScrollBarImageColor3 = T.accent
	c.Size = UDim2.new(0.5, -4, 1, 0); c.Position = right and UDim2.new(0.5, 4, 0, 0) or UDim2.new()
	c.AutomaticCanvasSize = Enum.AutomaticSize.Y; c.CanvasSize = UDim2.new(); c.Parent = page
	local l = Instance.new("UIListLayout", c); l.Padding = UDim.new(0, 8); l.SortOrder = Enum.SortOrder.LayoutOrder
	local p = Instance.new("UIPadding", c)
	p.PaddingTop = UDim.new(0, 1); p.PaddingLeft = UDim.new(0, 1); p.PaddingRight = UDim.new(0, 5); p.PaddingBottom = UDim.new(0, 1)
	return c
end
local function tab(name)
	local b = Instance.new("TextButton")
	b.AutomaticSize = Enum.AutomaticSize.X; b.Size = UDim2.new(0, 0, 1, 0); b.BackgroundTransparency = 1
	b.Font = T.font; b.TextSize = T.ts; b.Text = name; b.TextColor3 = T.dim; b.LayoutOrder = #tabBar:GetChildren()
	b.Parent = tabBar
	local page = Instance.new("Frame"); page.Size = UDim2.fromScale(1, 1); page.BackgroundTransparency = 1; page.Visible = false
	page.Parent = content
	pages[name] = page; tabBtns[name] = b
	con(b.MouseButton1Click, function() selectTab(name) end)
	return mkCol(page, false), mkCol(page, true)
end

local secN = 0
local function section(col, name)
	secN = secN + 1
	local f = Instance.new("Frame")
	f.BackgroundColor3 = T.panel; f.BorderSizePixel = 0; f.Size = UDim2.new(1, 0, 0, 0); f.AutomaticSize = Enum.AutomaticSize.Y
	f.LayoutOrder = secN; f.Parent = col
	stroke(f); corner(f, 3)
	local pd = Instance.new("UIPadding", f)
	pd.PaddingTop = UDim.new(0, 6); pd.PaddingBottom = UDim.new(0, 8); pd.PaddingLeft = UDim.new(0, 8); pd.PaddingRight = UDim.new(0, 8)
	local l = Instance.new("UIListLayout", f); l.Padding = UDim.new(0, 5); l.SortOrder = Enum.SortOrder.LayoutOrder
	txt(f, name, UDim2.new(1, 0, 0, 16)).LayoutOrder = 0
	return { f = f, n = 0 }
end
local function nextOrder(S) S.n = S.n + 1 return S.n end

-- Keybinds: Klick auf Box -> nächste Taste belegen (Escape = abbrechen)
local listening, keyBoxes = nil, {}
local function keyName(k) return k and k.Name:lower() or "none" end
local function keybox(parent, id)
	local b = Instance.new("TextButton")
	b.Size = UDim2.fromOffset(78, 16); b.AnchorPoint = Vector2.new(1, 0); b.Position = UDim2.new(1, 0, 0, 0)
	b.BackgroundColor3 = T.track; b.BorderSizePixel = 0; b.AutoButtonColor = false
	b.Font = T.font; b.TextSize = 12; b.TextColor3 = T.dim; b.Text = keyName(state.keys[id]); b.Parent = parent
	stroke(b); corner(b, 2)
	keyBoxes[id] = b
	con(b.MouseButton1Click, function() listening = id; b.Text = "..."; b.TextColor3 = T.accent end)
	return b
end

local refresh = {}
local ctl = {} -- Config: [id] = {get=, set=}
local function toggle(S, label, key, onChange, bindId)
	local row = Instance.new("TextButton")
	row.AutoButtonColor = false; row.BackgroundTransparency = 1; row.Text = ""; row.Size = UDim2.new(1, 0, 0, 16)
	row.LayoutOrder = nextOrder(S); row.Parent = S.f
	local dot = Instance.new("Frame")
	dot.Size = UDim2.fromOffset(12, 12); dot.Position = UDim2.fromOffset(0, 2); dot.BorderSizePixel = 0; dot.Parent = row
	Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
	stroke(dot)
	local l = txt(row, label, UDim2.new(1, bindId and -104 or -20, 1, 0)); l.Position = UDim2.fromOffset(20, 0)
	if bindId then keybox(row, bindId) end
	local function paint()
		local on = state[key]
		dot.BackgroundColor3 = on and T.accent or T.off
		l.TextColor3 = on and T.text or T.dim
	end
	paint()
	if state[key] then task.spawn(onChange, true) end -- gespeicherten Zustand anwenden
	con(row.MouseButton1Click, function() state[key] = not state[key]; paint(); task.spawn(onChange, state[key]) end)
	refresh[key] = paint
	ctl[key] = { get = function() return state[key] end,
		set = function(v) if state[key] ~= v then state[key] = v; paint(); task.spawn(onChange, v) end end }
	return paint
end

local function keyRow(S, label, id)
	local row = Instance.new("Frame"); row.BackgroundTransparency = 1; row.Size = UDim2.new(1, 0, 0, 16)
	row.LayoutOrder = nextOrder(S); row.Parent = S.f
	txt(row, label, UDim2.new(1, -84, 1, 0))
	keybox(row, id)
end

-- Slider: Label oben, Pill mit pinker Füllung + Wert mittig; onSet(v) liefert Werttext
local function slider(S, label, minV, maxV, init, onSet, id)
	txt(S.f, label, UDim2.new(1, 0, 0, 14)).LayoutOrder = nextOrder(S)
	local bar = Instance.new("Frame")
	bar.Size = UDim2.new(1, 0, 0, 14); bar.BackgroundColor3 = T.track; bar.BorderSizePixel = 0; bar.Active = true
	bar.LayoutOrder = nextOrder(S); bar.Parent = S.f
	corner(bar, 7)
	local fill = Instance.new("Frame")
	fill.BackgroundColor3 = T.accent; fill.BorderSizePixel = 0; fill.Parent = bar
	corner(fill, 7)
	local val = txt(bar, "", UDim2.fromScale(1, 1), T.text)
	val.TextXAlignment = Enum.TextXAlignment.Center; val.TextSize = 12; val.ZIndex = 2
	val.TextStrokeTransparency = 0.55; val.TextStrokeColor3 = Color3.new(0, 0, 0)
	local raw = init
	local function set(v)
		v = math.clamp(v, minV, maxV); raw = v
		fill.Size = UDim2.new((v - minV) / (maxV - minV), 0, 1, 0)
		val.Text = onSet(v)
	end
	set(init)
	if id then ctl[id] = { get = function() return raw end, set = set } end
	local sliding = false
	local function fromX(x) set(minV + (x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X * (maxV - minV)) end
	con(bar.InputBegan, function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then sliding = true; fromX(i.Position.X) end
	end)
	con(UIS.InputChanged, function(i)
		if sliding and i.UserInputType == Enum.UserInputType.MouseMovement then fromX(i.Position.X) end
	end)
	con(UIS.InputEnded, function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then sliding = false end end)
	return set
end

local function dropdown(S, label, opts, idx, onSel, id)
	txt(S.f, label, UDim2.new(1, 0, 0, 14)).LayoutOrder = nextOrder(S)
	local box = Instance.new("TextButton")
	box.Size = UDim2.new(1, 0, 0, 18); box.BackgroundColor3 = T.track; box.BorderSizePixel = 0; box.AutoButtonColor = false
	box.Text = ""; box.LayoutOrder = nextOrder(S); box.Parent = S.f
	stroke(box); corner(box, 2)
	local cur = txt(box, opts[idx], UDim2.new(1, -24, 1, 0)); cur.Position = UDim2.fromOffset(6, 0)
	local arr = txt(box, "▼", UDim2.new(0, 14, 1, 0), T.text); arr.Position = UDim2.new(1, -16, 0, 0); arr.TextSize = 10
	local list = Instance.new("Frame")
	list.Size = UDim2.new(1, 0, 0, 0); list.AutomaticSize = Enum.AutomaticSize.Y; list.BackgroundColor3 = T.bg
	list.BorderSizePixel = 0; list.Visible = false; list.LayoutOrder = nextOrder(S); list.Parent = S.f
	stroke(list)
	Instance.new("UIListLayout", list).SortOrder = Enum.SortOrder.LayoutOrder
	local items = {}
	local function paint() for i, b in ipairs(items) do b.TextColor3 = (i == idx) and T.accent or T.dim end end
	for i, o in ipairs(opts) do
		local b = Instance.new("TextButton")
		b.Size = UDim2.new(1, 0, 0, 17); b.BackgroundTransparency = 1; b.Font = T.font; b.TextSize = 12
		b.Text = "  " .. o; b.TextXAlignment = Enum.TextXAlignment.Left; b.LayoutOrder = i; b.Parent = list
		items[i] = b
		con(b.MouseButton1Click, function()
			idx = i; cur.Text = o; list.Visible = false; arr.Text = "▼"; paint(); task.spawn(onSel, i)
		end)
	end
	paint()
	if id then ctl[id] = { get = function() return idx end,
		set = function(i) if opts[i] then idx = i; cur.Text = opts[i]; paint(); task.spawn(onSel, i) end end } end
	con(box.MouseButton1Click, function() list.Visible = not list.Visible; arr.Text = list.Visible and "▲" or "▼" end)
end

local function button(S, label, fn)
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(1, 0, 0, 18); b.BackgroundColor3 = T.track; b.BorderSizePixel = 0; b.AutoButtonColor = false
	b.Font = T.font; b.TextSize = 12; b.TextColor3 = T.text; b.Text = label; b.LayoutOrder = nextOrder(S); b.Parent = S.f
	stroke(b); corner(b, 2)
	con(b.MouseButton1Click, fn)
	con(b.MouseEnter, function() b.TextColor3 = T.accent end)
	con(b.MouseLeave, function() b.TextColor3 = T.text end)
	return b
end

local function info(S, text, color)
	local l = txt(S.f, text, UDim2.new(1, 0, 0, 0), color or T.dim)
	l.AutomaticSize = Enum.AutomaticSize.Y; l.TextWrapped = true; l.RichText = true; l.TextSize = 12
	l.LayoutOrder = nextOrder(S)
	return l
end

-- Seiten + Sektionen
local comL = tab("Combat")
local visL, visR = tab("Visuals")
local miscL, miscR = tab("Misc")
local optL, optR = tab("Options")
local cfgL = tab("Config")
local plL, plR = tab("Players")

local S_combat = section(comL, "Combat")
local S_light = section(visL, "Lighting")
local S_items = section(visL, "Items")
local S_esp = section(visR, "ESP")
local S_staff = section(visR, "Staff Radar")
local S_vent = section(miscL, "Auto Vent")
local S_move = section(miscR, "Movement")
local S_menu = section(optL, "Menu")
local S_perf = section(optR, "Performance")
local S_cfg = section(cfgL, "Config")
local S_mark = section(plL, "Target")
local S_plInfo = section(plR, "Info")
info(S_combat, "Nothing here yet.")

-- ================= AUTO VENT =================
-- Spiel (VentSystemL, jedes RenderStepped): u8 = (MausX - Frame.AbsX)/Frame.AbsW; drin wenn Green.X < u8 < Green.X+Green.W
-- (Green vom letzten Frame), danach bewegt sich Green (prallt an 0/u7 ab). Marker.X = gelesenes u8.
-- Hook-frei (namecall-Hook = Kick!), keine Remotes: nur GUI lesen + echten Cursor (mousemoveabs) setzen.
-- Heartbeat läuft nach dem Green-Update; Lag wird über Marker.X vs. eigene Befehle gemessen, Vorhersage prallt ab.
-- M1 hält man selbst.
state.vent = sv("vent", true); state.ventPred = sv("ventPred", true); state.ventLog = sv("ventLog", true); state.ventBias = sv("ventBias", 0)
local V = { hist = {}, lagF = 1, prevP = nil, prevW = 0, dir = 1, mult = 1, open = false, st = nil, wasRed = false, last = "-" }
local VENT_LOG, MAX_LAG = "_autovent_log.txt", 6
local focused = (typeof(isrbxactive) == "function") and isrbxactive or function() return true end
local hasMove = typeof(mousemoveabs) == "function"

local function ventParts()
	local pg = lp:FindFirstChild("PlayerGui"); local mg = pg and pg:FindFirstChild("VentMinigame"); if not mg then return end
	local fr = mg:FindFirstChild("Frame"); if not fr or not fr.Visible then return end
	local gr = fr:FindFirstChild("Green"); if not gr then return end
	return fr, gr, fr:FindFirstChild("Marker")
end
-- Green um dist (Scale) in [0, u7] weiterschieben, an den Rändern abprallen wie im Spiel
local function advance(p, d, dist, u7)
	if u7 <= 0 then return 0 end
	local q = p + d * dist
	for _ = 1, 4 do
		if q > u7 then q = 2 * u7 - q elseif q < 0 then q = -q else break end
	end
	return math.clamp(q, 0, u7)
end
local function ventFlush()
	local st = V.st; V.st = nil
	if not st or st.frames == 0 then return end
	V.last = ("%d fails · min %.0fpx · %.1fs"):format(st.fails, st.minPx < 1e8 and st.minPx or 0, os.clock() - st.t0)
	if not state.ventLog then return end
	local line = ("[%s] %.1fs frames=%d drillFrames=%d outWhileDrill=%d fails=%d minMarginPx=%.1f edgeOut=%d lagF=%.2f mult=%.2f %s\n"):format(
		os.date("%H:%M:%S"), os.clock() - st.t0, st.frames, st.drill, st.out, st.fails, st.minPx, st.edgeOut, V.lagF, V.mult, table.concat(st.notes, " "))
	pcall(function()
		if typeof(appendfile) == "function" and isfile(VENT_LOG) then appendfile(VENT_LOG, line)
		else writefile(VENT_LOG, (isfile(VENT_LOG) and readfile(VENT_LOG) or "") .. line) end
	end)
end

con(RunService.Heartbeat, function(dt)
	local fr, gr, mk = ventParts()
	if not state.vent or not fr then
		if V.open then ventFlush(); V.hist = {}; V.prevP = nil; V.open = false end
		return
	end
	if not V.open then
		V.open = true
		V.st = { t0 = os.clock(), frames = 0, drill = 0, out = 0, fails = 0, minPx = 1e9, edgeOut = 0, notes = {} }
	end
	local st = V.st
	local p, w = gr.Position.X.Scale, gr.Size.X.Scale
	local u7 = 1 - w

	if V.prevP then
		-- Telemetrie: Marker = u8, das das Spiel diesen Frame gegen Green des Vorframes geprüft hat
		if mk then
			local m, pp, pw = mk.Position.X.Scale, V.prevP, V.prevW
			local mar = math.min(m - pp, pp + pw - m) * fr.AbsoluteSize.X
			local bc = fr.BackgroundColor3
			st.frames = st.frames + 1
			if bc.R > 0.35 and bc.G < 0.15 then -- Frame rot = am Bohren
				st.drill = st.drill + 1
				st.minPx = math.min(st.minPx, mar)
				if mar <= 0 then
					st.out = st.out + 1
					if pp < 0.01 or pp > (1 - pw) - 0.01 then st.edgeOut = st.edgeOut + 1 end
				end
			end
			local c = gr.BackgroundColor3
			local red = c.R > 0.95 and c.G < 0.05 and c.B < 0.05
			if red and not V.wasRed then
				st.fails = st.fails + 1
				st.notes[#st.notes + 1] = ("FAIL(m=%.3f g=%.3f..%.3f focus=%s)"):format(m, pp, pp + pw, tostring(focused()))
			end
			V.wasRed = red
		end
		-- Richtung + Tempo-Multiplikator (Tools) aus der Bewegung
		if p ~= V.prevP then
			if p <= 1e-6 then V.dir = 1
			elseif p >= u7 - 1e-6 then V.dir = -1
			else
				V.dir = (p > V.prevP) and 1 or -1
				if u7 > 0.01 and dt > 0 then
					local m = math.abs(p - V.prevP) / (u7 * dt)
					if m > 0.2 and m < 5 then V.mult = V.mult + (m - V.mult) * 0.2 end
				end
			end
		end
	end
	V.prevP, V.prevW = p, w

	-- Lag messen: welchen unserer letzten Befehle hat das Spiel gerade gelesen?
	if mk and #V.hist >= 2 then
		local m = mk.Position.X.Scale
		local bestK, bestE = nil, 1.5 / fr.AbsoluteSize.X
		for k = 1, math.min(#V.hist, MAX_LAG) do
			local e = math.abs(V.hist[#V.hist - k + 1] - m)
			if e < bestE then bestE, bestK = e, k end
		end
		if bestK then V.lagF = V.lagF + (bestK - V.lagF) * 0.15 end
	end

	local fdt = math.clamp(dt, 1 / 240, 1 / 20)
	local ahead = state.ventPred and math.max(V.lagF - 1 + state.ventBias, 0) * fdt or 0
	local target = advance(p, V.dir, u7 * V.mult * ahead, u7) + w * 0.5
	V.hist[#V.hist + 1] = target
	if #V.hist > MAX_LAG + 2 then table.remove(V.hist, 1) end

	if hasMove and focused() then
		local x = fr.AbsolutePosition.X + target * fr.AbsoluteSize.X
		local y = fr.AbsolutePosition.Y + fr.AbsoluteSize.Y * 0.5
		mousemoveabs(math.floor(x + 0.5), math.floor(y + 0.5))
	end
end)

toggle(S_vent, "Enabled", "vent", function() end, "vent")
toggle(S_vent, "Prediction", "ventPred", function() end)
slider(S_vent, "Lead Adjust (frames)", -2, 2, state.ventBias, function(v)
	state.ventBias = math.floor(v * 4 + 0.5) / 4
	return ("%+.2f"):format(state.ventBias)
end, "ventBias")
toggle(S_vent, "Log To File", "ventLog", function() end)
local ventStatus = info(S_vent, "Status: -")
local ventLast = info(S_vent, "Last: -")
if not hasMove then ventStatus.Text = '<font color="#ff6060">mousemoveabs fehlt</font>' end
task.spawn(function()
	while H.alive do
		if hasMove then
			local s
			if not state.vent then s = "off"
			elseif V.open then s = ('<font color="#f5a8de">aiming</font> · lag %.1ff · x%.2f'):format(V.lagF, V.mult)
			else s = "idle · waiting for vent" end
			ventStatus.Text = "Status: " .. s
		end
		ventLast.Text = "Last: " .. V.last
		task.wait(0.25)
	end
end)

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
toggle(S_light, "Fullbright", "fullbright", function(on) if on then applyFB() else restoreFB() end end)
-- Spiel setzt Lighting per Zone neu -> periodisch nachziehen
task.spawn(function()
	while H.alive do
		if state.fullbright then pcall(applyFB) end
		task.wait(0.5)
	end
end)

-- Helligkeit (Fullbright): 0..10 -> Brightness + ExposureCompensation
slider(S_light, "Brightness", 0, 10, state.bright, function(v)
	state.bright = v
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
	return ("%.1f/10.0"):format(v)
end, "brightness")

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

toggle(S_esp, "Enabled", "esp", function(on)
	if not on then for p in pairs(espObjs) do removeEsp(p) end end
end)
-- ESP-Reichweite + Fade-Zone (letzte X % der Reichweite blenden aus)
slider(S_esp, "Distance", 25, 3000, state.espDist, function(v)
	state.espDist = math.floor(v)
	return state.espDist .. "/3000"
end, "espDist")
slider(S_esp, "Fade (last % of range)", 0, 100, state.espFade * 100, function(v)
	state.espFade = v / 100
	return math.floor(v) .. "/100"
end, "espFade")

-- ================= ITEM-ESP (gedroppte Tools) =================
-- Spiel-Logik (PromptToolPickup): Tool direkt in workspace + Handle + CanBeDropped = aufhebbar
state.items = sv("items", false)
local itemObjs = {} -- [tool] = {bb=, lbl=}
local function isDropped(t) return t:IsA("Tool") and t.Parent == workspace and t:FindFirstChild("Handle") ~= nil end
local function clearItem(t) local o = itemObjs[t] if o then pcall(function() o.bb:Destroy() end) itemObjs[t] = nil end end
toggle(S_items, "Dropped Items", "items", function(on) if not on then for t in pairs(itemObjs) do clearItem(t) end end end)
con(workspace.ChildRemoved, function(t) clearItem(t) end)

-- ================= PERFORMANCE =================
-- Stufe 0 aus | 1 Schatten/Post-FX/Terrain-Deko aus | 2 + Partikel/Trails/Beams/Decals/Texturen weg | 3 + alles SmoothPlastic, Qualität min
state.perf = sv("perf", 0); state.updInt = sv("updInt", 0.2)
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
dropdown(S_perf, "Level", { "Off", "Shadows / FX", "+ Particles / Decals", "+ Materials" }, state.perf + 1, function(i)
	state.perf = i - 1
end, "perf")
slider(S_perf, "Hub Update Rate", 0.05, 1, state.updInt, function(v)
	state.updInt = v
	return ("%.1f/s"):format(1 / v)
end, "updInt")
info(S_perf, "Lower update rate = more FPS.")
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

-- ================= NO FALL DAMAGE =================
-- ClientFallDamage meldet FallImpact:FireServer(-vel.Y) beim Landen, aber nur wenn > 80.
-- Hook-frei: in Bodennähe jeden Frame auf 60 kappen (Landung max ~65) -> nichts wird gemeldet.
state.nofall = sv("nofall", false)
local FALL_CAP = 60
local fallParams = RaycastParams.new(); fallParams.FilterType = Enum.RaycastFilterType.Exclude
toggle(S_move, "No Fall Damage", "nofall", function() end)
con(RunService.Heartbeat, function(dt)
	if not state.nofall then return end
	local c = lp.Character
	local r = c and c:FindFirstChild("HumanoidRootPart")
	local hum = c and c:FindFirstChildOfClass("Humanoid")
	if not (r and hum) then return end
	local v = r.AssemblyLinearVelocity
	if v.Y >= -FALL_CAP then return end
	fallParams.FilterDescendantsInstances = { c }
	-- Vorausschau: Strecke der nächsten ~3 Frames + Hüfthöhe + Puffer
	local look = -v.Y * math.max(dt, 1 / 60) * 3 + hum.HipHeight + r.Size.Y / 2 + 6
	local hit = workspace:Raycast(r.Position, Vector3.new(0, -look, 0), fallParams)
	if hit then
		r.AssemblyLinearVelocity = Vector3.new(v.X, -FALL_CAP, v.Z)
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

local markInfo = info(S_mark, "Target: -", T.accent)

local search = Instance.new("TextBox")
search.Size = UDim2.new(1, 0, 0, 18); search.BackgroundColor3 = T.track; search.BorderSizePixel = 0; search.Font = T.font
search.TextSize = 12; search.TextColor3 = T.text; search.PlaceholderText = "search player..."
search.PlaceholderColor3 = T.dim; search.TextXAlignment = Enum.TextXAlignment.Left
search.Text = ""; search.ClearTextOnFocus = false; search.LayoutOrder = nextOrder(S_mark); search.Parent = S_mark.f
stroke(search); corner(search, 2)
Instance.new("UIPadding", search).PaddingLeft = UDim.new(0, 6)

local list = Instance.new("ScrollingFrame")
list.Size = UDim2.new(1, 0, 0, 300); list.BackgroundColor3 = T.bg; list.BorderSizePixel = 0; list.ScrollBarThickness = 2
list.ScrollBarImageColor3 = T.accent; list.LayoutOrder = nextOrder(S_mark)
list.AutomaticCanvasSize = Enum.AutomaticSize.Y; list.CanvasSize = UDim2.new(); list.Parent = S_mark.f
stroke(list)
local lay = Instance.new("UIListLayout", list); lay.Padding = UDim.new(0, 1); lay.SortOrder = Enum.SortOrder.Name

local function markedPlayer()
	if not state.markId then return nil end
	return Players:GetPlayerByUserId(state.markId)
end

local rebuildList
local function setMark(p)
	if p then state.markId = p.UserId; state.markName = p.Name else state.markId = nil; state.markName = nil end
	rebuildList()
end
button(S_mark, "Clear Target", function() setMark(nil) end)
local plCount = info(S_plInfo, "Players: -")
info(S_plInfo, "Click a player to mark them: highlight, label and an edge arrow when off-screen. Click again to unmark.")
task.spawn(function()
	while H.alive do
		plCount.Text = ("Players: %d / %d"):format(#Players:GetPlayers(), Players.MaxPlayers)
		task.wait(1)
	end
end)

function rebuildList()
	for _, c in ipairs(list:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
	local q = search.Text:lower()
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= lp and (q == "" or p.Name:lower():find(q, 1, true) or p.DisplayName:lower():find(q, 1, true)) then
			local marked = state.markId == p.UserId
			local b = Instance.new("TextButton")
			b.Name = p.Name:lower(); b.Size = UDim2.new(1, -4, 0, 18); b.BorderSizePixel = 0; b.AutoButtonColor = false
			b.BackgroundColor3 = marked and Color3.fromRGB(70, 38, 60) or T.bg
			b.BackgroundTransparency = marked and 0 or 1
			b.Font = T.font; b.TextSize = 12; b.TextXAlignment = Enum.TextXAlignment.Left
			b.TextTruncate = Enum.TextTruncate.AtEnd
			b.TextColor3 = marked and T.accent or teamColor(p)
			b.Text = (marked and " ◆ " or "   ") .. p.DisplayName .. " (@" .. p.Name .. ")  " .. (p.Team and p.Team.Name or "")
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
		markInfo.Text = state.markName and ("Target: " .. state.markName .. " (offline)") or "Target: -"
		return
	end
	local r, c = rootOf(p)
	if not r then
		markHL.Enabled = false; markBB.Enabled = false; arrow.Visible = false
		markInfo.Text = "Target: " .. p.Name .. " (no char / not streamed)"
		return
	end
	if markHL.Adornee ~= c then markHL.Adornee = c end
	if markBB.Adornee ~= r then markBB.Adornee = r end
	markHL.Enabled = true; markBB.Enabled = true
	local myRoot = rootOf(lp)
	local d = myRoot and math.floor((r.Position - myRoot.Position).Magnitude) or 0
	markLbl.Text = "◆ " .. p.DisplayName .. " ◆\n" .. d .. "m"
	markInfo.Text = "Target: " .. p.Name .. "  " .. d .. "m"

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
staffPanel.Size = UDim2.fromOffset(0, 0); staffPanel.AutomaticSize = Enum.AutomaticSize.XY
staffPanel.BackgroundColor3 = T.bg; staffPanel.BackgroundTransparency = 0.1
staffPanel.Font = T.font; staffPanel.TextSize = 13; staffPanel.RichText = true
staffPanel.TextColor3 = T.text; staffPanel.TextXAlignment = Enum.TextXAlignment.Left
staffPanel.TextYAlignment = Enum.TextYAlignment.Top; staffPanel.Visible = false; staffPanel.Parent = gui
corner(staffPanel, 4); stroke(staffPanel, T.edge)
local pad = Instance.new("UIPadding", staffPanel)
pad.PaddingLeft = UDim.new(0, 8); pad.PaddingRight = UDim.new(0, 8); pad.PaddingTop = UDim.new(0, 4); pad.PaddingBottom = UDim.new(0, 4)

state.staff = sv("staff", true)
toggle(S_staff, "Enabled", "staff", function() end)
local staffSummary = info(S_staff, "No staff detected.")
info(S_staff, "Group rank ≥ 90 or staff tag. Panel stays visible at the top even with the menu closed.")

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
				local sinfo, isStaff = staffInfo(p)
				if sinfo and state.staff then
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
						isStaff and "#ffcc40" or "#8fd0ff", isStaff and "★" or "•", esc(p.Name), esc(sinfo),
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
			staffPanel.Text = ('<font color="#f5a8de">STAFF IM SERVER: %d</font>\n'):format(n) .. table.concat(lines, "\n")
			staffPanel.Visible = true
			staffSummary.Text = ('<font color="#f5a8de">%d staff in server</font>'):format(n)
		else
			staffPanel.Visible = false
			staffSummary.Text = state.staff and "No staff detected." or "off"
		end
		task.wait(math.max(0.5, state.updInt))
	end
end)

-- ================= CONFIG =================
-- Laufende Einstellungen speichern sich automatisch (SAVE_FILE); hier zusätzlich ein Profil zum Sichern/Zurückholen
local CFG_FILE = "tsc_hub_config.json"
local DEFAULTS = { fullbright = false, esp = false, espDist = 1500, espFade = 40, brightness = 2, items = false, perf = 1,
	updInt = 0.2, nofall = false, staff = true, vent = true, ventPred = true, ventLog = true, ventBias = 0 }
local cfgStatus
local function saveCfg()
	local data = { keys = {} }
	for id, c in pairs(ctl) do data[id] = c.get() end
	for id, k in pairs(state.keys) do data.keys[id] = k.Name end
	local ok, err = pcall(function() writefile(CFG_FILE, HttpService:JSONEncode(data)) end)
	cfgStatus.Text = ok and ('<font color="#f5a8de">profile saved</font> ' .. os.date("%H:%M:%S")) or ("save failed: " .. tostring(err))
end
local function applyCfg(data)
	for id, v in pairs(data) do
		if id ~= "keys" and ctl[id] then pcall(ctl[id].set, v) end
	end
	for id, n in pairs(data.keys or {}) do
		local k = kc(n, nil)
		if k and keyBoxes[id] then state.keys[id] = k; keyBoxes[id].Text = keyName(k) end
	end
end
local function loadCfg()
	local ok, data = pcall(function() return HttpService:JSONDecode(readfile(CFG_FILE)) end)
	if not ok or type(data) ~= "table" then cfgStatus.Text = "no profile found"; return end
	applyCfg(data)
	cfgStatus.Text = '<font color="#f5a8de">profile loaded</font> ' .. os.date("%H:%M:%S")
end
button(S_cfg, "Save Profile", saveCfg)
button(S_cfg, "Load Profile", loadCfg)
button(S_cfg, "Reset To Defaults", function()
	applyCfg({ keys = { menu = "RightShift", vent = "End" } })
	for id, v in pairs(DEFAULTS) do if ctl[id] then pcall(ctl[id].set, v) end end
	cfgStatus.Text = '<font color="#f5a8de">defaults restored</font>'
end)
cfgStatus = info(S_cfg, "Settings save automatically.\nProfile: workspace/" .. CFG_FILE)

-- ================= MENU / KEYBINDS =================
keyRow(S_menu, "Toggle Menu", "menu")
button(S_menu, "Unload", function() task.defer(H.kill) end)
info(S_menu, "Click a key box, then press a key (Esc = cancel).")

con(UIS.InputBegan, function(i, gp)
	if listening then
		if i.UserInputType == Enum.UserInputType.Keyboard then
			local id = listening; listening = nil
			if i.KeyCode ~= Enum.KeyCode.Escape then state.keys[id] = i.KeyCode end
			local b = keyBoxes[id]; b.Text = keyName(state.keys[id]); b.TextColor3 = T.dim
		end
		return
	end
	if gp or i.UserInputType ~= Enum.UserInputType.Keyboard then return end
	if i.KeyCode == state.keys.menu then main.Visible = not main.Visible
	elseif i.KeyCode == state.keys.vent then state.vent = not state.vent; refresh.vent() end
end)

selectTab("Misc")
H.selectTab = selectTab

-- Speichern (nur bei Änderung, max 1x/s)
task.spawn(function()
	local last = ""
	while H.alive do
		local t = {}
		for _, k in ipairs(SAVE_KEYS) do t[k] = state[k] end
		t.keyMenu = state.keys.menu.Name; t.keyVent = state.keys.vent.Name
		t.guiX = main.Position.X.Offset; t.guiY = main.Position.Y.Offset; t.guiVisible = main.Visible
		local ok, js = pcall(function() return HttpService:JSONEncode(t) end)
		if ok and js ~= last then
			if pcall(writefile, SAVE_FILE, js) then last = js end
		end
		task.wait(1)
	end
end)

function H.kill()
	H.alive = false
	for _, c in ipairs(H.conns) do pcall(function() c:Disconnect() end) end
	H.conns = {}
	pcall(ventFlush)
	pcall(restoreFB)
	pcall(perfRestore)
	pcall(function() gui:Destroy() end)
end

return "TSC HUB geladen"
