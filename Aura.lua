-- Aura GUI library for Roblox executor scripts. Single-file, no require.
--=============================================================================
-- 1. SERVICES & CONFIGURATION
--=============================================================================

local function service(name)
	local instance = game:GetService(name)
	if type(cloneref) == "function" then
		local ok, cloned = pcall(cloneref, instance)
		if ok and cloned then return cloned end
	end
	return instance
end

local TweenService     = service("TweenService")
local UserInputService = service("UserInputService")
local GuiService       = service("GuiService")
local RunService       = service("RunService")
local TextService      = service("TextService")
local Players          = service("Players")

local Aura = {}
Aura.__index = Aura
Aura.Version = "3.0.0"

local Themes = {
	-- Neutral slate with a green accent. The default.
	Dark = {
		bg = Color3.fromRGB(13, 16, 21),      panel = Color3.fromRGB(17, 21, 27),
		panel2 = Color3.fromRGB(22, 27, 34),  panel3 = Color3.fromRGB(28, 34, 43),
		border = Color3.fromRGB(31, 38, 48),  border2 = Color3.fromRGB(44, 53, 66),
		text = Color3.fromRGB(226, 232, 240), muted = Color3.fromRGB(138, 149, 164),
		faint = Color3.fromRGB(94, 104, 118), accent = Color3.fromRGB(90, 209, 122),
		accentInk = Color3.fromRGB(6, 22, 12), danger = Color3.fromRGB(232, 93, 93),
		hover = Color3.fromRGB(28, 34, 43),   scrollIdle = Color3.fromRGB(44, 53, 66),
	},
	-- Deep blue-black, periwinkle accent. Cooler and higher contrast than Dark.
	Midnight = {
		bg = Color3.fromRGB(10, 12, 24),      panel = Color3.fromRGB(15, 18, 33),
		panel2 = Color3.fromRGB(20, 24, 43),  panel3 = Color3.fromRGB(27, 32, 56),
		border = Color3.fromRGB(33, 39, 66),  border2 = Color3.fromRGB(48, 56, 92),
		text = Color3.fromRGB(224, 230, 255), muted = Color3.fromRGB(136, 146, 190),
		faint = Color3.fromRGB(92, 101, 143), accent = Color3.fromRGB(112, 148, 255),
		accentInk = Color3.fromRGB(8, 12, 30), danger = Color3.fromRGB(235, 105, 130),
		hover = Color3.fromRGB(27, 32, 56),   scrollIdle = Color3.fromRGB(48, 56, 92),
	},
	-- Warm neutral grey, amber accent. The lightest of the set.
	Slate = {
		bg = Color3.fromRGB(20, 22, 25),      panel = Color3.fromRGB(26, 29, 33),
		panel2 = Color3.fromRGB(33, 37, 42),  panel3 = Color3.fromRGB(42, 47, 54),
		border = Color3.fromRGB(50, 56, 64),  border2 = Color3.fromRGB(70, 78, 89),
		text = Color3.fromRGB(233, 236, 240), muted = Color3.fromRGB(150, 158, 169),
		faint = Color3.fromRGB(105, 113, 124), accent = Color3.fromRGB(240, 170, 90),
		accentInk = Color3.fromRGB(28, 18, 6), danger = Color3.fromRGB(228, 100, 100),
		hover = Color3.fromRGB(42, 47, 54),   scrollIdle = Color3.fromRGB(70, 78, 89),
	},
	-- The Nord palette: polar-night greys under a frost-blue accent.
	Nord = {
		bg = Color3.fromRGB(35, 40, 49),      panel = Color3.fromRGB(46, 52, 64),
		panel2 = Color3.fromRGB(55, 62, 76),  panel3 = Color3.fromRGB(67, 76, 94),
		border = Color3.fromRGB(62, 70, 87),  border2 = Color3.fromRGB(84, 95, 117),
		text = Color3.fromRGB(236, 239, 244), muted = Color3.fromRGB(168, 180, 198),
		faint = Color3.fromRGB(122, 134, 154), accent = Color3.fromRGB(136, 192, 208),
		accentInk = Color3.fromRGB(10, 26, 32), danger = Color3.fromRGB(191, 97, 106),
		hover = Color3.fromRGB(67, 76, 94),   scrollIdle = Color3.fromRGB(84, 95, 117),
	},
	-- Muted plum with a dusty rose accent. Low contrast on purpose; easy at night.
	Rose = {
		bg = Color3.fromRGB(25, 23, 36),      panel = Color3.fromRGB(31, 29, 46),
		panel2 = Color3.fromRGB(38, 35, 58),  panel3 = Color3.fromRGB(49, 45, 70),
		border = Color3.fromRGB(46, 42, 66),  border2 = Color3.fromRGB(68, 62, 96),
		text = Color3.fromRGB(224, 222, 244), muted = Color3.fromRGB(150, 145, 178),
		faint = Color3.fromRGB(110, 106, 138), accent = Color3.fromRGB(235, 188, 186),
		accentInk = Color3.fromRGB(42, 24, 26), danger = Color3.fromRGB(235, 111, 146),
		hover = Color3.fromRGB(49, 45, 70),   scrollIdle = Color3.fromRGB(68, 62, 96),
	},
	Mono = {
		bg = Color3.fromRGB(14, 14, 14),      panel = Color3.fromRGB(20, 20, 20),
		panel2 = Color3.fromRGB(27, 27, 27),  panel3 = Color3.fromRGB(37, 37, 37),
		border = Color3.fromRGB(43, 43, 43),  border2 = Color3.fromRGB(62, 62, 62),
		text = Color3.fromRGB(242, 242, 242), muted = Color3.fromRGB(152, 152, 152),
		faint = Color3.fromRGB(106, 106, 106), accent = Color3.fromRGB(236, 236, 236),
		accentInk = Color3.fromRGB(16, 16, 16), danger = Color3.fromRGB(222, 92, 92),
		hover = Color3.fromRGB(37, 37, 37),   scrollIdle = Color3.fromRGB(62, 62, 62),
	},
	-- Warm charcoal, orange accent. The only palette whose greys lean red.
	Ember = {
		bg = Color3.fromRGB(22, 17, 15),      panel = Color3.fromRGB(29, 22, 19),
		panel2 = Color3.fromRGB(38, 29, 25),  panel3 = Color3.fromRGB(49, 37, 31),
		border = Color3.fromRGB(56, 42, 35),  border2 = Color3.fromRGB(80, 60, 49),
		text = Color3.fromRGB(245, 232, 224), muted = Color3.fromRGB(178, 154, 140),
		faint = Color3.fromRGB(130, 110, 99), accent = Color3.fromRGB(255, 138, 66),
		accentInk = Color3.fromRGB(34, 15, 4), danger = Color3.fromRGB(240, 88, 88),
		hover = Color3.fromRGB(49, 37, 31),   scrollIdle = Color3.fromRGB(80, 60, 49),
	},
	-- Deep teal with a cyan accent. The darkest background of the set.
	Ocean = {
		bg = Color3.fromRGB(9, 20, 26),       panel = Color3.fromRGB(13, 27, 35),
		panel2 = Color3.fromRGB(18, 36, 46),  panel3 = Color3.fromRGB(25, 48, 60),
		border = Color3.fromRGB(28, 54, 68),  border2 = Color3.fromRGB(44, 78, 96),
		text = Color3.fromRGB(222, 240, 245), muted = Color3.fromRGB(138, 170, 182),
		faint = Color3.fromRGB(97, 126, 138), accent = Color3.fromRGB(56, 196, 220),
		accentInk = Color3.fromRGB(3, 24, 29), danger = Color3.fromRGB(238, 101, 110),
		hover = Color3.fromRGB(25, 48, 60),   scrollIdle = Color3.fromRGB(44, 78, 96),
	},
	-- Aubergine with a violet accent. The most saturated greys here.
	Grape = {
		bg = Color3.fromRGB(19, 15, 28),      panel = Color3.fromRGB(26, 20, 38),
		panel2 = Color3.fromRGB(34, 27, 50),  panel3 = Color3.fromRGB(45, 35, 66),
		border = Color3.fromRGB(52, 40, 76),  border2 = Color3.fromRGB(75, 58, 108),
		text = Color3.fromRGB(233, 226, 248), muted = Color3.fromRGB(166, 154, 192),
		faint = Color3.fromRGB(120, 110, 146), accent = Color3.fromRGB(167, 124, 255),
		accentInk = Color3.fromRGB(18, 10, 34), danger = Color3.fromRGB(240, 100, 140),
		hover = Color3.fromRGB(45, 35, 66),   scrollIdle = Color3.fromRGB(75, 58, 108),
	},
}
Aura.Themes = Themes

local Theme = {}
for role, colour in pairs(Themes.Dark) do Theme[role] = colour end
Aura.Theme = Theme

--=============================================================================
-- CONFIGURATION
--=============================================================================

local Config = {
	Storage = {
		Enabled  = true,   -- false disables all disk writes, whatever controls ask for
		Folder   = "aura", -- folder under the executor's workspace
		File     = "settings",
		Debounce = 0.4,    -- seconds; a dragged slider must not write per frame
		Unique   = false,  -- claim the folder, suffixing _2, _3 if another owner has it
		Owner    = nil,    -- identity for that claim; defaults to the folder name
	},
	Themes = {
		Custom  = nil,
		Only    = nil,
		Hide    = nil,
		Default = "Dark",
	},
	--[[
		RespectReducedMotion defaults to FALSE, deliberately.

		Roblox reports ReducedMotionEnabled from an accessibility setting most
		players never knowingly touched, and honouring it by default meant this
		library silently deleted the one thing it is known for -- the dissolve --
		with no message and no visible cause. A user whose client happens to have
		the flag set experiences a broken install, not an accommodation.

		The option is kept, because honouring it IS correct for anyone who chose
		it on purpose. It just has to be the caller's decision, not a default that
		removes the feature behind their back.

		The budgets are the measured ones: 460 tiles keeps 36px cells on a normal
		window, 3 samples is what makes a control read as itself in the mosaic
		rather than a smear, and 52 particles is what the burn front needs to look
		like sparks rather than dots.
	]]
	Effects = {
		Enabled              = true,
		RespectReducedMotion = false,
		Quality              = "Balanced",
		MaxTiles             = 460,
		Samples              = 3,
		Particles            = 52,
		ToastParticles       = 14,
		MaxToasts            = 5,
	},

	Window = {
		Size       = Vector2.new(700, 452),
		MinSize    = Vector2.new(560, 300),
		MaxSize    = nil,  -- nil = clamp to the viewport
		Position   = nil,  -- nil = centred on open
		Rail       = 176,  -- sidebar width
		MinRail    = 132,
		MaxRail    = 320,
		MinContent = 300,  -- the content pane never shrinks past this
		SaveLayout = false, -- remember size, position and rail per window
		SafeArea   = true,  -- keep the window inside the usable viewport
		ReplaceExisting = false, -- allow more than one Aura window by default
	},
}

Aura.Config = Config

-- Assigned by the persistence section below. Configure is only callable after
-- the complete chunk has loaded, so keeping this private avoids exposing more
-- store lifecycle machinery on Aura.
local resetPersistence, flushPersistence

local function mergeInto(target, source)
	for key, value in pairs(source) do
		if type(value) == "table" and type(target[key]) == "table"
			and value[1] == nil and next(value) ~= nil then -- arrays/empty tables replace
			mergeInto(target[key], value)
		else
			target[key] = value
		end
	end
end

function Aura.Configure(options)
	if type(options) ~= "table" then return Config end
	-- Invalidate pending writes before changing their destination. Otherwise an
	-- old cache can be flushed into a newly configured folder or file.
	local storageChanged = type(options.Storage) == "table"
	local themeOptions = type(options.Themes) == "table" and options.Themes or nil
	if storageChanged then
		if flushPersistence then flushPersistence() end
		resetPersistence()
	end
	for key, value in pairs(options) do
		local current = Config[key]
		if type(current) == "table" then
			if type(value) == "table" then mergeInto(current, value) end
		else
			Config[key] = value
		end
	end
	if storageChanged and Aura.LoadThemes then Aura.LoadThemes() end
	if themeOptions and type(themeOptions.Custom) == "table" and Aura.RegisterTheme then
		local changed = false
		for name, palette in pairs(themeOptions.Custom) do
			if Aura.RegisterTheme(name, palette, true) then changed = true end
		end
		if changed and Aura._announceThemes then Aura._announceThemes() end
	end
	if themeOptions and themeOptions.Default ~= nil
		and Config.Themes.Default and Themes[Config.Themes.Default] then
		Aura.SetTheme(Config.Themes.Default)
	end
	return Config
end

function Aura.ThemeNames()
	local names = {}
	if type(Config.Themes.Only) == "table" then
		for _, name in ipairs(Config.Themes.Only) do
			if Themes[name] then table.insert(names, name) end
		end
	else
		for name in pairs(Themes) do table.insert(names, name) end
		table.sort(names)
	end
	if type(Config.Themes.Hide) == "table" then
		local hidden = {}
		for _, name in ipairs(Config.Themes.Hide) do hidden[name] = true end
		local kept = {}
		for _, name in ipairs(names) do
			if not hidden[name] then table.insert(kept, name) end
		end
		names = kept
	end
	return names
end

--=============================================================================
-- PERSISTENCE
--=============================================================================

local HttpService = service("HttpService")

local Store = {}

local function canStore()
	return type(writefile) == "function" and type(readfile) == "function"
		and type(isfile) == "function"
end

local resolvedDir

local function claimFolder(base, owner, allowCreate)
	if type(isfolder) ~= "function" then return nil end
	local marker = "/.owner"
	local available
	for attempt = 1, 50 do
		local candidate = attempt == 1 and base or (base .. "_" .. attempt)
		if not isfolder(candidate) then
			available = available or candidate
		else
			local existing
			if type(isfile) == "function" and type(readfile) == "function"
				and isfile(candidate .. marker) then
				local ok, contents = pcall(readfile, candidate .. marker)
				existing = ok and contents or nil
			end
			if existing == owner then return candidate end
		end
	end
	if allowCreate and available and type(makefolder) == "function"
		and type(writefile) == "function" then
		-- Recheck after the scan so a concurrent claimant cannot be overwritten.
		if isfolder(available) then return nil end
		makefolder(available)
		if pcall(writefile, available .. marker, owner) then return available end
	end
	return nil -- Never fall back to a directory which belongs to another owner.
end

local function storeDir(allowCreate)
	if resolvedDir then return resolvedDir end
	local storage = (Aura.Config and Aura.Config.Storage) or {}
	local base = type(storage.Folder) == "string" and storage.Folder ~= ""
		and storage.Folder or "aura"
	if not storage.Unique then return base end
	resolvedDir = claimFolder(base, tostring(storage.Owner or base), allowCreate == true)
	return resolvedDir
end

local function pathFor(name, allowCreate)
	local dir = storeDir(allowCreate)
	if not dir then return nil end
	return dir .. "/" .. tostring(name):gsub("[^%w_-]", "_") .. ".json"
end

function Store.set(name, data)
	if not Config.Storage.Enabled or not canStore() then return false end
	local ok = pcall(function()
		local dir = storeDir(true)
		if not dir then error("could not claim a unique storage folder") end
		if type(isfolder) == "function" and type(makefolder) == "function"
			and not isfolder(dir) then
			makefolder(dir)
		end
		local path = pathFor(name, true)
		if not path then error("storage path is unavailable") end
		writefile(path, HttpService:JSONEncode(data))
	end)
	return ok
end

function Store.get(name)
	if not canStore() then return nil end
	local ok, result = pcall(function()
		local path = pathFor(name, false)
		if not path then return nil end
		if not isfile(path) then return nil end
		return HttpService:JSONDecode(readfile(path))
	end)
	return ok and result or nil
end

function Store.clear(name)
	if not Config.Storage.Enabled
		or type(delfile) ~= "function" or type(isfile) ~= "function" then return false end
	return (pcall(function()
		local path = pathFor(name, false)
		if not path then return end -- no owned directory means there is nothing to delete
		if isfile(path) then delfile(path) end
	end))
end

function Store.available() return canStore() end

Aura.Store = Store

--=============================================================================
-- PER-CONTROL PERSISTENCE
--=============================================================================

local Persist = {}
local cache, cacheLoaded = {}, false
local dirty, flushQueued = false, false
local flushGeneration = 0

resetPersistence = function()
	flushGeneration += 1
	resolvedDir = nil
	cache, cacheLoaded = {}, false
	dirty, flushQueued = false, false
end

-- Kept for compatibility with callers which used the old internal hook.
function Aura._resetStoreDir()
	resetPersistence()
end

local function loadCache()
	if cacheLoaded then return cache end
	cacheLoaded = true
	local loaded = Store.get(Config.Storage.File)
	cache = type(loaded) == "table" and loaded or {}
	return cache
end

local function queueFlush()
	dirty = true
	if flushQueued or not Config.Storage.Enabled then return end
	flushQueued = true
	local generation = flushGeneration
	local destination = {
		File = Config.Storage.File,
		Folder = Config.Storage.Folder,
		Unique = Config.Storage.Unique,
		Owner = Config.Storage.Owner,
	}
	local queuedCache = cache
	local delay = math.max(0, tonumber(Config.Storage.Debounce) or 0.4)
	task.delay(delay, function()
		if generation ~= flushGeneration then return end
		local storage = Config.Storage
		if type(storage) ~= "table" or storage.File ~= destination.File
			or storage.Folder ~= destination.Folder or storage.Unique ~= destination.Unique
			or storage.Owner ~= destination.Owner then
			resetPersistence()
			return
		end
		flushQueued = false
		if not dirty or not Config.Storage.Enabled then return end
		if Store.set(destination.File, queuedCache) then dirty = false end
	end)
end

-- nil when the control did not ask to be saved
function Persist.key(opts, section, kind)
	if not opts or opts.Save == nil or opts.Save == false then return nil end
	if type(opts.Save) == "string" then return opts.Save end
	local where = tostring(section and section.Name or "window")
	local controlKind = tostring(kind or "value")
	local label = tostring(opts.Text or "value")
	return where .. "/" .. controlKind .. "/" .. label
end

function Persist.get(key, fallback)
	if key == nil then return fallback end
	local value = loadCache()[key]
	if value == nil then return fallback end
	return value
end

function Persist.set(key, value)
	if key == nil or not Config.Storage.Enabled then return end
	loadCache()[key] = value
	queueFlush()
end

function Persist.flush()
	if not Config.Storage.Enabled then return false end
	local ok = Store.set(Config.Storage.File, loadCache())
	if ok then dirty = false end
	return ok
end

flushPersistence = function()
	if not dirty then return true end
	return Persist.flush()
end

function Persist.forget()
	flushGeneration += 1
	flushQueued = false
	cache, cacheLoaded, dirty = {}, true, false
	return Store.clear(Config.Storage.File)
end

Aura.Persist = Persist

-- The entire rhythm of the UI comes from these numbers.
local Metrics = {
	pad      = 14,  -- padding inside panels
	gap      = 8,   -- vertical gap between cards
	row      = 20,  -- height of a single-line control line (before card padding)
	radius   = 8,   -- card corner radius
	winRadius = 12, -- window corner radius
	rail     = 176, -- default sidebar width
	topbar   = 46,
	control  = 26,  -- standard height of an interactive control
	ctlRadius = 6,  -- corner radius shared by every interactive control
	labelMin = 72,  -- a label column never shrinks below this

	controlCol = 104,
}

local Motion = {
	fast  = TweenInfo.new(0.14, Enum.EasingStyle.Quad,  Enum.EasingDirection.Out),
	base  = TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
	open  = TweenInfo.new(0.34, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
	shut  = TweenInfo.new(0.24, Enum.EasingStyle.Quart, Enum.EasingDirection.In),
}

local Fx = {
	tile       = 36,
	particles  = 52,
	burn       = 0.68,  -- share of the run spent sweeping corner to corner
	ember      = Color3.fromRGB(255, 132, 34),
	emberHot   = Color3.fromRGB(255, 248, 226),
	flashIn    = 0.03,
	flashOut   = 0.17,
	outTime    = 0.55,
	inTime     = 0.60,
}

local FONT      = Enum.Font.GothamMedium
local FONT_BOLD = Enum.Font.GothamBold

--=============================================================================
-- 2. UTIL
--=============================================================================

local Util = {}

function Util.create(class, props, children)
	local inst = Instance.new(class)
	for key, value in pairs(props or {}) do
		if key ~= "Parent" then inst[key] = value end
	end
	for _, child in ipairs(children or {}) do child.Parent = inst end
	if props and props.Parent then inst.Parent = props.Parent end
	return inst
end

local create = Util.create

function Util.corner(radius)
	return create("UICorner", { CornerRadius = UDim.new(0, radius or Metrics.radius) })
end

function Util.brighten(colour, amount)
	local h, sat, v = colour:ToHSV()
	return Color3.fromHSV(h, sat, math.clamp(v + (1 - v) * amount, 0, 1))
end

local STYLES = {
	outline = { fill = "bg",   fillFade = 0,    ink = "tone", edge = "border", edgeFade = 0 },
	filled  = { fill = "tone", fillFade = 0,    ink = "ink",  edge = "tone",   edgeFade = 0 },
	ghost   = { fill = "bg",   fillFade = 1,    ink = "tone", edge = "border", edgeFade = 1 },
	soft    = { fill = "tone", fillFade = 0.85, ink = "tone", edge = "tone",   edgeFade = 0.7 },
}

function Util.style(name, tone)
	local spec = STYLES[name] or STYLES.outline
	local function pick(key)
		if key == "tone" then return tone end
		if key == "ink" then return Theme.accentInk end
		return Theme[key]
	end
	return {
		fill = pick(spec.fill), fillFade = spec.fillFade,
		ink = pick(spec.ink),
		edge = pick(spec.edge), edgeFade = spec.edgeFade,
		name = STYLES[name] and name or "outline",
	}
end

function Util.pill()
	return Util.corner(999)
end

function Util.stroke(colour, thickness, transparency)
	return create("UIStroke", {
		Color = colour or Theme.border,
		Thickness = thickness or 1,
		Transparency = transparency or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		LineJoinMode = Enum.LineJoinMode.Round,
	})
end

function Util.padding(all, left, right, top, bottom)
	return create("UIPadding", {
		PaddingLeft   = UDim.new(0, left   or all),
		PaddingRight  = UDim.new(0, right  or all),
		PaddingTop    = UDim.new(0, top    or all),
		PaddingBottom = UDim.new(0, bottom or all),
	})
end

function Util.list(gap, direction, extra)
	local props = {
		Padding = UDim.new(0, gap or Metrics.gap),
		FillDirection = direction or Enum.FillDirection.Vertical,
		SortOrder = Enum.SortOrder.LayoutOrder,
	}
	for key, value in pairs(extra or {}) do props[key] = value end
	return create("UIListLayout", props)
end

function Util.hlist(gap)
	return Util.list(gap, Enum.FillDirection.Horizontal, {
		VerticalAlignment = Enum.VerticalAlignment.Center,
	})
end

local activeTweens = setmetatable({}, { __mode = "k" })
local activeTweenRoles = setmetatable({}, { __mode = "k" })

local function colourRole(value)
	if typeof(value) ~= "Color3" then return nil end
	for role, colour in pairs(Theme) do
		if value == colour then return role end
	end
	return nil
end

local function cancelOverlappingTweens(inst, propertyNames)
	local tracked = activeTweens[inst]
	if not tracked then return end
	local cancelled = {}
	for _, property in ipairs(propertyNames) do
		local previous = tracked[property]
		if previous and not cancelled[previous] then
			cancelled[previous] = true
			previous:Cancel()
		end
	end
end

function Util.tween(inst, props, info)
	local propertyNames = {}
	for property in pairs(props) do table.insert(propertyNames, property) end
	cancelOverlappingTweens(inst, propertyNames)

	local effects = type(Config.Effects) == "table" and Config.Effects or {}
	local reduceMotion = effects and effects.RespectReducedMotion ~= false
		and GuiService.ReducedMotionEnabled
	if effects and (effects.Enabled == false or reduceMotion) then
		for property, value in pairs(props) do inst[property] = value end
		return nil
	end

	local animation = TweenService:Create(inst, info or Motion.fast, props)
	local tracked = activeTweens[inst] or {}
	local trackedRoles = activeTweenRoles[inst] or {}
	activeTweens[inst] = tracked
	activeTweenRoles[inst] = trackedRoles
	for _, property in ipairs(propertyNames) do
		tracked[property] = animation
		trackedRoles[property] = colourRole(props[property])
	end

	local completed
	completed = animation.Completed:Connect(function()
		if completed then completed:Disconnect() end
		local current = activeTweens[inst]
		if not current then return end
		local currentRoles = activeTweenRoles[inst]
		for _, property in ipairs(propertyNames) do
			if current[property] == animation then
				current[property] = nil
				if currentRoles then currentRoles[property] = nil end
			end
		end
		if next(current) == nil then
			activeTweens[inst] = nil
			activeTweenRoles[inst] = nil
		end
	end)
	animation:Play()
	return animation
end

local tween = Util.tween

function Util.label(text, size, colour, font, richText)
	if type(text) ~= "string" then
		text = type(text) == "table" and (tostring(text.Text or "")) or tostring(text or "")
	end
	return create("TextLabel", {
		BackgroundTransparency = 1,
		Text = text or "",
		TextSize = size or 14,
		TextColor3 = colour or Theme.text,
		Font = font or FONT,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		RichText = richText == true,
	})
end

function Util.drag(handle, callbacks)
	callbacks = callbacks or {}
	local onMove  = callbacks.onMove
	local onStart = callbacks.onStart
	local onEnd   = callbacks.onEnd
	local activeInput, moveConn, endConn
	local dragging, disposed = false, false

	local function stop(notify)
		local wasDragging = dragging
		dragging, activeInput = false, nil
		if moveConn then
			moveConn:Disconnect()
			moveConn = nil
		end
		if endConn then
			endConn:Disconnect()
			endConn = nil
		end
		if notify and wasDragging and onEnd then onEnd() end
	end

	local beginConn
	beginConn = handle.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1
			and input.UserInputType ~= Enum.UserInputType.Touch then return end
		if disposed or dragging then return end

		if onStart and onStart(input) == false then return end
		activeInput, dragging = input, true
		local touch = input.UserInputType == Enum.UserInputType.Touch

		moveConn = UserInputService.InputChanged:Connect(function(moved)
			local belongsToDrag = touch and moved == activeInput
				or not touch and moved.UserInputType == Enum.UserInputType.MouseMovement
			if belongsToDrag and onMove then onMove(moved.Position) end
		end)
		endConn = UserInputService.InputEnded:Connect(function(ended)
			local belongsToDrag = touch and ended == activeInput
				or not touch and ended.UserInputType == Enum.UserInputType.MouseButton1
			if belongsToDrag then stop(true) end
		end)
	end)

	local destroyConn
	destroyConn = handle.Destroying:Connect(function()
		disposed = true
		stop(false)
		if beginConn then beginConn:Disconnect() end
		if destroyConn then destroyConn:Disconnect() end
	end)

	local cleanup = {}
	function cleanup:Disconnect()
		if disposed then return end
		disposed = true
		stop(true)
		if beginConn then beginConn:Disconnect() end
		if destroyConn then destroyConn:Disconnect() end
	end
	cleanup.Cancel = cleanup.Disconnect
	return cleanup
