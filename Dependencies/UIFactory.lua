CassiniEnergy.UIFactory = {}

function CassiniEnergy.UIFactory:MakeCheckbox(name, parent, tooltip_text)
    local cb = CreateFrame("CheckButton", name, parent, "UICheckButtonTemplate")
    cb:SetWidth(25)
    cb:SetHeight(25)
    cb:Show()

    local cblabel = cb:CreateFontString(nil, "OVERLAY")
    cblabel:SetFontObject("GameFontHighlight")
    cblabel:SetPoint("LEFT", cb,"RIGHT", 5,0)
    cb.label = cblabel

    cb.tooltip = tooltip_text

    -- Wire the stored tooltip text to the actual GameTooltip API. Empty strings
    -- (checkboxes that fold their note into the visible label) stay silent.
    cb:SetScript("OnEnter", function(self)
        if self.tooltip and self.tooltip ~= "" then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(self.tooltip, nil, nil, nil, nil, true)
            GameTooltip:Show()
        end
    end)
    cb:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)

    return cb
end

function CassiniEnergy.UIFactory:MakeText(parent, text, size)
    local text_obj = parent:CreateFontString(nil, "ARTWORK")
    text_obj:SetFont("Fonts/FRIZQT__.ttf", size)
    text_obj:SetJustifyV("MIDDLE")
    text_obj:SetJustifyH("CENTER")
    text_obj:SetText(text)
    return text_obj
end

function CassiniEnergy.UIFactory:MakeEditBox(name, parent, title, w, h, enter_func)
    local edit_box_obj = CreateFrame("EditBox", name, parent, BackdropTemplateMixin and "BackdropTemplate")
    edit_box_obj.title_text = CassiniEnergy.UIFactory:MakeText(edit_box_obj, title, 12)
    edit_box_obj.title_text:SetPoint("TOP", 0, 12)
    edit_box_obj:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile = true,
        tileSize = 26,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4}
    })
    edit_box_obj:SetBackdropColor(0,0,0,1)
    edit_box_obj:SetSize(w, h)
    edit_box_obj:SetMultiLine(false)
    edit_box_obj:SetAutoFocus(false)
    edit_box_obj:SetMaxLetters(4)
    edit_box_obj:SetJustifyH("CENTER")
	edit_box_obj:SetJustifyV("MIDDLE")
    edit_box_obj:SetFontObject(GameFontNormal)
    edit_box_obj:SetScript("OnEnterPressed", function(self)
        enter_func(self)
        self:ClearFocus()
    end)
    edit_box_obj:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)

    -- Title label is drawn above the box itself; tell the stack layout to
    -- reserve room for it instead of letting the next row overlap it.
    edit_box_obj.layoutTopPadding = 26

    return edit_box_obj
end

function CassiniEnergy.UIFactory:MakeButton(name, parent, width, height, text, textSize, color, on_click_func)
    local button = CreateFrame('Button', name, parent, "UIPanelButtonTemplate")
    button:SetSize(width, height)
    button:SetText(text)
    button:SetScript('OnClick', on_click_func)
    return button
end

function CassiniEnergy.UIFactory:MakeSlider(name, parent, title, min, max, step, onValueChanged)
    local slider = CreateFrame("Slider", name, parent, "MinimalSliderTemplate")
    slider:SetSize(150, 25)
    slider:SetMinMaxValues(min, max)
    slider:SetValueStep(step)
    if slider.SetObeyStepOnDrag then
        slider:SetObeyStepOnDrag(true)
    end

    slider.title_text = CassiniEnergy.UIFactory:MakeText(slider, title, 12)
    slider.title_text:SetPoint("BOTTOMLEFT", slider, "TOPLEFT", 4, 4)

    slider.value_text = CassiniEnergy.UIFactory:MakeText(slider, "0%", 12)
    slider.value_text:SetPoint("LEFT", slider, "RIGHT", 4, 0)

    slider:SetScript("OnValueChanged", function(self, value)
        if self.value_text then
            self.value_text:SetText(string.format("%d%%", value * 100))
        end
        if onValueChanged then
            onValueChanged(self, value)
        end
    end)

    -- Title label sits above the slider track; reserve room for it in stack layouts.
    slider.layoutTopPadding = 26

    return slider
end

function CassiniEnergy.UIFactory:MakeColor(r,g,b,a)
    return {r = r, g = g, b = b, a = a}
end

function CassiniEnergy.UIFactory:MakeColorPicker(name, parent, title, color, OnShow)
    local colorPickerFrame = CreateFrame("Frame", name, parent, BackdropTemplateMixin and "BackdropTemplate")
    colorPickerFrame.title_text = CassiniEnergy.UIFactory:MakeText(colorPickerFrame, title, 12)
    colorPickerFrame.title_text:SetPoint("TOP", 0, 16)
    colorPickerFrame:SetSize(75, 25)
    colorPickerFrame.texture = colorPickerFrame:CreateTexture(nil, "BACKGROUND")
    colorPickerFrame:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile = true,
        tileSize = 26,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4}
    })
    colorPickerFrame:SetBackdropColor(color[1], color[2], color[3], color[4])
    colorPickerFrame.texture:SetAllPoints(true)
    colorPickerFrame:SetScript("OnMouseDown", OnShow)

    -- Title label sits above the swatch; reserve room for it in stack layouts.
    colorPickerFrame.layoutTopPadding = 26

    return colorPickerFrame
