-- The single bar this addon draws: a progress bar that fills toward the next
-- predicted energy regen tick. Kept as a file-local table (not a global) so it
-- can coexist with FiveSecondRule's own TickBar.
local TickBar = {}

do -- private scope

    -- Declare Field Variables
    local tickbar = CreateFrame("StatusBar", "CassiniEnergy Statusbar - Energy Ticks", UIParent)
    local powerRegenTime = 2 -- energy ticks on a ~2 second cadence
    local tickAnchor = nil -- time of the last confirmed regen tick; the 2s clock free-runs from here
    local lastConfirmedTick = nil -- when a real tick last confirmed the cadence (tickAnchor free-runs, this does not)

    -- FORWARD DECLARATIONS (all local; nothing leaks to the global namespace)
    local Refresh, Lock, Unlock, Reset, OnTick, TickOffset, OnUpdate, UpdateProgress
    local onMouseDown, onMouseUp

    function Refresh()
        -- This function updates all properties on the tickbar that are dependant on options

        -- POSITION, SIZE
        tickbar:ClearAllPoints()
        tickbar:SetFrameStrata(CassiniEnergy_Options.frameStrata or "MEDIUM")
        if CassiniEnergy_Options.integrateIntoPlayerFrame then
            local pframe = PlayerFrameManaBar;
            local point, relativeTo, relativePoint, xOfs, yOfs = PlayerFrameManaBar:GetPoint()

            -- POSITION, SIZE
            tickbar:SetWidth(pframe:GetWidth())
            tickbar:SetHeight(pframe:GetHeight())
            tickbar:SetPoint(point, relativeTo, relativePoint, xOfs + 5, yOfs)
        else
            tickbar:SetWidth(CassiniEnergy_Options.barWidth)
            tickbar:SetHeight(CassiniEnergy_Options.barHeight)
            tickbar:SetPoint("TOPLEFT", CassiniEnergy_Options.barLeft, CassiniEnergy_Options.barTop)
        end

        -- VALUE
        tickbar:SetMinMaxValues(0, powerRegenTime)

        -- DRAGGING
        tickbar:SetScript("OnMouseDown", function(self, button) onMouseDown(button); end)
        tickbar:SetScript("OnMouseUp", function(self, button) onMouseUp(button); end)
        tickbar:SetMovable(true)
        tickbar:SetResizable(true)
        tickbar:EnableMouse(CassiniEnergy_Options.unlocked)
        tickbar:SetClampedToScreen(true)

        -- FOREGROUND
        tickbar:SetStatusBarTexture("Interface\\TARGETINGFRAME\\UI-StatusBar")
        tickbar:GetStatusBarTexture():SetHorizTile(false)
        tickbar:GetStatusBarTexture():SetVertTile(false)

        if CassiniEnergy_Options.integrateIntoPlayerFrame then
            tickbar:SetStatusBarColor(0, 0, 0, 0)
        else
            local fgc = CassiniEnergy_Options.energyTicksColor
            tickbar:SetStatusBarColor(fgc[1], fgc[2], fgc[3], fgc[4])

            if CassiniEnergy_Options.flat then
                tickbar:GetStatusBarTexture():SetColorTexture(fgc[1], fgc[2], fgc[3], fgc[4])
            end
        end


        -- BACKGROUND
        if (not tickbar.bg) then
            tickbar.bg = tickbar:CreateTexture(nil, "BACKGROUND")
        end
        tickbar.bg:SetTexture("Interface\\TARGETINGFRAME\\UI-StatusBar")
        tickbar.bg:SetAllPoints(true)

        if CassiniEnergy_Options.integrateIntoPlayerFrame then
            tickbar.bg:SetVertexColor(0, 0, 0)
            tickbar.bg:SetAlpha(0)
        else
            local bgc = CassiniEnergy_Options.energyTicksBackgroundColor
            tickbar.bg:SetVertexColor(bgc[1], bgc[2], bgc[3])
            tickbar.bg:SetAlpha(bgc[4])

            if CassiniEnergy_Options.flat then
                tickbar.bg:SetColorTexture(bgc[1], bgc[2], bgc[3], bgc[4])
            end
        end

        -- TEXT
        if (not tickbar.value) then
            tickbar.value = tickbar:CreateFontString(nil, "OVERLAY")
        end
        tickbar.value:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
        tickbar.value:SetJustifyH("LEFT")
        tickbar.value:SetShadowOffset(1, -1)
        tickbar.value:SetTextColor(1, 1, 1, 1)
        tickbar.value:SetPoint("LEFT", tickbar, "LEFT", 4, 0)
        CassiniEnergy.UIFactory:SetDefaultFont(tickbar)

        -- SPARK
        if (CassiniEnergy_Options.showSpark) then
            if (not tickbar.bg.spark) then
                local spark = tickbar:CreateTexture(nil, "OVERLAY")
                spark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
                spark:SetWidth(16)
                spark:SetVertexColor(1, 1, 1)
                spark:SetBlendMode("ADD")
                tickbar.bg.spark = spark
            end
        else
            if (tickbar.bg.spark) then
                tickbar.bg.spark:SetTexture(nil)
                tickbar.bg.spark = nil
            end
        end
    end

    function Lock()
        tickbar:EnableMouse(false)
        tickbar:StopMovingOrSizing()
        tickbar.resizing = nil
        tickbar:SetValue(0)
        tickbar:Hide()
    end

    function Unlock()
        tickbar:EnableMouse(true)
        tickbar:SetValue(powerRegenTime)
        tickbar:Show()
    end

    function Reset()
        tickbar:SetUserPlaced(false)
    end

    -- Dragging / resizing the bar while it is unlocked.
    function onMouseDown(button)
        if button == "LeftButton" then
            tickbar:StartMoving()
        elseif button == "RightButton" then
            tickbar:StartSizing("BOTTOMRIGHT")
            tickbar.resizing = 1
        end
    end

    function onMouseUp()
        tickbar:StopMovingOrSizing();
        tickbar.resizing = nil

        CassiniEnergy_Options.barLeft = tickbar:GetLeft()
        CassiniEnergy_Options.barTop = -1 * (GetScreenHeight() - tickbar:GetTop())
        CassiniEnergy_Options.barWidth = tickbar:GetWidth()
        CassiniEnergy_Options.barHeight = tickbar:GetHeight()

        Refresh()

        if CassiniEnergy.OptionsPanelFrame then
            CassiniEnergy.OptionsPanelFrame:UpdateOptionValues()
        end
    end

    -- Called by CassiniEnergy.ReconcilePower when a confirmed regen tick is
    -- observed. Resyncs the 2s clock to the server's actual tick cadence.
    function OnTick()
        tickAnchor = GetTime()
        lastConfirmedTick = tickAnchor
    end

    -- Seconds between `now` and the nearest predicted tick on the known cadence.
    -- Returns nil until a real tick has confirmed the cadence.
    function TickOffset(now)
        if (not lastConfirmedTick) then
            return nil
        end

        local phase = (now - tickAnchor) % powerRegenTime
        return math.min(phase, powerRegenTime - phase)
    end

    function OnUpdate()
        local power = CassiniEnergy.GetPower()
        local powerMax = CassiniEnergy.GetPowerMax()

        -- No energy pool right now (e.g. a Druid out of Cat Form). Nothing to tick.
        if (powerMax <= 0) then
            if (not CassiniEnergy_Options.unlocked) then
                tickbar:Hide()
            end
            return
        end

        local hasFullPower = power >= powerMax

        local shouldShow
        if (hasFullPower) then
            shouldShow = CassiniEnergy_Options.alwaysShowTicks
        else
            -- Energy is always regenerating toward full, so the cadence is always
            -- meaningful while below max.
            shouldShow = true
        end

        if (shouldShow) then
            tickbar:Show()
            UpdateProgress()
        else
            if (not CassiniEnergy_Options.unlocked) then
                tickbar:Hide()
            end
        end
    end

    function UpdateProgress()
        local now = GetTime()

        if (not tickAnchor) then
            tickAnchor = now
        end

        -- Free-run on the last confirmed tick instead of re-anchoring to frame time,
        -- so the bar keeps phase with the server even when a tick goes undetected
        -- (full energy, missed event).
        if (now - tickAnchor >= powerRegenTime) then
            tickAnchor = tickAnchor + math.floor((now - tickAnchor) / powerRegenTime) * powerRegenTime
        end

        local val = (tickAnchor + powerRegenTime) - now
        tickbar:SetValue(powerRegenTime - val)

        if (CassiniEnergy_Options.showText == true) then
            tickbar.value:SetText(string.format("%.1f", val).."s")
        else
            tickbar.value:SetText("")
        end

        if (CassiniEnergy_Options.showSpark) then
            local positionLeft = math.min(CassiniEnergy_Options.barWidth * (1 - (val/powerRegenTime)), CassiniEnergy_Options.barWidth)
            tickbar.bg.spark:SetPoint("CENTER", tickbar.bg, "LEFT", positionLeft-2, 0)
        end
    end

    -- Expose Field Variables and Functions
    TickBar.tickbar = tickbar
    TickBar.Refresh = Refresh
    TickBar.Lock = Lock
    TickBar.Unlock = Unlock
    TickBar.OnUpdate = OnUpdate
    TickBar.OnTick = OnTick
    TickBar.TickOffset = TickOffset
    TickBar.Reset = Reset

    CassiniEnergy.TickBar = TickBar

end

return TickBar