end

-- Hover tinting, used by every interactive surface so the feel is consistent.

function Util.hover(inst, enter, leave, region)
	local connections = {}
	local mouseInside, selected, active, disposed = false, false, false, false

	local function invoke(callback)
		if not callback then return end
		local ok, err = pcall(callback)
		if not ok then warn("[Aura] hover handler: " .. tostring(err)) end
	end

	local function update()
		local nextActive = mouseInside or selected
		if nextActive == active then return end
		active = nextActive
		invoke(active and enter or leave)
	end

	local function setMouseInside(inside)
		mouseInside = inside
		update()
	end

	local function inCustomRegion(x, y)
		local ok, position, size = pcall(region, inst)
		if not ok then
			warn("[Aura] hover region: " .. tostring(position))
			return false
		end
		return typeof(position) == "Vector2" and typeof(size) == "Vector2"
			and x >= position.X and x <= position.X + size.X
			and y >= position.Y and y <= position.Y + size.Y
	end

	local function connect(signal, callback)
		table.insert(connections, signal:Connect(callback))
	end

	if region then
		local function updateRegion(x, y) setMouseInside(inCustomRegion(x, y)) end
		connect(inst.MouseEnter, updateRegion)
		connect(inst.MouseMoved, updateRegion)
		connect(inst.MouseLeave, function() setMouseInside(false) end)
	else
		connect(inst.MouseEnter, function() setMouseInside(true) end)
		connect(inst.MouseLeave, function() setMouseInside(false) end)
	end
	connect(inst.SelectionGained, function()
		selected = true
		update()
	end)
	connect(inst.SelectionLost, function()
		selected = false
		update()
	end)

	local cleanup = {}
	function cleanup:Disconnect()
		if disposed then return end
		disposed = true
		for _, connection in ipairs(connections) do connection:Disconnect() end
		table.clear(connections)
		mouseInside, selected, active = false, false, false
	end
	return cleanup
end

local function roleColour(value, fallback)
	if type(value) == "string" then return Theme[value] or Theme[fallback] end
	if typeof(value) == "Color3" then return value end
	return Theme[fallback]
end

function Util.surface(button, tone, glyph, glyphRest, hoverFill)
	local edge = button:FindFirstChildOfClass("UIStroke") or Util.stroke(Theme.border)
	edge.Parent = button
	Util.hover(button,
		function()
			local lit = roleColour(tone, "accent")
			tween(button, { BackgroundColor3 = roleColour(hoverFill, "hover") })
			tween(edge, { Color = lit })
			if glyph then tween(glyph, { ImageColor3 = lit }) end
		end,
		function()
			tween(button, { BackgroundColor3 = Theme.bg })
			tween(edge, { Color = Theme.border })
			if glyph then
				tween(glyph, { ImageColor3 = roleColour(glyphRest or tone, "accent") })
			end
		end)
	return edge
end


--=============================================================================
-- 3. ICONS
--=============================================================================

local ICON_CELL = Vector2.new(48, 48)
local Icons = {
	["activity"] = { 16898612629, 514, 771 },
	["bell"] = { 16898612819, 820, 257 },
	["bot"] = { 16898612819, 869, 98 },
	["box"] = { 16898612819, 771, 196 },
	["brush"] = { 16898612819, 404, 820 },
	["bug"] = { 16898612819, 257, 967 },
	["check"] = { 16898612819, 710, 869 },
	["chevron-down"] = { 16898612819, 196, 918 },
	["chevron-right"] = { 16898612819, 869, 759 },
	["chevron-up"] = { 16898612819, 710, 918 },
	["circle-help"] = { 16898613044, 820, 257 },
	["clock"] = { 16898613044, 771, 661 },
	["code"] = { 16898613044, 355, 869 },
	["compass"] = { 16898613044, 514, 967 },
	["cpu"] = { 16898613044, 196, 869 },
	["crosshair"] = { 16898613044, 453, 869 },
	["database"] = { 16898613044, 710, 869 },
	["download"] = { 16898613044, 820, 906 },
	["droplet"] = { 16898613044, 820, 955 },
	["droplets"] = { 16898613044, 967, 857 },
	["eye"] = { 16898613353, 771, 563 },
	["eye-off"] = { 16898613353, 820, 514 },
	["file"] = { 16898613353, 820, 661 },
	["flame"] = { 16898613353, 967, 306 },
	["folder"] = { 16898613353, 404, 967 },
	["folder-open"] = { 16898613353, 820, 759 },
	["gauge"] = { 16898613353, 771, 955 },
	["hammer"] = { 16898613509, 306, 820 },
	["expand"] = { 16898613353, 306, 771 },
	["grip"] = { 16898613509, 869, 257 },
	["home"] = { 16898613509, 820, 147 },
	["maximize-2"] = { 16898613613, 820, 514 },
	["move-diagonal"] = { 16898613613, 918, 98 },
	["move-diagonal-2"] = { 16898613613, 967, 49 },
	["scaling"] = { 16898613699, 967, 661 },
	["info"] = { 16898613509, 612, 869 },
	["keyboard"] = { 16898613509, 453, 820 },
	["layers"] = { 16898613509, 98, 967 },
	["list"] = { 16898613509, 869, 808 },
	["lock"] = { 16898613509, 918, 857 },
	["map"] = { 16898613613, 306, 771 },
	["minus"] = { 16898613613, 771, 196 },
	["package"] = { 16898613613, 918, 196 },
	["pause"] = { 16898613699, 0, 771 },
	["pencil"] = { 16898613699, 820, 257 },
	["play"] = { 16898613699, 918, 257 },
	["plus"] = { 16898613699, 257, 918 },
	["power"] = { 16898613699, 820, 147 },
	["refresh-cw"] = { 16898613699, 404, 869 },
	["rotate-cw"] = { 16898613699, 869, 453 },
	["save"] = { 16898613699, 918, 453 },
	["search"] = { 16898613699, 918, 857 },
	["settings"] = { 16898613777, 771, 257 },
	["shield"] = { 16898613777, 869, 0 },
	["sliders-horizontal"] = { 16898613777, 820, 355 },
	["sparkles"] = { 16898613777, 918, 49 },
	["spray-can"] = { 16898613777, 967, 257 },
	["square"] = { 16898613777, 869, 710 },
	["star"] = { 16898613777, 967, 147 },
	["target"] = { 16898613869, 514, 771 },
	["terminal"] = { 16898613869, 820, 257 },
	["trash-2"] = { 16898613869, 257, 918 },
	["triangle-alert"] = { 16898613869, 967, 0 },
	["unlock"] = { 16898613869, 771, 710 },
	["upload"] = { 16898613869, 612, 869 },
	["user"] = { 16898613869, 661, 869 },
	["users"] = { 16898613869, 967, 98 },
	["wand-sparkles"] = { 16898613869, 453, 918 },
	["wrench"] = { 16898613869, 820, 906 },
	["x"] = { 16898613869, 869, 906 },
	["zap"] = { 16898613869, 918, 906 },
}

local function finiteNumber(value)
	return type(value) == "number" and value == value
		and value > -math.huge and value < math.huge
end

local function normaliseCell(cell)
	if cell == nil then return nil end
	if finiteNumber(cell) and cell >= 0 then return Vector2.new(cell, cell) end
	if typeof(cell) == "Vector2" and finiteNumber(cell.X) and finiteNumber(cell.Y)
		and cell.X >= 0 and cell.Y >= 0 then return cell end
	return nil
end

local function normaliseSprite(sprite)
	if type(sprite) ~= "table" then return nil, "descriptor must be a table" end
	local assetId = sprite[1]
	if finiteNumber(assetId) then
		if assetId < 0 or assetId % 1 ~= 0 then return nil, "asset id must be a non-negative integer" end
	elseif type(assetId) ~= "string" or assetId == "" then
		return nil, "asset id must be a number or content string"
	end

	local rectX, rectY = sprite[2] or 0, sprite[3] or 0
	if not finiteNumber(rectX) or not finiteNumber(rectY) or rectX < 0 or rectY < 0 then
		return nil, "sprite offsets must be non-negative finite numbers"
	end
	local cell = normaliseCell(sprite[4])
	if sprite[4] ~= nil and not cell then
		return nil, "cell must be a non-negative number or Vector2"
	end
	return { assetId, rectX, rectY, cell }
end

-- Own every descriptor in the registry so callers cannot mutate it behind the
-- resolver. This also validates the embedded atlas at load time.
for name, sprite in pairs(Icons) do
	local normalised = normaliseSprite(sprite)
	assert(normalised, "invalid embedded icon: " .. name)
	Icons[name] = normalised
end

function Aura.RegisterIcon(name, assetId, rectX, rectY, cell)
	if type(name) ~= "string" or name == "" then return false, "name must be a non-empty string" end
	local sprite, reason = normaliseSprite({ assetId, rectX or 0, rectY or 0, cell })
	if not sprite then return false, reason end
	Icons[name] = sprite
	return name
end

function Aura.RegisterIcons(set)
	if set == nil then return true end
	if type(set) ~= "table" then return false, "icon set must be a table" end
	local staged = {}
	for name, source in pairs(set) do
		if type(name) ~= "string" or name == "" then
			return false, "every icon name must be a non-empty string"
		end
		local sprite, reason = normaliseSprite(source)
		if not sprite then return false, name .. ": " .. reason end
		staged[name] = sprite
	end
	for name, sprite in pairs(staged) do Icons[name] = sprite end
	return true
end

local function resolveIcon(source)
	if not source then return nil end

	local assetId, offset, cell, spriteSheet
	if type(source) == "table" then
		local sprite = normaliseSprite(source)
		if not sprite then return nil end
		assetId, offset, cell = sprite[1], Vector2.new(sprite[2], sprite[3]), sprite[4]
		spriteSheet = true
	elseif type(source) == "number" then
		if not finiteNumber(source) or source < 0 or source % 1 ~= 0 then return nil end
		assetId = source
	elseif type(source) == "string" then
		if source:match("^rbxassetid://%d+$") or source:match("^rbxthumb://") then
			assetId = source
		elseif source:match("^%d+$") then
			assetId = tonumber(source)
			if not finiteNumber(assetId) then return nil end
		else
			local sprite = Icons[source]
			if not sprite then return nil end
			assetId, offset, cell = sprite[1], Vector2.new(sprite[2], sprite[3]), sprite[4]
			spriteSheet = true
		end
	else
		return nil
	end

	return {
		Image = type(assetId) == "string" and assetId or ("rbxassetid://" .. tostring(assetId)),
		ImageRectOffset = offset or Vector2.zero,
		ImageRectSize = spriteSheet and (cell or ICON_CELL) or Vector2.zero,
	}
end

function Util.setIcon(label, source)
	local resolved = resolveIcon(source)
	if typeof(label) ~= "Instance" or not resolved
		or (not label:IsA("ImageLabel") and not label:IsA("ImageButton")) then return false end
	return pcall(function()
		label.Image = resolved.Image
		label.ImageRectOffset = resolved.ImageRectOffset
		label.ImageRectSize = resolved.ImageRectSize
	end)
end

function Util.icon(source, size, colour)
	local resolved = resolveIcon(source)
	if not resolved then return nil end
	local dimension = finiteNumber(size) and math.max(0, size) or 16
	local tint = typeof(colour) == "Color3" and colour or Theme.muted
	return create("ImageLabel", {
		BackgroundTransparency = 1,
		Image = resolved.Image,
		ImageRectOffset = resolved.ImageRectOffset,
		ImageRectSize = resolved.ImageRectSize,
		ImageColor3 = tint,
		ScaleType = Enum.ScaleType.Fit,
		Size = UDim2.fromOffset(dimension, dimension),
	})
end

local SPIN = TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

local function scaledSize(size, factor)
	return UDim2.new(
		size.X.Scale * factor, math.floor(size.X.Offset * factor + 0.5),
		size.Y.Scale * factor, math.floor(size.Y.Offset * factor + 0.5))
end

function Util.rotatable(glyph)
	local parent = glyph and glyph.Parent
	if not parent or not parent:FindFirstChildOfClass("UIListLayout") then return glyph end
	local wrapper = create("Frame", {
		Name = "__spin", Parent = parent,
		BackgroundTransparency = 1,
		Size = glyph.Size,
		LayoutOrder = glyph.LayoutOrder,
	})
	glyph.AnchorPoint = Vector2.new(0.5, 0.5)
	glyph.Position = UDim2.fromScale(0.5, 0.5)
	glyph.Parent = wrapper
	return glyph
end

function Util.interact(button, spec)
	spec = type(spec) == "table" and spec or {}
	local hover = type(spec.Hover) == "table" and spec.Hover or nil
	local click = type(spec.Click) == "table" and spec.Click or nil
	if not hover and not click then return end

	local glyph, caption = spec.Glyph, spec.Caption
	if glyph and ((hover and hover.Rotate) or (click and click.Rotate)) then
		glyph = Util.rotatable(glyph)
	end
	local baseIcon = glyph and {
		Image = glyph.Image,
		ImageRectOffset = glyph.ImageRectOffset,
		ImageRectSize = glyph.ImageRectSize,
	} or nil
	local baseText = caption and caption.Text or nil
	local baseRotation = glyph and glyph.Rotation or 0
	local baseSize = glyph and glyph.Size or nil
	local generation = 0 -- a fast second click cannot let an old completion restore early
	local hovered, clickVisual, rotationBusy = false, false, false

	local function restoreIcon()
		if not glyph or not baseIcon then return end
		glyph.Image = baseIcon.Image
		glyph.ImageRectOffset = baseIcon.ImageRectOffset
		glyph.ImageRectSize = baseIcon.ImageRectSize
	end

	local function render()
		local state = clickVisual and click or (hovered and hover or nil)
		if glyph then
			if state and state.Icon ~= nil then
				if not Util.setIcon(glyph, state.Icon) then restoreIcon() end
			else
				restoreIcon()
			end

			local hoverScale = hovered and hover and hover.Scale
			if baseSize then
				local factor = finiteNumber(hoverScale) and math.clamp(hoverScale, 0, 10) or 1
				tween(glyph, { Size = scaledSize(baseSize, factor) })
			end
			if not rotationBusy then
				local hoverRotation = hovered and hover and hover.Rotate
				local target = baseRotation
				if finiteNumber(hoverRotation) then target += hoverRotation end
				tween(glyph, { Rotation = target }, spec.Info or Motion.base)
			end
		end
		if caption then
			caption.Text = state and state.Text ~= nil and tostring(state.Text) or baseText
		end
	end

	if hover then
		Util.hover(button,
			function()
				hovered = true
				render()
			end,
			function()
				hovered = false
				render()
			end)
	end

	if click then
		button.Activated:Connect(function()
			generation += 1
			local currentGeneration = generation
			if click.Icon ~= nil or click.Text ~= nil then
				clickVisual = true
				render()
				local hold = finiteNumber(tonumber(click.Hold))
					and math.max(0, tonumber(click.Hold)) or 0.9
				task.delay(hold, function()
					if generation ~= currentGeneration then return end
					clickVisual = false
					render() -- restore the hover state when the pointer is still inside
				end)
			end

			if glyph and finiteNumber(click.Rotate) then
				rotationBusy = true
				local fullTurn = click.Rotate % 360 == 0
				local forward = tween(glyph,
					{ Rotation = baseRotation + click.Rotate }, spec.ClickInfo or SPIN)

				local function settle()
					if generation ~= currentGeneration then return end
					if fullTurn then
						glyph.Rotation = baseRotation
						rotationBusy = false
						return
					end
					local backward = tween(glyph, { Rotation = baseRotation }, Motion.base)
					if not backward then
						rotationBusy = false
						return
					end
					backward.Completed:Connect(function()
						if generation == currentGeneration then rotationBusy = false end
					end)
				end

				if forward then
					forward.Completed:Connect(function(state)
						if generation ~= currentGeneration then return end
						if state == Enum.PlaybackState.Completed then settle()
						else rotationBusy = false end
					end)
				else
					settle()
				end
			end
		end)
	end
end

-- Every icon name currently registered.
function Aura.Icons()
	local names = {}
	for name in pairs(Icons) do table.insert(names, name) end
	table.sort(names)
	return names
end

function Aura.HasIcon(name) return Icons[name] ~= nil end


--=============================================================================
-- 4. PANEL
--=============================================================================

local Panel = {}

function Panel.round(frame, radius, sides, colour)
	if typeof(frame) ~= "Instance" or not frame:IsA("GuiObject") then return false end
	local validRadius = type(radius) == "number" and radius == radius
		and radius > -math.huge and radius < math.huge
	local resolvedRadius = validRadius and math.max(0, radius) or Metrics.radius
	Util.corner(resolvedRadius).Parent = frame
	local fill = colour or frame.BackgroundColor3
	local seen = {}
	for _, side in ipairs(type(sides) == "table" and sides or {}) do
		local props = {
			Name = "__patch",
			Parent = frame,
			BackgroundColor3 = fill,
			BorderSizePixel = 0,
			ZIndex = frame.ZIndex,
		}
		if side == "top" then
			props.Position = UDim2.new(0, 0, 0, 0)
			props.Size = UDim2.new(1, 0, 0, resolvedRadius)
		elseif side == "bottom" then
			props.Position = UDim2.new(0, 0, 1, -resolvedRadius)
			props.Size = UDim2.new(1, 0, 0, resolvedRadius)
		elseif side == "left" then
			props.Position = UDim2.new(0, 0, 0, 0)
			props.Size = UDim2.new(0, resolvedRadius, 1, 0)
		elseif side == "right" then
			props.Position = UDim2.new(1, -resolvedRadius, 0, 0)
			props.Size = UDim2.new(0, resolvedRadius, 1, 0)
		end
		if props.Size and not seen[side] then
			seen[side] = true
			create("Frame", props)
		end
	end
	return true
end

--=============================================================================
-- 5. CARD
--=============================================================================

local Card = {}

function Card.new(parent, opts)
	opts = type(opts) == "table" and opts or {}
	local hasDescription = opts.Description ~= nil and opts.Description ~= ""

	local card = create("Frame", {
		Parent = parent,
		BackgroundColor3 = Theme.panel2,
		BackgroundTransparency = opts.Flat and 1 or 0,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = finiteNumber(opts.LayoutOrder) and opts.LayoutOrder or 0,
		ClipsDescendants = true,
	}, { Util.corner(Metrics.radius), Util.padding(0, 12, 10, 7, 7), Util.list(0) })
	if not opts.Flat then Util.stroke(Theme.border).Parent = card end

	local line = create("Frame", {
		Parent = card,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, Metrics.row),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = 1,
	}, { Util.hlist(12) })

	local iconLabel
	if opts.Icon then
		iconLabel = Util.icon(opts.Icon, opts.IconSize or 16, opts.IconColor or Theme.muted)
		if iconLabel then
			iconLabel.LayoutOrder = 0
			iconLabel.Parent = line
		end
	end

	local labels = create("Frame", {
		Parent = line,
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = 1,
	}, {
		Util.list(2),
		-- Fill = take whatever width the control slot did not.
		create("UIFlexItem", { FlexMode = Enum.UIFlexMode.Fill }),
		create("UISizeConstraint", { MinSize = Vector2.new(Metrics.labelMin, 0) }),
	})

	local title = Util.label(opts.Text or "", 14, Theme.text)
	title.Size = UDim2.new(1, 0, 0, 0)
	title.AutomaticSize = Enum.AutomaticSize.Y
	title.TextWrapped = true
	title.Parent = labels

	if hasDescription then
		local description = Util.label(opts.Description, 12, Theme.faint)
		description.Size = UDim2.new(1, 0, 0, 0)
		description.AutomaticSize = Enum.AutomaticSize.Y
		description.TextWrapped = true
		description.LayoutOrder = 2
		description.Parent = labels
	end

	-- Sizes to its children on BOTH axes, so no control inside ever needs clipping.
	local slot = create("Frame", {
		Parent = line,
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.XY,
		LayoutOrder = 2,
	})


	local function fit(element, reserve, minWidth)
		local floor = finiteNumber(minWidth) and math.max(0, minWidth) or 60
		local cap = create("UISizeConstraint", {
			Parent = element, MinSize = Vector2.new(floor, 0),
		})
		local function apply()
			local inner = card.AbsoluteSize.X - 24 -- the card's own padding
			if inner <= 0 then return end
			local keep = reserve
			if type(keep) == "function" then keep = keep() end
			keep = finiteNumber(keep) and math.max(0, keep) or Metrics.labelMin
			cap.MaxSize = Vector2.new(
				math.max(floor, inner - 12 - keep), 1000000)
		end
		card:GetPropertyChangedSignal("AbsoluteSize"):Connect(apply)
		apply()
		return cap, apply
	end

	return card, slot, title, line, iconLabel, fit
end

Aura.Panel = Panel
Aura.Card = Card


--=============================================================================
-- 6. CONTROLS
--=============================================================================

local Controls = {}

local function normaliseNumber(value, fallback)
	local number = tonumber(value)
	if number == nil or number ~= number or number == math.huge or number == -math.huge then
		return fallback
	end
	return number
end

local function keyCode(value)
	if value == nil then return nil end
	if type(value) == "string" then return Enum.KeyCode[value] end
	if typeof(value) == "EnumItem" and value.EnumType == Enum.KeyCode then return value end
	return nil
end

local function coalescedCallback(owner, callback)
	local queued = false
	local active = true
	local latest
	local function emit(value)
		if not callback then return end
		latest = value
		if queued then return end
		queued = true
		task.defer(function()
			queued = false
			if active and owner.Parent then callback(latest) end
		end)
	end
	local function cancel()
		active = false
		latest = nil
	end
	return emit, cancel
end

function Controls.mount(section, opts)
	opts = type(opts) == "table" and opts or {}
	local card, slot, title, line, icon, fit = Card.new(section.Page, opts)
	section:_add(card)
	section:_index(card, tostring(opts.Text or "") .. " " .. tostring(opts.Description or ""))
	return card, slot, title, line, icon, fit
end

----------------------------------------------------------------- Title -------
-- Accepts either Title("Automation") or Title({ Text = ..., Icon = "zap" }).
Controls.Title = function(section, textOrOpts)
	local opts = type(textOrOpts) == "table" and textOrOpts or { Text = textOrOpts }
	local text = tostring(opts.Text or "")

	if not opts.Icon then
		local heading = Util.label(string.upper(text), 13, Theme.muted, FONT_BOLD)
		heading.Size = UDim2.new(1, 0, 0, 20)
		heading:SetAttribute("AuraHeading", true)
		section:_add(heading)
		section:_index(heading, text)
		return heading
	end

	local rowFrame = create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 20),
	}, { Util.hlist(7) })
	local glyph = Util.icon(opts.Icon, opts.IconSize or 13, opts.IconColor or Theme.muted)
	if glyph then
		glyph.LayoutOrder = 1
		glyph.Parent = rowFrame
	end
	local heading = Util.label(string.upper(text), 13, Theme.muted, FONT_BOLD)
	heading.Size = UDim2.new(0, 0, 1, 0)
	heading.AutomaticSize = Enum.AutomaticSize.X
	heading.LayoutOrder = 2
	heading.Parent = rowFrame

	section:_add(rowFrame)
	rowFrame:SetAttribute("AuraHeading", true)
	section:_index(rowFrame, text)
	return rowFrame
