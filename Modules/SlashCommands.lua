-- COMMANDS
SLASH_CASSINIENERGY1 = '/cassinienergy';
SLASH_CASSINIENERGY2 = '/ce';

function SlashCmdList.CASSINIENERGY(msg, editbox)
    local cmd = msg:lower()

    if cmd == "unlock" or cmd == "u" then
        print("CassiniEnergy - UNLOCKED.")
        CassiniEnergy:Unlock()
    end

    if cmd == "lock" or cmd == "l" then
        print("CassiniEnergy - LOCKED.")
        CassiniEnergy:Lock()
    end

    if cmd == "reset" then
        print("CassiniEnergy - RESET ALL SETTINGS")
        CassiniEnergy:Reset()
    end

    if cmd == "enable" or cmd == "enabled" then
        print("CassiniEnergy - ENABLED")
        CassiniEnergy_Options.enabled = true
        CassiniEnergy:Refresh()
    end

    if cmd == "disable" or cmd == "disabled" then
        print("CassiniEnergy - DISABLED")
        CassiniEnergy_Options.enabled = false
        CassiniEnergy:Refresh()
    end

    if cmd == "debug" then
        CassiniEnergy.debug = not CassiniEnergy.debug
        print("CassiniEnergy - DEBUG "..(CassiniEnergy.debug and "ON" or "OFF"))
    end

    if cmd == "" or cmd == "help" then
        Settings.OpenToCategory(CassiniEnergy.OptionsPanelFrame.optionsPanel.category:GetID())
    end
end
