-- CONFIGURE
local ADDON_NAME = "CassiniEnergy"
local NAMESPACE = CassiniEnergy

-- STATE
local frame = CreateFrame("Frame", nil, InterfaceOptionsFrame)
local colorPickerStateSet = false

-- LOADER
local OptionsPanelFrame = CreateFrame("Frame", ADDON_NAME.."OptionsPanelFrame")

-- EXPOSE OPTIONS PANEL TO NAMESPACE
NAMESPACE.OptionsPanelFrame = OptionsPanelFrame

OptionsPanelFrame:RegisterEvent("PLAYER_LOGIN")
OptionsPanelFrame:SetScript("OnEvent",
    function(self, event, arg1, ...)
        if event == "PLAYER_LOGIN" then
            if not OptionsPanelFrame.optionsPanel then
                OptionsPanelFrame.optionsPanel = OptionsPanelFrame:CreateGUI(ADDON_NAME)
                OptionsPanelFrame.optionsPanel.category = Settings.RegisterCanvasLayoutCategory(OptionsPanelFrame.optionsPanel, ADDON_NAME)
                Settings.RegisterAddOnCategory(OptionsPanelFrame.optionsPanel.category)
            end
        end
    end
);

-- LOADING VALUES

function OptionsPanelFrame:UpdateOptionValues()
    if frame == nil or frame.content == nil then
        return
    end

    frame.content.flat:SetChecked(CassiniEnergy_Options.flat == true)
    frame.content.showText:SetChecked(CassiniEnergy_Options.showText == true)
    frame.content.showSpark:SetChecked(CassiniEnergy_Options.showSpark == true)
    frame.content.alwaysShowTicks:SetChecked(CassiniEnergy_Options.alwaysShowTicks == true)
    frame.content.integrateIntoPlayerFrame:SetChecked(CassiniEnergy_Options.integrateIntoPlayerFrame == true)

    frame.content.barWidth:SetText(tostring(CassiniEnergy_Options.barWidth))
    frame.content.barHeight:SetText(tostring(CassiniEnergy_Options.barHeight))

    frame.content.barLeft:SetText(tostring(CassiniEnergy_Options.barLeft))
    frame.content.barTop:SetText(tostring(CassiniEnergy_Options.barTop))

    if frame.content.frameStrataDropdown then
        UIDropDownMenu_SetSelectedValue(frame.content.frameStrataDropdown, CassiniEnergy_Options.frameStrata or "MEDIUM")
    end

    local etfgc = CassiniEnergy_Options.energyTicksColor
    frame.content.energyTicksForegroundColorFrame:SetBackdropColor(etfgc[1], etfgc[2], etfgc[3], etfgc[4])
    frame.content.energyTicksForegroundAlphaSlider:SetValue(etfgc[4])
    frame.content.energyTicksForegroundAlphaSlider.value_text:SetText(string.format("%d%%", etfgc[4] * 100))

    local etbgc = CassiniEnergy_Options.energyTicksBackgroundColor
    frame.content.energyTicksBackgroundColorFrame:SetBackdropColor(etbgc[1], etbgc[2], etbgc[3], etbgc[4])
    frame.content.energyTicksBackgroundAlphaSlider:SetValue(etbgc[4])
    frame.content.energyTicksBackgroundAlphaSlider.value_text:SetText(string.format("%d%%", etbgc[4] * 100))

    if (CassiniEnergy_Options.integrateIntoPlayerFrame) then
        frame.content.energyTicksTitle:Hide()
        frame.content.energyTicksForegroundColorFrame:Hide()
        frame.content.energyTicksBackgroundColorFrame:Hide()
        frame.content.energyTicksForegroundAlphaSlider:Hide()
        frame.content.energyTicksBackgroundAlphaSlider:Hide()
        frame.content.toggleLock:Hide()
    else
        frame.content.energyTicksTitle:Show()
        frame.content.energyTicksForegroundColorFrame:Show()
        frame.content.energyTicksBackgroundColorFrame:Show()
        frame.content.energyTicksForegroundAlphaSlider:Show()
        frame.content.energyTicksBackgroundAlphaSlider:Show()
        frame.content.toggleLock:Show()
    end

    CassiniEnergy:Refresh()
end