end

------------------------------------------------------------ IconButton -------

Controls.IconButton = function(section, opts)
	opts = type(opts) == "table" and opts or {}
	local entries = type(opts.Buttons) == "table" and opts.Buttons or { opts }
	local card, slot = Controls.mount(section, opts)

	local row = Util.hlist(6)
	row.HorizontalAlignment = Enum.HorizontalAlignment.Right
	row.Parent = slot
	create("UISizeConstraint", { Parent = slot, MinSize = Vector2.new(Metrics.controlCol, 0) })

	local made = {}
	for index, entry in ipairs(entries) do
		entry = type(entry) == "table" and entry or {}
		local button = create("TextButton", {
			Parent = slot,
			BackgroundColor3 = Theme.bg,
			Size = UDim2.fromOffset(Metrics.control + 4, Metrics.control + 4),
			Text = "",
			AutoButtonColor = false,
			LayoutOrder = index,
		}, { Util.corner(Metrics.ctlRadius), Util.stroke(Theme.border) })

		local tint = entry.Danger and Theme.danger or Theme.accent
		local glyph = Util.icon(entry.Icon, 15, tint)
		if glyph then
			glyph.AnchorPoint = Vector2.new(0.5, 0.5)
			glyph.Position = UDim2.fromScale(0.5, 0.5)
			glyph.Parent = button
		end

		Util.surface(button, entry.HoverColor or (entry.Danger and "danger" or "accent"),
			glyph, nil, entry.HoverFill)
		Util.interact(button, {
			Glyph = glyph, Icon = entry.Icon,
			Hover = entry.Hover, Click = entry.Click,
		})

		button.Activated:Connect(function()
			if type(entry.Callback) == "function" then task.spawn(entry.Callback) end
		end)
		made[index] = button
	end

	return { Instance = card, Buttons = made }
end

----------------------------------------------------------- Description -------

Controls.Description = function(section, textOrOpts)
	local opts = type(textOrOpts) == "table" and textOrOpts or { Text = textOrOpts }
	local text = tostring(opts.Text or "")
	local body = Util.label(text, 12.5, Theme.faint)
	body.Size = UDim2.new(1, 0, 0, 0)
	body.AutomaticSize = Enum.AutomaticSize.Y
	body.TextWrapped = true
	section:_add(body)
	section:_index(body, text)
	return body
end

------------------------------------------------------------- Separator -------
Controls.Separator = function(section)
	local holder = create("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 9) })
	holder:SetAttribute("AuraSeparator", true)
	create("Frame", {
		Parent = holder,
		BackgroundColor3 = Theme.border,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.new(1, 0, 0, 1),
	})
	section:_add(holder)
	return holder
end

---------------------------------------------------------------- Button -------
Controls.Button = function(section, opts)
	opts = type(opts) == "table" and opts or {}
	local card, slot = Controls.mount(section, opts)


	local function currentTone() return opts.Danger and Theme.danger or Theme.accent end
	local styleName = opts.Style or (opts.Primary == true and "filled") or "outline"
	local look = Util.style(styleName, currentTone())
	local filled = look.name == "filled"

	local glyph = opts.ButtonIcon and Util.icon(opts.ButtonIcon, 14, look.ink) or nil
	local padL, padR = glyph and 12 or 16, glyph and 14 or 16
	local buttonFloor = math.max(0, Metrics.controlCol - padL - padR)
	local button = create("TextButton", {
		Parent = slot,
		BackgroundColor3 = look.fill,
		BackgroundTransparency = look.fillFade,
		Size = UDim2.new(0, 0, 0, Metrics.control),
		AutomaticSize = Enum.AutomaticSize.X, -- grows with its label, never clips
		Text = glyph and "" or tostring(opts.ButtonText or "Run"),
		TextSize = 13,
		Font = FONT_BOLD,
		TextColor3 = look.ink,
		AutoButtonColor = false,
	}, { Util.corner(Metrics.ctlRadius), Util.padding(0, padL, padR, 0, 0),
		Util.stroke(look.edge, nil, look.edgeFade),
		create("UISizeConstraint", {
			MinSize = Vector2.new(buttonFloor, Metrics.control),
		}) })

	local captionLabel = button
	if glyph then
		Util.hlist(6).Parent = button
		glyph.LayoutOrder = 1

		local seat = create("Frame", {
			Name = "__seat", Parent = button, BackgroundTransparency = 1,
			LayoutOrder = 1,
			Size = UDim2.fromOffset(glyph.Size.X.Offset, glyph.Size.Y.Offset + 1),
		})
		glyph.AnchorPoint = Vector2.new(0.5, 0.5)
		glyph.Position = UDim2.new(0.5, 0, 0.5, 1)
		glyph.Parent = seat
		local caption = Util.label(opts.ButtonText or "Run", 13, look.ink, FONT_BOLD)
		caption.Size = UDim2.new(0, 0, 1, 0)
		caption.AutomaticSize = Enum.AutomaticSize.X
		caption.LayoutOrder = 2
		caption.Parent = button
		captionLabel = caption
	end

	if filled then
		Util.hover(button,
			function() tween(button, { BackgroundTransparency = 0.15 }) end,
			function() tween(button, { BackgroundTransparency = 0 }) end)
	elseif look.name == "ghost" or look.name == "soft" then
		-- No hard edge to light, so these lift their fill instead.
		local restFade = look.fillFade
		Util.hover(button,
			function()
				tween(button, { BackgroundColor3 = currentTone(), BackgroundTransparency = 0.72 })
			end,
			function()
				local current = Util.style(styleName, currentTone())
				tween(button, { BackgroundColor3 = current.fill,
					BackgroundTransparency = restFade })
			end)
	else
		-- HoverColor overrides the accent/danger tone for this button only.
		Util.surface(button, opts.HoverColor or (opts.Danger and "danger" or "accent"),
			glyph, nil, opts.HoverFill)
	end

	Util.interact(button, {
		Glyph = glyph, Caption = captionLabel, Icon = opts.ButtonIcon,
		Hover = opts.Hover, Click = opts.Click,
	})


	button.Activated:Connect(function()
		-- Fade rather than shrink for the press: a Size dip fights AutomaticSize.
		local resting = button.BackgroundTransparency
		local pressed = resting < 0.45 and math.min(1, resting + 0.4)
			or math.max(0, resting - 0.25)
		tween(button, { BackgroundTransparency = pressed }, Motion.fast)
		task.delay(0.09, function()
			tween(button, { BackgroundTransparency = resting }, Motion.fast)
		end)
		if opts.Callback then task.spawn(opts.Callback) end
	end)

	return {
		Instance = card,
		-- Caption may be a child label when ButtonIcon is set; button.Text is then "".
		SetText = function(_, text)
			local value = tostring(text == nil and "" or text)
			if captionLabel ~= button then
				captionLabel.Text = value
			else
				button.Text = value
			end
		end,
	}
end

---------------------------------------------------------------- Toggle -------
Controls.Toggle = function(section, opts)
	opts = type(opts) == "table" and opts or {}
	-- A saved value overrides Default; Default is what to use the FIRST time.
	local saveKey = Persist.key(opts, section, "Toggle")
	local state = Persist.get(saveKey, opts.Default == true) == true
	local card, slot = Controls.mount(section, opts)

	local track = create("Frame", {
		Name = "Track",
		Parent = slot,
		BackgroundColor3 = state and Theme.accent or Theme.bg,
		Size = UDim2.fromOffset(42, 23),
	}, { Util.pill() })
	local outline = Util.stroke(Theme.border2)
	outline.Parent = track

	local knob = create("Frame", {
		Name = "Knob",
		Parent = track,
		BackgroundColor3 = state and Theme.accentInk or Theme.faint,
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, state and 22 or 3, 0.5, 0),
		Size = UDim2.fromOffset(17, 17),
	}, { Util.pill() })

	local hit = create("TextButton", {
		Name = "__hit", Parent = track, BackgroundTransparency = 1, Text = "",
		Size = UDim2.fromScale(1, 1), ZIndex = 3,
	})

	local handle = { Instance = card }
	function handle:Set(value, silent)
		state = value and true or false
		Persist.set(saveKey, state)
		tween(track,   { BackgroundColor3 = state and Theme.accent or Theme.bg }, Motion.fast)
		tween(outline, { Color = state and Theme.accent or Theme.border2 }, Motion.fast)
		tween(knob, {
			Position = UDim2.new(0, state and 22 or 3, 0.5, 0),
			BackgroundColor3 = state and Theme.accentInk or Theme.faint,
		}, Motion.fast)
		if not silent and opts.Callback then task.spawn(opts.Callback, state) end
		return true
	end
	function handle:Get() return state end

	hit.Activated:Connect(function() handle:Set(not state) end)
	if state and opts.FireOnStart and opts.Callback then task.spawn(opts.Callback, true) end

	return handle
end

---------------------------------------------------------------- Slider -------
Controls.Slider = function(section, opts)
	opts = type(opts) == "table" and opts or {}
	local min = normaliseNumber(opts.Min, 0)
	local max = normaliseNumber(opts.Max, 100)
	if max < min then min, max = max, min end
	local step = math.abs(normaliseNumber(opts.Step, 1))
	local saveKey = Persist.key(opts, section, "Slider")
	local default = normaliseNumber(opts.Default, min)
	local value = math.clamp(
		normaliseNumber(Persist.get(saveKey, default), default), min, max)

	local card, slot, _, _, _, fit = Controls.mount(section, opts)

	local sliderRow = Util.hlist(10)
	sliderRow.HorizontalAlignment = Enum.HorizontalAlignment.Right
	sliderRow.Parent = slot

	local readout = Util.label("", 12, Theme.muted, FONT_BOLD)
	readout.Size = UDim2.new(0, 0, 0, Metrics.control)
	readout.AutomaticSize = Enum.AutomaticSize.X
	readout.TextXAlignment = Enum.TextXAlignment.Right
	readout.LayoutOrder = 1
	readout.Parent = slot


	local barArea = create("Frame", {
		Parent = slot, BackgroundTransparency = 1,
		Size = UDim2.fromOffset(110, Metrics.control), LayoutOrder = 2,
	})
	local bar = create("Frame", {
		Name = "Bar", Parent = barArea,
		BackgroundColor3 = Theme.panel3,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(1, -8, 0, 5),
	}, { Util.pill() })
	local fill = create("Frame", {
		Name = "Fill", Parent = bar, BackgroundColor3 = Theme.accent,
		Size = UDim2.new(0, 0, 1, 0),
	}, { Util.pill() })
	local knob = create("Frame", {
		Name = "Knob", Parent = bar, BackgroundColor3 = Theme.text,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.fromOffset(11, 11), ZIndex = 2,
	}, { Util.pill() })

	local BAR_MIN = 56
	local _, refitBar = fit(barArea, function()
		return Metrics.labelMin + readout.AbsoluteSize.X + 10 -- + the layout's gap
	end, BAR_MIN)
	readout:GetPropertyChangedSignal("AbsoluteSize"):Connect(refitBar)

	local handle = { Instance = card }
	local emitCallback, cancelCallback = coalescedCallback(card, opts.Callback)
	handle._cleanups = { cancelCallback }

	local function apply(raw, silent, animate)
		local number = normaliseNumber(raw)
		if number == nil then return false, "value must be a finite number" end
		local v = math.clamp(number, min, max)
		if step > 0 then v = math.clamp(math.floor((v - min) / step + 0.5) * step + min, min, max) end
		value = v
		Persist.set(saveKey, v)
		local alpha = (max > min) and (v - min) / (max - min) or 0
		local info = animate and Motion.fast or TweenInfo.new(0)
		tween(fill, { Size = UDim2.new(alpha, 0, 1, 0) }, info)
		tween(knob, { Position = UDim2.new(alpha, 0, 0.5, 0) }, info)
		readout.Text = ((step > 0 and step % 1 == 0) and tostring(math.floor(v)) or string.format("%.2f", v))
			.. tostring(opts.Suffix or "")
		if not silent then emitCallback(v) end
		return true
	end
	function handle:Set(v, silent) return apply(v, silent, true) end
	function handle:Get() return value end

	local hit = create("TextButton", {
		Name = "__hit", Parent = barArea, BackgroundTransparency = 1, Text = "",
		Size = UDim2.fromScale(1, 1), ZIndex = 3,
	})
	local function fromX(x)
		apply(min + math.clamp((x - bar.AbsolutePosition.X) / math.max(1, bar.AbsoluteSize.X), 0, 1) * (max - min),
			false, false)
	end
	Util.drag(hit, {
		onStart = function(input)
			tween(knob, { Size = UDim2.fromOffset(14, 14) })
			fromX(input.Position.X)
		end,
		onMove = function(position) fromX(position.X) end,
		onEnd = function() tween(knob, { Size = UDim2.fromOffset(11, 11) }) end,
	})

	apply(value, true, false)
	return handle
end

----------------------------------------------------------------- Input -------
Controls.Input = function(section, opts)
	opts = type(opts) == "table" and opts or {}
	local saveKey = Persist.key(opts, section, "Input")
	local card, slot, _, _, _, fit = Controls.mount(section, opts)
	local defaultText = opts.Default
	if defaultText == nil then defaultText = "" end

	local inputStyle = opts.Style or "outline"
	local inputLook = Util.style(inputStyle, Theme.accent)
	local box = create("TextBox", {
		Parent = slot,
		ClipsDescendants = true,
		BackgroundColor3 = inputLook.fill,
		BackgroundTransparency = inputLook.fillFade,
		Size = UDim2.fromOffset(168, Metrics.control),
		Text = tostring(Persist.get(saveKey, defaultText)),
		PlaceholderText = tostring(opts.Placeholder or ""),
		PlaceholderColor3 = Theme.faint,
		TextColor3 = Theme.text,
		TextSize = 13,
		Font = FONT,
		ClearTextOnFocus = false,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, { Util.corner(Metrics.ctlRadius), Util.stroke(inputLook.edge, nil, inputLook.edgeFade),
		Util.padding(0, 9, 9, 0, 0) })
	fit(box, nil, 90)

	local outline = box:FindFirstChildOfClass("UIStroke")
	box.Focused:Connect(function() tween(outline, { Color = Theme.accent }) end)
	box.FocusLost:Connect(function(enterPressed)
		tween(outline, { Color = Util.style(inputStyle, Theme.accent).edge })
		Persist.set(saveKey, box.Text)
		if opts.Callback and (enterPressed or opts.FireOnBlur) then
			task.spawn(opts.Callback, box.Text)
		end
	end)

	local handle = { Instance = card }
	function handle:Set(value, silent)
		box.Text = tostring(value == nil and "" or value)
		Persist.set(saveKey, box.Text)
		if not silent and opts.Callback then task.spawn(opts.Callback, box.Text) end
		return true
	end
	function handle:Get() return box.Text end

	return handle
end

--------------------------------------------------------------- Keybind -------
Controls.Keybind = function(section, opts)
	opts = type(opts) == "table" and opts or {}
	local saveKey = Persist.key(opts, section, "Keybind")
	-- An EnumItem cannot be JSON encoded, so the name is what gets stored.
	local savedName = saveKey and Persist.get(saveKey)
	local key = keyCode(savedName) or keyCode(opts.Default)
	local listening = false

	local card, slot = Controls.mount(section, opts)

	-- Grows with the key name so "RightShift" is never shortened.
	local button = create("TextButton", {
		Parent = slot,
		BackgroundColor3 = Theme.bg,
		Size = UDim2.new(0, 0, 0, Metrics.control),
		AutomaticSize = Enum.AutomaticSize.X,
		Text = key and key.Name or "None",
		TextSize = 12, Font = FONT_BOLD, TextColor3 = Theme.muted,
		AutoButtonColor = false,
	}, {
		Util.corner(Metrics.ctlRadius), Util.stroke(Theme.border), Util.padding(0, 12, 12, 0, 0),
		-- Less its own 12 + 12 padding, for the same reason as Button above.
		create("UISizeConstraint", { MinSize = Vector2.new(Metrics.controlCol - 24, Metrics.control) }),
	})
	Util.surface(button, opts.HoverColor or "accent", nil, nil, opts.HoverFill)

	button.Activated:Connect(function()
		listening = true
		button.Text = "..."
		button.TextColor3 = Theme.accent
	end)

	local inputConnection = UserInputService.InputBegan:Connect(function(input, processed)
		if listening and input.UserInputType == Enum.UserInputType.Keyboard then
			listening = false
			key = input.KeyCode
			Persist.set(saveKey, key.Name)
			button.Text = key.Name
			button.TextColor3 = Theme.muted
			if opts.Changed then task.spawn(opts.Changed, key) end
		elseif not processed and key and input.KeyCode == key and opts.Callback then
			task.spawn(opts.Callback, key)
		end
	end)
	card.Destroying:Connect(function()
		inputConnection:Disconnect()
	end)

	local handle = { Instance = card, _connections = { inputConnection } }
	function handle:Get() return key end
	function handle:Set(newKey, silent)
		local normalised = keyCode(newKey)
		if newKey ~= nil and normalised == nil then
			return false, "key must be a KeyCode, key name, or nil"
		end
		key = normalised
		Persist.set(saveKey, key and key.Name or nil)
		button.Text = key and key.Name or "None"
		button.TextColor3 = Theme.muted
		if not silent and opts.Changed then task.spawn(opts.Changed, key) end
		return true
	end
	return handle
end

---------------------------------------------------------------- Status -------
-- A read-only value, for reporting progress out of a running loop.
Controls.Status = function(section, opts)
	opts = type(opts) == "table" and opts or {}
	local card, slot, _, _, _, fit = Controls.mount(section, opts)

	local initialValue = opts.Default
	if initialValue == nil then initialValue = "-" end
	local value = Util.label(tostring(initialValue), 13, Theme.accent, FONT_BOLD)
	value.Size = UDim2.new(0, 0, 0, 22)
	value.AutomaticSize = Enum.AutomaticSize.XY
	value.TextWrapped = true
	value.TextXAlignment = Enum.TextXAlignment.Right
	value.Parent = slot
	fit(value)

	return {
		Instance = card,
		Set = function(_, text) value.Text = tostring(text) end,
		Get = function() return value.Text end,
	}
end

------------------------------------------------------------ ColorPicker ------

Controls.ColorPicker = function(section, opts)
	opts = type(opts) == "table" and opts or {}
	local saveKey = Persist.key(opts, section, "ColorPicker")

	local function toColour(value)
		if typeof(value) == "Color3" then return value end
		if type(value) == "table" then
			local r = normaliseNumber(value.r)
			local g = normaliseNumber(value.g)
			local b = normaliseNumber(value.b)
			if r and g and b then
				return Color3.new(math.clamp(r, 0, 1), math.clamp(g, 0, 1), math.clamp(b, 0, 1))
			end
		end
		return nil
	end

	local defaultColour = toColour(opts.Default) or Theme.accent
	local colour = toColour(Persist.get(saveKey, defaultColour)) or defaultColour
	local hue, saturation, brightness = colour:ToHSV()
	local open = false

	local card, slot = Controls.mount(section, opts)

	-- The trigger: a swatch plus its hex, so the value is readable when shut.

	local trigger = create("TextButton", {
		Parent = slot, BackgroundColor3 = Theme.bg,
		Size = UDim2.new(0, 0, 0, Metrics.control),
		AutomaticSize = Enum.AutomaticSize.X,
		Text = "", AutoButtonColor = false,
	}, {
		Util.corner(Metrics.ctlRadius), Util.stroke(Theme.border),
		Util.padding(0, 6, 8, 4, 4), Util.hlist(7),
		create("UISizeConstraint", {
			MinSize = Vector2.new(Metrics.controlCol, Metrics.control),
		}),
	})

	local swatch = create("Frame", {
		Parent = trigger, BackgroundColor3 = colour,
		Size = UDim2.fromOffset(16, 16), LayoutOrder = 1,
	}, { Util.corner(4), Util.stroke(Theme.border2) })
	swatch:SetAttribute("AuraNoTheme", true)

	local hex = Util.label("", 12, Theme.muted, FONT_BOLD)
	hex.Size = UDim2.new(0, 0, 1, 0)
	hex.AutomaticSize = Enum.AutomaticSize.X
	hex.LayoutOrder = 2
	hex.Parent = trigger

	local chevron = Util.icon("chevron-down", 14, Theme.muted)
	chevron.LayoutOrder = 3
	chevron.Parent = trigger
	chevron = Util.rotatable(chevron)

	Util.surface(trigger, "accent", chevron, "muted")

	local PANEL_HEIGHT = 168
	local panel = create("Frame", {
		Name = "__picker", Parent = card, BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0), ClipsDescendants = true,
		Visible = false, LayoutOrder = 2,
	})

	local inner = create("Frame", {
		Parent = panel, BackgroundColor3 = Theme.bg,
		Position = UDim2.new(0, 0, 0, 10), Size = UDim2.new(1, 0, 1, -24),
	}, { Util.corner(Metrics.ctlRadius), Util.stroke(Theme.border), Util.padding(10) })


	local square = create("Frame", {
		Parent = inner, BackgroundColor3 = Color3.fromHSV(hue, 1, 1),
		Size = UDim2.new(1, 0, 1, -46),
	}, { Util.corner(4) })
	square:SetAttribute("AuraNoThemeTree", true)

	local tint = create("Frame", {
		Name = "__tint", Parent = square, BackgroundColor3 = Color3.new(1, 1, 1),
		Size = UDim2.fromScale(1, 1), ZIndex = 2,
	}, { Util.corner(4) })
	create("UIGradient", { Parent = tint, Transparency = NumberSequence.new(0, 1) })

	local shade = create("Frame", {
		Name = "__shade", Parent = square, BackgroundColor3 = Color3.new(0, 0, 0),
		Size = UDim2.fromScale(1, 1), ZIndex = 3,
	}, { Util.corner(4) })
	create("UIGradient", {
		Parent = shade, Rotation = 90,
		Transparency = NumberSequence.new(1, 0),
	})

	local knob = create("Frame", {
		Parent = square, BackgroundTransparency = 1, ZIndex = 4,
		AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(11, 11),
	}, { Util.pill(), Util.stroke(Color3.new(1, 1, 1), 2) })

	local strip = create("Frame", {
		Parent = inner, BackgroundColor3 = Color3.new(1, 1, 1),
		AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, -22),
		Size = UDim2.new(1, 0, 0, 12),
	}, { Util.pill() })
	strip:SetAttribute("AuraNoThemeTree", true)
	create("UIGradient", {
		Parent = strip,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0.00, Color3.fromHSV(0, 1, 1)),
			ColorSequenceKeypoint.new(0.20, Color3.fromHSV(0.20, 1, 1)),
			ColorSequenceKeypoint.new(0.40, Color3.fromHSV(0.40, 1, 1)),
			ColorSequenceKeypoint.new(0.60, Color3.fromHSV(0.60, 1, 1)),
			ColorSequenceKeypoint.new(0.80, Color3.fromHSV(0.80, 1, 1)),
			ColorSequenceKeypoint.new(1.00, Color3.fromHSV(1, 1, 1)),
		}),
	})
	local stripKnob = create("Frame", {
		Parent = strip, BackgroundTransparency = 1, ZIndex = 3,
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.fromOffset(6, 18),
	}, { Util.corner(3), Util.stroke(Color3.new(1, 1, 1), 2) })

	local field = create("TextBox", {
		Parent = inner, BackgroundColor3 = Theme.panel2, ClipsDescendants = true,
		AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, 0),
		Size = UDim2.new(1, 0, 0, 18),
		Text = "", PlaceholderText = "#RRGGBB", PlaceholderColor3 = Theme.faint,
		TextColor3 = Theme.text, TextSize = 12, Font = FONT,
		ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Center,
	}, { Util.corner(4) })

	local handle = { Instance = card }
	local emitCallback, cancelCallback = coalescedCallback(card, opts.Callback)
	handle._cleanups = { cancelCallback }

	local function refresh(silent)
		colour = Color3.fromHSV(hue, saturation, brightness)
		swatch.BackgroundColor3 = colour
		square.BackgroundColor3 = Color3.fromHSV(hue, 1, 1)
		knob.Position = UDim2.fromScale(saturation, 1 - brightness)
		stripKnob.Position = UDim2.new(hue, 0, 0.5, 0)
		local text = string.format("#%02X%02X%02X",
			math.floor(colour.R * 255 + 0.5),
			math.floor(colour.G * 255 + 0.5),
			math.floor(colour.B * 255 + 0.5))
		hex.Text = text
		if not field:IsFocused() then field.Text = text end
		Persist.set(saveKey, { r = colour.R, g = colour.G, b = colour.B })
		if not silent then emitCallback(colour) end
	end


	local function pickFromSquare(position)
		local point = Vector2.new(position.X, position.Y)
		local origin, size = square.AbsolutePosition, square.AbsoluteSize
		saturation = math.clamp((point.X - origin.X) / math.max(1, size.X), 0, 1)
		brightness = 1 - math.clamp((point.Y - origin.Y) / math.max(1, size.Y), 0, 1)
		refresh()
	end

	local function pickFromStrip(position)
		local point = Vector2.new(position.X, position.Y)
		local origin, size = strip.AbsolutePosition, strip.AbsoluteSize
		hue = math.clamp((point.X - origin.X) / math.max(1, size.X), 0, 1)
		refresh()
	end

	square.Active = true
	strip.Active = true
	Util.drag(square, { onStart = function(input) pickFromSquare(input.Position) end,
		onMove = pickFromSquare })
	Util.drag(strip, { onStart = function(input) pickFromStrip(input.Position) end,
		onMove = pickFromStrip })

	field.FocusLost:Connect(function()
		local text = field.Text:gsub("#", "")
		local value = tonumber(text, 16)
		if value and #text == 6 then
			handle:Set(Color3.fromRGB(
				math.floor(value / 65536) % 256,
				math.floor(value / 256) % 256,
				value % 256))
		else
			refresh(true) -- put the valid value back
		end
	end)

	local function setOpen(shouldOpen)
		open = shouldOpen
		if shouldOpen then panel.Visible = true end
		local info = shouldOpen and Motion.open or Motion.shut
		tween(panel, { Size = UDim2.new(1, 0, 0, shouldOpen and PANEL_HEIGHT or 0) }, info)
		tween(chevron, { Rotation = shouldOpen and 180 or 0 }, info)
		if shouldOpen then
			section:_revealDuring(card, 0.34, 4)
		else
			task.delay(0.26, function() if not open then panel.Visible = false end end)
		end
	end

	handle.Open = function() if not open then setOpen(true) end end
	handle.Close = function() if open then setOpen(false) end end
	handle.IsOpen = function() return open end
	section:_registerPopup(card, handle.Close)

	function handle:Set(value, silent)
		local nextColour = toColour(value)
		if not nextColour then return false, "value must be a Color3 or normalized RGB table" end
		hue, saturation, brightness = nextColour:ToHSV()
		refresh(silent)
		return true
	end
	function handle:Get() return colour end

	trigger.Activated:Connect(function() setOpen(not open) end)
	refresh(true)


	if opts.Open then
		task.defer(function()
			if card.Parent then setOpen(true) end
		end)
	end

	return handle
