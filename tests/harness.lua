-- Minimal Classic (WotLK) API stub for loading CassiniEnergy outside the client.
local root = arg[1] or ".."

local function newFrame(kind, name)
  local f = { _kind = kind, _events = {}, _scripts = {}, _shown = true, _w = 100, _h = 10, _points = {} }
  local m = {}
  function m:RegisterEvent(e) self._events[e] = true end
  function m:RegisterUnitEvent(e, unit) self._events[e] = unit end
  function m:SetScript(s, fn) self._scripts[s] = fn end
  function m:Show() self._shown = true end
  function m:Hide() self._shown = false end
  function m:IsShown() return self._shown end
  function m:SetWidth(w) self._w = w end
  function m:SetHeight(h) self._h = h end
  function m:GetWidth() return self._w end
  function m:GetHeight() return self._h end
  function m:SetPoint(...) table.insert(self._points, { ... }) end
  function m:ClearAllPoints() self._points = {} end
  function m:GetPoint() return unpack(self._points[1] or {}) end
  function m:SetValue(v) self._value = v end
  function m:SetText(t) self._text = t end
  function m:GetText() return self._text end
  function m:CreateTexture() return newFrame("Texture") end
  function m:CreateFontString() return newFrame("FontString") end
  function m:GetStatusBarTexture() self._sbt = self._sbt or newFrame("Texture"); return self._sbt end
  setmetatable(f, { __index = function(_, k)
    if m[k] then return m[k] end
    if type(k) == "string" and k:match("^%u") then return function() end end
  end })
  if name then _G[name] = f end
  table.insert(FRAMES, f)
  return f
end

function Reset()
  FRAMES = {}
  PRINTED = {}
  NOW = 1
  TOC = 30403
  CLASS = "ROGUE"
  POWER, POWER_MAX = 50, 100
  CombatLogEvent = nil
  CassiniEnergy_Options = nil
  PlayerFrameManaBar = nil
end

CreateFrame = function(kind, name) return newFrame(kind, name) end
print = function(...) table.insert(PRINTED, table.concat({ ... }, " ")) end
SlashCmdList = {}
Settings = {}
function GetBuildInfo() return "x", "1", "date", TOC end
function GetTime() return NOW end
function UnitClass() return "Rogue", CLASS end
function UnitGUID() return "Player-1" end
function UnitIsDead() return false end
function InCombatLockdown() return false end
function GetScreenHeight() return 1080 end
function UnitPower() return POWER end
function UnitPowerMax() return POWER_MAX end
function CombatLogGetCurrentEventInfo() return unpack(CombatLogEvent) end

function Load()
  UIParent = newFrame("Frame", "UIParent")
  if not PlayerFrameManaBar then
    PlayerFrameManaBar = newFrame("StatusBar")
    PlayerFrameManaBar._w, PlayerFrameManaBar._h = 119, 12
    PlayerFrameManaBar:SetPoint("TOPLEFT", "PlayerFrame", "TOPLEFT", 106, -52)
  end
  local toc = assert(io.open(root.."/CassiniEnergy.toc")):read("*a")
  for line in toc:gmatch("[^\r\n]+") do
    if not line:match("^%s*#") and line:match("%S") then
      local chunk = assert(loadfile(root.."/"..line:gsub("\\", "/")))
      chunk("CassiniEnergy", {})
    end
  end
  Fire("ADDON_LOADED", "CassiniEnergy")
end

function Fire(event, ...)
  for _, f in ipairs(FRAMES) do
    if f._events[event] and f._scripts.OnEvent then f._scripts.OnEvent(f, event, ...) end
  end
end

function Update(t)
  if t then NOW = t end
  CassiniEnergy._scripts.OnUpdate(CassiniEnergy, 0.016)
end

-- Distance from t to the nearest tick on the bar's current grid.
function Offset(t) return CassiniEnergy.TickBar.TickOffset(t) end
function BarShown() return CassiniEnergy.TickBar.tickbar:IsShown() end

local failures = 0
function Check(name, ok)
  if not ok then failures = failures + 1; io.write("\n  FAIL: "..name) end
end
function Done()
  io.write(failures == 0 and "ok\n" or "\n")
  os.exit(failures == 0 and 0 or 1)
end

Reset()
