dofile("harness.lua")

-- Integrated: takes the Player frame mana bar's size and place.
Load()
local bar = CassiniEnergy.TickBar.tickbar
Check("integrated bar matches the mana bar", bar._w == 119 and bar._h == 12)
Check("integrated bar sits on the mana bar", bar._points[1] and bar._points[1][2] == "PlayerFrame" and bar._points[1][4] == 111)

-- Free-standing: uses the saved size and position.
CassiniEnergy_Options.integrateIntoPlayerFrame = false
CassiniEnergy:Refresh()
Check("free bar uses the saved size", bar._w == 117 and bar._h == 11)
Check("free bar uses the saved position", bar._points[1][1] == "TOPLEFT" and bar._points[1][2] == 90)

-- Other classes have nothing to track.
Reset()
CLASS = "WARRIOR"
Load()
Check("disabled for non-energy classes", not CassiniEnergy.TickBar.tickbar:IsShown())
Done()