end

--------------------------------------------------------------- Palette -------

Controls.Palette = function(section, opts)
	opts = type(opts) == "table" and opts or {}
	local colours = {}
	local supplied = type(opts.Colors) == "table" and opts.Colors
		or type(opts.Colours) == "table" and opts.Colours or {}
	for _, colour in ipairs(supplied) do
		if typeof(colour) == "Color3" then table.insert(colours, colour) end
	end
	local saveKey = Persist.key(opts, section, "Palette")
	local chosen = normaliseNumber(Persist.get(saveKey, opts.Default or 1))
	if chosen and #colours > 0 then
		chosen = math.clamp(math.floor(chosen), 1, #colours)
	else
		chosen = nil
	end

	local card, slot = Controls.mount(section, opts)

	local row = Util.hlist(6)
	row.HorizontalAlignment = Enum.HorizontalAlignment.Right
	row.Parent = slot
	create("UISizeConstraint", { Parent = slot, MinSize = Vector2.new(Metrics.controlCol, 0) })

	local handle = { Instance = card }
	local swatches = {}

	local function highlight()
		for index, swatch in ipairs(swatches) do
			local edge = swatch:FindFirstChildOfClass("UIStroke")
			tween(edge, {
				Color = index == chosen and Theme.text or Theme.border,
				Thickness = index == chosen and 2 or 1,
			}, Motion.fast)
		end
	end

	for index, colour in ipairs(colours) do
		local swatch = create("TextButton", {
			Parent = row.Parent, BackgroundColor3 = colour, LayoutOrder = index,
			Size = UDim2.fromOffset(20, 20), Text = "", AutoButtonColor = false,
		}, { Util.corner(5), Util.stroke(Theme.border) })
		swatch:SetAttribute("AuraNoTheme", true) -- shows a colour, is not themed BY it
		swatches[index] = swatch
		Util.hover(swatch,
			function() tween(swatch, { Size = UDim2.fromOffset(23, 23) }, Motion.fast) end,
			function() tween(swatch, { Size = UDim2.fromOffset(20, 20) }, Motion.fast) end)
		swatch.Activated:Connect(function() handle:Set(index) end)
	end

	function handle:Set(index, silent)
		local normalised = normaliseNumber(index)
		if not normalised then return false, "index must be a finite number" end
		normalised = math.floor(normalised)
		if not colours[normalised] then return false, "index is outside the palette" end
		chosen = normalised
		Persist.set(saveKey, normalised)
		highlight()
		if not silent and opts.Callback then task.spawn(opts.Callback, colours[normalised], normalised) end
		return true
	end
	function handle:Get() return colours[chosen], chosen end

	highlight()
	return handle
end


-------------------------------------------------------------- Dropdown -------

Controls.Dropdown = function(section, opts)
	opts = type(opts) == "table" and opts or {}

	local function copyArray(list)
		local copy, seen = {}, {}
		if type(list) ~= "table" then return copy end
		for _, item in ipairs(list) do
			if not (type(item) == "number" and item ~= item) and not seen[item] then
				seen[item] = true
				table.insert(copy, item)
			end
		end
		return copy
	end

	local options = copyArray(opts.Options)
	local optionSet = {}
	local function indexOptions()
		table.clear(optionSet)
		for _, option in ipairs(options) do
			if not (type(option) == "number" and option ~= option) then
				optionSet[option] = true
			end
		end
	end
	indexOptions()
	local multi = opts.Multi == true
	local style = opts.Style or "check"
	if style ~= "check" and style ~= "fill" and style ~= "outline" then style = "check" end
	local saveKey = Persist.key(opts, section, "Dropdown")

	local function optionExists(candidate)
		if type(candidate) == "number" and candidate ~= candidate then return false end
		return optionSet[candidate] == true
	end

	local function normaliseValue(raw)
		if not multi then
			if raw ~= nil and optionExists(raw) then return raw end
			return nil
		end

		local supplied = type(raw) == "table" and raw or (raw ~= nil and { raw } or {})
		local selected, seen = {}, {}
		for _, candidate in ipairs(supplied) do
			if optionExists(candidate) and not seen[candidate] then
				seen[candidate] = true
				table.insert(selected, candidate)
			end
		end
		return selected
	end

	local value = normaliseValue(Persist.get(saveKey, opts.Default))
	local anchorIndex -- where a shift-range measures from

	local function isChosen(option)
		if not multi then return value == option end
		for _, held in ipairs(value) do
			if held == option then return true end
		end
		return false
	end

	local function summarise()
		if not multi then
			return value ~= nil and tostring(value) or tostring(opts.Placeholder or "Select")
		end
		if #value == 0 then return tostring(opts.Placeholder or "None") end
		if #value == 1 then return tostring(value[1]) end
		return #value .. " selected"
	end
	local open = false

	local card, slot = Controls.mount(section, opts)

	local button = create("TextButton", {
		Parent = slot,
		BackgroundColor3 = Theme.bg,
		Size = UDim2.new(0, 180, 0, Metrics.control),
		AutomaticSize = Enum.AutomaticSize.Y,
		Text = "",
		AutoButtonColor = false,
	}, {
		Util.corner(Metrics.ctlRadius), Util.stroke(Theme.border), Util.padding(0, 10, 8, 4, 4),
		create("UISizeConstraint", { MinSize = Vector2.new(0, Metrics.control) }),
		Util.hlist(6),
	})

	local hasInitialValue = multi and #value > 0 or (not multi and value ~= nil)
	local current = Util.label(summarise(), 13, hasInitialValue and Theme.text or Theme.faint)
	current.Size = UDim2.new(0, 0, 0, 18)
	current.AutomaticSize = Enum.AutomaticSize.Y
	current.TextWrapped = true
	current.LayoutOrder = 1
	current.Parent = button

	local chevron = Util.icon("chevron-down", 14, Theme.muted)
	chevron.LayoutOrder = 2
	chevron.Parent = button
	chevron = Util.rotatable(chevron) -- the button's hlist would pin it otherwise
	Util.surface(button, opts.HoverColor or "accent", chevron, "muted", opts.HoverFill)


	local BUTTON_MIN = 150
	local function fitWidth()
		local inner = card.AbsoluteSize.X - 24 -- card's horizontal padding
		if inner <= 0 then return end
		local text = summarise()
		-- label padding (10 + 8) + list gap (6) + chevron (14)
		local needed = TextService:GetTextSize(text, 13, FONT, Vector2.new(1e6, 1e6)).X + 38
		local cap = math.max(BUTTON_MIN, math.floor(inner * 0.55))
		local width = math.clamp(needed, BUTTON_MIN, cap)
		button.Size = UDim2.new(0, width, 0, Metrics.control)

		current.Size = UDim2.new(0, math.max(20, width - 38), 0, 18)
	end
	card:GetPropertyChangedSignal("AbsoluteSize"):Connect(fitWidth)

	local GAP_TOP, GAP_BOTTOM = 10, 14

	local menu = create("Frame", {
		Name = "__menu", Parent = card,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		ClipsDescendants = true,
		Visible = false,
		LayoutOrder = 2,
	})
	local menuPanel = create("Frame", {
		Parent = menu,
		BackgroundColor3 = Theme.bg,
		Position = UDim2.new(0, 0, 0, GAP_TOP),
		Size = UDim2.new(1, 0, 1, -(GAP_TOP + GAP_BOTTOM)),
	}, { Util.corner(Metrics.ctlRadius), Util.stroke(Theme.border) })
	local optionList = create("ScrollingFrame", {
		Parent = menuPanel,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = Theme.border2,
		ScrollBarImageTransparency = 0,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
	}, { Util.list(3), Util.padding(0, 6, 6, 5, 5) })

	local handle = { Instance = card }
	local rows, rowByOption = {}, {}

	local function menuHeight()
		local content = optionList.AbsoluteCanvasSize.Y
		if content <= 0 then content = #options * 28 end
		return math.min(content + 10, 190) + GAP_TOP + GAP_BOTTOM
	end

	local function setOpen(shouldOpen)
		open = shouldOpen
		if shouldOpen then menu.Visible = true end
		local info = shouldOpen and Motion.open or Motion.shut
		tween(menu, { Size = UDim2.new(1, 0, 0, shouldOpen and menuHeight() or 0) }, info)
		tween(chevron, { Rotation = shouldOpen and 180 or 0 }, info)
		if shouldOpen then
			section:_revealDuring(card, 0.34, 4)
		else
			task.delay(0.26, function() if not open then menu.Visible = false end end)
		end
	end

	handle.Open   = function() if not open then setOpen(true) end end
	handle.Close  = function() if open then setOpen(false) end end
	handle.IsOpen = function() return open end

	local function paintRow(row, animated)
		local chosen = isChosen(row.option)
		local fillColour = (multi and style == "fill") and Theme.accent or Theme.panel3
		local fade = row.hovered and (chosen and 0.72 or 0.86)
			or ((multi and style == "fill" and chosen) and 0.82 or 1)
		row.entry.BackgroundColor3 = fillColour
		row.entry.TextColor3 = chosen and Theme.accent or Theme.muted
		if animated then
			tween(row.entry, { BackgroundTransparency = fade })
		else
			row.entry.BackgroundTransparency = fade
		end
		if row.selectedStroke then
			row.selectedStroke.Color = chosen and Theme.accent or Theme.border
			row.selectedStroke.Transparency = chosen and 0 or (row.hovered and 0.55 or 1)
		end
		if row.bar then
			row.bar.BackgroundColor3 = Theme.accent
			row.bar.BackgroundTransparency = chosen and 0 or 1
			row.bar.Size = UDim2.new(0, 2, chosen and 0.62 or 0, 0)
		end
		if row.mark then
			row.mark.BackgroundColor3 = chosen and Theme.accent or Theme.bg
			if row.markStroke then row.markStroke.Color = chosen and Theme.accent or Theme.border end
			if row.tick then row.tick.Visible = chosen end
		end
	end

	local function buildRows()
		for _, row in ipairs(rows) do row.entry:Destroy() end
		rows, rowByOption = {}, {}

		for index, option in ipairs(options) do
			local entry = create("TextButton", {
				Parent = optionList,
				BackgroundColor3 = Theme.panel3,
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 0),
				Text = "  " .. tostring(option),
				TextXAlignment = Enum.TextXAlignment.Left,
				TextWrapped = true,
				AutomaticSize = Enum.AutomaticSize.Y,
				TextSize = 13, Font = FONT,
				TextColor3 = Theme.muted,
				AutoButtonColor = false, LayoutOrder = index,
			}, { Util.corner(5), Util.padding(0, 8, 8, 5, 5),
				create("UISizeConstraint", { MinSize = Vector2.new(0, 28) }) })

			if index < #options then
				create("Frame", {
					Name = "__rule", Parent = entry, BackgroundColor3 = Theme.border,
					BackgroundTransparency = 0.45, BorderSizePixel = 0, ZIndex = 0,
					AnchorPoint = Vector2.new(0.5, 1),
					Position = UDim2.new(0.5, 0, 1, 3),
					Size = UDim2.new(1, -10, 0, 1),
				})
			end

			local row = { entry = entry, option = option, hovered = false }
			if multi and style == "outline" then
				row.selectedStroke = Util.stroke(Theme.border, 1, 1)
				row.selectedStroke.Parent = entry
			elseif multi and style == "fill" then
				row.bar = create("Frame", {
					Name = "__bar", Parent = entry, BackgroundColor3 = Theme.accent,
					BorderSizePixel = 0, ZIndex = 2,
					AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0),
					Size = UDim2.new(0, 2, 0, 0),
				}, { Util.corner(1) })
			elseif multi then
				row.mark = create("Frame", {
					Parent = entry, BackgroundColor3 = Theme.bg,
					AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0),
					Size = UDim2.fromOffset(14, 14), ZIndex = 2,
				}, { Util.corner(4), Util.stroke(Theme.border) })
				row.markStroke = row.mark:FindFirstChildOfClass("UIStroke")
				row.tick = Util.icon("check", 10, Theme.accentInk)
				if row.tick then
					row.tick.Visible = false
					row.tick.AnchorPoint = Vector2.new(0.5, 0.5)
					row.tick.Position = UDim2.fromScale(0.5, 0.5)
					row.tick.ZIndex = 3
					row.tick.Parent = row.mark
				end
			end
			rows[index] = row
			rowByOption[option] = row

			Util.hover(entry,
				function()
					row.hovered = true
					paintRow(row, true)
				end,
				function()
					row.hovered = false
					paintRow(row, true)
				end)

			entry.Activated:Connect(function()
				if not multi then
					handle:Set(option)
					setOpen(false)
					return
				end
				local shiftHeld = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)
					or UserInputService:IsKeyDown(Enum.KeyCode.RightShift)

				if shiftHeld and anchorIndex then
					local from, to = math.min(anchorIndex, index), math.max(anchorIndex, index)
					local picked = {}
					for optionIndex = from, to do table.insert(picked, options[optionIndex]) end
					anchorIndex = index
					handle:Set(picked)
				else
					local nextValue = {}
					local removed = false
					for _, keep in ipairs(value) do
						if keep == option then
							removed = true
						else
							table.insert(nextValue, keep)
						end
					end
					if not removed then table.insert(nextValue, option) end
					anchorIndex = index
					handle:Set(nextValue)
				end
			end)
			paintRow(row, false)
		end
	end

	local function updateSummary()
		current.Text = summarise()
		local hasValue = multi and #value > 0 or (not multi and value ~= nil)
		current.TextColor3 = hasValue and Theme.text or Theme.faint
		fitWidth()
	end

	function handle:Set(newValue, silent)
		local normalised = normaliseValue(newValue)
		if not multi and newValue ~= nil and normalised == nil then
			return false, "value is not present in Options"
		end
		local previous = value
		value = normalised
		Persist.set(saveKey, value)
		updateSummary()
		if multi then
			local before, after = {}, {}
			for _, option in ipairs(previous) do before[option] = true end
			for _, option in ipairs(value) do after[option] = true end
			for option in pairs(before) do
				if not after[option] and rowByOption[option] then paintRow(rowByOption[option], false) end
			end
			for option in pairs(after) do
				if not before[option] and rowByOption[option] then paintRow(rowByOption[option], false) end
			end
		else
			if rowByOption[previous] then paintRow(rowByOption[previous], false) end
			if rowByOption[value] then paintRow(rowByOption[value], false) end
		end
		if not silent and opts.Callback then
			task.spawn(opts.Callback, multi and copyArray(value) or value)
		end
		return true
	end
	function handle:Get() return multi and copyArray(value) or value end
	function handle:SetOptions(list)
		if list ~= nil and type(list) ~= "table" then
			return false, "options must be an array"
		end
		options = copyArray(list)
		indexOptions()
		value = normaliseValue(value)
		anchorIndex = nil
		Persist.set(saveKey, value)
		buildRows()
		optionList.CanvasPosition = Vector2.zero
		updateSummary()
		if open then
			tween(menu, { Size = UDim2.new(1, 0, 0, menuHeight()) }, Motion.fast)
			task.defer(function()
				if open and menu.Parent then
					tween(menu, { Size = UDim2.new(1, 0, 0, menuHeight()) }, Motion.fast)
					section:_revealDuring(card, 0.2, 4)
				end
			end)
		end
		return true
	end

	button.Activated:Connect(function() setOpen(not open) end)
	section:_registerPopup(card, handle.Close)
	buildRows()
	updateSummary()
	return handle
end

--=============================================================================
-- 7. SECTION
--=============================================================================

local Section = {}
Section.__index = Section

function Section.new(window, name, iconName, opts)
	name = tostring(name or "Section")
	opts = type(opts) == "table" and opts or {}
	local self = setmetatable({}, Section)
	self.Window = window
	self.Name = name
	self._order = 1
	self._searchable = {}
	self._popups = {} -- { instance, close } records for expandable controls
	self._queries = { global = "", local_ = "" }
	self._groups = {}

	-- Leave room above the resize grip so the scrollbar is not under it.
	local GRIP_CLEARANCE = 30

	self.Page = create("ScrollingFrame", {
		Parent = window.Content,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 1, -GRIP_CLEARANCE),
		Visible = false,
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = Theme.border2,
		ScrollBarImageTransparency = 0,
		VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
	}, {
		Util.list(Metrics.gap),
		Util.padding(Metrics.pad + 2, Metrics.pad + 4, Metrics.pad + 4, Metrics.pad, Metrics.pad - 2),
	})


	local page = self.Page
	local scrollGeneration = 0
	local pointerOver = false


	local SCROLL_HOLD = 0.28
	local SCROLL_FADE = TweenInfo.new(0.55, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

	local function settleScrollbar(info)
		tween(page, {
			ScrollBarImageColor3 = pointerOver
				and Util.brighten(Theme.accent, 0.1) or Theme.scrollIdle,
			ScrollBarImageTransparency = pointerOver and 0.25 or 0.45,
		}, info or Motion.base)
	end


	local BAR_STRIP = 16

	Util.hover(page,
		function()
			-- Nothing to point at on a page that does not scroll.
			pointerOver = page.AbsoluteCanvasSize.Y > page.AbsoluteWindowSize.Y + 1
			settleScrollbar()
		end,
		function()
			pointerOver = false
			settleScrollbar()
		end,
		function(object)
			local position, size = object.AbsolutePosition, object.AbsoluteSize
			return Vector2.new(position.X + size.X - BAR_STRIP, position.Y),
				Vector2.new(BAR_STRIP, size.Y)
		end)


	local lastScrollY = page.CanvasPosition.Y

	page:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
		local y = page.CanvasPosition.Y
		if math.abs(y - lastScrollY) < 0.5 then return end
		lastScrollY = y
		scrollGeneration += 1
		local generation = scrollGeneration
		tween(page, {
			ScrollBarImageColor3 = Util.brighten(Theme.accent, 0.25),
			ScrollBarImageTransparency = 0.08,
		}, Motion.fast)
		task.delay(SCROLL_HOLD, function()
			if scrollGeneration == generation then settleScrollbar(SCROLL_FADE) end
		end)
	end)
	page.ScrollBarImageColor3 = Theme.scrollIdle
	page.ScrollBarImageTransparency = 0.45

	self.Tab, self.TabIcon, self.TabLabel, self.TabPip = window:_buildTab(self, name, iconName)
	if opts.Search then self:_buildSearch(opts.SearchPlaceholder) end
	return self
end

function Section:_add(instance)
	instance.LayoutOrder = self._order
	self._order += 1
	instance.Parent = self.Page
	return instance
end

function Section:_index(instance, text)
	table.insert(self._searchable, {
		instance = instance,
		text = string.lower(tostring(text or "")),
		group = self._groupRecord,
	})
end

function Section:_removeIndexed(instance)
	for index = #self._searchable, 1, -1 do
		local entry = self._searchable[index]
		if entry.instance == instance or not entry.instance or not entry.instance.Parent then
			table.remove(self._searchable, index)
		end
	end
end

function Section:_registerPopup(instance, close)
	if typeof(instance) ~= "Instance" or type(close) ~= "function" then return false end
	table.insert(self._popups, { instance = instance, close = close })
	return true
end

function Section:_removePopup(instance)
	for index = #self._popups, 1, -1 do
		local popup = self._popups[index]
		if type(popup) == "table" and (popup.instance == instance
			or not popup.instance or not popup.instance.Parent) then
			table.remove(self._popups, index)
		elseif type(popup) ~= "table" and type(popup) ~= "function" then
			table.remove(self._popups, index)
		end
	end
end

function Section:_applyFilter(query, source)
	source = source == "local" and "local_" or "global"
	self._queries[source] = string.lower(tostring(query or ""))
	local globalQuery = self._queries.global
	local localQuery = self._queries.local_
	local filtering = globalQuery ~= "" or localQuery ~= ""

	local function contains(text, wanted)
		return wanted == "" or string.find(text, wanted, 1, true) ~= nil
	end

	local matches = 0
	for index = #self._searchable, 1, -1 do
		local entry = self._searchable[index]
		if not entry.instance or not entry.instance.Parent then
			table.remove(self._searchable, index)
			continue
		end
		local groupText = entry.group and entry.group.text or ""
		local globalHit = contains(entry.text, globalQuery) or contains(groupText, globalQuery)
		local localHit = contains(entry.text, localQuery) or contains(groupText, localQuery)
		local hit = globalHit and localHit
		entry.instance.Visible = hit
		if hit and filtering then matches += 1 end
	end

	for groupIndex = #self._groups, 1, -1 do
		local group = self._groups[groupIndex]
		if not group.header.Parent or not group.holder.Parent then
			table.remove(self._groups, groupIndex)
			continue
		end
		local populated = false
		for _, entry in ipairs(self._searchable) do
			if entry.group == group and entry.instance.Visible then
				populated = true
				break
			end
		end
		group.header.Visible = not filtering or populated
		group.holder.Visible = not filtering or populated
	end

	if filtering then
		local children = {}
		for _, child in ipairs(self.Page:GetChildren()) do
			if child:IsA("GuiObject") then table.insert(children, child) end
		end
		table.sort(children, function(a, b) return a.LayoutOrder < b.LayoutOrder end)

		local heading, trailing, populated = nil, {}, false
		local function closeGroup()
			if heading then heading.Visible = populated end
			for _, spacer in ipairs(trailing) do spacer.Visible = populated end
			trailing = {}
		end

		for _, child in ipairs(children) do
			if child:GetAttribute("AuraHeading") then
				closeGroup()
				heading, populated = child, false
			elseif child:GetAttribute("AuraSeparator") then
				table.insert(trailing, child)
			elseif child.Visible then
				populated = true
			end
		end
		closeGroup()
	else
		for _, child in ipairs(self.Page:GetChildren()) do
			if child:IsA("GuiObject") then child.Visible = true end
		end
	end

	self._matchCount = matches
	return matches
end

function Section:_buildSearch(placeholder)
	local holder = create("Frame", {
		Parent = self.Page, BackgroundColor3 = Theme.bg,
		Size = UDim2.new(1, 0, 0, Metrics.control + 4), LayoutOrder = 0,
	}, {
		Util.corner(Metrics.ctlRadius), Util.stroke(Theme.border),
		Util.padding(0, 10, 10, 0, 0), Util.hlist(7),
	})

	local glyph = Util.icon("search", 13, Theme.faint)
	if glyph then
		glyph.LayoutOrder = 1
		glyph.Parent = holder
	end

	local box = create("TextBox", {
		Parent = holder, BackgroundTransparency = 1, ClipsDescendants = true,
		Size = UDim2.new(1, -30, 1, 0), LayoutOrder = 2,
		Text = "", PlaceholderText = placeholder or ("Search " .. self.Name .. "…"),
		PlaceholderColor3 = Theme.faint, TextColor3 = Theme.text,
		TextSize = 13, Font = FONT, ClearTextOnFocus = false,
		TextXAlignment = Enum.TextXAlignment.Left,
	})

	local outline = holder:FindFirstChildOfClass("UIStroke")
	box.Focused:Connect(function() tween(outline, { Color = Theme.accent }) end)
	box.FocusLost:Connect(function() tween(outline, { Color = Theme.border }) end)
	box:GetPropertyChangedSignal("Text"):Connect(function()
		self:_applyFilter(box.Text, "local")
		holder.Visible = true -- the box itself is never filtered away
	end)

	self.SearchBox = box
	return box