end

function CassiniEnergy.UIFactory:ShowColorPicker(r, g, b, a, changedCallback, enableOpacity)
    local previousValues = {r, g, b, a}
    local hasOpacity = enableOpacity == nil and true or enableOpacity

    local info = {
        swatchFunc = function()
            local newR, newG, newB = ColorPickerFrame:GetColorRGB()
            local newA = hasOpacity and ColorPickerFrame:GetColorAlpha() or a
            changedCallback({newR, newG, newB, newA})
        end,
        hasOpacity = hasOpacity,
        opacityFunc = hasOpacity and function()
            local newR, newG, newB = ColorPickerFrame:GetColorRGB()
            local newA = ColorPickerFrame:GetColorAlpha()
            changedCallback({newR, newG, newB, newA})
        end or nil,
        opacity = a,
        cancelFunc = function()
            -- Cancel was clicked, instantly revert to the original color
            changedCallback(previousValues)
        end,

        r = r,
        g = g,
        b = b,
    }

    ColorPickerFrame:SetupColorPickerAndShow(info)
end

function CassiniEnergy.UIFactory:SetDefaultFont(target)
    local height = target:GetHeight()
    local remainder = CassiniEnergyUtils:modulus(height, 2)
    local px = height - remainder

    px = math.min(px, 20)
    px = math.max(px, 1)

    if (px < 8) then
        target.value:SetTextColor(0, 0, 0, 0)
    else
        target.value:SetTextColor(0.95, 0.95, 0.95)
    end

    target.value:SetFont("Fonts\\FRIZQT__.TTF", px, "OUTLINE")
end

-- STACK LAYOUT
--
-- A small vertical/horizontal flow layout. Widgets are placed purely based on
-- the order they're added and their own size -- never an absolute Y. To
-- reorder, insert, or remove a control, just move/add/delete the matching
-- :Add()/:Row() call in the caller; everything placed after it re-flows on
-- its own.
--
-- Widgets that draw a label above their own frame (edit boxes, color
-- swatches, sliders -- see their layoutTopPadding above) are automatically
-- given extra headroom so their label never collides with the row above.
function CassiniEnergy.UIFactory:CreateStack(parent, x, y, opts)
    opts = opts or {}

    local stack = {
        parent = parent,
        x = x or 0,
        y = y or 0,
        rowGap = opts.rowGap or 10,
        colGap = opts.colGap or 15,
    }

    -- Places a single widget below the last one added and advances the
    -- cursor by its height (plus any layoutTopPadding/layoutBottomPadding the
    -- widget declares) and the row gap.
    --
    -- itemOpts (all optional):
    --   height - override the widget's measured height for cursor purposes
    --   gap    - override the gap left after this widget
    --   dx, dy - nudge the widget without affecting the cursor (for template
    --            quirks, e.g. a dropdown's built-in left inset)
    function stack:Add(widget, itemOpts)
        itemOpts = itemOpts or {}

        local topPad = widget.layoutTopPadding or 0
        local bottomPad = widget.layoutBottomPadding or 0

        widget:SetPoint("TOPLEFT", self.parent, "TOPLEFT", self.x + (itemOpts.dx or 0), self.y - topPad + (itemOpts.dy or 0))

        local height = itemOpts.height or widget:GetHeight() or 0
        self.y = self.y - topPad - height - bottomPad - (itemOpts.gap or self.rowGap)

        return widget
    end

    -- Places several widgets side by side on one row, then advances the
    -- cursor by the tallest item's total span (including label padding) plus
    -- the row gap. Each entry in `items` is either a plain widget or a
    -- { widget, width, height, dx, dy } spec (same meaning as in :Add).
    function stack:Row(items, rowOpts)
        rowOpts = rowOpts or {}

        local cursorX = self.x
        local maxSpan = 0

        for _, item in ipairs(items) do
            local widget, width, height, dx, dy
            if item.widget then
                widget, width, height, dx, dy = item.widget, item.width, item.height, item.dx, item.dy
            else
                widget = item
            end

            local topPad = widget.layoutTopPadding or 0
            local bottomPad = widget.layoutBottomPadding or 0

            widget:SetPoint("TOPLEFT", self.parent, "TOPLEFT", cursorX + (dx or 0), self.y - topPad + (dy or 0))

            width = width or widget:GetWidth() or 0
            height = height or widget:GetHeight() or 0

            cursorX = cursorX + width + (rowOpts.colGap or self.colGap)
            maxSpan = math.max(maxSpan, topPad + height + bottomPad)
        end

        self.y = self.y - maxSpan - (rowOpts.gap or self.rowGap)
    end

    -- Adds vertical whitespace without placing a widget.
    function stack:Space(height)
        self.y = self.y - height
    end

    return stack
end
