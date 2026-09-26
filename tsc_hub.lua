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
local SAVE_KEYS = { "fullbright", "esp", "espDist", "espFade", "espFadePow", "bright", "items", "perf", "updInt", "nofall", "staff", "markId", "markName",
	"vent", "ventPred", "ventLog", "ventBias", "ms", "msReader", "msHints", "msFlags", "msPace", "turrets", "pkgSel", "collapsed" }

local state = { fullbright = sv("fullbright", false), esp = sv("esp", false), espDist = sv("espDist", 1500),
	espFade = sv("espFade", 0.4), espFadePow = sv("espFadePow", 2), bright = sv("bright", 2), markId = sv("markId", nil), markName = sv("markName", nil),
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
local S_ms = section(miscL, "Auto Hack (Minesweeper)")
local S_move = section(miscR, "Movement")
local S_world = section(miscR, "World")
local S_pkg = section(miscR, "Packages (Dead Drops)")
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
-- Fade-Stärke: Transparenz = 1-(1-t)^k (k=1 linear, höher = blendet früher/stärker aus) + Schrift schrumpft
slider(S_esp, "Fade Strength", 1, 5, state.espFadePow, function(v)
	state.espFadePow = math.floor(v * 10 + 0.5) / 10
	return ("%.1fx"):format(state.espFadePow)
end, "espFadePow")
local function fadeAlpha(d)
	local fs = state.espDist * (1 - state.espFade)
	if d <= fs or state.espDist <= fs then return 0 end
	local t = math.clamp((d - fs) / (state.espDist - fs), 0, 1)
	return 1 - (1 - t) ^ state.espFadePow
end
local function applyFade(lbl, a, baseSize)
	lbl.TextTransparency = a
	lbl.TextStrokeTransparency = 0.3 + 0.7 * a
	lbl.TextSize = math.max(7, math.floor(baseSize * (1 - 0.45 * a) + 0.5))
end

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

-- ================= TURRET WIPE =================
-- workspace.EOP.TurretsFolder: vorhandene Turrets lokal löschen + neu gestreamte/gespawnte beim Erscheinen.
-- Rein clientseitig (Destroy), keine Remotes. Beim Ausschalten kommen gelöschte erst per Re-Stream/Rejoin zurück.
state.turrets = sv("turrets", false)
local turretConn, turretFolder, turretKilled = nil, nil, 0
local function killTurret(t)
	if t:IsA("Model") or t:IsA("BasePart") then
		if pcall(function() t:Destroy() end) then turretKilled = turretKilled + 1 end
	end
end
local function turretStop()
	if turretConn then turretConn:Disconnect(); turretConn = nil end
	turretFolder = nil
end
local function turretStart(folder)
	turretStop()
	turretFolder = folder
	for _, t in ipairs(folder:GetChildren()) do killTurret(t) end
	turretConn = folder.ChildAdded:Connect(killTurret)
	table.insert(H.conns, turretConn)
end
toggle(S_world, "Delete Turrets", "turrets", function(on) if not on then turretStop() end end)
local turretInfo = info(S_world, "Turrets: -")
-- Ordner kann später geladen/ersetzt werden -> jede Sekunde prüfen
task.spawn(function()
	while H.alive do
		local eop = workspace:FindFirstChild("EOP")
		local f = eop and eop:FindFirstChild("TurretsFolder")
		if state.turrets then
			if f and f ~= turretFolder then turretStart(f) elseif not f then turretStop() end
		end
		if not state.turrets then
			turretInfo.Text = "Turrets: " .. (f and (#f:GetChildren() .. " in folder") or "folder not loaded")
		else
			turretInfo.Text = ('Turrets: <font color="#f5a8de">%d deleted</font>%s'):format(turretKilled, f and "" or " · folder not loaded")
		end
		task.wait(1)
	end
end)

-- ================= MARKER =================
local markHL = Instance.new("Highlight")
markHL.Name = "TSC_MARK_HL"; markHL.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
markHL.FillColor = Color3.fromRGB(255, 40, 40); markHL.FillTransparency = 0.55
markHL.OutlineColor = Color3.fromRGB(255, 220, 60); markHL.OutlineTransparency = 0
markHL.Enabled = false; markHL.Parent = gui

-- Label + Punkt als 2D-Projektion (hängt nicht am Character -> funktioniert auch, wenn er rausgestreamt ist)
local markLbl = Instance.new("TextLabel")
markLbl.AnchorPoint = Vector2.new(0.5, 1); markLbl.Size = UDim2.fromOffset(240, 40); markLbl.BackgroundTransparency = 1
markLbl.Font = Enum.Font.GothamBlack; markLbl.TextSize = 15; markLbl.TextColor3 = Color3.fromRGB(255, 90, 90)
markLbl.TextStrokeTransparency = 0.2; markLbl.Visible = false; markLbl.Parent = gui
local markDot = Instance.new("Frame")
markDot.AnchorPoint = Vector2.new(0.5, 0.5); markDot.Size = UDim2.fromOffset(10, 10); markDot.BorderSizePixel = 0
markDot.Rotation = 45; markDot.Visible = false; markDot.Parent = gui


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
							applyFade(e.lbl, fadeAlpha(d), 12)
							e.lbl.Text = p.DisplayName .. "\n" .. math.floor(d) .. "m  HP " .. hp
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
						applyFade(o.lbl, fadeAlpha(d), 12)
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
-- StreamingEnabled: außerhalb der Streaming-Reichweite ist der Character lokal Parent=nil und seine Position
-- eingefroren (Server schickt nichts). Dann: letzte bekannte Position (grau) + Alter; live wieder, sobald er reinstreamt.
local markLast = { id = nil, pos = nil, t = nil }
-- letzte gesehene Position ALLER Spieler (2 Hz), damit auch rausgestreamte Ziele einen Anker haben
local lastSeen = {} -- [userId] = {pos=, t=}
task.spawn(function()
	while H.alive do
		for _, pl in ipairs(Players:GetPlayers()) do
			local c = pl.Character
			local rr = c and c:FindFirstChild("HumanoidRootPart")
			if rr and c:IsDescendantOf(workspace) then lastSeen[pl.UserId] = { pos = rr.Position, t = os.clock() } end
		end
		task.wait(0.5)
	end
end)
con(Players.PlayerRemoving, function(pl) lastSeen[pl.UserId] = nil end)
local function markHide() markHL.Enabled = false; markLbl.Visible = false; markDot.Visible = false; arrow.Visible = false end
con(RunService.RenderStepped, function()
	local p = markedPlayer()
	if not p then
		markHide()
		markInfo.Text = state.markName and ("Target: " .. state.markName .. " (offline)") or "Target: -"
		return
	end
	if markLast.id ~= p.UserId then markLast = { id = p.UserId } end
	local r, c = rootOf(p)
	local live = r and c and c:IsDescendantOf(workspace)
	local pos
	if live then
		pos = r.Position; markLast.pos = pos; markLast.t = os.clock()
		if markHL.Adornee ~= c then markHL.Adornee = c end
		markHL.Enabled = true
	else
		markHL.Enabled = false
		local ls = lastSeen[p.UserId]
		if ls and (not markLast.t or ls.t > markLast.t) then markLast.pos = ls.pos; markLast.t = ls.t end
		pos = markLast.pos
	end
	if not pos then
		markHide()
		markInfo.Text = "Target: " .. p.Name .. (c and " (out of stream range, not seen yet)" or " (no char)")
		return
	end
	local myRoot = rootOf(lp)
	local d = myRoot and math.floor((pos - myRoot.Position).Magnitude) or 0
	local age = markLast.t and math.floor(os.clock() - markLast.t) or nil
	local stale = not live
	local col = stale and Color3.fromRGB(200, 160, 120) or Color3.fromRGB(255, 90, 90)
	local ageTxt = stale and (age and ("last seen " .. age .. "s ago") or "last known pos") or nil
	markInfo.Text = "Target: " .. p.Name .. "  " .. d .. "m" .. (ageTxt and ("  (" .. ageTxt .. ")") or "")

	local vp = cam.ViewportSize
	local sp, onScreen = cam:WorldToViewportPoint(pos + Vector3.new(0, stale and 0 or 3.5, 0))
	if onScreen and sp.Z > 0 then
		arrow.Visible = false
		markLbl.Position = UDim2.fromOffset(sp.X, sp.Y - 6); markLbl.TextColor3 = col
		markLbl.Text = "◆ " .. p.DisplayName .. " ◆\n" .. d .. "m" .. (ageTxt and ("  · " .. ageTxt) or "")
		markLbl.Visible = true
		markDot.Position = UDim2.fromOffset(sp.X, sp.Y); markDot.BackgroundColor3 = col; markDot.Visible = stale
	else
		markLbl.Visible = false; markDot.Visible = false
		arrow.TextColor3 = col
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

-- ================= AUTO HACK (Minesweeper / HackingMinigame) =================
-- Übernommen aus minesweeper_bot.lua. Keine eigenen Remotes: liest den Mine-Layout-State clientseitig
-- (debug.getupvalues der Cell-Handler) bzw. löst per Solver, und feuert die EIGENEN Button-Handler
-- des Spiels (getconnections) -> das Spiel sendet seine normale Anfrage wie bei einem echten Klick.
state.ms = sv("ms", true); state.msReader = sv("msReader", true); state.msHints = sv("msHints", true)
state.msFlags = sv("msFlags", true); state.msPace = sv("msPace", 0)
toggle(S_ms, "Enabled", "ms", function() end)
toggle(S_ms, "Mine Reader (instant)", "msReader", function() end)
toggle(S_ms, "Use Hints", "msHints", function() end)
toggle(S_ms, "Place Flags", "msFlags", function() end)
slider(S_ms, "Solve Time (reader pacing)", 0, 30, state.msPace, function(v)
	state.msPace = math.floor(v + 0.5)
	return state.msPace == 0 and "instant" or (state.msPace .. "s")
end, "msPace")
local msStatus = info(S_ms, "Status: idle · waiting for hack")
local function msLog(s)
	msStatus.Text = "Status: " .. s
	print("[TSC HUB][HACK] " .. s)
end
local function msBot()
	local PlayerGui   = lp:WaitForChild("PlayerGui")

	-- ---- config ----------------------------------------------------------------
	local MINE_COUNT    = nil        -- manual override; nil = auto-detect from the level
	local LEVEL_MINES   = {          -- mines per level (fill in any you know)
	    [5] = 200,
	    [6] = 400,
	}
	local CYCLE_WAIT    = 0.05       -- pause between full read/solve cycles (after a batch)
	local MAX_ENUM      = 26         -- max frontier-component size to enumerate exactly
	local ENUM_ALL      = 26         -- endgame: full-board enumeration when <= this many covered cells
	local ENUM_BUDGET   = 2000000    -- safety cap on search nodes per component (prevents hangs)
	local FIRST_MOVE    = "center"   -- "center" or "corner": opening click on a blank board
	-- read stability / anti-stale-guess timing. The #1 cause of needless 50/50s is
	-- guessing on a board that hadn't finished updating. Levels 5-6 are dense AND
	-- laggy, so we settle HARD there; levels 1-4 are small/snappy and stay crazy fast.
	local SLOW_LEVELS   = { [5] = true, [6] = true }   -- levels that get the cautious timing
	local SLOW_MIN_MINES = 150        -- fallback: treat as "slow" if mines >= this (level label unread)
	local STABLE_MAX    = 20          -- max reads before giving up waiting for it to settle
	--                       slow (lv5-6) , fast (lv1-4)
	local STABLE_NEED_S, STABLE_NEED_F = 3   , 2     -- consecutive identical reads required
	local STABLE_WAIT_S, STABLE_WAIT_F = 0.03, 0     -- delay between reads
	local STUCK_CONFIRM_S, STUCK_CONFIRM_F = 0.25, 0 -- settle before any probability move
	local USE_WMC       = true        -- slow levels only: weight marginals by the global mine budget (exact WMC)
	local HINT_CANDIDATES = 16        -- slow levels: cap on cells scored for the "best hint" 1-ply search
	-- ---- direct mine-layout reader (the board is fully client-side) ------------
	local SOLVE_TIME    = {}          -- per-level reveal spread in seconds; empty = no pacing (fastest)
	local CHEAT_SHUFFLE = false       -- no pacing -> order is irrelevant; reveal in natural cell order

	-- current board's level / mine count (forward-declared so the timing helper below
	-- can read them; detection lives further down).
	local CURRENT_MINES = nil
	local CURRENT_LEVEL = nil
	-- are we on a slow (dense) level? drives the settle timing.
	local function isSlowLevel()
	    if CURRENT_LEVEL and SLOW_LEVELS[CURRENT_LEVEL] then return true end
	    if CURRENT_MINES and CURRENT_MINES >= SLOW_MIN_MINES then return true end   -- label unreadable
	    return false
	end

	-- ---- click WITHOUT moving the mouse ----------------------------------------
	-- The game listens on Button.MouseButton1Down (reveal) and MouseButton2Down (flag).
	-- We fire those handlers directly: no cursor movement, no jitter, no focus loss.
	-- The game's own handler runs and sends its normal request to the server.
	local hasGC = typeof(getconnections) == "function"
	local hasFS = typeof(firesignal) == "function"
	if not hasGC and not hasFS then msLog("no getconnections/firesignal -> disabled"); return end

	local function fire(signal, ...)
	    local args = table.pack(...)
	    if hasGC then
	        local ok, conns = pcall(getconnections, signal)
	        if ok and conns and #conns > 0 then
	            for _, c in ipairs(conns) do
	                pcall(function() c:Fire(table.unpack(args, 1, args.n)) end)
	            end
	            return true
	        end
	    end
	    if hasFS then return (pcall(firesignal, signal, table.unpack(args, 1, args.n))) end
	    return false
	end

	local function centreOf(cell)
	    return cell.AbsolutePosition.X + cell.AbsoluteSize.X/2,
	           cell.AbsolutePosition.Y + cell.AbsoluteSize.Y/2
	end

	-- fire synchronously, no per-click wait; we wait once per batch instead
	local function revealCell(cell)
	    local b = cell:FindFirstChild("Button"); if not b then return end
	    local x, y = centreOf(cell)
	    fire(b.MouseButton1Down, x, y)
	    fire(b.MouseButton1Up, x, y)
	end

	local function flagCell(cell)
	    local b = cell:FindFirstChild("Button"); if not b then return end
	    local x, y = centreOf(cell)
	    fire(b.MouseButton2Down, x, y)
	end

	-- ---- hints -----------------------------------------------------------------
	-- Mechanic: click the magnifying glass to EQUIP a hint (HintEquipped becomes
	-- visible), then click a cell -> it's a guaranteed-safe probe (mine -> flag,
	-- else -> reveal). We equip, then probe the most informative cell.
	-- Set HINT_EQUIP_NAME after the buttons-probe if auto-detect picks wrong.
	local HINT_EQUIP_NAME = nil
	local EQUIP_KEYWORDS  = { "hint", "magn", "glass", "search", "zoom", "help", "scan" }

	local function root4(board) return board.Parent or board end

	local function hintsLeft(board)
	    local lbl = root4(board):FindFirstChild("HintsLeft", true)
	    if lbl and lbl:IsA("TextLabel") then return tonumber(lbl.Text:match("%d+")) or 0 end
	    return 0
	end

	local function findEquipButton(board)
	    local root = root4(board)
	    if HINT_EQUIP_NAME then
	        local b = root:FindFirstChild(HINT_EQUIP_NAME, true)
	        if b then return b end
	    end
	    -- The magnifier is named "Button" but lives under a "Hints" frame, so match
	    -- on the ANCESTOR chain (this also excludes the identically-named Exit button).
	    for _, d in ipairs(root:GetDescendants()) do
	        if d:IsA("GuiButton") and d.Visible and not (d.Parent and d.Parent.Name == "Cell") then
	            local node = d
	            while node and node ~= root.Parent do
	                local n = node.Name:lower()
	                for _, kw in ipairs(EQUIP_KEYWORDS) do
	                    if n:find(kw) then return d end
	                end
	                node = node.Parent
	            end
	        end
	    end
	end

	local function isEquipped(board)
	    local he = root4(board):FindFirstChild("HintEquipped", true)
	    return he and he.Visible == true
	end

	-- probe one cell safely using a hint. returns true only if the cell was probed
	-- WITH a hint confirmed equipped (otherwise the click would be a real, deadly
	-- reveal of the most-likely-mine cell -- so we refuse to click).
	local function useHintOn(board, cell)
	    if not isEquipped(board) then
	        local eq = findEquipButton(board)
	        if not eq then
	            msLog("no magnifier button found (run minesweeper_buttonsprobe).")
	            return false
	        end
	        local ex, ey = centreOf(eq)
	        fire(eq.MouseButton1Down, ex, ey)
	        fire(eq.MouseButton1Up, ex, ey)
	        -- WAIT until the hint is actually equipped before probing
	        local t0 = os.clock()
	        while not isEquipped(board) and os.clock() - t0 < 0.8 do task.wait() end
	    end
	    if not isEquipped(board) then
	        msLog("hint failed to equip -> not probing (avoids a real click on a mine).")
	        return false
	    end
	    revealCell(cell)   -- equip confirmed: this click is the safe probe
	    msLog("hint probe fired (equip confirmed).")
	    return true
	end

	-- ---- board location --------------------------------------------------------
	local function dominantSizeCount(c)
	    local sizes = {}
	    for _, ch in ipairs(c:GetChildren()) do
	        if ch:IsA("GuiObject") then
	            local s = ch.AbsoluteSize
	            if s.X > 4 and s.Y > 4 then
	                local k = math.floor(s.X/2)*2 .. "_" .. math.floor(s.Y/2)*2
	                sizes[k] = (sizes[k] or 0) + 1
	            end
	        end
	    end
	    local bk, bc = nil, 0
	    for k, n in pairs(sizes) do if n > bc then bk, bc = k, n end end
	    return bc, bk
	end

	local function findBoard(root)
	    root = root or PlayerGui
	    local best, bc = nil, 0
	    for _, d in ipairs(root:GetDescendants()) do
	        if d:IsA("GuiObject") and d.Visible and #d:GetChildren() >= 9 then
	            local c = dominantSizeCount(d)
	            if c > bc then best, bc = d, c end
	        end
	    end
	    return best
	end

	-- ---- read board into a grid ------------------------------------------------
	local function vis(o, n) local c = o:FindFirstChild(n); return c and c.Visible == true end

	-- returns: grid[r][c] = {cell, state, num}, rows, cols, gridGeom
	local function readBoard(board)
	    local cells = {}
	    local _, domKey = dominantSizeCount(board)
	    for _, ch in ipairs(board:GetChildren()) do
	        if ch:IsA("GuiObject") then
	            local s = ch.AbsoluteSize
	            if (math.floor(s.X/2)*2 .. "_" .. math.floor(s.Y/2)*2) == domKey then
	                cells[#cells+1] = ch
	            end
	        end
	    end
	    if #cells == 0 then return nil end

	    -- cluster centres into columns / rows
	    local function cluster(vals, tol)
	        table.sort(vals)
	        local g = {}
	        for _, v in ipairs(vals) do
	            local last = g[#g]
	            if last and math.abs(v-last.mean) <= tol then
	                last.sum=last.sum+v; last.n=last.n+1; last.mean=last.sum/last.n
	            else g[#g+1] = {sum=v,n=1,mean=v} end
	        end
	        return g
	    end
	    local xs, ys = {}, {}
	    for _, c in ipairs(cells) do
	        xs[#xs+1] = c.AbsolutePosition.X + c.AbsoluteSize.X/2
	        ys[#ys+1] = c.AbsolutePosition.Y + c.AbsoluteSize.Y/2
	    end
	    local cs = cells[1].AbsoluteSize
	    local cols = cluster(xs, cs.X*0.4)
	    local rows = cluster(ys, cs.Y*0.4)
	    local function nearest(groups, v)
	        local bi, bd = 1, math.huge
	        for i, g in ipairs(groups) do local d=math.abs(v-g.mean); if d<bd then bi,bd=i,d end end
	        return bi
	    end

	    local grid = {}
	    for r = 1, #rows do grid[r] = {} end
	    for _, c in ipairs(cells) do
	        local cx = c.AbsolutePosition.X + c.AbsoluteSize.X/2
	        local cy = c.AbsolutePosition.Y + c.AbsoluteSize.Y/2
	        local ci, ri = nearest(cols, cx), nearest(rows, cy)
	        local state, num = "BLANK", 0
	        if vis(c, "Flag") then state = "FLAG"
	        elseif vis(c, "Hidden") then state = "COVERED"
	        elseif vis(c, "Mine") then state = "MINE"
	        else
	            local nb = c:FindFirstChild("Number")
	            if nb and nb.Visible then
	                local t = tonumber(nb.Text)
	                if t and t > 0 then state, num = "NUM", t end
	            end
	        end
	        grid[ri][ci] = { cell = c, state = state, num = num }
	    end
	    return grid, #rows, #cols
	end

	-- a compact fingerprint of the board, to detect when it has settled
	local function signature(grid, R, C)
	    local t = {}
	    for r=1,R do for c=1,C do local g = grid[r][c]; t[#t+1] = (g and (g.state .. g.num)) or "x" end end
	    return table.concat(t, ",")
	end

	-- read repeatedly until two consecutive reads agree (board not mid-cascade).
	-- This stops us from acting on a half-revealed cell (e.g. Hidden off but Number
	-- not yet on, which would look like a false "0" and get us killed).
	local function readStable(board)
	    local slow = isSlowLevel()
	    local need = slow and STABLE_NEED_S or STABLE_NEED_F
	    local wait = slow and STABLE_WAIT_S or STABLE_WAIT_F
	    local grid, R, C = readBoard(board)
	    if not grid then return nil end
	    local sig = signature(grid, R, C)
	    local streak = 1                       -- how many consecutive reads have matched
	    for _ = 1, STABLE_MAX do
	        task.wait(wait)
	        local g2, R2, C2 = readBoard(board)
	        if not g2 then return grid, R, C end
	        local s2 = signature(g2, R2, C2)
	        if s2 == sig then
	            streak = streak + 1
	            grid, R, C = g2, R2, C2
	            if streak >= need then return grid, R, C end   -- held still long enough
	        else
	            streak = 1                     -- still changing -> restart the count
	            grid, R, C, sig = g2, R2, C2, s2
	        end
	    end
	    return grid, R, C
	end

	-- current board's level number and total mines (declared up top; detection here).
	local function detectLevel(board)
	    local db = root4(board):FindFirstChild("DifficultyButton", true)
	    if db and (db:IsA("TextButton") or db:IsA("TextLabel")) then
	        return tonumber(tostring(db.Text):match("%d+"))
	    end
	    return nil
	end
	-- read an on-screen "N unflagged mines" counter, if present
	local function readMineCounter()
	    for _, d in ipairs(PlayerGui:GetDescendants()) do
	        if d:IsA("TextLabel") and d.Visible then
	            local t = tostring(d.Text):lower()
	            if t:find("mine") then
	                local n = tonumber(t:match("%d+"))
	                if n then return n end
	            end
	        end
	    end
	end

	-- total mines = (unflagged-mines counter) + (flags already placed). Falls back
	-- to the level table, then to manual override.
	local function detectMines(board, grid, R, C)
	    if MINE_COUNT then return MINE_COUNT end
	    local counter = readMineCounter()
	    if counter and grid then
	        local flags = 0
	        for r=1,R do for c=1,C do if grid[r][c].state == "FLAG" then flags = flags + 1 end end end
	        return counter + flags
	    end
	    if CURRENT_LEVEL and LEVEL_MINES[CURRENT_LEVEL] then return LEVEL_MINES[CURRENT_LEVEL] end
	    return nil
	end

	-- ---- solver ----------------------------------------------------------------
	local NB = {{-1,-1},{-1,0},{-1,1},{0,-1},{0,1},{1,-1},{1,0},{1,1}}

	local function solve(grid, R, C)
	    local function key(r,c) return r*100+c end
	    local mine, safe = {}, {}           -- key -> true
	    local covered = {}                  -- list of {r,c} still unknown (covered, unflagged)

	    for r=1,R do for c=1,C do
	        local g = grid[r][c]
	        if g.state == "FLAG" then mine[key(r,c)] = true
	        elseif g.state == "COVERED" then covered[#covered+1] = {r,c} end
	    end end

	    -- build constraints from revealed numbers
	    local constraints = {}            -- each: { cells = {key,...}, n = mines among them }
	    for r=1,R do for c=1,C do
	        local g = grid[r][c]
	        if g.state == "NUM" or g.state == "BLANK" then
	            local unk, mc = {}, 0
	            for _, d in ipairs(NB) do
	                local nr, nc = r+d[1], c+d[2]
	                if grid[nr] and grid[nr][nc] then
	                    local ng = grid[nr][nc]
	                    if ng.state == "FLAG" then mc = mc + 1
	                    elseif ng.state == "COVERED" then unk[#unk+1] = key(nr,nc) end
	                end
	            end
	            if #unk > 0 then constraints[#constraints+1] = { cells = unk, n = g.num - mc } end
	        end
	    end end

	    local function markSafe(k) if not safe[k] then safe[k]=true; return true end end
	    local function markMine(k) if not mine[k] then mine[k]=true; return true end end

	    -- iterate basic rules + subset elimination to a fixpoint
	    local function setOf(list) local s={} for _,k in ipairs(list) do s[k]=true end return s end
	    local changed = true
	    local guard = 0
	    while changed and guard < 200 do
	        changed = false; guard = guard + 1
	        -- prune decided cells out of every constraint
	        for _, con in ipairs(constraints) do
	            local nc, nn = {}, con.n
	            for _, k in ipairs(con.cells) do
	                if mine[k] then nn = nn - 1
	                elseif safe[k] then -- drop
	                else nc[#nc+1] = k end
	            end
	            con.cells, con.n = nc, nn
	            if #con.cells > 0 then
	                if con.n <= 0 then
	                    for _, k in ipairs(con.cells) do if markSafe(k) then changed = true end end
	                elseif con.n >= #con.cells then
	                    for _, k in ipairs(con.cells) do if markMine(k) then changed = true end end
	                end
	            end
	        end
	        -- subset elimination
	        for i=1,#constraints do for j=1,#constraints do
	            if i ~= j then
	                local A, B = constraints[i], constraints[j]
	                if #A.cells > 0 and #B.cells > 0 and #A.cells < #B.cells then
	                    local bset = setOf(B.cells)
	                    local subset = true
	                    for _, k in ipairs(A.cells) do if not bset[k] then subset=false break end end
	                    if subset then
	                        local aset = setOf(A.cells)
	                        local diff = {}
	                        for _, k in ipairs(B.cells) do if not aset[k] then diff[#diff+1]=k end end
	                        local dn = B.n - A.n
	                        if #diff > 0 then
	                            if dn <= 0 then
	                                for _, k in ipairs(diff) do if markSafe(k) then changed=true end end
	                            elseif dn >= #diff then
	                                for _, k in ipairs(diff) do if markMine(k) then changed=true end end
	                            end
	                        end
	                    end
	                end
	            end
	        end end
	    end

	    -- if the cheap rules already produced an actionable move, skip the costly
	    -- enumeration this cycle -- act now, enumerate only when truly stuck.
	    local hasMove = false
	    for _, rc in ipairs(covered) do
	        local k = key(rc[1], rc[2])
	        if safe[k] or mine[k] then hasMove = true break end
	    end

	    -- reusable exact CSP enumerator over a set of cell keys + constraints.
	    -- returns forcedSafe(set), forcedMine(set), prob(map key->mine probability).
	    local function csp(cellKeys, cons, maxSize)
	        local fSafe, fMine, fProb = {}, {}, {}
	        local inSet = {}
	        for _, k in ipairs(cellKeys) do inSet[k] = true end
	        local live = {}
	        for _, con in ipairs(cons) do
	            local cs = {}
	            for _, k in ipairs(con.cells) do if inSet[k] then cs[#cs+1] = k end end
	            if #cs > 0 then live[#live+1] = { cells = cs, n = con.n } end
	        end
	        local cellCons = {}
	        for ci, con in ipairs(live) do
	            for _, k in ipairs(con.cells) do cellCons[k] = cellCons[k] or {}; table.insert(cellCons[k], ci) end
	        end
	        local seenCon = {}
	        for start=1,#live do
	            if not seenCon[start] then
	                local stack, compCons, compCellsSet = {start}, {}, {}
	                seenCon[start] = true
	                while #stack > 0 do
	                    local ci = table.remove(stack)
	                    compCons[#compCons+1] = ci
	                    for _, k in ipairs(live[ci].cells) do
	                        compCellsSet[k] = true
	                        for _, cj in ipairs(cellCons[k]) do
	                            if not seenCon[cj] then seenCon[cj]=true; stack[#stack+1]=cj end
	                        end
	                    end
	                end
	                local compCells = {}
	                for k in pairs(compCellsSet) do compCells[#compCells+1] = k end
	                if #compCells <= maxSize then
	                    -- order cells by constraint-graph connectivity so constraints
	                    -- finish early -> far stronger forward-checking (lets us enumerate
	                    -- much larger frontiers without blowing up).
	                    local adj = {}
	                    for _, ci in ipairs(compCons) do
	                        local cl = live[ci].cells
	                        for a=1,#cl do
	                            adj[cl[a]] = adj[cl[a]] or {}
	                            for b=1,#cl do if a ~= b then adj[cl[a]][cl[b]] = true end end
	                        end
	                    end
	                    local ordered, vis = {}, {}
	                    local function dfs(k)
	                        vis[k] = true; ordered[#ordered+1] = k
	                        for nb in pairs(adj[k] or {}) do if not vis[nb] then dfs(nb) end end
	                    end
	                    for _, k in ipairs(compCells) do if not vis[k] then dfs(k) end end
	                    compCells = ordered

	                    local idx = {}; for i,k in ipairs(compCells) do idx[k]=i end
	                    local cons2 = {}
	                    for _, ci in ipairs(compCons) do
	                        local cl = {}
	                        for _, k in ipairs(live[ci].cells) do cl[#cl+1] = idx[k] end
	                        cons2[#cons2+1] = { cells = cl, n = live[ci].n }
	                    end
	                    local cellInCons = {}
	                    for i=1,#compCells do cellInCons[i] = {} end
	                    for ciI, con in ipairs(cons2) do
	                        for _, i in ipairs(con.cells) do table.insert(cellInCons[i], ciI) end
	                    end
	                    local ones  = {}; for i=1,#cons2 do ones[i]=0 end
	                    local remn  = {}; for i=1,#cons2 do remn[i]=#cons2[i].cells end
	                    local assign = {}
	                    local solCount = 0
	                    local mineCnt = {}; for i=1,#compCells do mineCnt[i]=0 end
	                    local n = #compCells
	                    local nodes, aborted = 0, false
	                    local function rec(i)
	                        if aborted then return end
	                        nodes = nodes + 1
	                        if nodes > ENUM_BUDGET then aborted = true; return end
	                        if i > n then
	                            solCount = solCount + 1
	                            for j=1,n do if assign[j]==1 then mineCnt[j]=mineCnt[j]+1 end end
	                            return
	                        end
	                        for _, v in ipairs({0,1}) do
	                            local ok = true
	                            for _, ciI in ipairs(cellInCons[i]) do
	                                ones[ciI] = ones[ciI] + v
	                                remn[ciI] = remn[ciI] - 1
	                                if ones[ciI] > cons2[ciI].n or ones[ciI] + remn[ciI] < cons2[ciI].n then ok = false end
	                            end
	                            if ok then assign[i] = v; rec(i+1) end
	                            for _, ciI in ipairs(cellInCons[i]) do
	                                ones[ciI] = ones[ciI] - v
	                                remn[ciI] = remn[ciI] + 1
	                            end
	                            if aborted then return end
	                        end
	                    end
	                    rec(1)
	                    -- only trust the result if enumeration finished (a partial run
	                    -- would give WRONG forced cells -> never act on it).
	                    if not aborted and solCount > 0 then
	                        for i, k in ipairs(compCells) do
	                            if mineCnt[i] == 0 then fSafe[k] = true
	                            elseif mineCnt[i] == solCount then fMine[k] = true
	                            else fProb[k] = mineCnt[i] / solCount end
	                        end
	                    end
	                end
	            end
	        end
	        return fSafe, fMine, fProb
	    end

	    -- ---- WMC: exact marginals weighted by the global mine budget --------------
	    -- The cheap per-component CSP above counts every satisfying assignment EQUALLY,
	    -- which is only correct for a component in isolation. On a board with a known
	    -- mine total, a frontier config that uses k mines must be weighted by
	    -- C(sea, minesLeft-k) -- the number of ways the remaining mines fill the
	    -- unconstrained "sea". That weighting skews with mine density, so it matters
	    -- most on levels 5-6. We enumerate each frontier component into a mine-count
	    -- histogram, convolve the components, fold in the sea via binomial weights, and
	    -- read off exact marginals for frontier AND sea cells on one common scale.
	    -- Returns nil (caller falls back to the cheap path) if a component is too big
	    -- to enumerate, so there is never a regression versus before.
	    local function wmc(maxSize)
	        -- frontier = undecided cells appearing in some (pruned) constraint
	        local frontierSet = {}
	        for _, con in ipairs(constraints) do
	            for _, k in ipairs(con.cells) do
	                if not safe[k] and not mine[k] then frontierSet[k] = true end
	            end
	        end
	        -- sea = covered, still-undecided, NOT on the frontier
	        local U = 0
	        for _, rc in ipairs(covered) do
	            local k = key(rc[1], rc[2])
	            if not mine[k] and not safe[k] and not frontierSet[k] then U = U + 1 end
	        end
	        -- mines already pinned (flags + deductions all live in `mine`)
	        local knownMines = 0
	        for _ in pairs(mine) do knownMines = knownMines + 1 end
	        local Mrem = CURRENT_MINES - knownMines

	        -- connected-component decomposition; each component enumerated exactly into
	        -- a mine-count histogram H[m] and per-cell mine counts cellMine[localIdx][m].
	        local live = {}
	        for _, con in ipairs(constraints) do
	            local cs = {}
	            for _, k in ipairs(con.cells) do if frontierSet[k] then cs[#cs+1] = k end end
	            if #cs > 0 then live[#live+1] = { cells = cs, n = con.n } end
	        end
	        local cellCons = {}
	        for ci, con in ipairs(live) do
	            for _, k in ipairs(con.cells) do cellCons[k] = cellCons[k] or {}; table.insert(cellCons[k], ci) end
	        end
	        local comps = {}
	        local seenCon = {}
	        for start = 1, #live do
	            if not seenCon[start] then
	                local stack, compCons, cellSet = {start}, {}, {}
	                seenCon[start] = true
	                while #stack > 0 do
	                    local ci = table.remove(stack)
	                    compCons[#compCons+1] = ci
	                    for _, k in ipairs(live[ci].cells) do
	                        cellSet[k] = true
	                        for _, cj in ipairs(cellCons[k]) do
	                            if not seenCon[cj] then seenCon[cj] = true; stack[#stack+1] = cj end
	                        end
	                    end
	                end
	                local compCells = {}
	                for k in pairs(cellSet) do compCells[#compCells+1] = k end
	                if #compCells > maxSize then return nil end       -- too big -> fall back
	                local adj = {}
	                for _, ci in ipairs(compCons) do
	                    local cl = live[ci].cells
	                    for a = 1, #cl do
	                        adj[cl[a]] = adj[cl[a]] or {}
	                        for b = 1, #cl do if a ~= b then adj[cl[a]][cl[b]] = true end end
	                    end
	                end
	                local ordered, vseen = {}, {}
	                local function dfs(k)
	                    vseen[k] = true; ordered[#ordered+1] = k
	                    for nb in pairs(adj[k] or {}) do if not vseen[nb] then dfs(nb) end end
	                end
	                for _, k in ipairs(compCells) do if not vseen[k] then dfs(k) end end
	                compCells = ordered
	                local idx = {}; for i, k in ipairs(compCells) do idx[k] = i end
	                local cons2 = {}
	                for _, ci in ipairs(compCons) do
	                    local cl = {}
	                    for _, k in ipairs(live[ci].cells) do cl[#cl+1] = idx[k] end
	                    cons2[#cons2+1] = { cells = cl, n = live[ci].n }
	                end
	                local cellInCons = {}
	                for i = 1, #compCells do cellInCons[i] = {} end
	                for ciI, con in ipairs(cons2) do
	                    for _, i in ipairs(con.cells) do table.insert(cellInCons[i], ciI) end
	                end
	                local ones = {}; for i = 1, #cons2 do ones[i] = 0 end
	                local remn = {}; for i = 1, #cons2 do remn[i] = #cons2[i].cells end
	                local n = #compCells
	                local assign = {}
	                local H = {}
	                local cellMine = {}; for i = 1, n do cellMine[i] = {} end
	                local nodes, aborted = 0, false
	                local function rec(i, used)
	                    if aborted then return end
	                    nodes = nodes + 1
	                    if nodes > ENUM_BUDGET then aborted = true; return end
	                    if i > n then
	                        H[used] = (H[used] or 0) + 1
	                        for j = 1, n do if assign[j] == 1 then cellMine[j][used] = (cellMine[j][used] or 0) + 1 end end
	                        return
	                    end
	                    for _, v in ipairs({0, 1}) do
	                        local ok = true
	                        for _, ciI in ipairs(cellInCons[i]) do
	                            ones[ciI] = ones[ciI] + v
	                            remn[ciI] = remn[ciI] - 1
	                            if ones[ciI] > cons2[ciI].n or ones[ciI] + remn[ciI] < cons2[ciI].n then ok = false end
	                        end
	                        if ok then assign[i] = v; rec(i + 1, used + v) end
	                        for _, ciI in ipairs(cellInCons[i]) do
	                            ones[ciI] = ones[ciI] - v
	                            remn[ciI] = remn[ciI] + 1
	                        end
	                        if aborted then return end
	                    end
	                end
	                rec(1, 0)
	                if aborted then return nil end                    -- budget blown -> fall back
	                local total = 0
	                for _, cnt in pairs(H) do total = total + cnt end
	                if total == 0 then return nil end                 -- inconsistent -> fall back
	                comps[#comps+1] = { cells = compCells, H = H, cellMine = cellMine, total = total, n = n }
	            end
	        end

	        local totalUndecided = U
	        for _, comp in ipairs(comps) do totalUndecided = totalUndecided + comp.n end
	        if Mrem < 0 or Mrem > totalUndecided then return nil end   -- count inconsistent -> fall back

	        -- log-factorial table for the sea binomials C(U, .)
	        local lf = {}; lf[0] = 0
	        for i = 1, U do lf[i] = lf[i-1] + math.log(i) end
	        local function Cbin(nn, kk)
	            if kk < 0 or kk > nn then return 0 end
	            return math.exp(lf[nn] - lf[kk] - lf[nn-kk])
	        end

	        -- no frontier -> every covered cell is sea, uniform marginal
	        if #comps == 0 then
	            return {}, {}, {}, (U > 0) and (Mrem / U) or nil
	        end

	        -- normalized component histograms (poly in x^mines) + per-cell mine dists.
	        -- Dividing by total keeps magnitudes ~1; constant factors cancel in ratios.
	        local hpoly, cmdist = {}, {}
	        for ci, comp in ipairs(comps) do
	            local p = { deg = comp.n }
	            for m = 0, comp.n do p[m] = (comp.H[m] or 0) / comp.total end
	            hpoly[ci] = p
	            local cm = {}
	            for j = 1, comp.n do
	                local arr = {}
	                for m = 0, comp.n do arr[m] = (comp.cellMine[j][m] or 0) / comp.total end
	                cm[j] = arr
	            end
	            cmdist[ci] = cm
	        end

	        local function conv(a, b)
	            local r = { deg = a.deg + b.deg }
	            for i = 0, r.deg do r[i] = 0 end
	            for i = 0, a.deg do
	                local ai = a[i]
	                if ai ~= 0 then for j = 0, b.deg do r[i+j] = r[i+j] + ai * b[j] end end
	            end
	            return r
	        end

	        -- prefix/suffix products so "all components except i" is one lookup
	        local K = #comps
	        local ONE = { deg = 0, [0] = 1 }
	        local pref, suf = {}, {}
	        pref[0] = ONE
	        for i = 1, K do pref[i] = conv(pref[i-1], hpoly[i]) end
	        suf[K+1] = ONE
	        for i = K, 1, -1 do suf[i] = conv(suf[i+1], hpoly[i]) end
	        local Gall = pref[K]                                       -- all frontier comps combined

	        -- total weight W = sum_T Gall[T] * C(U, Mrem - T)
	        local W = 0
	        for T = 0, Gall.deg do
	            local g = Gall[T]
	            if g ~= 0 then W = W + g * Cbin(U, Mrem - T) end
	        end
	        if W <= 0 then return nil end

	        local fSafe, fMine, probOut = {}, {}, {}
	        for ci, comp in ipairs(comps) do
	            local Hrest = conv(pref[ci-1], suf[ci+1])              -- product of the OTHER comps
	            -- A[s] = sum_t Hrest[t] * C(U, s - t)   (others + sea filling the rest)
	            local A = {}
	            for s = 0, Mrem do
	                local acc = 0
	                for t = 0, Hrest.deg do
	                    local ht = Hrest[t]
	                    if ht ~= 0 then acc = acc + ht * Cbin(U, s - t) end
	                end
	                A[s] = acc
	            end
	            local cm = cmdist[ci]
	            for j = 1, comp.n do
	                local numer, arr = 0, cm[j]
	                for m = 0, comp.n do
	                    local q = arr[m]
	                    if q ~= 0 then
	                        local s = Mrem - m
	                        if s >= 0 then numer = numer + q * A[s] end
	                    end
	                end
	                local pmine = numer / W
	                local k = comp.cells[j]
	                if pmine <= 1e-9 then fSafe[k] = true
	                elseif pmine >= 1 - 1e-9 then fMine[k] = true
	                else probOut[k] = pmine end
	            end
	        end

	        -- sea-cell marginal = expected leftover mines per sea cell
	        local seaP = nil
	        if U > 0 then
	            local ET = 0
	            for T = 0, Gall.deg do
	                local g = Gall[T]
	                if g ~= 0 then ET = ET + T * g * Cbin(U, Mrem - T) end
	            end
	            ET = ET / W
	            seaP = (Mrem - ET) / U
	            if seaP < 0 then seaP = 0 elseif seaP > 1 then seaP = 1 end
	        end

	        return fSafe, fMine, probOut, seaP
	    end

	    local prob = {}   -- key -> mine probability  (prob[0] = sea-cell probability)
	    if not hasMove then
	        local usedWMC = false
	        if USE_WMC and isSlowLevel() and CURRENT_MINES then
	            local fs, fm, pr, seaP = wmc(MAX_ENUM)
	            if fs then                                  -- WMC succeeded (all comps enumerable)
	                for k in pairs(fs) do markSafe(k) end
	                for k in pairs(fm) do markMine(k) end
	                prob = pr
	                if seaP then prob[0] = seaP end         -- sentinel key 0 = sea probability
	                usedWMC = true
	            end
	        end

	        if not usedWMC then
	            -- (1) frontier cells touched by number constraints (unweighted CSP)
	            local fkeys, seenk = {}, {}
	            for _, con in ipairs(constraints) do
	                for _, k in ipairs(con.cells) do
	                    if not safe[k] and not mine[k] and not seenk[k] then seenk[k]=true; fkeys[#fkeys+1]=k end
	                end
	            end
	            local fs, fm, pr = csp(fkeys, constraints, MAX_ENUM)
	            for k in pairs(fs) do markSafe(k) end
	            for k in pairs(fm) do markMine(k) end
	            prob = pr

	            -- (2) global mine-count endgame: "rem mines among the covered cells".
	            -- Resolves the last cells that local number-logic alone cannot.
	            if CURRENT_MINES then
	                local km = 0
	                for r=1,R do for c=1,C do if grid[r][c].state == "FLAG" then km = km + 1 end end end
	                local unknown = {}
	                for _, rc in ipairs(covered) do
	                    local k = key(rc[1], rc[2])
	                    if mine[k] then km = km + 1
	                    elseif not safe[k] then unknown[#unknown+1] = k end
	                end
	                local rem = CURRENT_MINES - km
	                if rem <= 0 then
	                    for _, k in ipairs(unknown) do markSafe(k) end
	                elseif rem == #unknown then
	                    for _, k in ipairs(unknown) do markMine(k) end
	                elseif #unknown > 0 and #unknown <= ENUM_ALL then
	                    local cons = {}
	                    for _, con in ipairs(constraints) do
	                        if #con.cells > 0 then cons[#cons+1] = { cells = con.cells, n = con.n } end
	                    end
	                    cons[#cons+1] = { cells = unknown, n = rem }   -- total mines remaining
	                    local fs2, fm2, pr2 = csp(unknown, cons, ENUM_ALL)
	                    for k in pairs(fs2) do markSafe(k) end
	                    for k in pairs(fm2) do markMine(k) end
	                    for k, v in pairs(pr2) do prob[k] = v end
	                end
	            end
	        end
	    end

	    -- collect results
	    local toReveal, toFlag = {}, {}
	    for _, rc in ipairs(covered) do
	        local k = key(rc[1], rc[2])
	        if safe[k] and not mine[k] then toReveal[#toReveal+1] = rc
	        elseif mine[k] then toFlag[#toFlag+1] = rc end
	    end

	    -- ---- best hint target: maximize expected cells unlocked (1-ply) ----------
	    -- A hint is a guaranteed-SAFE probe, so survival is NOT a factor -- we spend it
	    -- purely for information. Score each undetermined frontier cell by the EXPECTED
	    -- number of OTHER frontier cells that become forced once its true state is
	    -- known: with prob p it's a mine (-> flagged), otherwise it reveals a number
	    -- whose value distribution comes from the neighbours' marginals. Under each
	    -- hypothesis we re-run only the cheap single-point + subset deduction (NO
	    -- enumeration), so this stays light. Slow levels only (needs WMC marginals);
	    -- computed only when there's nothing certain to reveal (i.e. we're stuck).
	    local hintTarget = nil
	    if #toReveal == 0 and USE_WMC and isSlowLevel() then
	        local cand = {}
	        for k, p in pairs(prob) do
	            if k ~= 0 and p > 0 and p < 1 then cand[#cand+1] = k end
	        end
	        if #cand > 0 then
	            -- fresh number-constraints from the grid, for the simulation
	            local baseCons = {}
	            for r=1,R do for c=1,C do
	                local g = grid[r][c]
	                if g.state == "NUM" or g.state == "BLANK" then
	                    local unk, mc = {}, 0
	                    for _, d in ipairs(NB) do
	                        local nr, nc = r+d[1], c+d[2]
	                        if grid[nr] and grid[nr][nc] then
	                            local ng = grid[nr][nc]
	                            if ng.state == "FLAG" then mc = mc + 1
	                            elseif ng.state == "COVERED" then unk[#unk+1] = key(nr, nc) end
	                        end
	                    end
	                    if #unk > 0 then baseCons[#baseCons+1] = { cells = unk, n = g.num - mc } end
	                end
	            end end

	            -- rank candidates by constraint degree and keep the top HINT_CANDIDATES
	            -- so the 1-ply search stays bounded on dense boards.
	            local degree = {}
	            for _, con in ipairs(baseCons) do
	                for _, k in ipairs(con.cells) do degree[k] = (degree[k] or 0) + 1 end
	            end
	            table.sort(cand, function(a, b) return (degree[a] or 0) > (degree[b] or 0) end)
	            if #cand > HINT_CANDIDATES then
	                for i = #cand, HINT_CANDIDATES + 1, -1 do cand[i] = nil end
	            end

	            local undet = {}
	            for _, k in ipairs(cand) do undet[k] = true end

	            -- run single-point + subset deduction from current knowledge + `extra`
	            -- hypothesis constraints; return how many `undet` cells (except `exclude`)
	            -- become forced.
	            local function countForced(extra, exclude)
	                local mineC, safeC = {}, {}
	                for k in pairs(mine) do mineC[k] = true end
	                for k in pairs(safe) do safeC[k] = true end
	                local cons = {}
	                for _, con in ipairs(baseCons) do
	                    local cc = {}; for _, k in ipairs(con.cells) do cc[#cc+1] = k end
	                    cons[#cons+1] = { cells = cc, n = con.n }
	                end
	                for _, con in ipairs(extra) do
	                    local cc = {}; for _, k in ipairs(con.cells) do cc[#cc+1] = k end
	                    cons[#cons+1] = { cells = cc, n = con.n }
	                end
	                local function setOf(list) local s={} for _,k in ipairs(list) do s[k]=true end return s end
	                local changed, guard = true, 0
	                while changed and guard < 200 do
	                    changed = false; guard = guard + 1
	                    for _, con in ipairs(cons) do
	                        local nc, nn = {}, con.n
	                        for _, k in ipairs(con.cells) do
	                            if mineC[k] then nn = nn - 1
	                            elseif safeC[k] then -- drop
	                            else nc[#nc+1] = k end
	                        end
	                        con.cells, con.n = nc, nn
	                        if #con.cells > 0 then
	                            if con.n <= 0 then
	                                for _, k in ipairs(con.cells) do if not safeC[k] then safeC[k]=true; changed=true end end
	                            elseif con.n >= #con.cells then
	                                for _, k in ipairs(con.cells) do if not mineC[k] then mineC[k]=true; changed=true end end
	                            end
	                        end
	                    end
	                    for i=1,#cons do for j=1,#cons do
	                        if i ~= j then
	                            local A, B = cons[i], cons[j]
	                            if #A.cells > 0 and #B.cells > 0 and #A.cells < #B.cells then
	                                local bset = setOf(B.cells)
	                                local subset = true
	                                for _, k in ipairs(A.cells) do if not bset[k] then subset=false break end end
	                                if subset then
	                                    local aset = setOf(A.cells)
	                                    local diff = {}
	                                    for _, k in ipairs(B.cells) do if not aset[k] then diff[#diff+1]=k end end
	                                    local dn = B.n - A.n
	                                    if #diff > 0 then
	                                        if dn <= 0 then
	                                            for _, k in ipairs(diff) do if not safeC[k] then safeC[k]=true; changed=true end end
	                                        elseif dn >= #diff then
	                                            for _, k in ipairs(diff) do if not mineC[k] then mineC[k]=true; changed=true end end
	                                        end
	                                    end
	                                end
	                            end
	                        end
	                    end end
	                end
	                local cnt = 0
	                for k in pairs(undet) do
	                    if k ~= exclude and (mineC[k] or safeC[k]) then cnt = cnt + 1 end
	                end
	                return cnt
	            end

	            -- covered (still-unknown) neighbours of a cell -- those its number constrains
	            local function coveredNbrs(k)
	                local r = math.floor(k / 100); local c = k - r * 100
	                local nb = {}
	                for _, d in ipairs(NB) do
	                    local nr, nc = r + d[1], c + d[2]
	                    if grid[nr] and grid[nr][nc] and grid[nr][nc].state == "COVERED" then
	                        nb[#nb+1] = key(nr, nc)
	                    end
	                end
	                return nb
	            end

	            local best, bestScore, bestEnt = nil, -1, -1
	            for _, k in ipairs(cand) do
	                local p = prob[k]
	                -- mine outcome: c gets flagged
	                local uMine = countForced({ { cells = {k}, n = 1 } }, k)
	                -- safe outcome: c reveals a number -> covered-neighbour mines = m,
	                -- m ~ Poisson-binomial of the neighbours' marginals.
	                local nbrs = coveredNbrs(k)
	                local dist, deg = { [0] = 1 }, 0
	                for _, nk in ipairs(nbrs) do
	                    local q
	                    if mine[nk] then q = 1
	                    elseif safe[nk] then q = 0
	                    else q = prob[nk] or prob[0] or 0.5 end
	                    local nd = {}
	                    for m = 0, deg do
	                        local dm = dist[m] or 0
	                        nd[m]   = (nd[m]   or 0) + dm * (1 - q)
	                        nd[m+1] = (nd[m+1] or 0) + dm * q
	                    end
	                    dist, deg = nd, deg + 1
	                end
	                local uSafe = 0
	                for m = 0, #nbrs do
	                    local pm = dist[m] or 0
	                    if pm > 1e-9 then
	                        local extra = { { cells = {k}, n = 0 } }
	                        if #nbrs > 0 then extra[#extra+1] = { cells = nbrs, n = m } end
	                        uSafe = uSafe + pm * countForced(extra, k)
	                    end
	                end
	                local score = p * uMine + (1 - p) * uSafe
	                local ent = -(p * math.log(p) + (1 - p) * math.log(1 - p))   -- tiebreak: more uncertain wins
	                if score > bestScore + 1e-9 or (math.abs(score - bestScore) <= 1e-9 and ent > bestEnt) then
	                    best, bestScore, bestEnt = k, score, ent
	                end
	            end
	            if best then
	                local r = math.floor(best / 100)
	                hintTarget = { r, best - r * 100 }
	            end
	        end
	    end

	    return toReveal, toFlag, prob, covered, mine, key, hintTarget
	end

	-- ---- minigame open/closed detection (cheap -- vent-style idle) -------------
	-- While the minigame is closed we do ZERO board scanning/solving: just a single
	-- FindFirstChild on the known name. Only once it's open do we engage.
	local function minigameOpen()
	    local mg = PlayerGui:FindFirstChild("HackingMinigame")
	    if not mg then return nil end
	    if mg:IsA("ScreenGui") or mg:IsA("LayerCollector") then
	        if not mg.Enabled then return nil end
	    elseif mg:IsA("GuiObject") then
	        if not mg.Visible then return nil end
	    end
	    return mg
	end

	-- Wait until the board changes (our last action took effect / a cascade settled)
	-- or we time out / the minigame closes. This is what makes play event-driven
	-- instead of re-solving 20x/second.
	local function waitForChange(board, oldSig, timeout)
	    local t0 = os.clock()
	    while os.clock() - t0 < timeout do
	        task.wait()
	        if not minigameOpen() then return false end
	        local g, R, C = readBoard(board)
	        if g and signature(g, R, C) ~= oldSig then return true end
	    end
	    return false
	end

	-- deduce + act on CERTAIN moves only. returns a status plus the solve results so
	-- the caller can decide whether to gamble:
	--   "over"    a mine is showing, or every safe cell is already revealed
	--   "acted"   placed flags and/or revealed at least one PROVEN-safe cell
	--   "stuck"   no certain move -> caller may guess/hint (results returned)
	--   "idle"    board not readable right now
	local function deduceAndAct(board)
	    local grid, R, C = readStable(board)
	    if not grid then return "idle" end
	    CURRENT_MINES = detectMines(board, grid, R, C)

	    for r=1,R do for c=1,C do if grid[r][c].state == "MINE" then
	        msLog("a mine is revealed -> stopping (lost or finished).")
	        return "over"
	    end end end

	    local toReveal, toFlag, prob, covered, mine, key, hintTarget = solve(grid, R, C)

	    if state.msFlags then
	        for _, rc in ipairs(toFlag) do
	            local g = grid[rc[1]][rc[2]]
	            if g.state == "COVERED" then flagCell(g.cell) end
	        end
	    end

	    if #toReveal > 0 then
	        for _, rc in ipairs(toReveal) do
	            revealCell(grid[rc[1]][rc[2]].cell)
	        end
	        return "acted"
	    end

	    local unknownLeft = 0
	    for _, rc in ipairs(covered) do if not mine[key(rc[1],rc[2])] then unknownLeft = unknownLeft+1 end end
	    if unknownLeft == 0 then
	        msLog("solved -- all safe cells revealed.")
	        return "over"
	    end

	    return "stuck", grid, R, C, prob, covered, mine, key, hintTarget
	end

	-- ---- one play cycle: read -> solve -> act. returns "acted"/"idle"/"over". --
	local function playCycle(board)
	    CURRENT_LEVEL = detectLevel(board)

	    local status, grid, R, C, prob, covered, mine, key, hintTarget = deduceAndAct(board)
	    if status ~= "stuck" then return status end

	    -- STUCK. Needless 50/50s come from gambling on a board that hadn't finished
	    -- updating, so NEVER guess on the first stuck read. Give it extra settle time
	    -- and deduce again -- a cascade from the previous move often exposes proven-
	    -- safe cells we'd otherwise have gambled on. Only guess if STILL stuck.
	    -- Slow levels (5-6) settle; levels 1-4 confirm instantly and stay fast.
	    task.wait(isSlowLevel() and STUCK_CONFIRM_S or STUCK_CONFIRM_F)
	    local status2, grid2, R2, C2, prob2, covered2, mine2, key2, hintTarget2 = deduceAndAct(board)
	    if status2 ~= "stuck" then return status2 end        -- found a sure move / over
	    grid, R, C, prob, covered, mine, key = grid2, R2, C2, prob2, covered2, mine2, key2
	    hintTarget = hintTarget2

	    local anyRevealed = false
	    for r=1,R do for c=1,C do local s=grid[r][c].state; if s=="NUM" or s=="BLANK" then anyRevealed=true end end end

	    -- returns the safest covered cell AND its mine probability.
	    local function lowestProbCell()
	        local minesLeft = CURRENT_MINES
	        local flagged = 0
	        for r=1,R do for c=1,C do if grid[r][c].state=="FLAG" then flagged=flagged+1 end end end
	        -- prefer the exact WMC sea probability (prob[0]) over the flat base-rate guess
	        local defP = prob[0] or (minesLeft and math.max(0,(minesLeft-flagged))/math.max(1,#covered) or 0.5)
	        local best, bp = nil, 2
	        for _, rc in ipairs(covered) do
	            if not mine[key(rc[1],rc[2])] then
	                local p = prob[key(rc[1],rc[2])] or defP
	                if p < bp then bp, best = p, rc end
	            end
	        end
	        return best, bp
	    end
	    -- fallback hint target (fast levels / no WMC target): the frontier cell most
	    -- likely to be a mine. The slow-level path prefers solve()'s expected-unlock
	    -- `hintTarget` instead, which is far better at breaking the deadlock.
	    local function bestHintCell()
	        local best, bp = nil, -1
	        for _, rc in ipairs(covered) do
	            local p = prob[key(rc[1],rc[2])]
	            if p and not mine[key(rc[1],rc[2])] and p > bp then bp, best = p, rc end
	        end
	        return best or (lowestProbCell())
	    end
	    -- the opening: centre opens the most area on a fresh board.
	    local function openingCell()
	        local r = (FIRST_MOVE=="corner") and 1 or math.ceil(R/2)
	        local c = (FIRST_MOVE=="corner") and 1 or math.ceil(C/2)
	        return {r, c}
	    end

	    local canHint = state.msHints and hintsLeft(board) > 0
	    -- Always prefer a hint when one is available (incl. the opening), so we never
	    -- take an avoidable gamble. Only guess once hints are gone.
	    if canHint then
	        -- slow levels: spend the hint on the expected-unlock target from solve();
	        -- otherwise fall back to the highest-mine-prob cell (or the opening).
	        local t
	        if anyRevealed then t = hintTarget or bestHintCell() else t = openingCell() end
	        if t then
	            msLog(("stuck -> hint probe (%d,%d), %d left [mines=%s]"):format(
	                t[1], t[2], hintsLeft(board), tostring(CURRENT_MINES)))
	            useHintOn(board, grid[t[1]][t[2]].cell)
	        end
	    else
	        local pick, pickP
	        if anyRevealed then pick, pickP = lowestProbCell() else pick = openingCell() end
	        if pick then
	            msLog(("no hints -> guess (%d,%d) p=%.2f [mines=%s]"):format(
	                pick[1], pick[2], pickP or -1, tostring(CURRENT_MINES)))
	            revealCell(grid[pick[1]][pick[2]].cell)
	        end
	    end
	    return "acted"
	end

	-- ---- direct mine-layout reader (pure read, no network) --------------------
	-- The board is generated CLIENT-SIDE: each cell's reveal handler closes over a
	-- state table { HasMine, X, Y, UI=<frame>, ... }. We read it straight out of the
	-- handler's upvalues -- so we know every mine before touching anything. Sends
	-- nothing to the server; this is all reads. Falls back to the solver if the
	-- closure shape ever changes (returns nil).
	local hasGetUpvalues = typeof(debug) == "table" and typeof(debug.getupvalues) == "function"

	local function getCellState(btn)
	    local ok, conns = pcall(getconnections, btn.MouseButton1Up)
	    if not ok or not conns then return nil end
	    for _, c in ipairs(conns) do
	        local f
	        pcall(function() f = c.Function end)
	        if typeof(f) == "function" and hasGetUpvalues then
	            local ok2, ups = pcall(debug.getupvalues, f)
	            if ok2 and ups then
	                for _, u in ipairs(ups) do
	                    if typeof(u) == "table" and u.HasMine ~= nil and u.X ~= nil and u.Y ~= nil then
	                        return u
	                    end
	                end
	            end
	        end
	    end
	    return nil
	end

	-- read the live layout. returns { cells = {state,...}, mines = n } or nil.
	local function readMineLayout()
	    if not state.msReader or not hasGetUpvalues then return nil end
	    local mg = minigameOpen(); if not mg then return nil end
	    local canvas = mg:FindFirstChild("Canvas") or mg
	    local cells, mines = {}, 0
	    for _, d in ipairs(canvas:GetDescendants()) do
	        if d:FindFirstChild("Mine") and d:FindFirstChild("Hidden") and d:FindFirstChild("Button") then
	            local st = getCellState(d.Button)
	            if st then
	                if st.UI == nil then st.UI = d end   -- ensure a frame back-reference
	                cells[#cells+1] = st
	                if st.HasMine then mines = mines + 1 end
	            end
	        end
	    end
	    if #cells == 0 then return nil end
	    return { cells = cells, mines = mines }
	end

	local function cellCovered(st)
	    local h = st.UI and st.UI:FindFirstChild("Hidden")
	    return h and h.Visible == true
	end

	local function revealState(st)
	    local cell = st.UI; if not cell then return end
	    local btn = cell:FindFirstChild("Button")
	    if not btn and cell:IsA("GuiButton") then btn = cell end
	    if not btn then return end
	    local x, y = centreOf(cell)
	    fire(btn.MouseButton1Down, x, y)
	    fire(btn.MouseButton1Up, x, y)
	end

	-- play the board out from the known layout, pacing reveals so it spans SOLVE_TIME
	-- for the current level (so a 200/400-mine board never resolves instantly).
	-- returns "over" (done), or "fail" (couldn't read -> caller falls back to solver).
	local function cheatSolve(board)
	    local layout = readMineLayout()
	    if not layout then return "fail" end

	    local lvl = detectLevel(board)
	    local T = (lvl and SOLVE_TIME[lvl]) or state.msPace

	    local safe = {}
	    for _, st in ipairs(layout.cells) do
	        if not st.HasMine then safe[#safe+1] = st end
	    end
	    if #safe == 0 then return "fail" end

	    if CHEAT_SHUFFLE then
	        for i = #safe, 2, -1 do local j = math.random(i); safe[i], safe[j] = safe[j], safe[i] end
	    end

	    local interval = (#safe > 0) and (T / #safe) or 0
	    msLog(("reader: lvl %s, %d mines, revealing %d safe cells over %.0fs")
	        :format(tostring(lvl), layout.mines, #safe, T))

	    for _, st in ipairs(safe) do
	        if not minigameOpen() or not state.ms then return "over" end   -- closed/ended/disabled mid-solve
	        if cellCovered(st) then revealState(st) end     -- skip ones a cascade already opened
	        if interval > 0 then task.wait(interval) end
	    end
	    msLog("reader: board cleared.")
	    return "over"
	end

	-- ---- main loop -------------------------------------------------------------

	-- guards, both cleared when the minigame closes so the NEXT one restarts fresh:
	--   doneSig          (solver fallback) signature of a board we already finished
	--   cheatedThisOpen  (reader path) we already played this open instance to completion
	local doneSig = nil
	local cheatedThisOpen = false

	-- the solver fallback for one engagement (used only if the reader can't read).
	local function solverCycle(board)
	    local g0, R0, C0 = readBoard(board)
	    local before = g0 and signature(g0, R0, C0) or ""
	    if before == doneSig then task.wait(0.4); return end
	    local result = playCycle(board)
	    if result == "over" then
	        doneSig = before
	        task.wait(0.4)
	    elseif result == "acted" then
	        waitForChange(board, before, 1.0)   -- event-driven: wait for it to land
	    else
	        task.wait(CYCLE_WAIT)               -- "idle": board mid-read, retry shortly
	    end
	end

	task.spawn(function()
	    while H.alive do
	        local mg = state.ms and minigameOpen()
	        if not mg then
	            -- IDLE: minigame closed. No board scan -- just back off and reset guards.
	            doneSig, cheatedThisOpen = nil, false
	            task.wait(0.4)
	        else
	            local board = findBoard(mg)
	            if not board then
	                doneSig, cheatedThisOpen = nil, false   -- between games -> reset
	                task.wait(0.2)
	            elseif state.msReader then
	                if cheatedThisOpen then
	                    task.wait(0.4)                       -- solved; wait for it to close
	                else
	                    local res = cheatSolve(board)
	                    if res == "over" then
	                        cheatedThisOpen = true           -- done until this instance closes
	                        task.wait(0.4)
	                    else                                 -- "fail": read unavailable -> solve it
	                        solverCycle(board)
	                    end
	                end
	            else
	                solverCycle(board)
	            end
	        end
	    end
	end)
end
task.spawn(msBot)

-- ================= PAKETE / DEAD DROPS (Wegpunkt) =================
-- Quests: RS.Values.Quests.DeadDrops.<NPC>.<Ort> (Payout/Risk/Distance/CurrentPlayer); angenommen = lp.CurrentQuest.
-- Ziel-Part workspace.DeadDropLocations[<Ort>] streamt erst in der Nähe -> bis dahin Näherung (Region/Kamera),
-- danach exakte Position, dauerhaft gelernt in tsc_deaddrops.json. Anzeige rein 2D (keine Welt-Instanzen).
local DD_FILE = "tsc_deaddrops.json"
local ddLearned = {}
pcall(function() if isfile(DD_FILE) then ddLearned = HttpService:JSONDecode(readfile(DD_FILE)) end end)
if type(ddLearned) ~= "table" then ddLearned = {} end
-- Näherungen: Region-Boxen/Security-Kameras, gegen Quest-"Distance" plausibilisiert
local DD_HINTS = {
	["Centrifuge Control Room"] = { 1072, -158, 624 },
	["SteeleTown"] = { -259, 54, 93 },
	["AD Offices"] = { -600, 71, 410 },
	["CISCZ Kitchen"] = { 559, -141, 1247 },
	["U&M Spawn"] = { -340, 50, 105 },
	["S2 Commons Vent"] = { 1059, 26, -122 },
	["MD Spawn"] = { -86, 36, 273 },
	["Security Storage Entrance"] = { 989, 12, -62 },
	["Tram Platform A"] = { 284, 20, 57 },
	["S2 Staff Break Room"] = { 983, 10, -25 },
	["Classroom Wing"] = { 889, 62, -341 },
	["TSCZ Cargo Elevator"] = { 1494, 40, -513 },
	["TSCZ Cargo Dropoff"] = { 913, 80, -563 },
	["S1 Bridge"] = { -715, 87, 47 },
	["Solitary Confinement"] = { 1557.8, 70.5, -394 },
	["TSCZ Viewing Area"] = { 1556.4, 87.3, -246.6 },
	["Parkour Chute"] = { 1693.9, 204.1, -144 },
}
local function ddSave() pcall(writefile, DD_FILE, HttpService:JSONEncode(ddLearned)) end
local function ddLearn(part)
	if not part:IsA("BasePart") then return end
	local p = part.Position
	local old = ddLearned[part.Name]
	if not old or math.abs(old[1] - p.X) + math.abs(old[2] - p.Y) + math.abs(old[3] - p.Z) > 1 then
		ddLearned[part.Name] = { p.X, p.Y, p.Z }; ddSave()
	end
end
local ddFolder = workspace:FindFirstChild("DeadDropLocations")
if ddFolder then
	for _, c in ipairs(ddFolder:GetChildren()) do ddLearn(c) end
	con(ddFolder.ChildAdded, function(c) task.defer(ddLearn, c) end)
end
local function ddTarget(name)
	local live = ddFolder and ddFolder:FindFirstChild(name)
	if live and live:IsA("BasePart") then return live.Position, "exakt" end
	local l = ddLearned[name]; if l then return Vector3.new(l[1], l[2], l[3]), "gelernt" end
	local h = DD_HINTS[name]; if h then return Vector3.new(h[1], h[2], h[3]), "ca." end
	return nil, "unbekannt"
end
local function ddQuests()
	local out = {}
	local root = game:GetService("ReplicatedStorage"):FindFirstChild("Values")
	root = root and root:FindFirstChild("Quests"); root = root and root:FindFirstChild("DeadDrops")
	if not root then return out end
	for _, npc in ipairs(root:GetChildren()) do
		for _, q in ipairs(npc:GetChildren()) do
			local function v(n) local o = q:FindFirstChild(n) return o and o.Value end
			out[#out + 1] = { obj = q, name = q.Name, npc = npc.Name, pay = v("Payout") or 0, risk = v("Risk") or 0, who = v("CurrentPlayer") }
		end
	end
	table.sort(out, function(a, b) return a.pay > b.pay end)
	return out
end

state.pkgSel = sv("pkgSel", nil)
local pkgInfo = info(S_pkg, "No package selected", T.accent)
-- Ziel-Auswahl als Dropdown (Liste wird beim Aufklappen frisch gebaut)
local lastPkgSig = ""
local pkgCur
do
	txt(S_pkg.f, "Target", UDim2.new(1, 0, 0, 14)).LayoutOrder = nextOrder(S_pkg)
	local box = Instance.new("TextButton")
	box.Size = UDim2.new(1, 0, 0, 18); box.BackgroundColor3 = T.track; box.BorderSizePixel = 0; box.AutoButtonColor = false
	box.Text = ""; box.LayoutOrder = nextOrder(S_pkg); box.Parent = S_pkg.f
	stroke(box); corner(box, 2)
	pkgCur = txt(box, state.pkgSel or "none", UDim2.new(1, -24, 1, 0)); pkgCur.Position = UDim2.fromOffset(6, 0)
	pkgCur.TextTruncate = Enum.TextTruncate.AtEnd
	local arr = txt(box, "▼", UDim2.new(0, 14, 1, 0), T.text); arr.Position = UDim2.new(1, -16, 0, 0); arr.TextSize = 10
	local list = Instance.new("Frame")
	list.Size = UDim2.new(1, 0, 0, 0); list.AutomaticSize = Enum.AutomaticSize.Y; list.BackgroundColor3 = T.bg
	list.BorderSizePixel = 0; list.Visible = false; list.LayoutOrder = nextOrder(S_pkg); list.Parent = S_pkg.f
	stroke(list)
	Instance.new("UIListLayout", list).SortOrder = Enum.SortOrder.LayoutOrder
	local function close() list.Visible = false; arr.Text = "▼" end
	local function fill()
		for _, c in ipairs(list:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
		local cq = lp:FindFirstChild("CurrentQuest")
		local mineObj = cq and cq.Value
		local opts = { { label = "none" } }
		for _, q in ipairs(ddQuests()) do
			local _, kind = ddTarget(q.name)
			local npcShort = q.npc:gsub("'s Dead Drops", "")
			opts[#opts + 1] = { name = q.name, own = mineObj == q.obj, label = ("%s$%d %s [%s] r%d%s%s"):format(mineObj == q.obj and "> " or "",
				q.pay, q.name, npcShort, q.risk, q.who and (" - " .. (q.who == lp and "you" or q.who.Name)) or "", kind == "ca." and " ~" or "") }
		end
		for i, o in ipairs(opts) do
			local b = Instance.new("TextButton")
			b.Size = UDim2.new(1, 0, 0, 17); b.BackgroundTransparency = 1; b.Font = T.font; b.TextSize = 12
			b.Text = "  " .. o.label; b.TextXAlignment = Enum.TextXAlignment.Left; b.TextTruncate = Enum.TextTruncate.AtEnd
			b.TextColor3 = o.own and Color3.fromRGB(120, 255, 140) or ((o.name == state.pkgSel) and T.accent or T.dim)
			b.LayoutOrder = i; b.Parent = list
			b.MouseButton1Click:Connect(function() state.pkgSel = o.name; close() end)
		end
	end
	con(box.MouseButton1Click, function()
		if list.Visible then close() else fill(); list.Visible = true; arr.Text = "▲" end
	end)
end
button(S_pkg, "Clear Waypoint", function() state.pkgSel = nil end)
info(S_pkg, "~ = approx. (region/camera); exact once the drop point streams in (saved to workspace/" .. DD_FILE .. ")")

local function rebuildPkg()
	local sel = state.pkgSel or "none"
	if pkgCur.Text ~= sel then pkgCur.Text = sel end
end

-- Wegpunkt-Overlay (2D-Projektion)
local wpLbl = Instance.new("TextLabel")
wpLbl.AnchorPoint = Vector2.new(0.5, 1); wpLbl.Size = UDim2.fromOffset(220, 36); wpLbl.BackgroundTransparency = 1
wpLbl.Font = Enum.Font.GothamBold; wpLbl.TextSize = 14; wpLbl.TextStrokeTransparency = 0.2; wpLbl.Visible = false; wpLbl.Parent = gui
local wpDot = Instance.new("Frame")
wpDot.AnchorPoint = Vector2.new(0.5, 0.5); wpDot.Size = UDim2.fromOffset(12, 12); wpDot.BorderSizePixel = 0
wpDot.Rotation = 45; wpDot.Visible = false; wpDot.Parent = gui
local wpArrow = Instance.new("TextLabel")
wpArrow.AnchorPoint = Vector2.new(0.5, 0.5); wpArrow.Size = UDim2.fromOffset(200, 36); wpArrow.BackgroundTransparency = 1
wpArrow.Font = Enum.Font.GothamBold; wpArrow.TextSize = 14; wpArrow.TextStrokeTransparency = 0.2; wpArrow.Visible = false; wpArrow.Parent = gui

local autoSel = nil
con(RunService.RenderStepped, function()
	-- angenommene Quest automatisch wählen
	local cq = lp:FindFirstChild("CurrentQuest")
	local mine = cq and cq.Value and cq.Value.Name
	if mine and autoSel ~= mine then autoSel = mine; state.pkgSel = mine; lastPkgSig = "" end
	if not mine and autoSel then if state.pkgSel == autoSel then state.pkgSel = nil end autoSel = nil; lastPkgSig = "" end

	local name = state.pkgSel
	local pos, kind
	if name then pos, kind = ddTarget(name) end
	if not pos then
		wpLbl.Visible = false; wpDot.Visible = false; wpArrow.Visible = false
		pkgInfo.Text = name and ("Target: " .. name .. " (position unknown)") or "No package selected"
		return
	end
	local myRoot = rootOf(lp)
	local d = myRoot and math.floor((pos - myRoot.Position).Magnitude) or 0
	local dy = myRoot and math.floor(pos.Y - myRoot.Position.Y) or 0
	local col = (kind == "ca.") and Color3.fromRGB(255, 170, 60) or Color3.fromRGB(90, 255, 120)
	local txt = ("📦 %s\n%s%dm  (%s%d Höhe)"):format(name, kind == "ca." and "ca. " or "", d, dy >= 0 and "+" or "", dy)
	pkgInfo.Text = ("Target: %s  %dm  [%s]"):format(name, d, kind)
	local vp = cam.ViewportSize
	local sp, on = cam:WorldToViewportPoint(pos)
	if on and sp.Z > 0 then
		wpArrow.Visible = false
		wpDot.Position = UDim2.fromOffset(sp.X, sp.Y); wpDot.BackgroundColor3 = col; wpDot.Visible = true
		wpLbl.Position = UDim2.fromOffset(sp.X, sp.Y - 8); wpLbl.TextColor3 = col; wpLbl.Text = txt; wpLbl.Visible = true
	else
		wpLbl.Visible = false; wpDot.Visible = false
		local center = vp / 2
		local dir = Vector2.new(sp.X, sp.Y) - center
		if sp.Z < 0 then dir = -dir end
		if dir.Magnitude < 1 then dir = Vector2.new(0, -1) end
		dir = dir.Unit
		local m = 70
		local sx = (center.X - m) / math.max(math.abs(dir.X), 1e-3)
		local sy = (center.Y - m) / math.max(math.abs(dir.Y), 1e-3)
		local p2 = center + dir * math.min(sx, sy)
		wpArrow.Position = UDim2.fromOffset(p2.X, p2.Y); wpArrow.TextColor3 = col
		wpArrow.Text = "📦 " .. name .. "\n" .. d .. "m"; wpArrow.Visible = true
	end
end)
task.spawn(function() while H.alive do pcall(rebuildPkg) task.wait(1) end end)

-- ================= EINKLAPPEN =================
state.collapsed = sv("collapsed", false)
local FULL_H = main.Size.Y.Offset
local colBtn = Instance.new("TextButton")
colBtn.Size = UDim2.fromOffset(22, 22); colBtn.AnchorPoint = Vector2.new(1, 0); colBtn.Position = UDim2.new(1, -6, 0, 2)
colBtn.BackgroundTransparency = 1; colBtn.Font = T.font; colBtn.TextSize = 16; colBtn.TextColor3 = T.dim; colBtn.Parent = titleBar
local function applyCollapse()
	tabBar.Visible = not state.collapsed; content.Visible = not state.collapsed
	main.Size = UDim2.fromOffset(main.Size.X.Offset, state.collapsed and 26 or FULL_H)
	colBtn.Text = state.collapsed and "+" or "–"
end
applyCollapse()
con(colBtn.MouseButton1Click, function() state.collapsed = not state.collapsed; applyCollapse() end)
con(colBtn.MouseEnter, function() colBtn.TextColor3 = T.accent end)
con(colBtn.MouseLeave, function() colBtn.TextColor3 = T.dim end)

-- ================= CONFIG =================
-- Laufende Einstellungen speichern sich automatisch (SAVE_FILE); hier zusätzlich ein Profil zum Sichern/Zurückholen
local CFG_FILE = "tsc_hub_config.json"
local DEFAULTS = { fullbright = false, esp = false, espDist = 1500, espFade = 40, espFadePow = 2, brightness = 2, items = false, perf = 1,
	updInt = 0.2, nofall = false, staff = true, vent = true, ventPred = true, ventLog = true, ventBias = 0,
	ms = true, msReader = true, msHints = true, msFlags = true, msPace = 0, turrets = false }
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