end

function Section:_revealDuring(target, duration, bottomMargin)
	local page = self.Page
	if not page or not target then return end
	if self._revealConn then self._revealConn:Disconnect() end
	self._revealConn = nil
	self._revealToken = (self._revealToken or 0) + 1
	local token = self._revealToken

	local margin = bottomMargin or 4
	local startedAt = os.clock()
	local span = math.max(0, tonumber(duration) or 0.34)
	local connection

	local function stop()
		local active = connection
		if active then
			active:Disconnect()
			connection = nil
		end
		if self._revealConn == active then
			self._revealConn = nil
		end
	end

	local function reveal(instant, dt)
		if self._revealToken ~= token or not page.Parent or not target.Parent then
			return false, false
		end
		local view = page.AbsoluteWindowSize.Y
		local settled = false
		if view > 0 then
			local currentY = page.CanvasPosition.Y
			local top = target.AbsolutePosition.Y - page.AbsolutePosition.Y + currentY
			local bottom = top + target.AbsoluteSize.Y
			local goal = currentY
			if bottom > currentY + view - margin then goal = bottom - view + margin end
			if top < goal then goal = math.max(0, top - 10) end
			goal = math.clamp(goal, 0, math.max(0, page.AbsoluteCanvasSize.Y - view))

			local delta = goal - currentY
			settled = math.abs(delta) <= 0.4
			if instant or math.abs(delta) <= 0.4 then
				page.CanvasPosition = Vector2.new(page.CanvasPosition.X, goal)
			else
				page.CanvasPosition = Vector2.new(page.CanvasPosition.X,
					currentY + delta * (1 - math.exp(-16 * math.min(dt, 0.1))))
			end
		end
		return true, settled
	end

	local effects = type(Config.Effects) == "table" and Config.Effects or {}
	local reducedMotion = effects and (effects.Enabled == false
		or (effects.RespectReducedMotion ~= false and GuiService.ReducedMotionEnabled))
	if reducedMotion then
		reveal(true, 0)
		-- AutomaticSize/AbsoluteCanvasSize can settle after the current Lua cycle.
		task.defer(function()
			if self._revealToken == token then reveal(true, 0) end
		end)
		return
	end

	connection = RunService.PreRender:Connect(function(dt)
		local alive, settled = reveal(false, dt)
		if not alive then
			stop()
			return
		end
		local elapsed = os.clock() - startedAt
		if (settled and elapsed >= span) or elapsed >= span + 0.35 then
			reveal(true, 0)
			stop()
		end
	end)
	self._revealConn = connection
end

function Section:Group(opts)
	opts = type(opts) == "table" and opts or {}
	local open = opts.Open ~= false

	local header = create("TextButton", {
		BackgroundTransparency = 1, Text = "",
		Size = UDim2.new(1, 0, 0, 22), AutoButtonColor = false,
	}, { Util.hlist(7) })
	header:SetAttribute("AuraHeading", true)

	local chevron = Util.icon("chevron-down", 13, Theme.muted)
	if chevron then
		chevron.LayoutOrder = 1
		chevron.Parent = header
		chevron = Util.rotatable(chevron)
		chevron.Rotation = open and 0 or -90
	end

	local glyph = opts.Icon and Util.icon(opts.Icon, 13, Theme.muted) or nil
	if glyph then
		glyph.LayoutOrder = 2
		glyph.Parent = header
	end

	local label = Util.label(string.upper(tostring(opts.Text or "Group")), 13, Theme.muted, FONT_BOLD)
	label.Size = UDim2.new(0, 0, 1, 0)
	label.AutomaticSize = Enum.AutomaticSize.X
	label.LayoutOrder = 3
	label.Parent = header
	self:_add(header)

	local holder = create("Frame", {
		BackgroundTransparency = 1, ClipsDescendants = true,
		Size = UDim2.new(1, 0, 0, 0),
	})
	self:_add(holder)


	local inner = create("Frame", {
		Parent = holder, BackgroundTransparency = 1,
		Position = UDim2.fromOffset(12, 0),
		Size = UDim2.new(1, -12, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
	}, { Util.list(Metrics.gap) })

	create("Frame", {
		Name = "__groupRule", Parent = holder, BackgroundColor3 = Theme.border,
		BorderSizePixel = 0, BackgroundTransparency = 0.35,
		Position = UDim2.fromOffset(4, 0), Size = UDim2.new(0, 1, 1, 0),
	})

	local owner = self._owner or self
	local groupRecord = {
		header = header,
		holder = holder,
		text = string.lower(tostring(opts.Text or "Group")),
	}
	table.insert(owner._groups, groupRecord)

	local function contentHeight() return inner.AbsoluteSize.Y end

	local function apply(animated)
		local target = open and contentHeight() or 0
		if animated then
			tween(holder, { Size = UDim2.new(1, 0, 0, target) },
				open and Motion.open or Motion.shut)
			if chevron then
				tween(chevron, { Rotation = open and 0 or -90 },
					open and Motion.open or Motion.shut)
			end
		else
			holder.Size = UDim2.new(1, 0, 0, target)
			if chevron then chevron.Rotation = open and 0 or -90 end
		end
	end

	inner:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		if open then holder.Size = UDim2.new(1, 0, 0, contentHeight()) end
	end)

	Util.hover(header,
		function()
			tween(label, { TextColor3 = Theme.text })
			if chevron then tween(chevron, { ImageColor3 = Theme.accent }) end
		end,
		function()
			tween(label, { TextColor3 = Theme.muted })
			if chevron then tween(chevron, { ImageColor3 = Theme.muted }) end
		end)

	header.Activated:Connect(function()
		open = not open
		apply(true)
	end)

	local group = setmetatable({
		Window = self.Window,
		Name = self.Name,
		Page = inner,
		Header = header,
		Instance = holder,
		_order = 1,
		_searchable = self._searchable, -- one index, so search still finds these
		_popups = self._popups,
		_owner = self,
		_groupRecord = groupRecord,
	}, { __index = self })

	function group:_revealDuring(target, duration, margin)
		return self._owner:_revealDuring(target, duration, margin)
	end

	function group:SetOpen(state, animated)
		open = state ~= false
		apply(animated ~= false)
		return self
	end
	function group:IsOpen() return open end

	task.defer(function() apply(false) end)
	return group
end

function Section:ClosePopups()
	for index = #self._popups, 1, -1 do
		local popup = self._popups[index]
		if type(popup) == "function" then
			pcall(popup) -- compatibility with controls registered against Aura 2.1
		elseif type(popup) == "table" and popup.instance and popup.instance.Parent then
			pcall(popup.close)
		else
			table.remove(self._popups, index)
		end
	end
end

-- Lifecycle helpers shared by every card-based control.
local function decorateHandle(handle, section)
	if type(handle) ~= "table" or typeof(handle.Instance) ~= "Instance" then
		return handle
	end

	local instance = handle.Instance
	local customDestroy = handle.Destroy
	local destroyed = false

	if type(handle.SetVisible) ~= "function" then
		function handle:SetVisible(visible)
			if destroyed or not self.Instance then return self end
			self.Instance.Visible = visible ~= false
			return self
		end
	end
	if type(handle.Show) ~= "function" then
		function handle:Show() return self:SetVisible(true) end
	end
	if type(handle.Hide) ~= "function" then
		function handle:Hide() return self:SetVisible(false) end
	end

	function handle:Destroy(...)
		if destroyed then return false end
		destroyed = true

		local customOk, customError = true, nil
		if customDestroy then
			customOk, customError = pcall(customDestroy, self, ...)
		end

		for _, connection in ipairs(type(self._connections) == "table" and self._connections or {}) do
			pcall(function() connection:Disconnect() end)
		end
		self._connections = {}
		for _, cleanup in ipairs(type(self._cleanups) == "table" and self._cleanups or {}) do
			if type(cleanup) == "function" then pcall(cleanup) end
		end
		self._cleanups = {}

		section:_removeIndexed(instance)
		section:_removePopup(instance)
		if instance.Parent then instance:Destroy() end

		if not customOk then error(customError, 0) end
		return true
	end
	return handle
end

local installedMethods = {}
local customControls = {}

local function installControl(name, build)
	Controls[name] = build
	local method = function(self, ...)
		return decorateHandle(build(self, ...), self)
	end
	installedMethods[name] = method
	Section[name] = method
end

for name, build in pairs(Controls) do
	if name ~= "mount" then
		installControl(name, build)
	end
end

function Aura.RegisterControl(name, build)
	if type(name) ~= "string" or type(build) ~= "function" then
		return false, "name and builder required"
	end
	if not string.match(name, "^[A-Za-z_][A-Za-z0-9_]*$") then
		return false, "name must be a Lua identifier"
	end
	if name == "mount" or Controls[name] ~= nil or rawget(Section, name) ~= nil then
		return false, "control name is already registered or reserved"
	end
	installControl(name, build)
	customControls[name] = true
	return true
end

function Aura.UnregisterControl(name)
	if not customControls[name] then return false, "only custom controls can be unregistered" end
	Controls[name] = nil
	if rawget(Section, name) == installedMethods[name] then Section[name] = nil end
	installedMethods[name] = nil
	customControls[name] = nil
	return true
end

function Aura.HasControl(name) return Controls[name] ~= nil and name ~= "mount" end

function Aura.ControlNames()
	local names = {}
	for name in pairs(Controls) do
		if name ~= "mount" then table.insert(names, name) end
	end
	table.sort(names)
	return names
end

Aura.Controls = Controls


--=============================================================================
-- 8. DISSOLVE
--=============================================================================

local function effectNumber(name, fallback, minimum, maximum)
	local effects = type(Config.Effects) == "table" and Config.Effects or {}
	local value = normaliseNumber(effects[name], normaliseNumber(fallback, minimum))
	return math.clamp(value, minimum, maximum)
end

local function fxNumber(name, fallback, minimum, maximum)
	return math.clamp(normaliseNumber(Fx[name], fallback), minimum, maximum)
end

local function fxColour(name, fallback)
	return typeof(Fx[name]) == "Color3" and Fx[name] or fallback
end

local function effectsEnabled()
	local effects = type(Config.Effects) == "table" and Config.Effects or {}
	if effects.Enabled == false then return false end
	return not (effects.RespectReducedMotion ~= false and GuiService.ReducedMotionEnabled)
end

local function colourAt(rects, buckets, x, y)
	local out
	local candidates = buckets:at(x, y)
	for i = 1, #candidates do
		local r = rects[candidates[i]]
		if x >= r.x1 and x <= r.x2 and y >= r.y1 and y <= r.y2 then
			out = out and out:Lerp(r.colour, 1 - r.transparency) or r.colour
		end
	end
	return out
end

local function colourOver(rects, buckets, samples, x, y, w, h)
	local r, g, b, hits = 0, 0, 0, 0
	for i = 0, samples - 1 do
		for j = 0, samples - 1 do
			local px = x + w * ((i + 0.5) / samples)
			local py = y + h * ((j + 0.5) / samples)
			local c = colourAt(rects, buckets, px, py)
			if c then
				r += c.R
				g += c.G
				b += c.B
				hits += 1
			end
		end
	end
	if hits == 0 then return nil end
	return Color3.new(r / hits, g / hits, b / hits)
end

local function intersectRect(a, b)
	local x1, y1 = math.max(a.x1, b.x1), math.max(a.y1, b.y1)
	local x2, y2 = math.min(a.x2, b.x2), math.min(a.y2, b.y2)
	if x2 <= x1 or y2 <= y1 then return nil end
	return { x1 = x1, y1 = y1, x2 = x2, y2 = y2 }
end

-- Snapshot sampling used to scan every rendered rectangle for every sample point.
-- Bucketing preserves paint order while keeping each lookup local to one area.
local function bucketRects(rects, origin, size, cellSize)
	local columns = math.max(1, math.ceil(size.X / cellSize))
	local rows = math.max(1, math.ceil(size.Y / cellSize))
	local cells = {}
	for index, rect in ipairs(rects) do
		local left = math.clamp(math.floor((rect.x1 - origin.X) / cellSize), 0, columns - 1)
		local right = math.clamp(math.floor((rect.x2 - origin.X) / cellSize), 0, columns - 1)
		local top = math.clamp(math.floor((rect.y1 - origin.Y) / cellSize), 0, rows - 1)
		local bottom = math.clamp(math.floor((rect.y2 - origin.Y) / cellSize), 0, rows - 1)
		for row = top, bottom do
			for column = left, right do
				local key = row * columns + column + 1
				local cell = cells[key]
				if not cell then
					cell = {}
					cells[key] = cell
				end
				cell[#cell + 1] = index
			end
		end
	end

	local empty = {}
	return {
		at = function(_, x, y)
			local column = math.floor((x - origin.X) / cellSize)
			local row = math.floor((y - origin.Y) / cellSize)
			if column < 0 or column >= columns or row < 0 or row >= rows then return empty end
			return cells[row * columns + column + 1] or empty
		end,
	}
end

local function randomBetween(a, b) return a + math.random() * (b - a) end

function Aura:_snapshot(_force)
	local win = self.Window
	local origin, size = win.AbsolutePosition, win.AbsoluteSize
	if size.X < 4 or size.Y < 4 then return nil end


	local MIN_FEATURE = 6
	local GLYPH_WEIGHT, ICON_WEIGHT = 0.6, 0.55
	local rects = {}
	local windowRect = {
		x1 = origin.X, y1 = origin.Y,
		x2 = origin.X + size.X, y2 = origin.Y + size.Y,
	}

	local function add(bounds, colour, transparency)
		table.insert(rects, {
			x1 = bounds.x1, y1 = bounds.y1, x2 = bounds.x2, y2 = bounds.y2,
			colour = colour, transparency = transparency,
		})
	end

	local function collect(parent, clip)
		for _, node in ipairs(parent:GetChildren()) do
			if node:IsA("GuiObject") then
				if node.Visible then
					local position, dims = node.AbsolutePosition, node.AbsoluteSize
					local bounds = intersectRect({
						x1 = position.X, y1 = position.Y,
						x2 = position.X + dims.X, y2 = position.Y + dims.Y,
					}, clip)
					if not bounds then continue end
					if node.BackgroundTransparency < 0.9
						and math.min(dims.X, dims.Y) >= MIN_FEATURE then
						add(bounds, node.BackgroundColor3, node.BackgroundTransparency)
					end
					if (node:IsA("TextLabel") or node:IsA("TextButton") or node:IsA("TextBox"))
						and node.Text ~= "" and node.TextTransparency < 0.9 then
						add(bounds, node.TextColor3, GLYPH_WEIGHT)
					elseif (node:IsA("ImageLabel") or node:IsA("ImageButton"))
						and node.ImageTransparency < 0.9 then
						add(bounds, node.ImageColor3, ICON_WEIGHT)
					end
					collect(node, node.ClipsDescendants and bounds or clip)
				end
			else
				collect(node, clip)
			end
		end
	end
	collect(win, windowRect)
	-- The window's own ground colour sits underneath everything else.
	table.insert(rects, 1, {
		x1 = windowRect.x1, y1 = windowRect.y1,
		x2 = windowRect.x2, y2 = windowRect.y2,
		colour = win.BackgroundColor3,
		transparency = 0, -- the ground layer everything else composites onto
	})
	local effects = type(Config.Effects) == "table" and Config.Effects or {}
	local quality = effects.Quality or "Balanced"
	local qualityOffset = quality == "Low" and -1 or (quality == "High" and 1 or 0)
	local samples = math.floor(effectNumber("Samples", 2, 1, 3) + qualityOffset)
	samples = math.clamp(samples, 1, 3)
	local tileSize = fxNumber("tile", 36, 8, 128)
	local buckets = bucketRects(rects, origin, size, math.max(24, tileSize))

	local tiles = {}
	local radius = math.clamp(normaliseNumber(Metrics.winRadius, 12), 0, 64)
	local span = radius * 2 -- a UICorner radius is clamped to half the frame, so a
	                        -- piece carrying a true radius arc must be 2R across

	local function emit(x, y, w, h, roundAs)
		if w <= 0.5 or h <= 0.5 then return end
		local colour = colourOver(rects, buckets, samples, origin.X + x, origin.Y + y, w, h)
		if not colour then return end
		local u = (x + w / 2) / size.X
		local v = (y + h / 2) / size.Y
		table.insert(tiles, {
			x = x, y = y, w = w, h = h, colour = colour, round = roundAs,
			u = u - 0.5, v = v - 0.5,
			-- 0 at the top-left corner, 1 at the bottom-right: the burn axis.
			d = (u + v) * 0.5,
		})
	end

	local corners = {
		{ id = "tl", x = 0,              y = 0 },
		{ id = "tr", x = size.X - span,  y = 0 },
		{ id = "bl", x = 0,              y = size.Y - span },
		{ id = "br", x = size.X - span,  y = size.Y - span },
	}
	for _, corner in ipairs(corners) do emit(corner.x, corner.y, span, span, corner.id) end

	local function subtract(parts, ax, ay, aw, ah)
		local out = {}
		for _, r in ipairs(parts) do
			local x, y, w, h = r[1], r[2], r[3], r[4]
			if x + w <= ax or ax + aw <= x or y + h <= ay or ay + ah <= y then
				out[#out + 1] = r
			else
				if y < ay then out[#out + 1] = { x, y, w, ay - y } end
				if y + h > ay + ah then out[#out + 1] = { x, ay + ah, w, (y + h) - (ay + ah) } end
				local midY = math.max(y, ay)
				local midH = math.min(y + h, ay + ah) - midY
				if midH > 0 then
					if x < ax then out[#out + 1] = { x, midY, ax - x, midH } end
					if x + w > ax + aw then out[#out + 1] = { ax + aw, midY, (x + w) - (ax + aw), midH } end
				end
			end
		end
		return out
	end


	local qualityScale = quality == "Low" and 0.6 or (quality == "High" and 1.35 or 1)
	local tileBudget = math.floor(effectNumber("MaxTiles", 220, 32, 460) * qualityScale + 0.5)
	tileBudget = math.clamp(tileBudget, 32, 460)
	local step = tileSize
	local estimate = (size.X / step) * (size.Y / step)
	if estimate > tileBudget then
		step = math.ceil(step * math.sqrt(estimate / tileBudget))
	end
	for i = 0, math.ceil(size.X / step) - 1 do
		for j = 0, math.ceil(size.Y / step) - 1 do
			local x, y = i * step, j * step
			local w = math.min(step, size.X - x)
			local h = math.min(step, size.Y - y)
			if w > 1 and h > 1 then
				local parts = { { x, y, w, h } }
				for _, corner in ipairs(corners) do
					parts = subtract(parts, corner.x, corner.y, span, span)
				end
				for _, r in ipairs(parts) do emit(r[1], r[2], r[3], r[4]) end
			end
		end
	end

	self._tiles = { list = tiles, size = size }
	return self._tiles
end

function Aura:_warmPool(tileCount, particleCount)
	if self._warming then return end
	self._warming = true
	task.spawn(function()
		while true do
			local tiles = self._tilePool and #self._tilePool or 0
			local sparks = self._particlePool and #self._particlePool or 0
			if tiles >= tileCount and sparks >= particleCount then break end
			if not self.Gui or not self.Gui.Parent then break end
			-- _pool itself is the builder; ask it for a little more each time.
			self:_pool(math.min(tileCount, tiles + 32), math.min(particleCount, sparks + 8))
			RunService.Heartbeat:Wait()
		end
		self._warming = false
	end)
end

function Aura:_pool(tileCount, particleCount)
	local layer = self._fxLayer
	if not layer or not layer.Parent then
		layer = create("CanvasGroup", {
			Name = "__fx", Parent = self.Gui,
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			ZIndex = 50, Visible = false,
		})
		self._fxLayer = layer
		self._tilePool, self._particlePool = {}, {}
	end

	local tiles, particles = self._tilePool, self._particlePool
	for i = #tiles + 1, tileCount do
		local frame = create("Frame", {
			Parent = layer, BorderSizePixel = 0, ZIndex = 51,
		})
		if i <= 4 then
			create("UICorner", { Parent = frame, CornerRadius = UDim.new(0,
				math.clamp(normaliseNumber(Metrics.winRadius, 12), 0, 64)) })
			for k = 1, 2 do
				create("Frame", { Name = "P" .. k, Parent = frame, BorderSizePixel = 0, ZIndex = 52 })
			end
		end
		tiles[i] = frame
	end
	for i = #particles + 1, particleCount do
		particles[i] = create("Frame", {
			Parent = layer, BorderSizePixel = 0, ZIndex = 60,
		}, { Util.pill() })
	end
	-- Surplus from a previously larger window simply idles.
	for i = tileCount + 1, #tiles do tiles[i].Visible = false end
	for i = particleCount + 1, #particles do particles[i].Visible = false end
	return layer, tiles, particles
end

local function spawnParticles(pool, origin, size, outward, duration, ember, emberHot)
	for _, spark in ipairs(pool) do
		local dim = math.random(2, 4)
		local x = origin.X + math.random(0, math.max(1, math.floor(size.X)))
		local y = origin.Y + math.random(0, math.max(1, math.floor(size.Y)))
		spark.Visible = true
		spark.BackgroundColor3 = (math.random() < 0.55) and emberHot or ember
		spark.BackgroundTransparency = outward and 0.1 or 1

		local angle = randomBetween(0, math.pi * 2)
		local distance = randomBetween(30, 150)
		local dx = math.cos(angle) * distance
		local dy = math.sin(angle) * distance - randomBetween(8, 60)
		local axis = (((x - origin.X) / math.max(1, size.X)) + ((y - origin.Y) / math.max(1, size.Y))) * 0.5
		local lead = (outward and axis or (1 - axis)) * duration * 0.6

		local info = TweenInfo.new(duration * randomBetween(0.6, 1.1), Enum.EasingStyle.Quint,
			outward and Enum.EasingDirection.Out or Enum.EasingDirection.In,
			0, false, lead + randomBetween(0, 0.05))

		if outward then
			spark.Position = UDim2.fromOffset(x, y)
			spark.Size = UDim2.fromOffset(dim, dim)
			TweenService:Create(spark, info, {
				Position = UDim2.fromOffset(x + dx, y + dy),
				BackgroundTransparency = 1, Size = UDim2.fromOffset(1, 1),
			}):Play()
		else
			spark.Position = UDim2.fromOffset(x + dx, y + dy)
			spark.Size = UDim2.fromOffset(1, 1)
			TweenService:Create(spark, info, {
				Position = UDim2.fromOffset(x, y),
				BackgroundTransparency = 1, Size = UDim2.fromOffset(dim, dim),
			}):Play()
		end
	end
end

-- One expanding ring, used as punctuation when the window re-forms.
local function shockwave(layer, centre)
	local ring = create("Frame", {
		Parent = layer,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(centre.X, centre.Y),
		Size = UDim2.fromOffset(40, 40),
		BackgroundTransparency = 1, ZIndex = 55,
	}, { Util.pill() })
	local edge = create("UIStroke", {
		Parent = ring, Color = Theme.accent, Thickness = 3, Transparency = 0.15,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})
	local info = TweenInfo.new(0.6, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	TweenService:Create(ring, info, { Size = UDim2.fromOffset(900, 900) }):Play()
	TweenService:Create(edge, info, { Transparency = 1, Thickness = 0 }):Play()
	task.delay(0.65, function() ring:Destroy() end)
end

function Aura:_revealMask()
	local mask = self.Window:FindFirstChild("__reveal")
	if not mask then
		mask = create("UIGradient", {
			Name = "__reveal", Parent = self.Window, Rotation = 45,
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.44, 1),
				NumberSequenceKeypoint.new(0.56, 0),
				NumberSequenceKeypoint.new(1, 0),
			}),
		})
	end
	return mask
end

local EDGE_BURN = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 1),
	NumberSequenceKeypoint.new(0.44, 1),
	NumberSequenceKeypoint.new(0.56, 0),
	NumberSequenceKeypoint.new(1, 0),
})

function Aura:_edgeMask()
	local stroke = self.Window:FindFirstChildOfClass("UIStroke")
	return stroke and stroke:FindFirstChild("__edgeTint")
end

local function armEdge(gradient, from)
	if not gradient then return end
	gradient.Transparency = EDGE_BURN
	gradient.Offset = Vector2.new(from, 0)
end

local function restEdge(gradient)
	if not gradient then return end
	gradient.Transparency = NumberSequence.new(0)
	gradient.Offset = Vector2.zero
end

function Aura:_dissolve(outward, done)
	if not effectsEnabled() then
		self._fxGen = (self._fxGen or 0) + 1
		if self._fxLayer then self._fxLayer.Visible = false end
		self.Window.GroupTransparency = 0
		self.Window.BackgroundTransparency = 0
		self.Window.Visible = not outward
		if done then done() end
		return
	end

	local snapshot = self._tiles
	local win = self.Window
	if not snapshot or #snapshot.list == 0 then
		win.GroupTransparency = 0
		win.Visible = not outward
		if done then done() end
		return
	end

	-- A leftover mask would be captured as missing pixels by the next snapshot.

	local mask = self:_revealMask()
	local edgeMask = self:_edgeMask()
	local groundColour = win.BackgroundTransparency
	if outward then mask.Enabled = false end

	self._fxGen = (self._fxGen or 0) + 1
	local generation = self._fxGen

	local effects = type(Config.Effects) == "table" and Config.Effects or {}
	local quality = effects.Quality or "Balanced"
	local qualityScale = quality == "Low" and 0.6 or (quality == "High" and 1.35 or 1)
	local particleCount = math.floor(effectNumber("Particles",
		fxNumber("particles", 52, 0, 96), 0, 96) * qualityScale + 0.5)
	local duration = outward and fxNumber("outTime", 0.55, 0, 4)
		or fxNumber("inTime", 0.60, 0, 4)
	local burn = fxNumber("burn", 0.68, 0, 1.5)
	local flashIn = fxNumber("flashIn", 0.03, 0, 1)
	local flashOut = fxNumber("flashOut", 0.17, 0, 2)
	local ember = fxColour("ember", Color3.fromRGB(255, 132, 34))
	local emberHot = fxColour("emberHot", Color3.fromRGB(255, 248, 226))
	local layer, tilePool, particlePool = self:_pool(#snapshot.list, particleCount)
	layer.Visible = true
	layer.GroupTransparency = 0

	local layerPos, winPos = layer.AbsolutePosition, win.AbsolutePosition
	local origin = Vector2.new(winPos.X - layerPos.X, winPos.Y - layerPos.Y)
	local burnSpan = duration * burn

	for index, tile in ipairs(snapshot.list) do
		local frame = tilePool[index]
		frame.Visible = true
		frame.BackgroundColor3 = tile.colour
		frame.Size = UDim2.fromOffset(tile.w, tile.h)

		-- Corner slots keep their arc; the patches square off the inner sides.
		local p1, p2 = frame:FindFirstChild("P1"), frame:FindFirstChild("P2")
		if p1 and p2 then
			if tile.round then
				p1.Visible, p2.Visible = true, true
				p1.BackgroundColor3, p2.BackgroundColor3 = tile.colour, tile.colour
				local originHalf = UDim2.fromScale(0, 0)
				local rightHalf  = UDim2.fromScale(0.5, 0)
				local bottomHalf = UDim2.fromScale(0, 0.5)
				p1.Size = UDim2.fromScale(0.5, 1)
				p2.Size = UDim2.fromScale(1, 0.5)
				p1.Position = (tile.round == "tl" or tile.round == "bl") and rightHalf or originHalf
				p2.Position = (tile.round == "tl" or tile.round == "tr") and bottomHalf or originHalf
			else
				p1.Visible, p2.Visible = false, false
			end
		end

		local magnitude = math.sqrt(tile.u * tile.u + tile.v * tile.v) + 0.0001
		local dx = (tile.u / magnitude) * randomBetween(60, 320) + randomBetween(-40, 40)
		local dy = (tile.v / magnitude) * randomBetween(60, 320) + randomBetween(-70, 30)
		local spin = randomBetween(-160, 160)
		local delay = math.max(0, (outward and tile.d or (1 - tile.d)) * burnSpan)
			+ randomBetween(0, 0.04)

		local home = UDim2.fromOffset(origin.X + tile.x, origin.Y + tile.y)
		local away = UDim2.fromOffset(origin.X + tile.x + dx, origin.Y + tile.y + dy)
		local shrunk = UDim2.fromOffset(math.max(1, tile.w * 0.3), math.max(1, tile.h * 0.3))
		local full = UDim2.fromOffset(tile.w, tile.h)

		local flashTargets = { frame }
		if tile.round and p1 and p2 then
			table.insert(flashTargets, p1)
			table.insert(flashTargets, p2)
		end
		for _, target in ipairs(flashTargets) do
			TweenService:Create(target, TweenInfo.new(flashIn, Enum.EasingStyle.Linear,
				Enum.EasingDirection.Out, 0, false, delay), { BackgroundColor3 = emberHot }):Play()
		end
		task.delay(delay + flashIn + 0.01, function()
			if self._fxGen ~= generation then return end
			for _, target in ipairs(flashTargets) do
				if target.Parent then
					TweenService:Create(target, TweenInfo.new(flashOut, Enum.EasingStyle.Quad),
						{ BackgroundColor3 = tile.colour }):Play()
				end
			end
		end)

		if outward then

			frame.Position, frame.Size, frame.Rotation = home, full, 0
			for _, part in ipairs(flashTargets) do part.BackgroundTransparency = 1 end
			task.delay(delay, function()
				if self._fxGen ~= generation then return end
				if frame.Parent then
					for _, part in ipairs(flashTargets) do part.BackgroundTransparency = 0 end
				end
			end)
			TweenService:Create(frame, TweenInfo.new(duration, Enum.EasingStyle.Quint,
				Enum.EasingDirection.Out, 0, false, delay), {
				Position = away, Rotation = spin, Size = shrunk,
			}):Play()
			for _, part in ipairs(flashTargets) do
				TweenService:Create(part, TweenInfo.new(duration * 0.55, Enum.EasingStyle.Quad,
					Enum.EasingDirection.In, 0, false, delay + duration * 0.42), {
					BackgroundTransparency = 1,
				}):Play()
			end
		else

			frame.Position, frame.Size, frame.Rotation = away, shrunk, spin
			for _, part in ipairs(flashTargets) do part.BackgroundTransparency = 1 end
			task.delay(delay, function()
				if self._fxGen ~= generation then return end
				if not frame.Parent then return end
				for _, part in ipairs(flashTargets) do part.BackgroundTransparency = 0 end
			end)
			TweenService:Create(frame, TweenInfo.new(duration, Enum.EasingStyle.Quint,
				Enum.EasingDirection.Out, 0, false, delay), {
				Position = home, Rotation = 0, Size = full,
			}):Play()
			-- Fades just after landing, uncovering its own patch of the real window.
			for _, part in ipairs(flashTargets) do
				TweenService:Create(part, TweenInfo.new(duration * 0.34, Enum.EasingStyle.Quad,
					Enum.EasingDirection.Out, 0, false, delay + duration * 0.74), {
					BackgroundTransparency = 1,
				}):Play()
			end
		end
	end

	local band = self._fxBand
	if not band or not band.Parent then
		band = create("Frame", {
			Name = "__band", Parent = layer, BorderSizePixel = 0,
			BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 56,
		}, {
			create("UIGradient", {
				Name = "G", Rotation = 45,
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, ember),
					ColorSequenceKeypoint.new(0.44, ember),
					ColorSequenceKeypoint.new(0.50, emberHot),
					ColorSequenceKeypoint.new(0.56, ember),
					ColorSequenceKeypoint.new(1, ember),
				}),
				Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 1),
					NumberSequenceKeypoint.new(0.470, 1),
					NumberSequenceKeypoint.new(0.487, 0.62),
					NumberSequenceKeypoint.new(0.500, 0.08),
					NumberSequenceKeypoint.new(0.516, 0.55),
					NumberSequenceKeypoint.new(0.570, 0.86),
					NumberSequenceKeypoint.new(0.660, 1),
					NumberSequenceKeypoint.new(1, 1),
				}),
			}),
		})
		self._fxBand = band
	end
	band.Visible = true
	band.BackgroundTransparency = 1 -- the gradient does the drawing
	band.Position = UDim2.fromOffset(origin.X, origin.Y)
	band.Size = UDim2.fromOffset(snapshot.size.X, snapshot.size.Y)
	local bandGradient = band:FindFirstChild("G")
	if bandGradient then
		bandGradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, ember),
			ColorSequenceKeypoint.new(0.44, ember),
			ColorSequenceKeypoint.new(0.50, emberHot),
			ColorSequenceKeypoint.new(0.56, ember),
			ColorSequenceKeypoint.new(1, ember),
		})
		bandGradient.Offset = Vector2.new(outward and -1.1 or 1.1, 0)
		TweenService:Create(bandGradient, TweenInfo.new(duration * (burn + 0.22),
			Enum.EasingStyle.Linear), { Offset = Vector2.new(outward and 1.1 or -1.1, 0) }):Play()
	end

	-- Drive the window's own mask so content stays live ahead of the front.
	local settle
	if outward then
		mask.Enabled = true
		mask.Offset = Vector2.new(-0.62, 0)
		win.Visible = true
		win.GroupTransparency = 0
		local sweep = burnSpan + duration * 0.16
		TweenService:Create(mask, TweenInfo.new(sweep, Enum.EasingStyle.Linear),
			{ Offset = Vector2.new(0.62, 0) }):Play()
		-- Same axis, same span: the outline comes apart with the surface it traces.
		armEdge(edgeMask, -0.62)
		if edgeMask then
			TweenService:Create(edgeMask, TweenInfo.new(sweep, Enum.EasingStyle.Linear),
				{ Offset = Vector2.new(0.62, 0) }):Play()
		end

		TweenService:Create(win, TweenInfo.new(sweep * 0.8, Enum.EasingStyle.Quad),
			{ BackgroundTransparency = 1 }):Play()
		task.delay(sweep + 0.02, function()
			if self._fxGen == generation then
				win.Visible = false
				mask.Enabled = false
				restEdge(edgeMask)
				win.BackgroundTransparency = groundColour -- ready for the next show
			end
		end)
		settle = sweep + 0.05
	else
		mask.Enabled = true
		mask.Offset = Vector2.new(0.62, 0)
		win.GroupTransparency = 0
		win.Visible = true
		local sweepStart = duration * 0.52
		local sweep = burnSpan + duration * 0.22
		TweenService:Create(mask, TweenInfo.new(sweep, Enum.EasingStyle.Linear,
			Enum.EasingDirection.Out, 0, false, sweepStart),
			{ Offset = Vector2.new(-0.62, 0) }):Play()
		armEdge(edgeMask, 0.62)
		if edgeMask then
			TweenService:Create(edgeMask, TweenInfo.new(sweep, Enum.EasingStyle.Linear,
				Enum.EasingDirection.Out, 0, false, sweepStart),
				{ Offset = Vector2.new(-0.62, 0) }):Play()
		end

		-- Hidden until the front starts moving, then faded up under it.
		win.BackgroundTransparency = 1
		TweenService:Create(win, TweenInfo.new(sweep * 0.5, Enum.EasingStyle.Quad,
			Enum.EasingDirection.Out, 0, false, sweepStart),
			{ BackgroundTransparency = groundColour }):Play()
		task.delay(sweepStart + sweep + 0.05, function()
			if self._fxGen ~= generation then return end
			if mask.Parent then mask.Enabled = false end
			win.GroupTransparency = 0
			restEdge(edgeMask)
		end)
		settle = sweepStart + sweep
	end

	spawnParticles(particlePool, origin, snapshot.size, outward, duration, ember, emberHot)
	if not outward then
		shockwave(layer, Vector2.new(origin.X + snapshot.size.X / 2, origin.Y + snapshot.size.Y / 2))
	end
	-- Keep the pool exclusively owned by this run until its latest delayed tile
	-- or particle tween has settled. Reusing pooled frames earlier lets an old
	-- tween fight the next transition for Position/Size/Transparency.
	settle = math.max(settle, duration + burnSpan + 0.1)

	local fired = false
	local function finish()
		if fired then return end
		fired = true
		if not outward then
			win.GroupTransparency = 0
			mask.Enabled = false
		end
		-- Unconditional: a superseded run must not leave the outline half-masked.
		if not outward then restEdge(edgeMask) end
		-- A superseded or interrupted run must never leave the panel invisible.
		if not outward then win.BackgroundTransparency = groundColour end
		if done then done() end
	end
	task.delay(settle, function()
		if self._fxGen == generation then finish() end
	end)
	task.delay(math.max(duration, settle) + 0.5, function()
		if self._fxGen ~= generation then return end -- superseded by a newer run
		if self._fxLayer == layer and layer.Parent then
			layer.Visible = false
			if self._fxBand then self._fxBand.Visible = false end
		end
		finish()
	end)