-- GUI
function OptionsPanelFrame:CreateGUI(name, parent)
    if (not frame) then
        frame = CreateFrame("Frame", nil, InterfaceOptionsFrame)
    end

    frame:Hide()
    frame.parent = parent
    frame.name = name

    -- TITLE
    if (not frame.title) then
        local title = frame:CreateFontString(ADDON_NAME.."Title", "OVERLAY", "GameFontNormalLarge")
        title:SetPoint("TOPLEFT", 10, -15)
        title:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", 10, -45)
        title:SetJustifyH("LEFT")
        title:SetJustifyV("TOP")
        title:SetText(name)
        frame.title = title
    end

    -- ROOT (scrollable)
    if (not frame.scrollFrame) then
        local scrollFrame = CreateFrame("ScrollFrame", ADDON_NAME.."ScrollFrame", frame, "UIPanelScrollFrameTemplate")
        scrollFrame:SetPoint("TOPLEFT", 10, -35)     -- leaves a strip above for the Unlock/Lock and Reset buttons
        scrollFrame:SetPoint("BOTTOMRIGHT", -30, 0) -- leaves room on the right for the scrollbar
        frame.scrollFrame = scrollFrame

        local content = CreateFrame("Frame", "CassiniEnergyOptionsContent", scrollFrame)
        content:SetPoint("TOPLEFT", 0, 0)
        content:SetWidth(scrollFrame:GetWidth())
        scrollFrame:SetScrollChild(content)
        frame.content = content

        -- The scroll child's width isn't known until the panel has actually
        -- been sized by the Settings canvas, so keep it in sync going forward.
        scrollFrame:SetScript("OnSizeChanged", function(self, width)
            content:SetWidth(width)
        end)
    end

    -- LAYOUT
    -- Two independent column stacks
    local leftCol = CassiniEnergy.UIFactory:CreateStack(frame.content, 10, 0)
    local rightCol = CassiniEnergy.UIFactory:CreateStack(frame.content, 300, 0)

    leftCol:Space(20)
    rightCol:Space(20)

    -- FLAT DESIGN
    if (not frame.content.flat) then
        local flat = CassiniEnergy.UIFactory:MakeCheckbox(ADDON_NAME.."flat", frame.content, "Check to make the bar use a flat color rather than a textured background.")
        flat.label:SetText("Flat bars")
        flat:SetScript("OnClick",function(self,button)
            CassiniEnergy_Options.flat = self:GetChecked()
            CassiniEnergy:Refresh()
        end)
        frame.content.flat = flat
    end
    leftCol:Add(frame.content.flat)

    -- SHOW TEXT?
    if (not frame.content.showText) then
        local showText = CassiniEnergy.UIFactory:MakeCheckbox(ADDON_NAME.."showText", frame.content, "Check to show text on the bar (seconds until the next tick).")
        showText.label:SetText("Show text")
        showText:SetScript("OnClick",function(self,button)
            CassiniEnergy_Options.showText = self:GetChecked()
            CassiniEnergy:Refresh()
        end)
        frame.content.showText = showText
    end
    leftCol:Add(frame.content.showText)

    -- SHOW SPARK?
    if (not frame.content.showSpark) then
        local showSpark = CassiniEnergy.UIFactory:MakeCheckbox(ADDON_NAME.."showSpark", frame.content, "Check to show a glowing spark on the bar.")
        showSpark.label:SetText("Show spark")
        showSpark:SetScript("OnClick",function(self,button)
            CassiniEnergy_Options.showSpark = self:GetChecked()
            CassiniEnergy:Refresh()
        end)
        frame.content.showSpark = showSpark
    end
    leftCol:Add(frame.content.showSpark)

    -- ALWAYS SHOW ENERGY TICKS?
    if (not frame.content.alwaysShowTicks) then
        local alwaysShowTicks = CassiniEnergy.UIFactory:MakeCheckbox(ADDON_NAME.."alwaysShowTicks", frame.content, "Show energy ticks even on full energy.")
        alwaysShowTicks.label:SetText("Always show energy ticks")
        alwaysShowTicks:SetScript("OnClick",function(self,button)
            CassiniEnergy_Options.alwaysShowTicks = self:GetChecked()
            CassiniEnergy:Refresh()
        end)
        frame.content.alwaysShowTicks = alwaysShowTicks
    end
    leftCol:Add(frame.content.alwaysShowTicks)

    -- INTEGRATE INTO PLAYER FRAME ENERGY BAR?
    if (not frame.content.integrateIntoPlayerFrame) then
        local integrateIntoPlayerFrame = CassiniEnergy.UIFactory:MakeCheckbox(ADDON_NAME.."integrateIntoPlayerFrame", frame.content, "Check to integrate the tick spark into the player frame energy bar.")
        integrateIntoPlayerFrame.label:SetText("Integrate into Player frame energy bar")
        integrateIntoPlayerFrame:SetScript("OnClick",function(self,button)
            CassiniEnergy_Options.integrateIntoPlayerFrame = self:GetChecked()
            OptionsPanelFrame:UpdateOptionValues()
            CassiniEnergy:Refresh()
        end)
        frame.content.integrateIntoPlayerFrame = integrateIntoPlayerFrame
    end
    leftCol:Add(frame.content.integrateIntoPlayerFrame)

    -- BAR SIZE
    local barWidth = CassiniEnergy.UIFactory:MakeEditBox(ADDON_NAME.."CountdownWidth", frame.content, "Width", 75, 25, function(self)
        CassiniEnergy_Options.barWidth = tonumber(self:GetText())
        CassiniEnergy:Refresh()
    end)
    barWidth:SetCursorPosition(0)
    frame.content.barWidth = barWidth

    local barHeight = CassiniEnergy.UIFactory:MakeEditBox(ADDON_NAME.."CountdownHeight", frame.content, "Height", 75, 25, function(self)
        CassiniEnergy_Options.barHeight = tonumber(self:GetText())
        CassiniEnergy:Refresh()
    end)
    barHeight:SetCursorPosition(0)
    frame.content.barHeight = barHeight

    rightCol:Row({ frame.content.barWidth, frame.content.barHeight })

    -- BAR POSITION
    local barLeft = CassiniEnergy.UIFactory:MakeEditBox(ADDON_NAME.."BarLeft", frame.content, "X (from left)", 75, 25, function(self)
        CassiniEnergy_Options.barLeft = tonumber(self:GetText())
        CassiniEnergy:Refresh()
    end)
    barLeft:SetCursorPosition(0)
    frame.content.barLeft = barLeft

    local barTop = CassiniEnergy.UIFactory:MakeEditBox(ADDON_NAME.."BarTop", frame.content, "Y (from top)", 75, 25, function(self)
        CassiniEnergy_Options.barTop = tonumber(self:GetText())
        CassiniEnergy:Refresh()
    end)
    barTop:SetCursorPosition(0)
    frame.content.barTop = barTop

    rightCol:Row({ frame.content.barLeft, frame.content.barTop })

    -- FRAME STRATA
    if (not frame.content.frameStrataDropdown) then
        local strataOptions = {
            { text = "BACKGROUND", value = "BACKGROUND" },
            { text = "LOW", value = "LOW" },
            { text = "MEDIUM", value = "MEDIUM" },
            { text = "HIGH", value = "HIGH" },
            { text = "DIALOG", value = "DIALOG" },
            { text = "FULLSCREEN", value = "FULLSCREEN" },
            { text = "FULLSCREEN_DIALOG", value = "FULLSCREEN_DIALOG" },
            { text = "TOOLTIP", value = "TOOLTIP" },
        }

        frame.content.frameStrataLabel = CassiniEnergy.UIFactory:MakeText(frame.content, "Frame Strata", 12)
        frame.content.frameStrataLabel:SetJustifyH("LEFT")

        local strataDropdown = CreateFrame("Frame", ADDON_NAME.."FrameStrataDropdown", frame.content, "UIDropDownMenuTemplate")
        UIDropDownMenu_SetWidth(strataDropdown, 120)
        UIDropDownMenu_JustifyText(strataDropdown, "LEFT")

        UIDropDownMenu_Initialize(strataDropdown, function(self, level)
            for _, option in ipairs(strataOptions) do
                local info = UIDropDownMenu_CreateInfo()
                info.text = option.text
                info.value = option.value
                info.arg1 = option.value
                info.func = function(_, value)
                    CassiniEnergy_Options.frameStrata = value
                    UIDropDownMenu_SetSelectedValue(strataDropdown, value)
                    CassiniEnergy:Refresh()
                end
                info.checked = (CassiniEnergy_Options.frameStrata == option.value)
                UIDropDownMenu_AddButton(info, level)
            end
        end)

        UIDropDownMenu_SetSelectedValue(strataDropdown, CassiniEnergy_Options.frameStrata or "MEDIUM")

        frame.content.frameStrataDropdown = strataDropdown
    end
    rightCol:Add(frame.content.frameStrataLabel, { height = 16, gap = 4 })
    -- UIDropDownMenuTemplate's clickable control is inset ~15px left of the
    -- frame's own anchor point; nudge it back in line with the label above.
    rightCol:Add(frame.content.frameStrataDropdown, { dx = -15, height = 32 })


    -- LOCK TOGGLE AND RESET BUTTON
    local function lockToggled(self)
        if (CassiniEnergy_Options.unlocked) then
            CassiniEnergy:Lock()
            self:SetText("Unlock")
        else
            CassiniEnergy:Unlock()
            self:SetText("Lock")
        end
    end

    local toggleLockText = (CassiniEnergy_Options.unlocked and "Lock" or "Unlock")
    local toggleLock = CassiniEnergy.UIFactory:MakeButton(ADDON_NAME.."LockButton", frame, 60, 20, toggleLockText, 14, CassiniEnergy.UIFactory:MakeColor(1,1,1,1), function(self)
        lockToggled(self)
    end)

    -- RESET BUTTON (fixed top-right chrome, outside the flow)
    local resetButton = CassiniEnergy.UIFactory:MakeButton(ADDON_NAME.."ResetButton", frame, 60, 20, "Reset", 14, CassiniEnergy.UIFactory:MakeColor(1,1,1,1), function(self)
        if (CassiniEnergy_Options.unlocked) then
            lockToggled(toggleLock)
        end

        CassiniEnergy:Reset()
        OptionsPanelFrame:UpdateOptionValues(frame.content)
    end)

    resetButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -15, 0)
    frame.content.resetButton = resetButton

    toggleLock:SetPoint("TOPRIGHT", resetButton, "TOPLEFT", -15, 0)
    frame.content.toggleLock = toggleLock


    -- Below both columns: a single full-width stack for the color/style
    -- section, picking up under whichever column ran longer.
    local styleCol = CassiniEnergy.UIFactory:CreateStack(frame.content, 12, math.min(leftCol.y, rightCol.y) - 10)
    styleCol:Space(20)

    -- ENERGY TICKS BAR STYLE TITLE
    frame.content.energyTicksTitle = CassiniEnergy.UIFactory:MakeText(frame.content, "Energy Ticks Style", 16)
    styleCol:Add(frame.content.energyTicksTitle, { height = 20, gap = 5 })

    -- ENERGY TICKS BAR COLOR PICKERS
    if (not frame.content.energyTicksForegroundColorFrame) then
        frame.content.energyTicksForegroundColorFrame = CassiniEnergy.UIFactory:MakeColorPicker(ADDON_NAME.."EnergyTicksColorFrame",  frame.content, "Foreground", CassiniEnergy_Options.energyTicksColor)
        frame.content.energyTicksForegroundColorFrame:SetScript("OnMouseDown",
            function (self, button)
                local editColor = CassiniEnergyUtils:deepcopy(CassiniEnergy_Options.energyTicksColor)

                CassiniEnergy.UIFactory:ShowColorPicker(editColor[1], editColor[2], editColor[3], editColor[4], function (colorTable)
                    CassiniEnergy_Options.energyTicksColor = colorTable
                    OptionsPanelFrame:UpdateOptionValues()
                end, false)
            end
        )
    end

    if (not frame.content.energyTicksBackgroundColorFrame) then
        frame.content.energyTicksBackgroundColorFrame = CassiniEnergy.UIFactory:MakeColorPicker(ADDON_NAME.."EnergyTicksBackgroundColorFrame", frame.content, "Background",  CassiniEnergy_Options.energyTicksBackgroundColor)
        frame.content.energyTicksBackgroundColorFrame:SetScript("OnMouseDown",
            function (self, button)
                local editColor = CassiniEnergyUtils:deepcopy(CassiniEnergy_Options.energyTicksBackgroundColor)

                CassiniEnergy.UIFactory:ShowColorPicker(editColor[1], editColor[2], editColor[3], editColor[4], function (colorTable)
                    CassiniEnergy_Options.energyTicksBackgroundColor = colorTable
                    OptionsPanelFrame:UpdateOptionValues()
                end, false)
            end
        )
    end

    if (not frame.content.energyTicksForegroundAlphaSlider) then
        frame.content.energyTicksForegroundAlphaSlider = CassiniEnergy.UIFactory:MakeSlider(ADDON_NAME.."EnergyTicksForegroundAlphaSlider", frame.content, "Alpha", 0, 1, 0.01, function(self, value)
            CassiniEnergy_Options.energyTicksColor[4] = value
            OptionsPanelFrame:UpdateOptionValues()
        end)
    end

    if (not frame.content.energyTicksBackgroundAlphaSlider) then
        frame.content.energyTicksBackgroundAlphaSlider = CassiniEnergy.UIFactory:MakeSlider(ADDON_NAME.."EnergyTicksBackgroundAlphaSlider", frame.content, "Alpha", 0, 1, 0.01, function(self, value)
            CassiniEnergy_Options.energyTicksBackgroundColor[4] = value
            OptionsPanelFrame:UpdateOptionValues()
        end)
    end

    styleCol:Row({ frame.content.energyTicksForegroundColorFrame, frame.content.energyTicksForegroundAlphaSlider })
    styleCol:Row({ frame.content.energyTicksBackgroundColorFrame, frame.content.energyTicksBackgroundAlphaSlider })

    -- Size the scroll child to whatever the layout actually ended up needing,
    -- so the scrollbar's range matches the real content instead of clipping
    -- it or leaving dead scroll space. Whichever stack ran lowest wins.
    frame.content:SetHeight(math.abs(math.min(leftCol.y, rightCol.y, styleCol.y)) + 20)

    -- UPDATE VALUES ON SHOW
    frame:SetScript("OnShow", function(self) OptionsPanelFrame:UpdateOptionValues() end)

    return frame
end
