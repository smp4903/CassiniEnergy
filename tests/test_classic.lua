dofile("harness.lua")
Load()
Check("uses the combat log", CassiniEnergy._events.COMBAT_LOG_EVENT_UNFILTERED == true)

POWER = 50
Fire("PLAYER_ENTERING_WORLD")
Update(10.0)
POWER = 70
Update(10.5)
Check("an unexplained gain is a tick", Offset(12.5) < 0.01)

-- Thistle Tea: explained by the combat log, so not a tick.
CombatLogEvent = { 0, "SPELL_ENERGIZE", false, "", "", 0, 0, "Player-1", "", 0, 0, 7676, "Thistle Tea", 1, 40, 0, 3 }
NOW = 11.2
Fire("COMBAT_LOG_EVENT_UNFILTERED")
POWER = 100
Update(11.2)
Check("an energize doesn't move the grid", Offset(12.5) < 0.01)

CassiniEnergy_Options.alwaysShowTicks = false
Update(11.3)
Check("hidden at full energy", not BarShown())

CLASS, POWER_MAX = "DRUID", 0
Update(11.4)
Check("hidden without an energy pool", not BarShown())
Done()