end


--=============================================================================
-- 9. WINDOW
--=============================================================================

local function dispose(resource)
	if type(resource) == "function" then
		pcall(resource)
	elseif resource then
		local okDisconnect, disconnect = pcall(function() return resource.Disconnect end)
		if okDisconnect and type(disconnect) == "function" then
			pcall(disconnect, resource)
		else
			local okDestroy, destroy = pcall(function() return resource.Destroy end)
			if okDestroy and type(destroy) == "function" then pcall(destroy, resource) end
		end
	end
end

function Aura:_track(resource)
	if not resource then return resource end
	if self._destroyed then
		dispose(resource)
	else
		table.insert(self._connections, resource)
	end
	return resource
end

Aura.Track = Aura._track

function Aura:OnDestroy(callback)
	if type(callback) ~= "function" then return nil, "callback required" end
	local entry
	local subscription = { Connected = true }
	function subscription:Disconnect()
		if not self.Connected then return end
		self.Connected = false
		local owner = self._owner
		self._owner = nil
		local index = owner and entry and table.find(owner._destroyListeners, entry)
		if index then table.remove(owner._destroyListeners, index) end
		if entry then entry.callback = nil end
	end
	subscription._owner = self
	if self._destroyed then
		subscription.Connected = false
		subscription._owner = nil
		task.defer(function()
			local ok, err = pcall(callback, self)
			if not ok then warn("[Aura] destroy handler: " .. tostring(err)) end
		end)
		return subscription
	end
	entry = { callback = callback, subscription = subscription }
	table.insert(self._destroyListeners, entry)
	return subscription
end

local function viewportSize()
	local camera = workspace.CurrentCamera
	local size = camera and camera.ViewportSize or nil
	if not size or size.X < 100 or size.Y < 100 then
		local ok, displaySize = pcall(function() return GuiService.ViewportDisplaySize end)
		if ok and typeof(displaySize) == "Vector2" then size = displaySize end
	end
	if not size or size.X < 100 or size.Y < 100 then return Vector2.new(1280, 720) end
	return size
end

function Aura:_applyRail(width)
	width = normaliseNumber(width)
	if width == nil then return false end
	local windowWidth = self.Window.AbsoluteSize.X
	if windowWidth <= 0 then
		local full = self._fullSize or self.Window.Size
		windowWidth = full.X.Offset
	end
	local minRail = math.min(self.MinRail, math.max(96, math.floor(windowWidth * 0.42)))
	local contentFloor = math.min(self.MinContent, math.max(160, windowWidth - minRail))
	local maxByContent = math.max(minRail, windowWidth - contentFloor)
	width = math.clamp(math.floor(width), minRail, math.min(self.MaxRail, maxByContent))
	self._railWidth = width
	self.Rail.Size = UDim2.new(0, width, 1, 0)
	self.Content.Position = UDim2.new(0, width, 0, 0)
	self.Content.Size = UDim2.new(1, -width, 1, 0)
	if self.Divider then self.Divider.Position = UDim2.new(0, width - 2, 0, 0) end
	return true
end

function Aura:_applySize(width, height, fromViewport)
	width, height = tonumber(width), tonumber(height)
	if not finiteNumber(width) or not finiteNumber(height) then return false end
	if not fromViewport then self._desiredSize = Vector2.new(width, height) end
	local viewport = viewportSize()
	local availableWidth, availableHeight = math.max(1, viewport.X - 16), math.max(1, viewport.Y - 16)
	local minWidth = math.min(self.MinSize.X, availableWidth)
	local minHeight = math.min(self.MinSize.Y, availableHeight)
	local maxWidth = math.min(self.MaxSize and self.MaxSize.X or availableWidth, availableWidth)
	local maxHeight = math.min(self.MaxSize and self.MaxSize.Y or availableHeight, availableHeight)
	width = math.clamp(math.floor(width), minWidth, math.max(minWidth, maxWidth))
	height = math.clamp(math.floor(height), minHeight, math.max(minHeight, maxHeight))


	if self._minimised then
		self._fullSize = UDim2.fromOffset(width, height)
		self.Window.Size = UDim2.fromOffset(width, Metrics.topbar)
		self:_applyRail(self._railWidth or 176)
		if self._safeArea then self:_clampPosition() end
		return true
	end

	self.Window.Size = UDim2.fromOffset(width, height)
	self._fullSize = self.Window.Size
	self:_applyRail(self._railWidth or 176)
	if self._safeArea then self:_clampPosition() end
	return true
end

function Aura:_clampPosition()
	if not self.Window then return false end
	local viewport = viewportSize()
	local size = self._minimised and Vector2.new(
		(self._fullSize or self.Window.Size).X.Offset, Metrics.topbar)
		or self.Window.AbsoluteSize
	local position = self.Window.Position
	local x = viewport.X * position.X.Scale + position.X.Offset
	local y = viewport.Y * position.Y.Scale + position.Y.Offset
	x = math.clamp(x, 0, math.max(0, viewport.X - size.X))
	y = math.clamp(y, 0, math.max(0, viewport.Y - size.Y))
	self.Window.Position = UDim2.fromOffset(math.floor(x), math.floor(y))
	return true
end

function Aura:SetSize(width, height)
	if typeof(width) == "Vector2" then width, height = width.X, width.Y end
	return self:_applySize(width, height) and self or false
end

function Aura:SetRailWidth(width)
	return self:_applyRail(width) and self or false
end

function Aura:SetTitle(text)
	if self.TitleLabel then self.TitleLabel.Text = tostring(text or "") end
	return self
end

function Aura:SetSubtitle(text)
	if self.SubtitleLabel then self.SubtitleLabel.Text = tostring(text or "") end
	return self
end

function Aura:SetMinSize(size)
	if typeof(size) ~= "Vector2" or not finiteNumber(size.X) or not finiteNumber(size.Y) then
		return false
	end
	self.MinSize = Vector2.new(math.max(280, size.X), math.max(180, size.Y))
	local full = self._fullSize or self.Window.Size
	self:_applySize(full.X.Offset, full.Y.Offset)
	return self
end

function Aura:SetMaxSize(size)
	if size ~= nil and (typeof(size) ~= "Vector2"
		or not finiteNumber(size.X) or not finiteNumber(size.Y)) then return false end
	self.MaxSize = size
	local full = self._fullSize or self.Window.Size
	self:_applySize(full.X.Offset, full.Y.Offset)
	return self
end

function Aura:SetPosition(position)
	if typeof(position) == "Vector2" then
		position = UDim2.fromOffset(position.X, position.Y)
	end
	if typeof(position) ~= "UDim2" then return false end
	self.Window.Position = position
	if self._safeArea then self:_clampPosition() end
	return self
end

function Aura:Centre()
	local viewport = viewportSize()
	local size = self.Window.AbsoluteSize
	self.Window.Position = UDim2.fromOffset(
		math.floor((viewport.X - size.X) / 2),
		math.floor((viewport.Y - size.Y) / 2))
	if self._safeArea then self:_clampPosition() end
	return self
end
Aura.Center = Aura.Centre

function Aura:GetLayout()
	local full = self._minimised and self._fullSize or self.Window.Size
	local viewport = viewportSize()
	local position = self.Window.Position
	return {
		width = math.floor(full.X.Offset),
		height = math.floor(full.Y.Offset),
		x = math.floor(viewport.X * position.X.Scale + position.X.Offset),
		y = math.floor(viewport.Y * position.Y.Scale + position.Y.Offset),
		rail = math.floor(self._railWidth or 176),
	}
end

function Aura:_layoutKey()
	return "layout/" .. (self._layoutName or "window")
end

function Aura:SaveLayout()
	if not self._saveLayout then return false end
	Persist.set(self:_layoutKey(), self:GetLayout())
	return true
end

function Aura:RestoreLayout()
	local saved = self._saveLayout and Persist.get(self:_layoutKey())
	if type(saved) ~= "table" then return false end
	local width, height = normaliseNumber(saved.width), normaliseNumber(saved.height)
	local rail, x, y = normaliseNumber(saved.rail), normaliseNumber(saved.x), normaliseNumber(saved.y)
	if width and height then self:_applySize(width, height) end
	if rail then self:_applyRail(rail) end
	if x and y then
		self.Window.Position = UDim2.fromOffset(math.floor(x), math.floor(y))
	end
	if self._safeArea then self:_clampPosition() end
	return true
end

------------------------------------------------------------------ Tabs -------
function Aura:_buildTab(section, name, iconName)
	local tab = create("TextButton", {
		Parent = self.TabList,
		BackgroundColor3 = Theme.panel2,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 32),
		Text = "", AutoButtonColor = false,
		LayoutOrder = #self.Sections + 1,
	}, { Util.corner(Metrics.ctlRadius) })


	local count = create("TextLabel", {
		Parent = tab, BackgroundTransparency = 1, Visible = false,
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.new(0, 22, 0, 14), ZIndex = 4,
		Text = "", TextSize = 11, Font = FONT_BOLD,
		TextColor3 = Theme.accent, TextXAlignment = Enum.TextXAlignment.Right,
	})
	section.TabCount = count

	local pip = create("Frame", {
		Parent = tab, BackgroundColor3 = Theme.accent,
		AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.new(0, 3, 0, 0),
	}, { Util.corner(2) })

	local glyph = Util.icon(iconName, 16, Theme.faint)
	if glyph then
		glyph.AnchorPoint = Vector2.new(0, 0.5)
		glyph.Position = UDim2.new(0, 10, 0.5, 0)
		glyph.Parent = tab
	else
		glyph = Util.label(string.sub(name, 1, 1):upper(), 12, Theme.faint, FONT_BOLD)
		glyph.Position = UDim2.new(0, 11, 0, 0)
		glyph.Size = UDim2.new(0, 16, 1, 0)
		glyph.TextXAlignment = Enum.TextXAlignment.Center
		glyph.Parent = tab
	end

	local caption = Util.label(name, 13, Theme.muted)
	caption.Position = UDim2.new(0, 34, 0, 0)
	caption.Size = UDim2.new(1, -42, 1, 0)
	caption.TextWrapped = true
	caption.Parent = tab

	Util.hover(tab,
		function() if self._active ~= section then tween(tab, { BackgroundTransparency = 0.9 }) end end,
		function() if self._active ~= section then tween(tab, { BackgroundTransparency = 1 }) end end)
	tab.Activated:Connect(function() self:Select(section) end)

	return tab, glyph, caption, pip
end

function Aura:Section(name, iconName, opts)
	if self._destroyed then return nil end
	name = tostring(name or ("Section " .. (#self.Sections + 1)))
	local section = Section.new(self, name, iconName, opts)
	table.insert(self.Sections, section)
	if #self.Sections == 1 then self:Select(section) end
	return section
end

function Aura:_setTabCount(section, matches)
	local label = section.TabCount
	if not label then return end
	if matches == nil then
		label.Visible = false
		return
	end
	label.Visible = true
	label.Text = tostring(matches)
	label.TextColor3 = matches > 0 and Theme.accent or Theme.faint
end

function Aura:Select(section)
	local found = false
	for _, candidate in ipairs(self.Sections) do
		if candidate == section then
			found = true
			break
		end
	end
	if not found then return false end
	for _, other in ipairs(self.Sections) do other:ClosePopups() end

	for _, other in ipairs(self.Sections) do
		local active = (other == section)
		other.Page.Visible = active
		tween(other.Tab, { BackgroundTransparency = active and 0.82 or 1 }, Motion.fast)
		tween(other.TabPip, { Size = UDim2.new(0, 3, 0, active and 16 or 0) }, Motion.base)
		tween(other.TabLabel, { TextColor3 = active and Theme.text or Theme.muted }, Motion.fast)
		if other.TabIcon:IsA("ImageLabel") then
			tween(other.TabIcon, { ImageColor3 = active and Theme.accent or Theme.faint }, Motion.fast)
		else
			tween(other.TabIcon, { TextColor3 = active and Theme.accent or Theme.faint }, Motion.fast)
		end
	end
	self._active = section

	if self.Search and self.Search.Text ~= "" then
		section:_applyFilter(string.lower(self.Search.Text), "global")
	end
	return true
end

function Aura:_drainToggle()
	local wanted = self._pending
	self._pending = nil
	if not self._destroyed and wanted ~= nil and wanted ~= self.Window.Visible then
		task.defer(function() self:Toggle(wanted) end)
	end
end

function Aura:Toggle(visible)
	if self._destroyed then return false end
	if visible == nil then
		local target = self._targetVisible
		if target == nil then target = self.Window.Visible end
		visible = not target
	else
		visible = visible ~= false
	end
	if self._fxBusy then
		self._pending = visible
		return false
	end
	self._pending = nil
	self._targetVisible = visible
	if visible == self.Window.Visible then return true end
	self._fxBusy = true

	local duration = visible and fxNumber("inTime", 0.60, 0, 4)
		or fxNumber("outTime", 0.55, 0, 4)
	local runLength = duration * (1 + fxNumber("burn", 0.68, 0, 1.5)) + 0.35
	self._fxGuard = (self._fxGuard or 0) + 1
	local guard = self._fxGuard
	task.delay(runLength, function()
		if self._fxGuard == guard and self._fxBusy then
			self._fxBusy = false
			self:_drainToggle()
		end
	end)

	if visible then
		if effectsEnabled() then self:_snapshot(true) end
		self:_dissolve(false, function()
			if self._destroyed then return end
			self.Window.Visible = true
			self._fxBusy = false
			self:_drainToggle()
		end)
	else
		if effectsEnabled() then self:_snapshot(true) end
		self:_dissolve(true, function()
			if self._destroyed then return end
			self._fxBusy = false
			self:_drainToggle()
		end)
	end
	return true
end

function Aura:Minimise()
	if self._destroyed then return false end
	self._minimised = not self._minimised
	local full = self._fullSize or self.Window.Size
	self._fullSize = full

	if self._minimised and self.Body then self.Body.Visible = false end
	if self._grip then self._grip.Visible = not self._minimised end

	tween(self.Window, {
		Size = self._minimised and UDim2.fromOffset(full.X.Offset, Metrics.topbar) or full,
	}, Motion.base)

	if not self._minimised then
		local delay = effectsEnabled() and 0.12 or 0
		task.delay(delay, function()
			if self.Body and not self._minimised then self.Body.Visible = true end
		end)
	end

	if self._minimiseGlyph then
		Util.setIcon(self._minimiseGlyph, self._minimised and "plus" or "minus")
	end
	return self._minimised
end
Aura.Minimize = Aura.Minimise

---------------------------------------------------------------- Notify -------

local TOAST_BURN = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 1),
	NumberSequenceKeypoint.new(0.42, 1),
	NumberSequenceKeypoint.new(0.58, 0),
	NumberSequenceKeypoint.new(1, 0),
})

