-- NAMESPACE / CLASS: CassiniEnergy
-- OPTIONS: CassiniEnergy_Options
--
-- Tracks the server's energy regeneration tick cadence (a tick every 2 seconds)
-- for classes that use Energy -- Rogues, and Druids while in Cat Form. This is a
-- standalone extraction of the tick-tracking mechanics; it has nothing to do with
-- mana, spirit regen, or the five second rule.

CassiniEnergy = CreateFrame("Frame")

do -- Private Scope
    local ADDON_NAME = "CassiniEnergy"

    local defaults = {
        ["enabled"] = true,
        ["unlocked"] = false,
        ["integrateIntoPlayerFrame"] = true,
        ["barWidth"] = 117,
        ["barHeight"] = 11,
        ["barLeft"] = 90,
        ["barTop"] = -68,
        ["flat"] = false,
        ["showText"] = false,
        ["showSpark"] = true,
        ["alwaysShowTicks"] = true,
        ["frameStrata"] = "MEDIUM",
        ["energyTicksColor"] = {1, 0.85, 0, 1},
        ["energyTicksBackgroundColor"] = {0.35, 0.35, 0.35, 0.8},
    }

    -- STATE VARIABLES
    CassiniEnergy.previousPower = 0
    CassiniEnergy.debug = false

    -- POWER GAIN LEDGER
    -- Energy regen ticks never appear in the combat log; they arrive as a silent
    -- +N to the energy pool on a fixed ~2s cadence. Every other gain (Tiger's
    -- Fury, Thistle Tea, Relentless Strikes, combat potency, etc.) arrives as
    -- SPELL_ENERGIZE / SPELL_PERIODIC_ENERGIZE and is accumulated here, then
    -- subtracted from the raw power delta each frame. A positive remainder is a
    -- regen tick on that cadence.
    local explainedGain = 0

    -- FORWARD DECLARATIONS
    -- Kept strictly local so this addon can run side by side with FiveSecondRule
    -- without either clobbering the other's global helper functions.
    local Init, LoadOptions, EnableAddon, DisableAddon
    local onEvent, onUpdate, onCombatLogEvent, ReconcilePower
    local GetPower, GetPowerMax, GetPowerType, savePlayerPower
    local DebugPrint, Refresh, Unlock, Lock, Reset

    -- REGISTER EVENTS
    CassiniEnergy:RegisterEvent("ADDON_LOADED")
    CassiniEnergy:RegisterEvent("PLAYER_ENTERING_WORLD")
    CassiniEnergy:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
    CassiniEnergy:RegisterEvent("PLAYER_UNGHOST")
    CassiniEnergy:RegisterEvent("UNIT_DISPLAYPOWER")
    CassiniEnergy:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

    CassiniEnergy:SetScript("OnEvent", function(self, event, arg1, ...) onEvent(self, event, arg1, ...) end);

    -- INITIALIZATION
    function Init()
        LoadOptions()

        -- Only Energy users have a tick cadence worth tracking. Rogues always use
        -- Energy; Druids use it in Cat Form. Everyone else is disabled.
        local class = select(2, UnitClass("player"))
        if (class ~= "ROGUE" and class ~= "DRUID") then
            DisableAddon()
            return
        end

        EnableAddon()
        CassiniEnergy:Refresh()
    end

    function DisableAddon()
        CassiniEnergy.TickBar.tickbar:Hide()
        CassiniEnergy:SetScript("OnUpdate", nil)
    end

    function EnableAddon()
        CassiniEnergy:SetScript("OnUpdate", function(self, sinceLastUpdate) onUpdate(sinceLastUpdate); end);
        CassiniEnergy.TickBar.tickbar:Show()
    end

    function LoadOptions()
        CassiniEnergy_Options = CassiniEnergy_Options or CassiniEnergyUtils:deepcopy(defaults)

        for key,value in pairs(defaults) do
            if (CassiniEnergy_Options[key] == nil) then
                CassiniEnergy_Options[key] = value
            end
        end

        CassiniEnergy_Options.unlocked = false
    end

    function onEvent(self, event, arg1, ...)
        if event == "ADDON_LOADED" then
            if arg1 == ADDON_NAME then
                Init()
            end
        end

        if not CassiniEnergy_Options or not CassiniEnergy_Options.enabled then
            return
        end

        if event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_EQUIPMENT_CHANGED" or event == "PLAYER_UNGHOST" then
            savePlayerPower()
        end

        -- Shifting forms (e.g. a Druid entering/leaving Cat Form) swaps the power
        -- pool out from under us; re-baseline so the jump isn't misread as a tick.
        if event == "UNIT_DISPLAYPOWER" and arg1 == "player" then
            savePlayerPower()
        end

        if event == "COMBAT_LOG_EVENT_UNFILTERED" then
            onCombatLogEvent()
        end
    end

    function onUpdate(sinceLastUpdate)
        if (not CassiniEnergy_Options.enabled) or UnitIsDead("player") then
            CassiniEnergy.TickBar.tickbar:Hide()
            return
        end

        -- time needs to be defined for this to work
        if (GetTime() == nil) then
            savePlayerPower()
            return
        end

        ReconcilePower()

        CassiniEnergy.TickBar:OnUpdate()
    end

    -- Accumulate power gains that are attributable to a combat log event, so
    -- ReconcilePower can tell them apart from silent regen ticks.
    function onCombatLogEvent()
        local _, subevent, _, _, _, _, _, destGUID, _, _, _, _, spellName, _, amount, overEnergize, powerType = CombatLogGetCurrentEventInfo()

        if (subevent ~= "SPELL_ENERGIZE" and subevent ~= "SPELL_PERIODIC_ENERGIZE") then
            return
        end

        if (destGUID ~= UnitGUID("player")) then
            return
        end

        DebugPrint("raw "..subevent.." spell="..tostring(spellName).." amount="..tostring(amount).." over="..tostring(overEnergize).." powerType="..tostring(powerType))

        if (powerType == nil) then
            -- legacy energize payload without the overEnergize field: (amount, powerType)
            powerType = overEnergize
            overEnergize = 0
        end

        if (powerType ~= GetPowerType()) then
            return
        end

        local gained = (amount or 0) - (overEnergize or 0)
        if (gained > 0) then
            explainedGain = explainedGain + gained
        end

        DebugPrint("energize +"..gained.." ("..tostring(spellName)..")")
    end

    -- Classify the net power change since the last frame using the energize ledger.
    -- Runs once per frame, after all of the frame's events, so combat log entries
    -- and the power change they explain are always seen together.
    function ReconcilePower()
        local current = GetPower()
        local delta = current - CassiniEnergy.previousPower

        if (delta > 0) then
            local residual = delta - explainedGain

            if (residual > 0) then
                -- Power not accounted for by any combat log event: a regen tick.
                -- Every unexplained gain re-anchors the 2s clock to the server's
                -- actual cadence.
                local offset = CassiniEnergy.TickBar.TickOffset(GetTime())
                CassiniEnergy.TickBar:OnTick()
                DebugPrint("tick +"..residual..(offset and string.format(" (offset %.2f)", offset) or ""))
            end
        end

        explainedGain = 0
        CassiniEnergy.previousPower = current
    end

    function GetPower()
        return UnitPower("player", GetPowerType())
    end

    function GetPowerMax()
        return UnitPowerMax("player", GetPowerType())
    end

    function GetPowerType()
        return 3 -- Energy
    end

    function savePlayerPower()
        CassiniEnergy.previousPower = GetPower()
        explainedGain = 0
    end

    function DebugPrint(msg)
        if (CassiniEnergy.debug) then
            print("|cffffe000CassiniEnergy|r "..msg)
        end
    end

    function Refresh()
        CassiniEnergy.TickBar:Refresh()
    end

    function Unlock()
        CassiniEnergy_Options.unlocked = true
        CassiniEnergy.TickBar:Unlock()
    end

    function Lock()
        CassiniEnergy_Options.unlocked = false
        CassiniEnergy.TickBar:Lock()
    end

    function Reset()
        CassiniEnergy.TickBar:Reset()

        CassiniEnergy_Options = CassiniEnergyUtils:deepcopy(defaults)

        Init()
    end

    -- Expose Field Variables and Functions
    CassiniEnergy.Unlock = Unlock
    CassiniEnergy.Lock = Lock
    CassiniEnergy.Reset = Reset
    CassiniEnergy.Refresh = Refresh
    CassiniEnergy.GetPower = GetPower
    CassiniEnergy.GetPowerMax = GetPowerMax
    CassiniEnergy.GetPowerType = GetPowerType
    CassiniEnergy.DebugPrint = DebugPrint

end