-- A short-lived ember burst over a rect, in the gui's own coordinates.
local function toastEmbers(gui, card, outward)
	if not effectsEnabled() then return end
	local origin = card.AbsolutePosition - gui.AbsolutePosition
	local size = card.AbsoluteSize
	if size.X < 4 then return end
	local count = math.floor(effectNumber("ToastParticles", 8, 0, 24))
	for _ = 1, count do
		local dim = math.random(2, 4)
		local x = origin.X + math.random(0, math.max(1, math.floor(size.X)))
		local y = origin.Y + math.random(0, math.max(1, math.floor(size.Y)))
		local spark = create("Frame", {
			Parent = gui, ZIndex = 60, BorderSizePixel = 0,
			BackgroundColor3 = (math.random() < 0.55)
				and fxColour("emberHot", Color3.fromRGB(255, 248, 226))
				or fxColour("ember", Color3.fromRGB(255, 132, 34)),
			Position = UDim2.fromOffset(x, y),
			Size = UDim2.fromOffset(dim, dim),
			BackgroundTransparency = outward and 0.1 or 1,
		}, { Util.pill() })
		local dx = math.random(-26, 26)
		local dy = -math.random(10, 38)
		local info = TweenInfo.new(math.random(28, 52) / 100, Enum.EasingStyle.Quint,
			Enum.EasingDirection.Out, 0, false, math.random(0, 12) / 100)
		tween(spark, {
			Position = UDim2.fromOffset(x + dx, y + dy),
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(1, 1),
		}, info)
		task.delay(0.9, function() if spark.Parent then spark:Destroy() end end)
	end
end

function Aura:Notify(opts)
	if self._destroyed then return nil end
	opts = type(opts) == "table" and opts or {}
	local tone = typeof(opts.IconColor) == "Color3" and opts.IconColor or Theme.accent
	if not self._toasts then
		self._toasts = create("Frame", {
			Parent = self.Gui, BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -16, 1, -16),
			Size = UDim2.new(0, 280, 1, -32),
		}, { Util.list(8, nil, { VerticalAlignment = Enum.VerticalAlignment.Bottom }) })
	end

	local maxToasts = math.floor(effectNumber("MaxToasts", 5, 1, 12))
	local existing = {}
	for _, child in ipairs(self._toasts:GetChildren()) do
		if child:IsA("CanvasGroup") then existing[#existing + 1] = child end
	end
	table.sort(existing, function(a, b) return a.LayoutOrder < b.LayoutOrder end)
	while #existing >= maxToasts do
		local oldest = table.remove(existing, 1)
		oldest:Destroy()
	end
	self._toastSerial = (self._toastSerial or 0) + 1

	local card = create("CanvasGroup", {
		Parent = self._toasts, BackgroundColor3 = Theme.panel2,
		Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
		GroupTransparency = effectsEnabled() and 1 or 0,
		LayoutOrder = self._toastSerial,
	}, { Util.corner(8), Util.stroke(Theme.border2), Util.padding(10, 12, 12, 12, 10) })

	local row = create("Frame", {
		Parent = card, BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
	}, { Util.hlist(9) })

	local burn = create("UIGradient", {
		Parent = card, Rotation = 45,
		Transparency = TOAST_BURN, Offset = Vector2.new(0.62, 0),
	})


	local edge = card:FindFirstChildOfClass("UIStroke")
	local edgeBurn = edge and create("UIGradient", {
		Parent = edge, Rotation = 45,
		Transparency = TOAST_BURN, Offset = Vector2.new(0.62, 0),
	})

	local glyph = Util.icon(opts.Icon, 16, tone)
	if glyph then
		glyph.LayoutOrder = 1
		glyph.Parent = row
	end

	local body = create("Frame", {
		Parent = row, BackgroundTransparency = 1,
		Size = UDim2.new(0, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 2,
	}, {
		Util.list(3),
		create("UIFlexItem", { FlexMode = Enum.UIFlexMode.Fill }),
	})

	local title = Util.label(opts.Title or "Notice", 13, Theme.text, FONT_BOLD)
	title.Size = UDim2.new(1, 0, 0, 0)
	title.AutomaticSize = Enum.AutomaticSize.Y
	title.TextWrapped = true
	title.Parent = body

	if opts.Text then
		local text = Util.label(opts.Text, 12, Theme.muted)
		text.Size = UDim2.new(1, 0, 0, 0)
		text.AutomaticSize = Enum.AutomaticSize.Y
		text.TextWrapped = true
		text.LayoutOrder = 2
		text.Parent = body
	end

	local life = math.max(0, tonumber(opts.Duration) or 3)

	-- The draining rule. Anchored bottom-left so it shortens from the right.
	local rule = create("Frame", {
		Parent = card, BackgroundColor3 = tone,
		BorderSizePixel = 0, ZIndex = 4,
		AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, -12, 1, 10),
		Size = UDim2.new(1, 24, 0, 2), BackgroundTransparency = 0.35,
	})

	-- Burn in: the wipe uncovers from the bottom-right, embers trail the front.
	if effectsEnabled() then
		tween(card, { GroupTransparency = 0 }, Motion.fast)
		tween(burn, { Offset = Vector2.new(-0.62, 0) },
			TweenInfo.new(0.34, Enum.EasingStyle.Linear))
		if edgeBurn then
			tween(edgeBurn, { Offset = Vector2.new(-0.62, 0) },
				TweenInfo.new(0.34, Enum.EasingStyle.Linear))
		end
		task.defer(function()
			RunService.Heartbeat:Wait()
			if card.Parent then toastEmbers(self.Gui, card, false) end
		end)
	else
		burn.Enabled = false
		if edgeBurn then edgeBurn.Enabled = false end
	end
	tween(rule, { Size = UDim2.new(0, 0, 0, 2) },
		TweenInfo.new(life, Enum.EasingStyle.Linear))

	task.delay(life, function()
		if not card.Parent then return end
		toastEmbers(self.Gui, card, true)
		if not effectsEnabled() then
			card:Destroy()
			return
		end
		-- Cover from the top-left, mirroring the window's own dismissal.
		tween(burn, { Offset = Vector2.new(0.62, 0) },
			TweenInfo.new(0.30, Enum.EasingStyle.Linear))
		if edgeBurn then
			tween(edgeBurn, { Offset = Vector2.new(0.62, 0) },
				TweenInfo.new(0.30, Enum.EasingStyle.Linear))
		end
		tween(card, { GroupTransparency = 1 }, TweenInfo.new(0.34, Enum.EasingStyle.Quad))
		task.delay(0.4, function() if card.Parent then card:Destroy() end end)
	end)
	return card
end

--------------------------------------------------------------- Destroy -------
function Aura:Destroy(immediate)
	if self._destroyed then return false end
	self._destroyed = true
	self._targetVisible = false
	self._pending = nil
	self._fxGuard = (self._fxGuard or 0) + 1

	local destroyListeners = self._destroyListeners or {}
	self._destroyListeners = {}
	for _, entry in ipairs(destroyListeners) do
		if entry.subscription.Connected then
			entry.subscription.Connected = false
			local ok, err = pcall(entry.callback, self)
			if not ok then warn("[Aura] destroy handler: " .. tostring(err)) end
		end
		entry.subscription._owner = nil
		entry.callback = nil
	end

	for _, connection in ipairs(self._connections or {}) do
		dispose(connection)
	end
	self._connections = {}
	if self._revealConn then
		pcall(function() self._revealConn:Disconnect() end)
		self._revealConn = nil
	end
	for _, section in ipairs(self.Sections) do
		if section._revealConn then
			pcall(function() section._revealConn:Disconnect() end)
			section._revealConn = nil
		end
		section:ClosePopups()
	end

	local registry = self._registry
	local live = registry and registry.__AURA_LIVE
	if type(live) == "table" then
		for index = #live, 1, -1 do
			if live[index] == self then table.remove(live, index) end
		end
	end

	local gui = self.Gui
	local function releaseGui()
		if gui and gui.Parent then gui:Destroy() end
		if self.Gui == gui then
			self.Gui, self.Window, self.Body = nil, nil, nil
			self.Rail, self.Content, self.Divider = nil, nil, nil
			self._fxLayer, self._fxBand = nil, nil
			self._tilePool, self._particlePool, self._tiles = nil, nil, nil
		end
	end

	if immediate or self._fxBusy or not gui or not gui.Parent or not self.Window.Visible then
		releaseGui()
		return true
	end

	if self.Window.Visible then
		if effectsEnabled() then self:_snapshot(true) end
		self:_dissolve(true)
	end
	task.delay(effectsEnabled() and (fxNumber("outTime", 0.55, 0, 4) + 0.55) or 0,
		releaseGui)
	return true
end

--=============================================================================
-- CONSTRUCTOR
--=============================================================================

function Aura.new(opts)
	opts = type(opts) == "table" and opts or {}
	local windowDefaults = type(Config.Window) == "table" and Config.Window or {}

	local registry = (getgenv and getgenv()) or _G
	local live = type(registry.__AURA_LIVE) == "table" and registry.__AURA_LIVE or {}
	registry.__AURA_LIVE = live
	for index = #live, 1, -1 do
		local previous = live[index]
		if type(previous) ~= "table" or previous._destroyed
			or not previous.Gui or not previous.Gui.Parent then
			table.remove(live, index)
		end
	end
	local replaceExisting = opts.ReplaceExisting
	if replaceExisting == nil then replaceExisting = windowDefaults.ReplaceExisting == true end
	if replaceExisting == true then
		local previousWindows = table.clone(live)
		for _, previous in ipairs(previousWindows) do
			pcall(function() previous:Destroy(true) end)
		end
	end

	local self = setmetatable({}, Aura)
	self.Sections = {}
	self._connections = {}
	self._destroyListeners = {}
	self._active = nil
	self._minimised = false
	self._destroyed = false
	self._registry = registry

	if typeof(opts.Accent) == "Color3" then Aura.SetTheme({ accent = opts.Accent }) end

	local defaultSize = windowDefaults.Size
	local size = opts.Size or defaultSize
	if typeof(size) == "Vector2" then size = UDim2.fromOffset(size.X, size.Y) end
	if typeof(size) ~= "UDim2" then size = UDim2.fromOffset(700, 452) end
	local configuredMin = typeof(opts.MinSize) == "Vector2" and opts.MinSize
		or windowDefaults.MinSize
	if typeof(configuredMin) ~= "Vector2" then configuredMin = Vector2.new(560, 300) end
	local minX = finiteNumber(configuredMin.X) and configuredMin.X or 560
	local minY = finiteNumber(configuredMin.Y) and configuredMin.Y or 300
	self.MinSize = Vector2.new(math.max(280, minX), math.max(180, minY))
	self.MaxSize = opts.MaxSize
	if self.MaxSize == nil then self.MaxSize = windowDefaults.MaxSize end
	if self.MaxSize ~= nil and (typeof(self.MaxSize) ~= "Vector2"
		or not finiteNumber(self.MaxSize.X) or not finiteNumber(self.MaxSize.Y)) then
		self.MaxSize = nil
	end
	self._saveLayout = opts.SaveLayout
	if self._saveLayout == nil then self._saveLayout = windowDefaults.SaveLayout end
	self._layoutName = (type(opts.SaveLayout) == "string" and opts.SaveLayout)
		or opts.Name or opts.Title or "window"
	self.MinRail = math.max(72, normaliseNumber(opts.MinRail,
		normaliseNumber(windowDefaults.MinRail, 132)))
	self.MaxRail = math.max(self.MinRail, normaliseNumber(opts.MaxRail,
		normaliseNumber(windowDefaults.MaxRail, 320)))
	self.MinContent = math.max(120, normaliseNumber(opts.MinContent,
		normaliseNumber(windowDefaults.MinContent, 300)))
	self._railWidth = normaliseNumber(opts.Rail, normaliseNumber(windowDefaults.Rail, 176))

	------------------------------------------------------------------ host ----
	local guiProps = {
		Name = tostring(opts.Name or ("Aura_" .. tostring(math.random(1e6, 9e6)))),
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 999,
	}
	local safeArea = opts.SafeArea
	if safeArea == nil then safeArea = windowDefaults.SafeArea ~= false end
	self._safeArea = safeArea
	if safeArea then
		guiProps.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
	else
		guiProps.IgnoreGuiInset = true
	end
	local gui = create("ScreenGui", guiProps)
	local placed = pcall(function()
		if syn and syn.protect_gui then syn.protect_gui(gui) end
		if gethui then gui.Parent = gethui() else gui.Parent = service("CoreGui") end
	end)
	if not placed or not gui.Parent then
		gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	end
	self.Gui = gui

	---------------------------------------------------------------- window ----
	local viewport = viewportSize()
	local requestedWidth = viewport.X * size.X.Scale + size.X.Offset
	local requestedHeight = viewport.Y * size.Y.Scale + size.Y.Offset
	if not finiteNumber(requestedWidth) then requestedWidth = 700 end
	if not finiteNumber(requestedHeight) then requestedHeight = 452 end
	local initialPosition = opts.Position or Config.Window.Position
	if typeof(initialPosition) == "Vector2" then
		initialPosition = UDim2.fromOffset(initialPosition.X, initialPosition.Y)
	end
	if typeof(initialPosition) ~= "UDim2"
		or not finiteNumber(initialPosition.X.Scale) or not finiteNumber(initialPosition.X.Offset)
		or not finiteNumber(initialPosition.Y.Scale) or not finiteNumber(initialPosition.Y.Offset) then
		initialPosition = UDim2.fromOffset(
			math.floor((viewport.X - requestedWidth) / 2),
			math.floor((viewport.Y - requestedHeight) / 2))
	end
	local win = create("CanvasGroup", {
		Parent = gui,
		BackgroundColor3 = Theme.bg,
		AnchorPoint = Vector2.new(0, 0),
		Position = initialPosition,
		Size = UDim2.fromOffset(requestedWidth, requestedHeight),
		ClipsDescendants = true,
	}, { Util.corner(Metrics.winRadius), Util.stroke(Theme.border2) })
	self.Window = win

	---------------------------------------------------------------- topbar ----
	local topbar = create("Frame", {
		Parent = win, BackgroundColor3 = Theme.panel, BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, Metrics.topbar),
	})
	Panel.round(topbar, Metrics.winRadius, { "bottom" })
	create("Frame", { -- hairline, above the corner patches
		Parent = topbar, BackgroundColor3 = Theme.border, BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 1, -1), Size = UDim2.new(1, 0, 0, 1), ZIndex = 2,
	})

	create("Frame", {
		Parent = topbar, BackgroundColor3 = Theme.accent, ZIndex = 3,
		Position = UDim2.new(0, Metrics.pad, 0.5, -9), Size = UDim2.fromOffset(4, 18),
	}, { Util.corner(2) })

	local titleLabel = Util.label(opts.Title or "Aura", 15, Theme.text, FONT_BOLD)
	titleLabel.ZIndex = 3
	titleLabel.Position = UDim2.new(0, Metrics.pad + 14, 0, opts.Subtitle and 5 or 0)
	titleLabel.Size = UDim2.new(0, 260, 0, opts.Subtitle and 20 or Metrics.topbar)
	titleLabel.Parent = topbar
	self.TitleLabel = titleLabel
	if opts.Subtitle then
		local subtitle = Util.label(opts.Subtitle, 11.5, Theme.faint)
		subtitle.ZIndex = 3
		subtitle.Position = UDim2.new(0, Metrics.pad + 14, 0, 24)
		subtitle.Size = UDim2.new(0, 300, 0, 16)
		subtitle.Parent = topbar
		self.SubtitleLabel = subtitle
	end

	local topGlyph
	local function topButton(iconName, offsetX, hot, onClick, motion)
		local button = create("TextButton", {
			Parent = topbar, BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, offsetX, 0.5, 0),
			Size = UDim2.fromOffset(26, 26), ZIndex = 3,
			Text = "", AutoButtonColor = false,
		}, { Util.corner(Metrics.ctlRadius) })
		local glyph = Util.icon(iconName, 15, Theme.faint)
		topGlyph = glyph
		glyph.AnchorPoint = Vector2.new(0.5, 0.5)
		glyph.Position = UDim2.fromScale(0.5, 0.5)
		glyph.Parent = button
		if motion then
			Util.interact(button, { Glyph = glyph, Icon = iconName, Hover = motion })
		end
		Util.hover(button, function()
			tween(glyph, { ImageColor3 = hot })
			tween(button, { BackgroundTransparency = 0.9, BackgroundColor3 = hot })
		end, function()
			tween(glyph, { ImageColor3 = Theme.faint })
			tween(button, { BackgroundTransparency = 1 })
		end)
		button.Activated:Connect(onClick)
		return button
	end
	topButton("x", -Metrics.pad + 4, Theme.danger,
		function() self:Destroy() end, { Rotate = 90, Scale = 1.1 })
	topButton("minus", -Metrics.pad - 26, Theme.text,
		function() self:Minimise() end, { Scale = 1.3 })
	self._minimiseGlyph = topGlyph


	local edge = win:FindFirstChildOfClass("UIStroke")
	edge.Color = Color3.new(1, 1, 1)
	local edgeTint = create("UIGradient", {
		Name = "__edgeTint", Parent = edge, Rotation = 45,
		Color = ColorSequence.new(Theme.border2),
	})

	local REACH_IDLE, REACH_FULL = 0.985, 0.34
	local RAMP_STEPS = 5

	local function applyGlow(cornerLevel, ambientLevel, breath)
		local base = Theme.border2:Lerp(Theme.accent, ambientLevel * 0.5)
		local reach = REACH_IDLE + (REACH_FULL - REACH_IDLE) * cornerLevel

		local peak = base:Lerp(Theme.accent, math.min(1, cornerLevel * 1.5))
		local glowHot = Util.brighten(Theme.accent, 0.85)
		peak = peak:Lerp(glowHot, math.max(0, cornerLevel - 0.55) / 0.45 * 0.4 + breath * 0.22)

		local keys = { ColorSequenceKeypoint.new(0, base) }
		for i = 0, RAMP_STEPS do
			local along = i / RAMP_STEPS
			keys[#keys + 1] = ColorSequenceKeypoint.new(
				math.clamp(reach + (1 - reach) * along, 0, 1),
				base:Lerp(peak, along * along))
		end
		edgeTint.Color = ColorSequence.new(keys)
		edge.Thickness = 1 + cornerLevel * 1.5 + ambientLevel * 0.55 + breath * 0.7
	end


	local function easeOut(a)
		return 1 - (1 - a) ^ 4
	end

	local function channel() return { value = 0, from = 0, to = 0, elapsed = 0, span = 0 } end
	local cornerCh, ambientCh = channel(), channel()
	local glowBreath, glowConn, glowClock = false, nil, 0

	local function step(ch, dt)
		if ch.value == ch.to and ch.elapsed >= ch.span then return true end
		ch.elapsed += dt
		local a = ch.span > 0 and math.clamp(ch.elapsed / ch.span, 0, 1) or 1
		ch.value = ch.from + (ch.to - ch.from) * easeOut(a)
		return a >= 1
	end

	local function retarget(ch, target, span)
		ch.from, ch.to, ch.elapsed, ch.span = ch.value, target, 0, span or 0.4
		if glowConn then return end
		glowConn = RunService.PreRender:Connect(function(dt)
			if not win.Parent then
				glowConn:Disconnect()
				glowConn = nil
				return
			end
			glowClock += dt
			local doneA, doneB = step(cornerCh, dt), step(ambientCh, dt)
			applyGlow(cornerCh.value, ambientCh.value,
				glowBreath and (0.5 + 0.5 * math.sin(glowClock * 2.6)) or 0)
			if doneA and doneB and not glowBreath then
				glowConn:Disconnect()
				glowConn = nil
			end
		end)
	end

	-- Exposed so either can be driven programmatically (and asserted in tests).
	function self:_glowCorner(target, breathing, span)
		glowBreath = breathing
		retarget(cornerCh, target, span)
	end
	function self:_glowEdge(target, span) retarget(ambientCh, target, span) end
	self:_track({
		Disconnect = function()
			if glowConn then
				glowConn:Disconnect()
				glowConn = nil
			end
		end,
	})

	Util.drag(topbar, {
		onStart = function(input)
			if self._minimised then return false end
			self._dragOrigin = win.Position
			self._dragFrom = input.Position
			self:_glowEdge(1, 0.24)
			return true
		end,
		onMove = function(position)
			local delta = position - self._dragFrom
			local from = self._dragOrigin
			win.Position = UDim2.new(from.X.Scale, from.X.Offset + delta.X,
				from.Y.Scale, from.Y.Offset + delta.Y)
		end,
		-- Longer on release than on grab, so the outline settles rather than snaps.
		onEnd = function()
			self:_glowEdge(0, 0.45)
			if self._safeArea then self:_clampPosition() end
			self:SaveLayout() -- no-op unless this window opted in
		end,
	})

	------------------------------------------------------------------ body ----
	local body = create("Frame", {
		Parent = win, BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 0, Metrics.topbar),
		Size = UDim2.new(1, 0, 1, -Metrics.topbar),
	})
	self.Body = body

	local rail = create("Frame", {
		Parent = body, BackgroundColor3 = Theme.panel, BorderSizePixel = 0,
		Size = UDim2.new(0, self._railWidth, 1, 0),
	})
	Panel.round(rail, Metrics.winRadius, { "top", "right" })
	local railEdge = create("Frame", {
		Parent = rail, BackgroundColor3 = Theme.border, BorderSizePixel = 0,
		Position = UDim2.new(1, -1, 0, 0), Size = UDim2.new(0, 1, 1, 0), ZIndex = 2,
	})
	self.Rail = rail

	local searchBox = create("Frame", {
		Parent = rail, BackgroundColor3 = Theme.bg, ZIndex = 3,
		Position = UDim2.fromOffset(10, 10), Size = UDim2.new(1, -21, 0, 30),
	}, { Util.corner(Metrics.ctlRadius), Util.stroke(Theme.border) })
	local searchIcon = Util.icon("search", 14, Theme.faint)
	searchIcon.AnchorPoint = Vector2.new(0, 0.5)
	searchIcon.Position = UDim2.new(0, 9, 0.5, 0)
	searchIcon.ZIndex = 4
	searchIcon.Parent = searchBox
	local search = create("TextBox", {
		ClipsDescendants = true,
		Parent = searchBox, BackgroundTransparency = 1, ZIndex = 4,
		Position = UDim2.fromOffset(25, 0), Size = UDim2.new(1, -32, 1, 0),
		Text = "", PlaceholderText = "Search...", PlaceholderColor3 = Theme.faint,
		TextColor3 = Theme.text, TextSize = 12.5, Font = FONT,
		TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false,
	})
	self.Search = search

	self.TabList = create("ScrollingFrame", {
		Parent = rail, BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 3,
		Position = UDim2.fromOffset(8, 50), Size = UDim2.new(1, -17, 1, -78),
		ScrollBarThickness = 0, CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
	}, { Util.list(4) })

	local footer = Util.label(opts.Footer or "aura", 11, Theme.faint)
	footer.ZIndex = 3
	footer.Position = UDim2.new(0, 14, 1, -24)
	footer.Size = UDim2.new(1, -20, 0, 16)
	footer.Parent = rail

	self.Content = create("Frame", {
		Parent = body, BackgroundTransparency = 1,
		Position = UDim2.new(0, self._railWidth, 0, 0),
		Size = UDim2.new(1, -self._railWidth, 1, 0),
	})

	--------------------------------------------------------------- divider ----
	local divider = create("TextButton", {
		Name = "__divider", Parent = body, Text = "", AutoButtonColor = false,
		BackgroundColor3 = Theme.accent, BackgroundTransparency = 1,
		Position = UDim2.new(0, self._railWidth - 2, 0, 0), Size = UDim2.new(0, 5, 1, 0),
		ZIndex = 6,
	})
	self.Divider = divider
	local dividerHover, dividerDragging = false, false
	local function showRailEdge(visible)
		railEdge.BackgroundTransparency = visible and 0 or 1
	end

	Util.hover(divider,
		function()
			dividerHover = true
			if not dividerDragging then
				tween(divider, { BackgroundTransparency = 0.55 })
				showRailEdge(false)
			end
		end,
		function()
			dividerHover = false
			if not dividerDragging then
				tween(divider, { BackgroundTransparency = 1 })
				showRailEdge(true)
			end
		end)
	Util.drag(divider, {
		onStart = function()
			if self._minimised then return false end
			dividerDragging = true
			tween(divider, { BackgroundTransparency = 0.25 })
			showRailEdge(false)
			return true
		end,
		onMove = function(position)
			if not dividerDragging then return end
			self:_applyRail(position.X - win.AbsolutePosition.X)
		end,
		onEnd = function()
			dividerDragging = false
			tween(divider, { BackgroundTransparency = dividerHover and 0.55 or 1 })
			showRailEdge(not dividerHover)
			self:SaveLayout() -- the sidebar width is part of the layout
		end,
	})

	------------------------------------------------------------ resize grip ---
	if opts.Resizable ~= false then
		local grip = create("TextButton", {
			Name = "__grip", Parent = win, Text = "", AutoButtonColor = false,
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(1, 1), Position = UDim2.fromScale(1, 1),
			Size = UDim2.fromOffset(26, 26), ZIndex = 25,
		})

		local IDLE_FADE = 0.55
		local gripLines = {}
		for index, spec in ipairs({ { len = 14, off = 8 }, { len = 10, off = 12 }, { len = 6, off = 16 } }) do
			gripLines[index] = create("Frame", {
				Parent = grip, BackgroundColor3 = Theme.border2, BorderSizePixel = 0,
				BackgroundTransparency = IDLE_FADE,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromOffset(26 - spec.off, 26 - spec.off),
				Size = UDim2.fromOffset(spec.len, 2),
				Rotation = -45, ZIndex = 26,
			}, { Util.corner(1) })
		end

		local function setGrip(lineColour, lineFade)
			for _, line in ipairs(gripLines) do
				tween(line, { BackgroundColor3 = lineColour, BackgroundTransparency = lineFade }, Motion.fast)
			end
		end

		local hovering, resizing = false, false
		local function toIdle()
			setGrip(Theme.border2, IDLE_FADE)
			self:_glowCorner(0, false, 0.30)
		end
		local function toHover()
			setGrip(Theme.accent, 0)
			self:_glowCorner(0.42, false, 0.20)
		end
		local function toActive()
			setGrip(Theme.accent, 0)
			self:_glowCorner(1, true, 0.34)
		end

		Util.hover(grip,
			function()
				hovering = true
				if not resizing then toHover() end
			end,
			function()
				hovering = false
				if not resizing then toIdle() end
			end)

		self._grip = grip


		local startSize, startPointer
		Util.drag(grip, {
			onStart = function(input)
				if self._minimised then return false end
				resizing = true
				startSize, startPointer = win.AbsoluteSize, input.Position
				toActive()
				return true
			end,
			onMove = function(position)
				if self._minimised or not startSize then return end
				self:_applySize(startSize.X + (position.X - startPointer.X),
					startSize.Y + (position.Y - startPointer.Y))
			end,
			onEnd = function()
				startSize = nil
				if not resizing then return end
				resizing = false
				if hovering then toHover() else toIdle() end
				self:SaveLayout()
			end,
		})
	end

	---------------------------------------------------------------- search ----

	search:GetPropertyChangedSignal("Text"):Connect(function()
		local query = string.lower(search.Text)
		local firstHit, activeHits = nil, 0

		for _, section in ipairs(self.Sections) do
			local matches = section:_applyFilter(query, "global")
			if query ~= "" and matches > 0 and not firstHit then firstHit = section end
			if section == self._active then activeHits = matches end
			self:_setTabCount(section, query ~= "" and matches or nil)
		end

		if query ~= "" and activeHits == 0 and firstHit then self:Select(firstHit) end
	end)

	--------------------------------------------------------------- keybind ----
	local explicitBind = opts.Keybind ~= nil
	local bind = opts.Keybind or Enum.KeyCode.RightShift
	if type(bind) == "string" then bind = Enum.KeyCode[bind] end
	if typeof(bind) ~= "EnumItem" or bind.EnumType ~= Enum.KeyCode then
		bind = Enum.KeyCode.RightShift
	end
	self:_track(UserInputService.InputBegan:Connect(function(input, processed)
		if not processed and input.KeyCode == bind
			and (explicitBind or live[#live] == self) then self:Toggle() end
	end))

	-- Resolve every constructor option through the same geometry path used later.
	self:_applySize(requestedWidth, requestedHeight)
	self:RestoreLayout()

	local viewportConnection
	local function applyViewport()
		if self._destroyed then return end
		local desired = self._desiredSize
		local full = self._fullSize or win.Size
		self:_applySize(desired and desired.X or full.X.Offset,
			desired and desired.Y or full.Y.Offset, true)
		if self._safeArea then self:_clampPosition() end
	end
	local function watchCamera()
		if viewportConnection then viewportConnection:Disconnect() end
		local current = workspace.CurrentCamera
		viewportConnection = current
			and current:GetPropertyChangedSignal("ViewportSize"):Connect(applyViewport) or nil
	end
	watchCamera()
	self:_track(workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
		watchCamera()
		applyViewport()
	end))
	self:_track(function()
		if viewportConnection then
			viewportConnection:Disconnect()
			viewportConnection = nil
		end
	end)

	----------------------------------------------------------------- intro ----
	win.Visible = false
	self._targetVisible = true
	self._fxBusy = true
	table.insert(live, self)
	task.defer(function()
		RunService.Heartbeat:Wait()
		if effectsEnabled() then RunService.Heartbeat:Wait() end
		if self._destroyed or not win.Parent then return end
		local snapshot = effectsEnabled() and self:_snapshot(true) or nil
		self:_dissolve(false, function()
			if self._destroyed then return end
			win.Visible = true
			self._fxBusy = false
			self:_drainToggle()

			if snapshot and effectsEnabled() then
				local effects = type(Config.Effects) == "table" and Config.Effects or {}
				local quality = effects.Quality or "Balanced"
				local scale = quality == "Low" and 0.6 or (quality == "High" and 1.35 or 1)
				local particles = math.floor(effectNumber("Particles",
					fxNumber("particles", 52, 0, 96), 0, 96) * scale + 0.5)
				task.defer(function() self:_warmPool(#snapshot.list, particles) end)
			end
		end)
	end)
	return self
end

--=============================================================================
-- THEME SWITCHING
--=============================================================================

local COLOUR_PROPERTIES = {
	Frame = { "BackgroundColor3" },
	CanvasGroup = { "BackgroundColor3" },
	ScrollingFrame = { "BackgroundColor3", "ScrollBarImageColor3" },
	TextLabel = { "BackgroundColor3", "TextColor3" },
	TextButton = { "BackgroundColor3", "TextColor3" },
	TextBox = { "BackgroundColor3", "TextColor3", "PlaceholderColor3" },
	ImageLabel = { "BackgroundColor3", "ImageColor3" },
	ImageButton = { "BackgroundColor3", "ImageColor3" },
	UIStroke = { "Color" },
}

local ROLES = {
	"bg", "panel", "panel2", "panel3", "border", "border2",
	"text", "muted", "faint", "accent", "accentInk", "danger",
	"hover", "scrollIdle",
}

local function colourKey(colour)
	return string.format("%d:%d:%d",
		math.floor(colour.R * 65535 + 0.5),
		math.floor(colour.G * 65535 + 0.5),
		math.floor(colour.B * 65535 + 0.5))
end

local function subscribe(listeners, callback, owner)
	if type(callback) ~= "function" then return nil, "callback required" end
	local entry = { callback = callback }
	local subscription = { Connected = true }
	function subscription:Disconnect()
		if not self.Connected then return end
		self.Connected = false
		local index = table.find(listeners, entry)
		if index then table.remove(listeners, index) end
		entry.callback = nil
	end
	entry.subscription = subscription
	table.insert(listeners, entry)
	if owner and type(owner._track) == "function" then owner:_track(subscription) end
	return subscription
end

local function announce(listeners, ...)
	for _, entry in ipairs(table.clone(listeners)) do
		if entry.subscription.Connected then
			local ok, err = pcall(entry.callback, ...)
			if not ok then warn("[Aura] listener: " .. tostring(err)) end
		end
	end
end

local appliedListeners = {}

function Aura.OnThemeApplied(callback, owner)
	return subscribe(appliedListeners, callback, owner)
end

function Aura.SetTheme(theme)
	local appliedName
	if type(theme) == "string" then
		appliedName = theme
		theme = Themes[theme]
		if not theme then return false end
	end
	if type(theme) ~= "table" then return false end

	-- Build a validated old-colour lookup before mutating the stable Theme table.
	local updates, swaps = {}, {}
	for _, role in ipairs(ROLES) do
		local newColour = theme[role]
		if newColour ~= nil then
			if typeof(newColour) ~= "Color3" then return false, "invalid colour for " .. role end
			updates[role] = newColour
			local oldColour = Theme[role]
			if oldColour ~= newColour then
				swaps[colourKey(oldColour)] = swaps[colourKey(oldColour)] or newColour
			end
		end
	end
	if next(updates) == nil then return false, "no theme roles supplied" end
	for role, value in pairs(updates) do Theme[role] = value end
	if appliedName then
		Aura.CurrentTheme = appliedName
	else
		Aura.CurrentTheme = nil
	end
	if next(swaps) == nil then
		if appliedName then announce(appliedListeners, appliedName) end
		return true, 0
	end

	local repainted = 0
	local registry = _G
	if type(getgenv) == "function" then
		local ok, environment = pcall(getgenv)
		if ok and type(environment) == "table" then registry = environment end
	end
	local live = type(registry.__AURA_LIVE) == "table" and registry.__AURA_LIVE or {}
	for _, window in ipairs(live) do
		if window.Gui and window.Gui.Parent then
			for _, node in ipairs(window.Gui:GetDescendants()) do
				local properties = COLOUR_PROPERTIES[node.ClassName]
				if properties then
					local ancestor = node
					while ancestor and ancestor ~= window.Gui do
						if ancestor:GetAttribute("AuraNoTheme")
							or ancestor:GetAttribute("AuraNoThemeTree") then
							properties = nil
							break
						end
						ancestor = ancestor.Parent
					end
				end
				if properties then
					for _, property in ipairs(properties) do
						local tweenRole = activeTweenRoles[node]
							and activeTweenRoles[node][property] or nil
						if tweenRole then cancelOverlappingTweens(node, { property }) end
						local current = node[property]
						local replacement = tweenRole and Theme[tweenRole]
							or (typeof(current) == "Color3" and swaps[colourKey(current)])
						if replacement then
							node[property] = replacement
							repainted += 1
						end
					end
				end
			end
			window._tiles = nil
			local edge = window.Window and window.Window:FindFirstChildOfClass("UIStroke")
			local tint = edge and edge:FindFirstChild("__edgeTint")
			if tint then tint.Color = ColorSequence.new(Theme.border2) end
		end
	end
	if appliedName then announce(appliedListeners, appliedName) end
	return true, repainted
end

--=============================================================================
-- THEME MANAGEMENT
--=============================================================================

local BUILT_IN = {}
for name in pairs(Themes) do BUILT_IN[name] = true end

Aura.ThemeRoles = table.freeze(table.clone(ROLES))

local ROLE_LABELS = {
	bg         = "Window background",
	panel      = "Sidebar",
	panel2     = "Card surface",
	panel3     = "Hover surface",
	border     = "Hairline border",
	border2    = "Strong border",
	text       = "Body text",
	muted      = "Secondary text",
	faint      = "Placeholder text",
	accent     = "Accent",
	accentInk  = "Text on accent",
	danger     = "Danger / delete",
	hover      = "Control hover fill",
	scrollIdle = "Scrollbar at rest",
}

local ROLE_HINTS = {
	bg         = "Behind everything, and inside inputs.",
	panel      = "The section rail on the left.",
	panel2     = "Every control's card.",
	panel3     = "A card or row under the cursor.",
	border     = "The 1px outline on cards and controls.",
	border2    = "Dividers and the resize grip.",
	text       = "Titles and values.",
	muted      = "Labels and inactive tabs.",
	faint      = "Descriptions and placeholders.",
	accent     = "Buttons, toggles, the active tab pip.",
	accentInk  = "Text ON a filled accent button. Keep it dark.",
	danger     = "Delete buttons and warnings.",
	hover      = "Fill behind a hovered control.",
	scrollIdle = "The scrollbar before you touch it.",
}

Aura.ThemeRoleLabels = table.freeze(table.clone(ROLE_LABELS))

function Aura.ThemeRoleLabel(role) return ROLE_LABELS[role] or role end

function Aura.IsBuiltInTheme(name) return BUILT_IN[name] == true end

local themeListeners = {}

function Aura.OnThemesChanged(callback, owner)
	return subscribe(themeListeners, callback, owner)
end

local function announceThemes()
	announce(themeListeners, Aura.ThemeNames())
end
Aura._announceThemes = announceThemes

local function normaliseColour(value)
	if typeof(value) == "Color3" then return value end
	if type(value) ~= "table" then return nil end
	local r, g, b = tonumber(value.r), tonumber(value.g), tonumber(value.b)
	if not finiteNumber(r) or not finiteNumber(g) or not finiteNumber(b) then return nil end
	if r >= 0 and r <= 1 and g >= 0 and g <= 1 and b >= 0 and b <= 1 then
		return Color3.new(r, g, b)
	end
	return Color3.fromRGB(
		math.clamp(math.floor(r + 0.5), 0, 255),
		math.clamp(math.floor(g + 0.5), 0, 255),
		math.clamp(math.floor(b + 0.5), 0, 255))
end

local function normalisePalette(palette)
	if type(palette) ~= "table" then return nil end
	local built, supplied = {}, 0
	for _, role in ipairs(ROLES) do
		local colour = normaliseColour(palette[role])
		if colour then
			built[role] = colour
			supplied += 1
		end
	end
	if supplied == 0 then return nil end
	for _, role in ipairs(ROLES) do
		if not built[role] then built[role] = Themes.Dark[role] end
	end
	return built
end

function Aura.SaveThemes()
	local out = {}
	for name, palette in pairs(Themes) do
		if type(name) == "string" and not BUILT_IN[name] then
			palette = normalisePalette(palette)
			if not palette then continue end
			local roles = {}
			for _, role in ipairs(ROLES) do
				local colour = palette[role]
				roles[role] = {
					r = math.floor(colour.R * 255 + 0.5),
					g = math.floor(colour.G * 255 + 0.5),
					b = math.floor(colour.B * 255 + 0.5),
				}
			end
			out[name] = roles
		end
	end
	return Store.set("themes", out)
end

function Aura.LoadThemes()
	local stored = Store.get("themes")
	if type(stored) ~= "table" then return 0 end
	local loaded = 0
	for name, roles in pairs(stored) do
		if Aura.RegisterTheme(name, roles, true) then loaded += 1 end
	end
	if loaded > 0 then announceThemes() end
	return loaded
end

function Aura.RegisterTheme(name, palette, skipSave)
	if type(name) ~= "string" then return false, "name required" end
	name = name:match("^%s*(.-)%s*$")
	if name == "" or #name > 64 or name:find("[%c]") then return false, "invalid name" end
	if BUILT_IN[name] then return false, "built-in themes cannot be overwritten" end
	local built = normalisePalette(palette)
	if not built then return false, "no usable colours" end
	Themes[name] = built
	if not skipSave then
		Aura.SaveThemes()
		announceThemes()
	end
	return true, name
end

function Aura.RemoveTheme(name)
	if BUILT_IN[name] then return false, "built-in themes cannot be removed" end
	if not Themes[name] then return false, "no such theme" end
	Themes[name] = nil
	if Aura.CurrentTheme == name then Aura.SetTheme("Dark") end
	Aura.SaveThemes()
	announceThemes()
	return true
end

function Aura.ExportTheme(name)
	local palette = normalisePalette(Themes[name])
	if not palette then return nil end
	local out = { name = name, roles = {} }
	for _, role in ipairs(ROLES) do
		local colour = palette[role]
		out.roles[role] = {
			r = math.floor(colour.R * 255 + 0.5),
			g = math.floor(colour.G * 255 + 0.5),
			b = math.floor(colour.B * 255 + 0.5),
		}
	end
	local ok, encoded = pcall(function() return HttpService:JSONEncode(out) end)
	return ok and encoded or nil
end

function Aura.ImportTheme(source, nameOverride)
	if type(source) ~= "string" or source == "" then return nil, "nothing to import" end
	if #source > 131072 then return nil, "theme data is too large" end

	local text = source
	if source:match("^https?://") then
		local ok, body = pcall(function() return game:HttpGet(source) end)
		if not ok or type(body) ~= "string" then return nil, "could not fetch that URL" end
		if #body > 131072 then return nil, "theme data is too large" end
		text = body
	end

	local ok, decoded = pcall(function() return HttpService:JSONDecode(text) end)
	if not ok or type(decoded) ~= "table" then return nil, "that is not valid JSON" end

	local roles = decoded.roles or decoded
	local name = nameOverride or decoded.name or "Imported"
	local registered, result = Aura.RegisterTheme(name, roles)
	if not registered then return nil, result or "no usable colours in it" end
	return result
end

function Aura:ThemeEditor(opts)
	opts = type(opts) == "table" and opts or {}
	local section = self:Section(opts.Name or "Themes", opts.Icon or "droplet")
	local editing = {}   -- role -> Color3, the palette being edited
	local swatches = {}  -- role -> the button showing it
	-- Whatever is on screen right now, not whatever was configured at startup.
	local themeConfig = type(Aura.Config.Themes) == "table" and Aura.Config.Themes or {}
	local source = Aura.CurrentTheme or themeConfig.Default or "Dark"
	if not Themes[source] then source = "Dark" end
	local activeRole = "accent"

	local chooser, picker, roleStatus

	local function paintSwatches()
		for role, button in pairs(swatches) do
			button.BackgroundColor3 = editing[role]
			local edge = button:FindFirstChildOfClass("UIStroke")
			if edge then
				edge.Color = (role == activeRole) and Theme.text or Theme.border
				edge.Thickness = (role == activeRole) and 2 or 1
			end
		end
	end

	local roleHintRef
	local function selectRole(role)
		activeRole = role
		if roleStatus then roleStatus:Set(ROLE_LABELS[role] or role) end
		if roleHintRef then roleHintRef:Set(ROLE_HINTS[role] or "") end
		if picker then picker:Set(editing[role], true) end
		paintSwatches()
	end

	local function loadInto(name)
		local palette = Themes[name]
		if not palette then return end
		source = name
		for _, role in ipairs(ROLES) do editing[role] = palette[role] end
		paintSwatches()
		if picker then picker:Set(editing[activeRole], true) end
	end

	for _, role in ipairs(ROLES) do editing[role] = Themes[source][role] end

	section:Title({ Text = "BASE", Icon = "droplet" })
	section:Description("Load a theme, click any colour to change it, then save the result under a new name.")

	chooser = section:Dropdown({
		Text = "Base theme", Options = Aura.ThemeNames(), Default = source,
		Callback = function(name)
			loadInto(name)
			Aura.SetTheme(name)
		end,
	})

	Aura.OnThemeApplied(function(name)
		if name == source then return end
		loadInto(name)
		chooser:Set(name, true)
	end, self)


	section:Separator()
	section:Title({ Text = "COLOURS", Icon = "brush" })

	local gridCard, gridSlot = Card.new(section.Page, {
		Text = "Palette", Description = "Every colour in the theme. Click one to edit it below.",
	})
	section:_add(gridCard)

	local grid = create("Frame", {
		Parent = gridSlot, BackgroundTransparency = 1,
		Size = UDim2.fromOffset(7 * 26, 2 * 26),
	}, {
		create("UIGridLayout", {
			CellSize = UDim2.fromOffset(22, 22),
			CellPadding = UDim2.fromOffset(4, 4),
			FillDirectionMaxCells = 7,
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})

	for index, role in ipairs(ROLES) do
		local button = create("TextButton", {
			Parent = grid, BackgroundColor3 = editing[role], LayoutOrder = index,
			Text = "", AutoButtonColor = false,
		}, { Util.corner(5), Util.stroke(Theme.border) })
		button:SetAttribute("AuraNoTheme", true)
		swatches[role] = button
		Util.hover(button,
			function() tween(button, { Size = UDim2.fromOffset(25, 25) }, Motion.fast) end,
			function() tween(button, { Size = UDim2.fromOffset(22, 22) }, Motion.fast) end)
		button.Activated:Connect(function() selectRole(role) end)
	end

	roleStatus = section:Status({ Text = "Editing", Default = ROLE_LABELS[activeRole] })
	roleHintRef = section:Status({ Text = "Which is", Default = ROLE_HINTS[activeRole] })

	picker = section:ColorPicker({
		Text = "Colour", Description = "Square for shade, strip for hue, or type a hex code.",
		Open = true,
		Default = editing[activeRole],
		Callback = function(colour)
			editing[activeRole] = colour
			paintSwatches()
			if opts.LivePreview ~= false then Aura.SetTheme({ [activeRole] = colour }) end
		end,
	})

	section:Separator()
	section:Title({ Text = "KEEP IT", Icon = "save" })

	local nameBox = section:Input({
		Text = "Name", Placeholder = "My theme", FireOnBlur = true,
	})

	section:Button({
		Text = "Apply without saving", Description = "Push these colours to every open window.",
		ButtonText = "Apply", Style = "soft", ButtonIcon = "play",
		Callback = function() Aura.SetTheme(editing) end,
	})

	Aura.OnThemesChanged(function(names) chooser:SetOptions(names) end, self)

	local function refreshChooser(select)
		chooser:SetOptions(Aura.ThemeNames())
		if select then chooser:Set(select, true) end
	end

	section:Button({
		Text = "Save as a new theme", ButtonText = "Save", ButtonIcon = "save",
		Click = { Icon = "check", Hold = 1 },
		Callback = function()
			local name = nameBox:Get()
			if name == "" then
				self:Notify({ Title = "Name it first", Icon = "triangle-alert",
					IconColor = Theme.danger })
				return
			end
			local saved, result = Aura.RegisterTheme(name, editing)
			if not saved then
				self:Notify({ Title = "Could not save", Text = result,
					Icon = "triangle-alert", IconColor = Theme.danger })
				return
			end
			refreshChooser(result)
			self:Notify({ Title = "Saved", Text = result, Icon = "check" })
		end,
	})

	section:Button({
		Text = "Delete the selected theme", Description = "Built-in palettes cannot be removed.",
		ButtonText = "Delete", Danger = true, ButtonIcon = "trash-2", Hover = { Text = "Sure?" },
		Callback = function()
			local ok, why = Aura.RemoveTheme(chooser:Get())
			if ok then
				refreshChooser("Dark")
				loadInto("Dark")
				self:Notify({ Title = "Removed", Icon = "check" })
			else
				self:Notify({ Title = "Cannot remove", Text = why,
					Icon = "triangle-alert", IconColor = Theme.danger })
			end
		end,
	})

	section:Separator()
	section:Title({ Text = "SHARE", Icon = "upload" })

	section:Button({
		Text = "Export the current theme", Description = "As JSON, to the clipboard.",
		ButtonText = "Export", ButtonIcon = "upload", Style = "soft",
		Click = { Icon = "check", Hold = 1 },
		Callback = function()
			local encoded = Aura.ExportTheme(chooser:Get())
			if encoded and type(setclipboard) == "function"
				and pcall(setclipboard, encoded) then
				self:Notify({ Title = "Copied", Icon = "check" })
			else
				self:Notify({ Title = "No clipboard", Text = "This executor has no setclipboard.",
					Icon = "triangle-alert", IconColor = Theme.danger })
			end
		end,
	})

	local urlBox = section:Input({
		Text = "Import", Placeholder = "URL or JSON", FireOnBlur = true,
	})

	section:Button({
		Text = "Import that", Description = "Fetches a URL, or reads JSON pasted above.",
		ButtonText = "Import", ButtonIcon = "download",
		Callback = function()
			local name, why = Aura.ImportTheme(urlBox:Get())
			if name then
				refreshChooser(name)
				loadInto(name)
				self:Notify({ Title = "Imported", Text = name, Icon = "check" })
			else
				self:Notify({ Title = "Import failed", Text = why,
					Icon = "triangle-alert", IconColor = Theme.danger, Duration = 5 })
			end
		end,
	})

	selectRole(activeRole)
	return section
end

-- Extension surface for custom controls / theming without forking the library.
Aura.Util = Util
Aura.Metrics = Metrics
Aura.Motion = Motion
Aura.Fx = Fx

return Aura
