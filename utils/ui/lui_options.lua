--[[
    LuheyUI Options Pages
    Top-down flow layout for the /qui GUI
    Single scrollable content area per tab
]]

local ADDON_NAME, ns = ...
local QUI = LuheyUI
local GUI = QUI.GUI
local LUICore = ns.Addon
local C = GUI.Colors

---------------------------------------------------------------------------
-- CONSTANTS - Match panel width (750px panel)
---------------------------------------------------------------------------
-- local CONTENT_WIDTH = 670  -- No longer used - scroll content now dynamically sizes
local ROW_GAP = 28
local SECTION_GAP = 38
local SECTION_HEADER_GAP = 46  -- Section header height + spacing below underline
local PADDING = 15  -- Standard left/right padding for all content

-- Nine-point anchor options (used for UI element positioning)
local NINE_POINT_ANCHOR_OPTIONS = {
    {value = "TOPLEFT", text = "Top Left"},
    {value = "TOP", text = "Top"},
    {value = "TOPRIGHT", text = "Top Right"},
    {value = "LEFT", text = "Left"},
    {value = "CENTER", text = "Center"},
    {value = "RIGHT", text = "Right"},
    {value = "BOTTOMLEFT", text = "Bottom Left"},
    {value = "BOTTOM", text = "Bottom"},
    {value = "BOTTOMRIGHT", text = "Bottom Right"},
}

---------------------------------------------------------------------------
-- QUAZII RECOMMENDED FPS SETTINGS (58 CVars)
---------------------------------------------------------------------------
local QUAZII_FPS_CVARS = {
    -- Graphics Tab
    ["vsync"] = "0",
    ["LowLatencyMode"] = "3",
    ["MSAAQuality"] = "0",
    ["ffxAntiAliasingMode"] = "0",
    ["alphaTestMSAA"] = "1",
    ["cameraFov"] = "90",

    -- Graphics Quality (Base)
    ["graphicsQuality"] = "9",
    ["graphicsShadowQuality"] = "0",
    ["graphicsLiquidDetail"] = "1",
    ["graphicsParticleDensity"] = "5",
    ["graphicsSSAO"] = "0",
    ["graphicsDepthEffects"] = "0",
    ["graphicsComputeEffects"] = "0",
    ["graphicsOutlineMode"] = "1",
    ["OutlineEngineMode"] = "1",
    ["graphicsTextureResolution"] = "2",
    ["graphicsSpellDensity"] = "0",
    ["spellClutter"] = "1",
    ["spellVisualDensityFilterSetting"] = "1",
    ["graphicsProjectedTextures"] = "1",
    ["projectedTextures"] = "1",
    ["graphicsViewDistance"] = "3",
    ["graphicsEnvironmentDetail"] = "0",
    ["graphicsGroundClutter"] = "0",

    -- Advanced Tab
    ["gxTripleBuffer"] = "0",
    ["textureFilteringMode"] = "5",
    ["graphicsRayTracedShadows"] = "0",
    ["rtShadowQuality"] = "0",
    ["ResampleQuality"] = "4",
    ["ffxSuperResolution"] = "1",
    ["VRSMode"] = "0",
    ["GxApi"] = "D3D12",
    ["physicsLevel"] = "0",
    ["maxFPS"] = "144",
    ["maxFPSBk"] = "60",
    ["targetFPS"] = "61",
    ["useTargetFPS"] = "0",
    ["ResampleSharpness"] = "0.2",
    ["Contrast"] = "75",
    ["Brightness"] = "50",
    ["Gamma"] = "1",

    -- Additional Optimizations
    ["particulatesEnabled"] = "0",
    ["clusteredShading"] = "0",
    ["volumeFogLevel"] = "0",
    ["reflectionMode"] = "0",
    ["ffxGlow"] = "0",
    ["farclip"] = "5000",
    ["horizonStart"] = "1000",
    ["horizonClip"] = "5000",
    ["lodObjectCullSize"] = "35",
    ["lodObjectFadeScale"] = "50",
    ["lodObjectMinSize"] = "0",
    ["doodadLodScale"] = "50",
    ["entityLodDist"] = "7",
    ["terrainLodDist"] = "350",
    ["TerrainLodDiv"] = "512",
    ["waterDetail"] = "1",
    ["rippleDetail"] = "0",
    ["weatherDensity"] = "3",
    ["entityShadowFadeScale"] = "15",
    ["groundEffectDist"] = "40",
    ["ResampleAlwaysSharpen"] = "1",

    -- Special Hacks
    ["cameraDistanceMaxZoomFactor"] = "2.6",
    ["CameraReduceUnexpectedMovement"] = "1",
}

---------------------------------------------------------------------------
-- HELPER: Get texture list from LSM
---------------------------------------------------------------------------
local LSM = LibStub("LibSharedMedia-3.0", true)

local function GetTextureList()
    local textures = {}
    if LSM then
        for _, name in ipairs(LSM:List("statusbar")) do
            table.insert(textures, {value = name, text = name})
        end
    else
        textures = {{value = "Solid", text = "Solid"}}
    end
    return textures
end

-- Hidden frame for pre-warming fonts (forces WoW to load font files)
local fontPrewarmFrame = nil

local function GetFontList()
    local fonts = {}
    if LSM then
        -- Create a hidden frame for pre-warming fonts if needed
        if not fontPrewarmFrame then
            fontPrewarmFrame = CreateFrame("Frame", nil, UIParent)
            fontPrewarmFrame:SetSize(1, 1)
            fontPrewarmFrame:SetPoint("TOPLEFT", -9999, 9999)  -- Off-screen
            fontPrewarmFrame.text = fontPrewarmFrame:CreateFontString(nil, "OVERLAY")
            fontPrewarmFrame.text:SetPoint("CENTER")
            fontPrewarmFrame.text:SetFont("Fonts\\FRIZQT__.TTF", 12, "")  -- Set default font first
            fontPrewarmFrame.text:SetText("A")  -- Need some text for font to load
        end

        for _, name in ipairs(LSM:List("font")) do
            local path = LSM:Fetch("font", name) or ""
            local pathLower = path:lower()

            -- Only allow fonts from WoW defaults, LuheyUI, or SharedMedia
            local isWoWFont = pathLower:find("^fonts\\") ~= nil or pathLower:find("^fonts/") ~= nil
            local isQuaziiFont = pathLower:find("quaziiui") ~= nil
            local isSharedMediaFont = pathLower:find("sharedmedia") ~= nil

            if (isWoWFont or isQuaziiFont or isSharedMediaFont) and path ~= "" then
                -- Pre-warm the font by actually applying it (forces WoW to load the font file)
                local success = pcall(function()
                    fontPrewarmFrame.text:SetFont(path, 12, "")
                end)
                if success then
                    table.insert(fonts, {value = name, text = name})
                end
            end
        end
    else
        fonts = {{value = "Friz Quadrata TT", text = "Friz Quadrata TT"}}
    end
    return fonts
end

local function GetBorderList()
    local borders = {{value = "None", text = "None (Solid)"}}
    if LSM then
        for _, name in ipairs(LSM:List("border")) do
            table.insert(borders, {value = name, text = name})
        end
    end
    return borders
end

---------------------------------------------------------------------------
-- HELPER: Create scrollable content frame
---------------------------------------------------------------------------
local function CreateScrollableContent(parent)
    local scrollFrame = CreateFrame("ScrollFrame", nil, parent, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 5, -5)
    scrollFrame:SetPoint("BOTTOMRIGHT", -28, 5)

    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetWidth(scrollFrame:GetWidth())  -- Dynamic width based on scroll frame
    content:SetHeight(1)
    scrollFrame:SetScrollChild(content)
    content._hasContent = false  -- Track if any content added (for auto-spacing)

    -- Update content width when scroll frame resizes (for panel resize support)
    scrollFrame:SetScript("OnSizeChanged", function(self, width, height)
        content:SetWidth(width)
    end)

    local scrollBar = scrollFrame.ScrollBar
    if scrollBar then
        scrollBar:SetPoint("TOPLEFT", scrollFrame, "TOPRIGHT", 4, -16)
        scrollBar:SetPoint("BOTTOMLEFT", scrollFrame, "BOTTOMRIGHT", 4, 16)

        -- Style the thumb (safe operation)
        local thumb = scrollBar:GetThumbTexture()
        if thumb then
            thumb:SetColorTexture(0.35, 0.45, 0.5, 0.8)  -- Subtle grey-blue
        end

        -- Hide arrow buttons (modern best practice)
        local scrollUp = scrollBar.ScrollUpButton or scrollBar.Back
        local scrollDown = scrollBar.ScrollDownButton or scrollBar.Forward
        if scrollUp then scrollUp:Hide(); scrollUp:SetAlpha(0) end
        if scrollDown then scrollDown:Hide(); scrollDown:SetAlpha(0) end

        -- Auto-hide scrollbar when not needed
        scrollBar:HookScript("OnShow", function(self)
            C_Timer.After(0.066, function()
                local maxScroll = scrollFrame:GetVerticalScrollRange()
                if maxScroll <= 1 then
                    self:Hide()
                end
            end)
        end)
    end

    return scrollFrame, content
end

---------------------------------------------------------------------------
-- HELPER: Get database safely
---------------------------------------------------------------------------
local function GetDB()
    if LUICore and LUICore.db and LUICore.db.profile then
        return LUICore.db.profile
    end
    return nil
end

---------------------------------------------------------------------------
-- FPS SETTINGS FUNCTIONS (must be after GetDB)
---------------------------------------------------------------------------
local function BackupCurrentFPSSettings()
    local db = GetDB()
    local backup = {}
    for cvar, _ in pairs(QUAZII_FPS_CVARS) do
        local success, current = pcall(C_CVar.GetCVar, cvar)
        if success and current then
            backup[cvar] = current
        end
    end
    db.fpsBackup = backup
    return true
end

local function RestorePreviousFPSSettings()
    local db = GetDB()
    if not db.fpsBackup then
        print("|cffFF6B6BLuheyUI:|r No backup found. Apply FPS settings first to create a backup.")
        return false
    end

    local successCount = 0
    local failCount = 0
    for cvar, value in pairs(db.fpsBackup) do
        local ok = pcall(C_CVar.SetCVar, cvar, tostring(value))
        if ok then
            successCount = successCount + 1
        else
            failCount = failCount + 1
        end
    end

    -- Clear backup after successful restore
    db.fpsBackup = nil

    print("|cff34D399LuheyUI:|r Restored " .. successCount .. " previous settings.")
    if failCount > 0 then
        print("|cffFF6B6BLuheyUI:|r " .. failCount .. " settings could not be restored.")
    end
    return true
end

local function ApplyQuaziiFPSSettings()
    -- Backup current settings first
    BackupCurrentFPSSettings()

    local successCount = 0
    local failCount = 0

    for cvar, value in pairs(QUAZII_FPS_CVARS) do
        local success = pcall(function()
            C_CVar.SetCVar(cvar, value)
        end)

        if success then
            successCount = successCount + 1
        else
            failCount = failCount + 1
        end
    end

    print("|cff34D399LuheyUI:|r Your previous settings have been backed up.")
    print("|cff34D399LuheyUI:|r Applied " .. successCount .. " FPS settings. Use 'Restore Previous Settings' to undo.")
    if failCount > 0 then
        print("|cffFF6B6BLuheyUI:|r " .. failCount .. " settings could not be applied (may require restart).")
    end
end

local function CheckCVarsMatch()
    local matchCount, totalCount = 0, 0
    for cvar, expectedVal in pairs(QUAZII_FPS_CVARS) do
        totalCount = totalCount + 1
        local currentVal = C_CVar.GetCVar(cvar)
        if currentVal == expectedVal then
            matchCount = matchCount + 1
        end
    end
    return matchCount == totalCount, matchCount, totalCount
end

---------------------------------------------------------------------------
-- HELPER: Refresh callbacks
---------------------------------------------------------------------------
local function RefreshAll()
    if LUICore and LUICore.RefreshAll then LUICore:RefreshAll() end
end

local function RefreshMinimap()
    if LUICore and LUICore.Minimap and LUICore.Minimap.Refresh then LUICore.Minimap:Refresh() end
end

local function RefreshUIHider()
    if _G.LuheyUI_RefreshUIHider then _G.LuheyUI_RefreshUIHider() end
end

local function RefreshUnitFrames(unit)
    if LUICore and LUICore.UnitFrames then
        -- If unit is a string (valid unit name), update that specific frame
        -- Otherwise (nil, boolean from checkbox, etc.), refresh all frames
        if type(unit) == "string" then
            LUICore.UnitFrames:UpdateUnitFrame(unit)
        else
            LUICore.UnitFrames:RefreshFrames()
        end
    end
end

local function RefreshBuffBorders()
    if _G.LuheyUI_RefreshBuffBorders then
        _G.LuheyUI_RefreshBuffBorders()
    end
end

---------------------------------------------------------------------------
-- PAGE: General & QoL
---------------------------------------------------------------------------
local function CreateGeneralQoLPage(parent)
    local scroll, content = CreateScrollableContent(parent)
    local db = GetDB()

    -- Refresh callback for crosshair
    local function RefreshCrosshair()
        if _G.LuheyUI_RefreshCrosshair then
            _G.LuheyUI_RefreshCrosshair()
        end
    end

    -- Refresh callback for reticle
    local function RefreshReticle()
        if _G.LuheyUI_RefreshReticle then
            _G.LuheyUI_RefreshReticle()
        end
    end

    -- Refresh callback for fonts/textures (refreshes everything that uses these defaults)
    local function RefreshAll()
        -- Refresh core CDM viewers
        if LUICore and LUICore.RefreshAll then
            LUICore:RefreshAll()
        end
        -- Refresh unit frames (use global function)
        if _G.LuheyUI_RefreshUnitFrames then
            _G.LuheyUI_RefreshUnitFrames()
        end
        -- Refresh power bars (recreate to apply new fonts/textures)
        if LUICore then
            if LUICore.UpdatePowerBar then
                LUICore:UpdatePowerBar()
            end
            if LUICore.UpdateSecondaryPowerBar then
                LUICore:UpdateSecondaryPowerBar()
            end
        end
        -- Refresh minimap/datatext
        if LUICore and LUICore.Minimap and LUICore.Minimap.Refresh then
            LUICore.Minimap:Refresh()
        end
        -- Refresh buff borders
        if _G.LuheyUI_RefreshBuffBorders then
            _G.LuheyUI_RefreshBuffBorders()
        end
        -- Refresh NCDM (CDM icons)
        if ns and ns.NCDM and ns.NCDM.RefreshAll then
            ns.NCDM:RefreshAll()
        end
        -- Trigger CDM layout refresh
        C_Timer.After(0.1, function()
            if LUICore and LUICore.ApplyViewerLayout then
                LUICore:ApplyViewerLayout("EssentialCooldownViewer")
                LUICore:ApplyViewerLayout("UtilityCooldownViewer")
            end
        end)
    end

    -- =====================================================
    -- SUB-TAB: GENERAL
    -- =====================================================
    local function BuildGeneralTab(tabContent)
        local y = -10
        local FORM_ROW = 32

        -- Set search context for auto-registration
        GUI:SetSearchContext({tabIndex = 1, tabName = "General & QoL", subTabIndex = 1, subTabName = "General"})

        -- UI Scale Section
        GUI:SetSearchSection("UI Scale")
        local scaleHeader = GUI:CreateSectionHeader(tabContent, "UI Scale")
        scaleHeader:SetPoint("TOPLEFT", PADDING, y)
        y = y - scaleHeader.gap

        if db and db.general then
            local scaleSlider = GUI:CreateFormSlider(tabContent, "Global UI Scale", 0.3, 2.0, 0.01,
                "uiScale", db.general, function(val)
                    pcall(function() UIParent:SetScale(val) end)
                    if LUICore and LUICore.UIMult then LUICore:UIMult() end
                end, { deferOnDrag = true, precision = 7 })
            scaleSlider:SetPoint("TOPLEFT", PADDING, y)
            scaleSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
            y = y - FORM_ROW

            -- Quick preset buttons
            local presetLabel = GUI:CreateLabel(tabContent, "Quick UI Scale Presets:", 12, C.text)
            presetLabel:SetPoint("TOPLEFT", PADDING, y)

            local function ApplyPreset(val, name)
                db.general.uiScale = val
                pcall(function() UIParent:SetScale(val) end)
                local msg = "|cff34D399[LuheyUI]|r UI scale set to " .. val
                if name then msg = msg .. " (" .. name .. ")" end
                DEFAULT_CHAT_FRAME:AddMessage(msg)
                if LUICore and LUICore.UIMult then LUICore:UIMult() end
                scaleSlider.SetValue(val, true)
            end

            local function AutoScale()
                local _, height = GetPhysicalScreenSize()
                local scale = 768 / height
                scale = math.max(0.3, math.min(2.0, scale))
                ApplyPreset(scale, "Auto")
            end

            -- Button container aligned with slider track (180px) to editbox right edge
            local buttonContainer = CreateFrame("Frame", nil, tabContent)
            buttonContainer:SetPoint("LEFT", scaleSlider, "LEFT", 180, 0)
            buttonContainer:SetPoint("RIGHT", scaleSlider, "RIGHT", 0, 0)
            buttonContainer:SetPoint("TOP", presetLabel, "TOP", 0, 0)
            buttonContainer:SetHeight(26)

            local BUTTON_GAP = 6
            local NUM_BUTTONS = 5
            local buttons = {}

            -- Create buttons with placeholder width (will be set dynamically)
            buttons[1] = GUI:CreateButton(buttonContainer, "1080p", 50, 26, function() ApplyPreset(0.7111111, "1080p") end)
            buttons[2] = GUI:CreateButton(buttonContainer, "1440p", 50, 26, function() ApplyPreset(0.5333333, "1440p") end)
            buttons[3] = GUI:CreateButton(buttonContainer, "1440p+", 50, 26, function() ApplyPreset(0.64, "1440p+") end)
            buttons[4] = GUI:CreateButton(buttonContainer, "4K", 50, 26, function() ApplyPreset(0.3555556, "4K") end)
            buttons[5] = GUI:CreateButton(buttonContainer, "Auto", 50, 26, AutoScale)

            -- Dynamically size and position buttons when container width is known
            buttonContainer:SetScript("OnSizeChanged", function(self, width)
                if width and width > 0 then
                    local buttonWidth = (width - (NUM_BUTTONS - 1) * BUTTON_GAP) / NUM_BUTTONS
                    for i, btn in ipairs(buttons) do
                        btn:SetWidth(buttonWidth)
                        btn:ClearAllPoints()
                        if i == 1 then
                            btn:SetPoint("LEFT", self, "LEFT", 0, 0)
                        else
                            btn:SetPoint("LEFT", buttons[i-1], "RIGHT", BUTTON_GAP, 0)
                        end
                    end
                end
            end)

            -- Tooltip data for preset buttons
            local tooltipData = {
                { title = "1080p", desc = "Scale: 0.7111111\nPixel-perfect for 1920×1080" },
                { title = "1440p", desc = "Scale: 0.5333333\nPixel-perfect for 2560×1440" },
                { title = "1440p+", desc = "Scale: 0.64\nRequires manual adjustment for pixel perfection." },
                { title = "4K", desc = "Scale: 0.3555556\nPixel-perfect for 3840×2160" },
                { title = "Auto", desc = "Computes pixel-perfect scale based on your resolution.\nFormula: 768 ÷ screen height" },
            }

            -- Add tooltips to buttons
            for i, btn in ipairs(buttons) do
                local data = tooltipData[i]
                btn:HookScript("OnEnter", function(self)
                    GameTooltip:SetOwner(self, "ANCHOR_TOP")
                    GameTooltip:AddLine(data.title, 1, 1, 1)
                    GameTooltip:AddLine(data.desc, 0.8, 0.8, 0.8, true)
                    GameTooltip:Show()
                end)
                btn:HookScript("OnLeave", function()
                    GameTooltip:Hide()
                end)
            end

            y = y - FORM_ROW - 6

            -- Single summary line (cleaner than 5 separate description lines)
            local presetSummary = GUI:CreateLabel(tabContent,
                "Hover over any preset for details.",
                11, C.textMuted)
            presetSummary:SetPoint("TOPLEFT", PADDING, y)
            y = y - 20

            -- Big picture advice
            local bigPicture = GUI:CreateLabel(tabContent,
                "UI scale is highly personal—it depends on your monitor size, resolution, and preference. If you already have a scale you like from years of playing WoW, stick with it. These presets are just common values people tend to use.",
                11, C.textMuted)
            bigPicture:SetPoint("TOPLEFT", PADDING, y)
            bigPicture:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
            bigPicture:SetJustifyH("LEFT")
            y = y - 36
        end

        -- Default Font Section
        GUI:SetSearchSection("Default Font Settings")
        local fontTexHeader = GUI:CreateSectionHeader(tabContent, "Default Font Settings")
        fontTexHeader:SetPoint("TOPLEFT", PADDING, y)
        y = y - fontTexHeader.gap

        local tipText = GUI:CreateLabel(tabContent, "These settings apply throughout the UI. Individual elements with their own font options will override these defaults.", 11, C.textMuted)
        tipText:SetPoint("TOPLEFT", PADDING, y)
        tipText:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        tipText:SetJustifyH("LEFT")
        y = y - 28

        if db and db.general then
            local fontList = {}
            local LSM = LibStub("LibSharedMedia-3.0", true)
            if LSM then
                for name in pairs(LSM:HashTable("font")) do
                    table.insert(fontList, {value = name, text = name})
                end
                table.sort(fontList, function(a, b) return a.text < b.text end)
            else
                fontList = {{value = "Friz Quadrata TT", text = "Friz Quadrata TT"}}
            end

            local fontDropdown = GUI:CreateFormDropdown(tabContent, "Default Font", fontList, "font", db.general, RefreshAll)
            fontDropdown:SetPoint("TOPLEFT", PADDING, y)
            fontDropdown:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
            y = y - FORM_ROW

            local outlineOptions = {
                {value = "", text = "None"},
                {value = "OUTLINE", text = "Outline"},
                {value = "THICKOUTLINE", text = "Thick Outline"},
            }
            local outlineDropdown = GUI:CreateFormDropdown(tabContent, "Font Outline", outlineOptions, "fontOutline", db.general, RefreshAll)
            outlineDropdown:SetPoint("TOPLEFT", PADDING, y)
            outlineDropdown:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
            y = y - FORM_ROW
        end

        y = y - 10

        -- Quazii Recommended FPS Settings Section
        local fpsHeader = GUI:CreateSectionHeader(tabContent, "Quazii Recommended FPS Settings")
        fpsHeader:SetPoint("TOPLEFT", PADDING, y)
        y = y - fpsHeader.gap

        local fpsDesc = GUI:CreateLabel(tabContent,
            "Apply Quazii's optimized graphics settings for competitive play. " ..
            "Your current settings are automatically saved when you click Apply - use 'Restore Previous Settings' to revert anytime. " ..
            "Caution: Clicking Apply again will overwrite your backup with these settings.",
            11, C.textMuted)
        fpsDesc:SetPoint("TOPLEFT", PADDING, y)
        fpsDesc:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        fpsDesc:SetJustifyH("LEFT")
        fpsDesc:SetWordWrap(true)
        fpsDesc:SetHeight(30)
        y = y - 40

        local restoreFpsBtn
        local fpsStatusText

        local function UpdateFPSStatus()
            local allMatch, matched, total = CheckCVarsMatch()
            -- Some CVars can't be verified (protected/restart required), so threshold at 50+
            if matched >= 50 then
                fpsStatusText:SetText("Settings: All applied")
                fpsStatusText:SetTextColor(C.accent[1], C.accent[2], C.accent[3], 1)
            else
                fpsStatusText:SetText(string.format("Settings: %d/%d match", matched, total))
                fpsStatusText:SetTextColor(C.textMuted[1], C.textMuted[2], C.textMuted[3], 1)
            end
        end

        local applyFpsBtn = GUI:CreateButton(tabContent, "Apply FPS Settings", 180, 28, function()
            ApplyQuaziiFPSSettings()
            restoreFpsBtn:SetAlpha(1)
            restoreFpsBtn:Enable()
            UpdateFPSStatus()
        end)
        applyFpsBtn:SetPoint("TOPLEFT", PADDING, y)
        applyFpsBtn:SetPoint("RIGHT", tabContent, "CENTER", -5, 0)

        restoreFpsBtn = GUI:CreateButton(tabContent, "Restore Previous Settings", 180, 28, function()
            if RestorePreviousFPSSettings() then
                restoreFpsBtn:SetAlpha(0.5)
                restoreFpsBtn:Disable()
            end
            UpdateFPSStatus()
        end)
        restoreFpsBtn:SetPoint("LEFT", tabContent, "CENTER", 5, 0)
        restoreFpsBtn:SetPoint("TOP", applyFpsBtn, "TOP", 0, 0)
        restoreFpsBtn:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        y = y - 38

        fpsStatusText = GUI:CreateLabel(tabContent, "", 11, C.accent)
        fpsStatusText:SetPoint("TOPLEFT", PADDING, y)

        if not db.fpsBackup then
            restoreFpsBtn:SetAlpha(0.5)
            restoreFpsBtn:Disable()
        end

        UpdateFPSStatus()

        y = y - 22

        -- Combat Status Text Indicator Section
        local combatTextHeader = GUI:CreateSectionHeader(tabContent, "Combat Status Text Indicator")
        combatTextHeader:SetPoint("TOPLEFT", PADDING, y)
        y = y - combatTextHeader.gap

        local combatTextDesc = GUI:CreateLabel(tabContent,
            "Displays '+Combat' or '-Combat' text on screen when entering or leaving combat. Useful for Shadowmeld skips.",
            11, C.textMuted)
        combatTextDesc:SetPoint("TOPLEFT", PADDING, y)
        combatTextDesc:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        combatTextDesc:SetJustifyH("LEFT")
        combatTextDesc:SetWordWrap(true)
        combatTextDesc:SetHeight(15)
        y = y - 25

        -- Preview buttons
        local previewEnterBtn = GUI:CreateButton(tabContent, "Preview +Combat", 140, 28, function()
            if _G.LuheyUI_PreviewCombatText then _G.LuheyUI_PreviewCombatText("+Combat") end
        end)
        previewEnterBtn:SetPoint("TOPLEFT", PADDING, y)
        previewEnterBtn:SetPoint("RIGHT", tabContent, "CENTER", -5, 0)

        local previewLeaveBtn = GUI:CreateButton(tabContent, "Preview -Combat", 140, 28, function()
            if _G.LuheyUI_PreviewCombatText then _G.LuheyUI_PreviewCombatText("-Combat") end
        end)
        previewLeaveBtn:SetPoint("LEFT", tabContent, "CENTER", 5, 0)
        previewLeaveBtn:SetPoint("TOP", previewEnterBtn, "TOP", 0, 0)
        previewLeaveBtn:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        y = y - 38

        local combatTextDB = db.combatText
        if combatTextDB then
            local combatTextCheck = GUI:CreateFormCheckbox(tabContent, "Enable Combat Text", "enabled", combatTextDB, function(val)
                if _G.LuheyUI_RefreshCombatText then _G.LuheyUI_RefreshCombatText() end
            end)
            combatTextCheck:SetPoint("TOPLEFT", PADDING, y)
            combatTextCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
            y = y - FORM_ROW

            local displayTimeSlider = GUI:CreateFormSlider(tabContent, "Display Time (sec)", 0.3, 3.0, 0.1, "displayTime", combatTextDB, function()
                if _G.LuheyUI_RefreshCombatText then _G.LuheyUI_RefreshCombatText() end
            end)
            displayTimeSlider:SetPoint("TOPLEFT", PADDING, y)
            displayTimeSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
            y = y - FORM_ROW

            local fadeTimeSlider = GUI:CreateFormSlider(tabContent, "Fade Duration (sec)", 0.1, 1.0, 0.05, "fadeTime", combatTextDB, function()
                if _G.LuheyUI_RefreshCombatText then _G.LuheyUI_RefreshCombatText() end
            end)
            fadeTimeSlider:SetPoint("TOPLEFT", PADDING, y)
            fadeTimeSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
            y = y - FORM_ROW

            local fontSizeSlider = GUI:CreateFormSlider(tabContent, "Font Size", 12, 48, 1, "fontSize", combatTextDB, function()
                if _G.LuheyUI_RefreshCombatText then _G.LuheyUI_RefreshCombatText() end
            end)
            fontSizeSlider:SetPoint("TOPLEFT", PADDING, y)
            fontSizeSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
            y = y - FORM_ROW

            local xOffsetSlider = GUI:CreateFormSlider(tabContent, "X Position Offset", -2000, 2000, 1, "xOffset", combatTextDB, function()
                if _G.LuheyUI_RefreshCombatText then _G.LuheyUI_RefreshCombatText() end
            end)
            xOffsetSlider:SetPoint("TOPLEFT", PADDING, y)
            xOffsetSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
            y = y - FORM_ROW

            local yOffsetSlider = GUI:CreateFormSlider(tabContent, "Y Position Offset", -2000, 2000, 1, "yOffset", combatTextDB, function()
                if _G.LuheyUI_RefreshCombatText then _G.LuheyUI_RefreshCombatText() end
            end)
            yOffsetSlider:SetPoint("TOPLEFT", PADDING, y)
            yOffsetSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
            y = y - FORM_ROW

            local enterColorPicker = GUI:CreateFormColorPicker(tabContent, "+Combat Text Color", "enterCombatColor", combatTextDB, function()
                if _G.LuheyUI_RefreshCombatText then _G.LuheyUI_RefreshCombatText() end
            end)
            enterColorPicker:SetPoint("TOPLEFT", PADDING, y)
            enterColorPicker:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
            y = y - FORM_ROW

            local leaveColorPicker = GUI:CreateFormColorPicker(tabContent, "-Combat Text Color", "leaveCombatColor", combatTextDB, function()
                if _G.LuheyUI_RefreshCombatText then _G.LuheyUI_RefreshCombatText() end
            end)
            leaveColorPicker:SetPoint("TOPLEFT", PADDING, y)
            leaveColorPicker:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
            y = y - FORM_ROW
        end

        y = y - 10

        -- Combat Timer Section
        local combatTimerHeader = GUI:CreateSectionHeader(tabContent, "Combat Timer")
        combatTimerHeader:SetPoint("TOPLEFT", PADDING, y)
        y = y - combatTimerHeader.gap

        local combatTimerDesc = GUI:CreateLabel(tabContent,
            "Displays elapsed combat time. Timer resets each time you leave combat.",
            11, C.textMuted)
        combatTimerDesc:SetPoint("TOPLEFT", PADDING, y)
        combatTimerDesc:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        combatTimerDesc:SetJustifyH("LEFT")
        combatTimerDesc:SetWordWrap(true)
        combatTimerDesc:SetHeight(15)
        y = y - 25

        local combatTimerDB = db.combatTimer
        if combatTimerDB then
            local combatTimerCheck = GUI:CreateFormCheckbox(tabContent, "Enable Combat Timer", "enabled", combatTimerDB, function(val)
                if _G.LuheyUI_RefreshCombatTimer then _G.LuheyUI_RefreshCombatTimer() end
            end)
            combatTimerCheck:SetPoint("TOPLEFT", PADDING, y)
            combatTimerCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
            y = y - FORM_ROW

            -- Encounters-only mode toggle
            local encountersOnlyCheck = GUI:CreateFormCheckbox(tabContent, "Only Show In Encounters", "onlyShowInEncounters", combatTimerDB, function(val)
                if _G.LuheyUI_RefreshCombatTimer then _G.LuheyUI_RefreshCombatTimer() end
            end)
            encountersOnlyCheck:SetPoint("TOPLEFT", PADDING, y)
            encountersOnlyCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
            y = y - FORM_ROW

            -- Preview toggle
            local previewState = { enabled = _G.LuheyUI_IsCombatTimerPreviewMode and _G.LuheyUI_IsCombatTimerPreviewMode() or false }
            local previewCheck = GUI:CreateFormCheckbox(tabContent, "Preview Combat Timer", "enabled", previewState, function(val)
                if _G.LuheyUI_ToggleCombatTimerPreview then
                    _G.LuheyUI_ToggleCombatTimerPreview(val)
                end
            end)
            previewCheck:SetPoint("TOPLEFT", PADDING, y)
            previewCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
            y = y - FORM_ROW

            -- Frame size settings
            local timerWidthSlider = GUI:CreateFormSlider(tabContent, "Frame Width", 40, 200, 1, "width", combatTimerDB, function()
                if _G.LuheyUI_RefreshCombatTimer then _G.LuheyUI_RefreshCombatTimer() end
            end)
            timerWidthSlider:SetPoint("TOPLEFT", PADDING, y)
            timerWidthSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
            y = y - FORM_ROW

            local timerHeightSlider = GUI:CreateFormSlider(tabContent, "Frame Height", 20, 100, 1, "height", combatTimerDB, function()
                if _G.LuheyUI_RefreshCombatTimer then _G.LuheyUI_RefreshCombatTimer() end
            end)
            timerHeightSlider:SetPoint("TOPLEFT", PADDING, y)
            timerHeightSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
            y = y - FORM_ROW

            local timerFontSizeSlider = GUI:CreateFormSlider(tabContent, "Font Size", 12, 32, 1, "fontSize", combatTimerDB, function()
                if _G.LuheyUI_RefreshCombatTimer then _G.LuheyUI_RefreshCombatTimer() end
            end)
            timerFontSizeSlider:SetPoint("TOPLEFT", PADDING, y)
            timerFontSizeSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
            y = y - FORM_ROW

            local timerXOffsetSlider = GUI:CreateFormSlider(tabContent, "X Position Offset", -2000, 2000, 1, "xOffset", combatTimerDB, function()
                if _G.LuheyUI_RefreshCombatTimer then _G.LuheyUI_RefreshCombatTimer() end
            end)
            timerXOffsetSlider:SetPoint("TOPLEFT", PADDING, y)
            timerXOffsetSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
            y = y - FORM_ROW

            local timerYOffsetSlider = GUI:CreateFormSlider(tabContent, "Y Position Offset", -2000, 2000, 1, "yOffset", combatTimerDB, function()
                if _G.LuheyUI_RefreshCombatTimer then _G.LuheyUI_RefreshCombatTimer() end
            end)
            timerYOffsetSlider:SetPoint("TOPLEFT", PADDING, y)
            timerYOffsetSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
            y = y - FORM_ROW

            -- Text color with class color toggle
            local timerColorPicker  -- Forward declare

            local useClassColorTextCheck = GUI:CreateFormCheckbox(tabContent, "Use Class Color for Text", "useClassColorText", combatTimerDB, function(val)
                if _G.LuheyUI_RefreshCombatTimer then _G.LuheyUI_RefreshCombatTimer() end
                -- Enable/disable text color picker based on toggle
                if timerColorPicker and timerColorPicker.SetEnabled then
                    timerColorPicker:SetEnabled(not val)
                end
            end)
            useClassColorTextCheck:SetPoint("TOPLEFT", PADDING, y)
            useClassColorTextCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
            y = y - FORM_ROW

            timerColorPicker = GUI:CreateFormColorPicker(tabContent, "Timer Text Color", "textColor", combatTimerDB, function()
                if _G.LuheyUI_RefreshCombatTimer then _G.LuheyUI_RefreshCombatTimer() end
            end)
            timerColorPicker:SetPoint("TOPLEFT", PADDING, y)
            timerColorPicker:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
            -- Initial state based on setting
            if timerColorPicker.SetEnabled then
                timerColorPicker:SetEnabled(not combatTimerDB.useClassColorText)
            end
            y = y - FORM_ROW

            -- Font selection with custom toggle
            -- Create font dropdown first, then the toggle (so toggle callback can reference it)
            local fontList = GetFontList()
            local timerFontDropdown  -- Forward declare

            local useCustomFontCheck = GUI:CreateFormCheckbox(tabContent, "Use Custom Font", "useCustomFont", combatTimerDB, function(val)
                if _G.LuheyUI_RefreshCombatTimer then _G.LuheyUI_RefreshCombatTimer() end
                -- Enable/disable font dropdown based on toggle
                if timerFontDropdown and timerFontDropdown.SetEnabled then
                    timerFontDropdown:SetEnabled(val)
                end
            end)
            useCustomFontCheck:SetPoint("TOPLEFT", PADDING, y)
            useCustomFontCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
            y = y - FORM_ROW

            timerFontDropdown = GUI:CreateFormDropdown(tabContent, "Font", fontList, "font", combatTimerDB, function()
                if _G.LuheyUI_RefreshCombatTimer then _G.LuheyUI_RefreshCombatTimer() end
            end)
            timerFontDropdown:SetPoint("TOPLEFT", PADDING, y)
            timerFontDropdown:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
            -- Limit dropdown height to 8 items (scrollable)
            if timerFontDropdown.menuFrame then
                timerFontDropdown.menuFrame:SetClipsChildren(true)
            end
            -- Initial state based on setting
            if timerFontDropdown.SetEnabled then
                timerFontDropdown:SetEnabled(combatTimerDB.useCustomFont == true)
            end
            y = y - FORM_ROW

            -- Backdrop settings
            local backdropCheck = GUI:CreateFormCheckbox(tabContent, "Show Backdrop", "showBackdrop", combatTimerDB, function(val)
                if _G.LuheyUI_RefreshCombatTimer then _G.LuheyUI_RefreshCombatTimer() end
            end)
            backdropCheck:SetPoint("TOPLEFT", PADDING, y)
            backdropCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
            y = y - FORM_ROW

            local backdropColorPicker = GUI:CreateFormColorPicker(tabContent, "Backdrop Color", "backdropColor", combatTimerDB, function()
                if _G.LuheyUI_RefreshCombatTimer then _G.LuheyUI_RefreshCombatTimer() end
            end)
            backdropColorPicker:SetPoint("TOPLEFT", PADDING, y)
            backdropColorPicker:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
            y = y - FORM_ROW

            -- Border settings
            -- Forward declare border controls so hide toggle can reference them
            local borderSizeSlider, borderTextureDropdown, useClassColorCheck, borderColorPicker

            -- Helper to update all border control states
            local function UpdateBorderControlsEnabled(enabled)
                if borderSizeSlider and borderSizeSlider.SetEnabled then borderSizeSlider:SetEnabled(enabled) end
                if borderTextureDropdown and borderTextureDropdown.SetEnabled then borderTextureDropdown:SetEnabled(enabled) end
                if useClassColorCheck and useClassColorCheck.SetEnabled then useClassColorCheck:SetEnabled(enabled) end
                -- Border color picker is enabled if borders are shown AND class color is not used
                if borderColorPicker and borderColorPicker.SetEnabled then 
                    borderColorPicker:SetEnabled(enabled and not combatTimerDB.useClassColorBorder)
                end
            end

            -- Hide Border toggle
            local hideBorderCheck = GUI:CreateFormCheckbox(tabContent, "Hide Border", "hideBorder", combatTimerDB, function(val)
                if _G.LuheyUI_RefreshCombatTimer then _G.LuheyUI_RefreshCombatTimer() end
                UpdateBorderControlsEnabled(not val)
            end)
            hideBorderCheck:SetPoint("TOPLEFT", PADDING, y)
            hideBorderCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
            y = y - FORM_ROW

            borderSizeSlider = GUI:CreateFormSlider(tabContent, "Border Size", 0, 5, 1, "borderSize", combatTimerDB, function()
                if _G.LuheyUI_RefreshCombatTimer then _G.LuheyUI_RefreshCombatTimer() end
            end)
            borderSizeSlider:SetPoint("TOPLEFT", PADDING, y)
            borderSizeSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
            y = y - FORM_ROW

            local borderList = GetBorderList()
            borderTextureDropdown = GUI:CreateFormDropdown(tabContent, "Border Texture", borderList, "borderTexture", combatTimerDB, function()
                if _G.LuheyUI_RefreshCombatTimer then _G.LuheyUI_RefreshCombatTimer() end
            end)
            borderTextureDropdown:SetPoint("TOPLEFT", PADDING, y)
            borderTextureDropdown:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
            y = y - FORM_ROW

            -- Class color border toggle
            useClassColorCheck = GUI:CreateFormCheckbox(tabContent, "Use Class Color for Border", "useClassColorBorder", combatTimerDB, function(val)
                if _G.LuheyUI_RefreshCombatTimer then _G.LuheyUI_RefreshCombatTimer() end
                -- Enable/disable border color picker based on toggle (only if borders are shown)
                if borderColorPicker and borderColorPicker.SetEnabled then
                    borderColorPicker:SetEnabled(not val and not combatTimerDB.hideBorder)
                end
            end)
            useClassColorCheck:SetPoint("TOPLEFT", PADDING, y)
            useClassColorCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
            y = y - FORM_ROW

            borderColorPicker = GUI:CreateFormColorPicker(tabContent, "Border Color", "borderColor", combatTimerDB, function()
                if _G.LuheyUI_RefreshCombatTimer then _G.LuheyUI_RefreshCombatTimer() end
            end)
            borderColorPicker:SetPoint("TOPLEFT", PADDING, y)
            borderColorPicker:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
            y = y - FORM_ROW

            -- Set initial enabled states based on current settings
            local bordersVisible = not combatTimerDB.hideBorder
            UpdateBorderControlsEnabled(bordersVisible)
        end

        y = y - 10

        -- Automation Section
        local autoHeader = GUI:CreateSectionHeader(tabContent, "Automation")
        autoHeader:SetPoint("TOPLEFT", PADDING, y)
        y = y - autoHeader.gap

        local keystoneCheck = GUI:CreateFormCheckbox(tabContent, "Auto Insert M+ Keys", "autoInsertKey", db.general, nil)
        keystoneCheck:SetPoint("TOPLEFT", PADDING, y)
        keystoneCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        y = y - FORM_ROW

        local combatLogCheck = GUI:CreateFormCheckbox(tabContent, "Auto Combat Log in M+", "autoCombatLog", db.general, nil)
        combatLogCheck:SetPoint("TOPLEFT", PADDING, y)
        combatLogCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        y = y - FORM_ROW

        local sellJunkCheck = GUI:CreateFormCheckbox(tabContent, "Sell Gray Items", "sellJunk", db.general, nil)
        sellJunkCheck:SetPoint("TOPLEFT", PADDING, y)
        sellJunkCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        y = y - FORM_ROW

        local repairOptions = {
            {value = "off", text = "Off"},
            {value = "personal", text = "Personal Gold"},
            {value = "guild", text = "Guild Bank First"},
        }
        local repairDropdown = GUI:CreateFormDropdown(tabContent, "Auto Repair", repairOptions, "autoRepair", db.general, nil)
        repairDropdown:SetPoint("TOPLEFT", PADDING, y)
        repairDropdown:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        y = y - FORM_ROW

        local autoRoleCheck = GUI:CreateFormCheckbox(tabContent, "Auto Accept Role Check", "autoRoleAccept", db.general, nil)
        autoRoleCheck:SetPoint("TOPLEFT", PADDING, y)
        autoRoleCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        y = y - FORM_ROW

        local inviteOptions = {
            {value = "off", text = "Off"},
            {value = "all", text = "All Invites"},
            {value = "friends", text = "Friends Only"},
            {value = "guild", text = "Guild Only"},
            {value = "both", text = "Friends & Guild"},
        }
        local inviteDropdown = GUI:CreateFormDropdown(tabContent, "Auto Accept Invites", inviteOptions, "autoAcceptInvites", db.general, nil)
        inviteDropdown:SetPoint("TOPLEFT", PADDING, y)
        inviteDropdown:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        y = y - FORM_ROW

        local autoAcceptQuestCheck = GUI:CreateFormCheckbox(tabContent, "Auto Accept Quests", "autoAcceptQuest", db.general, nil)
        autoAcceptQuestCheck:SetPoint("TOPLEFT", PADDING, y)
        autoAcceptQuestCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        y = y - FORM_ROW

        local autoTurnInCheck = GUI:CreateFormCheckbox(tabContent, "Auto Turn-In Quests", "autoTurnInQuest", db.general, nil)
        autoTurnInCheck:SetPoint("TOPLEFT", PADDING, y)
        autoTurnInCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        y = y - FORM_ROW

        local questShiftCheck = GUI:CreateFormCheckbox(tabContent, "Shift Pauses Accept & Turn-In", "questHoldShift", db.general, nil)
        questShiftCheck:SetPoint("TOPLEFT", PADDING, y)
        questShiftCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        y = y - FORM_ROW

        local fastLootCheck = GUI:CreateFormCheckbox(tabContent, "Faster Auto Loot", "fastAutoLoot", db.general, function(enabled)
            if enabled then
                SetCVar("autoLootDefault", "1")
            end
        end)
        fastLootCheck:SetPoint("TOPLEFT", PADDING, y)
        fastLootCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        y = y - FORM_ROW

        local fastLootDesc = GUI:CreateLabel(tabContent, "Instantly loots all items. Enables WoW's Auto Loot setting automatically.", 11, C.textMuted)
        fastLootDesc:SetPoint("TOPLEFT", PADDING, y + 4)
        fastLootDesc:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        fastLootDesc:SetJustifyH("LEFT")
        y = y - 16

        local autoGossipCheck = GUI:CreateFormCheckbox(tabContent, "Auto-Select Single Gossip Option", "autoSelectGossip", db.general, nil, {keywords = {"conversations", "cutscene"}})
        autoGossipCheck:SetPoint("TOPLEFT", PADDING, y)
        autoGossipCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        y = y - FORM_ROW

        local autoDeleteCheck = GUI:CreateFormCheckbox(tabContent, "Auto-Fill Delete Confirmation", "autoDeleteConfirm", db.general, nil)
        autoDeleteCheck:SetPoint("TOPLEFT", PADDING, y)
        autoDeleteCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        y = y - FORM_ROW

        local autoDeleteDesc = GUI:CreateLabel(tabContent, "Automatically fills in DELETE when destroying high-quality items.", 11, C.textMuted)
        autoDeleteDesc:SetPoint("TOPLEFT", PADDING, y + 4)
        autoDeleteDesc:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        autoDeleteDesc:SetJustifyH("LEFT")
        y = y - 16

        y = y - 10

        -- Missing Raid Buffs Section
        local raidBuffsHeader = GUI:CreateSectionHeader(tabContent, "Missing Raid Buffs")
        raidBuffsHeader:SetPoint("TOPLEFT", PADDING, y)
        y = y - raidBuffsHeader.gap

        local raidBuffsDesc = GUI:CreateLabel(tabContent, "Display missing raid buffs when a buff-providing class is in your group. Shows out of combat only.", 11, C.textMuted)
        raidBuffsDesc:SetPoint("TOPLEFT", PADDING, y)
        raidBuffsDesc:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        raidBuffsDesc:SetJustifyH("LEFT")
        raidBuffsDesc:SetWordWrap(true)
        raidBuffsDesc:SetHeight(20)
        y = y - 30

        -- Ensure raidBuffs settings exist
        if not db.raidBuffs then
            db.raidBuffs = { enabled = true, showOnlyInGroup = true, showOnlyInInstance = false, providerMode = false, hideLabelBar = false, iconSize = 32, labelFontSize = 12, labelTextColor = nil, position = nil }
        end
        local rbDB = db.raidBuffs

        -- Refresh function for live preview
        local function RefreshRaidBuffs()
            if ns.RaidBuffs and ns.RaidBuffs.ForceUpdate then
                ns.RaidBuffs:ForceUpdate()
            end
        end

        local rbEnableCheck = GUI:CreateFormCheckbox(tabContent, "Enable Missing Raid Buffs", "enabled", rbDB, RefreshRaidBuffs)
        rbEnableCheck:SetPoint("TOPLEFT", PADDING, y)
        rbEnableCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        y = y - FORM_ROW

        local rbGroupOnlyCheck = GUI:CreateFormCheckbox(tabContent, "Show Only When In Group", "showOnlyInGroup", rbDB, RefreshRaidBuffs)
        rbGroupOnlyCheck:SetPoint("TOPLEFT", PADDING, y)
        rbGroupOnlyCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        y = y - FORM_ROW

        local rbInstanceOnlyCheck = GUI:CreateFormCheckbox(tabContent, "Show Only In Instance", "showOnlyInInstance", rbDB, RefreshRaidBuffs)
        rbInstanceOnlyCheck:SetPoint("TOPLEFT", PADDING, y)
        rbInstanceOnlyCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        y = y - FORM_ROW

        local instanceOnlyDesc = GUI:CreateLabel(tabContent, "Hide when forming groups in cities, show only when zoned into dungeon/raid.", 11, C.textMuted)
        instanceOnlyDesc:SetPoint("TOPLEFT", PADDING, y + 4)
        instanceOnlyDesc:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        instanceOnlyDesc:SetJustifyH("LEFT")
        y = y - 20

        local rbProviderCheck = GUI:CreateFormCheckbox(tabContent, "Also Show Buffs You Can Provide", "providerMode", rbDB, RefreshRaidBuffs)
        rbProviderCheck:SetPoint("TOPLEFT", PADDING, y)
        rbProviderCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        y = y - FORM_ROW

        local providerDesc = GUI:CreateLabel(tabContent, "When enabled, also shows buffs you can cast that party members are missing.", 11, C.textMuted)
        providerDesc:SetPoint("TOPLEFT", PADDING, y + 4)
        providerDesc:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        providerDesc:SetJustifyH("LEFT")
        y = y - 20

        local rbHideLabelCheck = GUI:CreateFormCheckbox(tabContent, "Hide Label Bar", "hideLabelBar", rbDB, RefreshRaidBuffs)
        rbHideLabelCheck:SetPoint("TOPLEFT", PADDING, y)
        rbHideLabelCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        y = y - FORM_ROW

        local rbIconSizeSlider = GUI:CreateFormSlider(tabContent, "Icon Size", 20, 64, 2, "iconSize", rbDB, RefreshRaidBuffs)
        rbIconSizeSlider:SetPoint("TOPLEFT", PADDING, y)
        rbIconSizeSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        y = y - FORM_ROW

        local rbFontSizeSlider = GUI:CreateFormSlider(tabContent, "Label Font Size", 10, 32, 1, "labelFontSize", rbDB, RefreshRaidBuffs)
        rbFontSizeSlider:SetPoint("TOPLEFT", PADDING, y)
        rbFontSizeSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        y = y - FORM_ROW

        local rbTextColorPicker = GUI:CreateFormColorPicker(tabContent, "Label Text Color", "labelTextColor", rbDB, RefreshRaidBuffs)
        rbTextColorPicker:SetPoint("TOPLEFT", PADDING, y)
        rbTextColorPicker:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        y = y - FORM_ROW

        -- Disable color picker when label bar is hidden (color is irrelevant)
        local function UpdateColorPickerState()
            local isHidden = rbDB.hideLabelBar
            if rbTextColorPicker.SetEnabled then
                rbTextColorPicker:SetEnabled(not isHidden)
            end
            -- Visual feedback: dim the control when disabled
            rbTextColorPicker:SetAlpha(isHidden and 0.5 or 1.0)
        end
        rbHideLabelCheck.track:HookScript("OnClick", UpdateColorPickerState)
        UpdateColorPickerState()  -- Set initial state

        -- Preview toggle button
        local previewBtn = GUI:CreateButton(tabContent, "Toggle Preview", 120, 24)
        previewBtn:SetPoint("TOPLEFT", PADDING, y)
        previewBtn:SetScript("OnClick", function()
            if _G.LuheyUI_ToggleRaidBuffsPreview then
                local isPreview = _G.LuheyUI_ToggleRaidBuffsPreview()
                previewBtn:SetText(isPreview and "Hide Preview" or "Toggle Preview")
            end
        end)
        y = y - 35

        y = y - 10

        -- Quick Salvage Section
        local quickSalvageHeader = GUI:CreateSectionHeader(tabContent, "Quick Salvage")
        quickSalvageHeader:SetPoint("TOPLEFT", PADDING, y)
        y = y - quickSalvageHeader.gap

        local quickSalvageDesc = GUI:CreateLabel(tabContent,
            "Mill, prospect, or disenchant items with a single click using a modifier key. Requires the corresponding profession. If your salvaging profession skill is not recognised at first, try opening and closing the Professions UI.",
            11, C.textMuted)
        quickSalvageDesc:SetPoint("TOPLEFT", PADDING, y)
        quickSalvageDesc:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        quickSalvageDesc:SetJustifyH("LEFT")
        quickSalvageDesc:SetWordWrap(true)
        quickSalvageDesc:SetHeight(20)
        y = y - 30

        -- Ensure quickSalvage settings exist
        if not db.general.quickSalvage then
            db.general.quickSalvage = { enabled = false, modifier = "ALT" }
        end
        local qsDB = db.general.quickSalvage

        local qsEnableCheck = GUI:CreateFormCheckbox(tabContent, "Enable Quick Salvage", "enabled", qsDB, function()
            if _G.LuheyUI_RefreshQuickSalvage then _G.LuheyUI_RefreshQuickSalvage() end
        end)
        qsEnableCheck:SetPoint("TOPLEFT", PADDING, y)
        qsEnableCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        y = y - FORM_ROW

        local modifierOptions = {
            {value = "ALT", text = "Alt"},
            {value = "ALTCTRL", text = "Alt + Ctrl"},
            {value = "ALTSHIFT", text = "Alt + Shift"},
        }
        local qsModifierDropdown = GUI:CreateFormDropdown(tabContent, "Modifier Key", modifierOptions, "modifier", qsDB, function()
            if _G.LuheyUI_RefreshQuickSalvage then _G.LuheyUI_RefreshQuickSalvage() end
        end)
        qsModifierDropdown:SetPoint("TOPLEFT", PADDING, y)
        qsModifierDropdown:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        y = y - FORM_ROW

        local qsActionsDesc = GUI:CreateLabel(tabContent,
            "Milling: Herbs (5+ stack)  |  Prospecting: Ores (5+ stack)  |  Disenchanting: Green+ gear",
            11, C.textMuted)
        qsActionsDesc:SetPoint("TOPLEFT", PADDING, y)
        qsActionsDesc:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        qsActionsDesc:SetJustifyH("LEFT")
        qsActionsDesc:SetWordWrap(true)
        qsActionsDesc:SetHeight(20)
        y = y - 30

        y = y - 10

        -- M+ Dungeons Section
        local mplusHeader = GUI:CreateSectionHeader(tabContent, "M+ Dungeons")
        mplusHeader:SetPoint("TOPLEFT", PADDING, y)
        y = y - mplusHeader.gap

        local mplusDesc = GUI:CreateLabel(tabContent,
            "Click dungeon icons in the M+ tab to teleport (requires +20 achievement for that dungeon).",
            11, C.textMuted)
        mplusDesc:SetPoint("TOPLEFT", PADDING, y)
        mplusDesc:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        mplusDesc:SetJustifyH("LEFT")
        mplusDesc:SetWordWrap(true)
        mplusDesc:SetHeight(20)
        y = y - 30

        if db.general.mplusTeleportEnabled == nil then db.general.mplusTeleportEnabled = true end
        local teleportCheck = GUI:CreateFormCheckbox(tabContent, "Click-to-Teleport on M+ Tab", "mplusTeleportEnabled", db.general, nil)
        teleportCheck:SetPoint("TOPLEFT", PADDING, y)
        teleportCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        y = y - FORM_ROW

        if db.general.keyTrackerEnabled == nil then db.general.keyTrackerEnabled = true end
        local keyTrackerCheck = GUI:CreateFormCheckbox(tabContent, "Show Party Keys on M+ Tab", "keyTrackerEnabled", db.general, nil)
        keyTrackerCheck:SetPoint("TOPLEFT", PADDING, y)
        keyTrackerCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        y = y - FORM_ROW

        if db.general.keyTrackerFontSize == nil then db.general.keyTrackerFontSize = 9 end
        local fontSizeSlider = GUI:CreateFormSlider(tabContent, "Key Tracker Font Size", 7, 12, 1, "keyTrackerFontSize", db.general, function()
            if _G.LuheyUI_RefreshKeyTrackerFonts then
                _G.LuheyUI_RefreshKeyTrackerFonts()
            end
        end)
        fontSizeSlider:SetPoint("TOPLEFT", PADDING, y)
        fontSizeSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        y = y - FORM_ROW

        y = y - 10

        -- Others Section
        local othersHeader = GUI:CreateSectionHeader(tabContent, "Others")
        othersHeader:SetPoint("TOPLEFT", PADDING, y)
        y = y - othersHeader.gap

        local minimapBtnDB = db.minimapButton
        if minimapBtnDB then
            local showMinimapIconCheck = GUI:CreateFormCheckbox(tabContent, "Hide LUI Minimap Icon", "hide", minimapBtnDB, function(dbVal)
                local LibDBIcon = LibStub("LibDBIcon-1.0", true)
                if LibDBIcon then
                    if dbVal then
                        LibDBIcon:Hide("LuheyUI")
                    else
                        LibDBIcon:Show("LuheyUI")
                    end
                end
            end)
            showMinimapIconCheck:SetPoint("TOPLEFT", PADDING, y)
            showMinimapIconCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
            y = y - FORM_ROW
        end

        local panelAlphaSlider = GUI:CreateFormSlider(tabContent, "LUI Panel Transparency", 0.3, 1.0, 0.01, "configPanelAlpha", db, function(val)
            local mainFrame = GUI.MainFrame
            if mainFrame then
                local bgColor = GUI.Colors.bg
                mainFrame:SetBackdropColor(bgColor[1], bgColor[2], bgColor[3], val)
            end
        end)
        panelAlphaSlider:SetPoint("TOPLEFT", PADDING, y)
        panelAlphaSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        y = y - FORM_ROW

        tabContent:SetHeight(math.abs(y) + 50)
    end

    -- =====================================================
    -- SUB-TAB: HUD VISIBILITY
    -- =====================================================
    local function BuildHUDVisibilityTab(tabContent)
        local y = -10
        local FORM_ROW = 32

        -- Set search context for auto-registration
        GUI:SetSearchContext({tabIndex = 1, tabName = "General & QoL", subTabIndex = 2, subTabName = "HUD Visibility"})

        -- Ensure cdmVisibility settings exist
        if not db.cdmVisibility then db.cdmVisibility = {} end
        local cdmVis = db.cdmVisibility
        if cdmVis.showAlways == nil then cdmVis.showAlways = true end
        if cdmVis.showWhenTargetExists == nil then cdmVis.showWhenTargetExists = false end
        if cdmVis.showInCombat == nil then cdmVis.showInCombat = false end
        if cdmVis.showInGroup == nil then cdmVis.showInGroup = false end
        if cdmVis.showInInstance == nil then cdmVis.showInInstance = false end
        if cdmVis.showOnMouseover == nil then cdmVis.showOnMouseover = false end
        if cdmVis.fadeDuration == nil then cdmVis.fadeDuration = 0.2 end
        if cdmVis.fadeOutAlpha == nil then cdmVis.fadeOutAlpha = 0 end

        local function RefreshCDMVisibility()
            if _G.LuheyUI_RefreshCDMVisibility then
                _G.LuheyUI_RefreshCDMVisibility()
            end
        end

        -- CDM Visibility Section
        local cdmHeader = GUI:CreateSectionHeader(tabContent, "CDM Visibility")
        cdmHeader:SetPoint("TOPLEFT", PADDING, y)
        y = y - cdmHeader.gap

        local cdmTip = GUI:CreateLabel(tabContent,
            "Show CDM viewers and power bars. Uncheck 'Show Always' to use conditional visibility.",
            11, C.textMuted)
        cdmTip:SetPoint("TOPLEFT", PADDING, y)
        cdmTip:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        cdmTip:SetJustifyH("LEFT")
        y = y - 28

        local cdmConditionChecks = {}

        local function UpdateCDMConditionState()
            local enabled = not cdmVis.showAlways
            for _, check in ipairs(cdmConditionChecks) do
                if enabled then
                    check:SetAlpha(1)
                    if check.track then check.track:EnableMouse(true) end
                else
                    check:SetAlpha(0.4)
                    if check.track then check.track:EnableMouse(false) end
                end
            end
        end

        local cdmAlwaysCheck = GUI:CreateFormCheckbox(tabContent, "Show Always", "showAlways", cdmVis, function()
            RefreshCDMVisibility()
            UpdateCDMConditionState()
        end)
        cdmAlwaysCheck:SetPoint("TOPLEFT", PADDING, y)
        cdmAlwaysCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        y = y - FORM_ROW

        local cdmTargetCheck = GUI:CreateFormCheckbox(tabContent, "Show When Target Exists", "showWhenTargetExists", cdmVis, RefreshCDMVisibility)
        cdmTargetCheck:SetPoint("TOPLEFT", PADDING, y)
        cdmTargetCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        table.insert(cdmConditionChecks, cdmTargetCheck)
        y = y - FORM_ROW

        local cdmCombatCheck = GUI:CreateFormCheckbox(tabContent, "Show In Combat", "showInCombat", cdmVis, RefreshCDMVisibility)
        cdmCombatCheck:SetPoint("TOPLEFT", PADDING, y)
        cdmCombatCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        table.insert(cdmConditionChecks, cdmCombatCheck)
        y = y - FORM_ROW

        local cdmGroupCheck = GUI:CreateFormCheckbox(tabContent, "Show In Group", "showInGroup", cdmVis, RefreshCDMVisibility)
        cdmGroupCheck:SetPoint("TOPLEFT", PADDING, y)
        cdmGroupCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        table.insert(cdmConditionChecks, cdmGroupCheck)
        y = y - FORM_ROW

        local cdmInstanceCheck = GUI:CreateFormCheckbox(tabContent, "Show In Instance", "showInInstance", cdmVis, RefreshCDMVisibility)
        cdmInstanceCheck:SetPoint("TOPLEFT", PADDING, y)
        cdmInstanceCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        table.insert(cdmConditionChecks, cdmInstanceCheck)
        y = y - FORM_ROW

        local cdmMouseoverCheck = GUI:CreateFormCheckbox(tabContent, "Show On Mouseover", "showOnMouseover", cdmVis, function()
            RefreshCDMVisibility()
            if _G.LuheyUI_RefreshCDMMouseover then
                _G.LuheyUI_RefreshCDMMouseover()
            end
        end)
        cdmMouseoverCheck:SetPoint("TOPLEFT", PADDING, y)
        cdmMouseoverCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        table.insert(cdmConditionChecks, cdmMouseoverCheck)
        y = y - FORM_ROW

        UpdateCDMConditionState()

        local cdmFadeSlider = GUI:CreateFormSlider(tabContent, "Fade Duration (sec)", 0.1, 1.0, 0.05, "fadeDuration", cdmVis, RefreshCDMVisibility)
        cdmFadeSlider:SetPoint("TOPLEFT", PADDING, y)
        cdmFadeSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        y = y - FORM_ROW

        local cdmFadeAlpha = GUI:CreateFormSlider(tabContent, "Fade Out Opacity", 0, 1.0, 0.05, "fadeOutAlpha", cdmVis, RefreshCDMVisibility)
        cdmFadeAlpha:SetPoint("TOPLEFT", PADDING, y)
        cdmFadeAlpha:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        y = y - FORM_ROW

        if cdmVis.hideWhenMounted == nil then cdmVis.hideWhenMounted = false end
        local cdmMountedCheck = GUI:CreateFormCheckbox(tabContent, "Hide When Mounted", "hideWhenMounted", cdmVis, RefreshCDMVisibility)
        cdmMountedCheck:SetPoint("TOPLEFT", PADDING, y)
        cdmMountedCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        y = y - FORM_ROW

        local cdmMountedHint = GUI:CreateLabel(tabContent,
            "When enabled, elements hide while mounted regardless of the settings above.",
            11, C.textMuted)
        cdmMountedHint:SetPoint("TOPLEFT", PADDING, y)
        cdmMountedHint:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        cdmMountedHint:SetJustifyH("LEFT")
        y = y - 20

        y = y - 10

        -- Unitframes Visibility Section
        if not db.unitframesVisibility then db.unitframesVisibility = {} end
        local ufVis = db.unitframesVisibility
        if ufVis.showAlways == nil then ufVis.showAlways = true end
        if ufVis.showWhenTargetExists == nil then ufVis.showWhenTargetExists = false end
        if ufVis.showInCombat == nil then ufVis.showInCombat = false end
        if ufVis.showInGroup == nil then ufVis.showInGroup = false end
        if ufVis.showInInstance == nil then ufVis.showInInstance = false end
        if ufVis.showOnMouseover == nil then ufVis.showOnMouseover = false end
        if ufVis.fadeDuration == nil then ufVis.fadeDuration = 0.2 end
        if ufVis.fadeOutAlpha == nil then ufVis.fadeOutAlpha = 0 end

        local function RefreshUnitframesVisibility()
            if _G.LuheyUI_RefreshUnitframesVisibility then
                _G.LuheyUI_RefreshUnitframesVisibility()
            end
        end

        local ufHeader = GUI:CreateSectionHeader(tabContent, "Unitframes Visibility")
        ufHeader:SetPoint("TOPLEFT", PADDING, y)
        y = y - ufHeader.gap

        local ufTip = GUI:CreateLabel(tabContent,
            "Show unit frames. Uncheck 'Show Always' to use conditional visibility.",
            11, C.textMuted)
        ufTip:SetPoint("TOPLEFT", PADDING, y)
        ufTip:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        ufTip:SetJustifyH("LEFT")
        y = y - 28

        local ufConditionChecks = {}

        local function UpdateUFConditionState()
            local enabled = not ufVis.showAlways
            for _, check in ipairs(ufConditionChecks) do
                if enabled then
                    check:SetAlpha(1)
                    if check.track then check.track:EnableMouse(true) end
                else
                    check:SetAlpha(0.4)
                    if check.track then check.track:EnableMouse(false) end
                end
            end
        end

        local ufAlwaysCheck = GUI:CreateFormCheckbox(tabContent, "Show Always", "showAlways", ufVis, function()
            RefreshUnitframesVisibility()
            UpdateUFConditionState()
        end)
        ufAlwaysCheck:SetPoint("TOPLEFT", PADDING, y)
        ufAlwaysCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        y = y - FORM_ROW

        local ufTargetCheck = GUI:CreateFormCheckbox(tabContent, "Show When Target Exists", "showWhenTargetExists", ufVis, RefreshUnitframesVisibility)
        ufTargetCheck:SetPoint("TOPLEFT", PADDING, y)
        ufTargetCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        table.insert(ufConditionChecks, ufTargetCheck)
        y = y - FORM_ROW

        local ufCombatCheck = GUI:CreateFormCheckbox(tabContent, "Show In Combat", "showInCombat", ufVis, RefreshUnitframesVisibility)
        ufCombatCheck:SetPoint("TOPLEFT", PADDING, y)
        ufCombatCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        table.insert(ufConditionChecks, ufCombatCheck)
        y = y - FORM_ROW

        local ufGroupCheck = GUI:CreateFormCheckbox(tabContent, "Show In Group", "showInGroup", ufVis, RefreshUnitframesVisibility)
        ufGroupCheck:SetPoint("TOPLEFT", PADDING, y)
        ufGroupCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        table.insert(ufConditionChecks, ufGroupCheck)
        y = y - FORM_ROW

        local ufInstanceCheck = GUI:CreateFormCheckbox(tabContent, "Show In Instance", "showInInstance", ufVis, RefreshUnitframesVisibility)
        ufInstanceCheck:SetPoint("TOPLEFT", PADDING, y)
        ufInstanceCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        table.insert(ufConditionChecks, ufInstanceCheck)
        y = y - FORM_ROW

        local ufMouseoverCheck = GUI:CreateFormCheckbox(tabContent, "Show On Mouseover", "showOnMouseover", ufVis, function()
            RefreshUnitframesVisibility()
            if _G.LuheyUI_RefreshUnitframesMouseover then
                _G.LuheyUI_RefreshUnitframesMouseover()
            end
        end)
        ufMouseoverCheck:SetPoint("TOPLEFT", PADDING, y)
        ufMouseoverCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        table.insert(ufConditionChecks, ufMouseoverCheck)
        y = y - FORM_ROW

        UpdateUFConditionState()

        local ufFadeSlider = GUI:CreateFormSlider(tabContent, "Fade Duration (sec)", 0.1, 1.0, 0.05, "fadeDuration", ufVis, RefreshUnitframesVisibility)
        ufFadeSlider:SetPoint("TOPLEFT", PADDING, y)
        ufFadeSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        y = y - FORM_ROW

        local ufFadeAlpha = GUI:CreateFormSlider(tabContent, "Fade Out Opacity", 0, 1.0, 0.05, "fadeOutAlpha", ufVis, RefreshUnitframesVisibility)
        ufFadeAlpha:SetPoint("TOPLEFT", PADDING, y)
        ufFadeAlpha:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        y = y - FORM_ROW

        if ufVis.alwaysShowCastbars == nil then ufVis.alwaysShowCastbars = false end
        local ufCastbarsCheck = GUI:CreateFormCheckbox(tabContent, "Always Show Castbars", "alwaysShowCastbars", ufVis, RefreshUnitframesVisibility)
        ufCastbarsCheck:SetPoint("TOPLEFT", PADDING, y)
        ufCastbarsCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        table.insert(ufConditionChecks, ufCastbarsCheck)
        y = y - FORM_ROW

        if ufVis.hideWhenMounted == nil then ufVis.hideWhenMounted = false end
        local ufMountedCheck = GUI:CreateFormCheckbox(tabContent, "Hide When Mounted", "hideWhenMounted", ufVis, RefreshUnitframesVisibility)
        ufMountedCheck:SetPoint("TOPLEFT", PADDING, y)
        ufMountedCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        y = y - FORM_ROW

        local ufMountedHint = GUI:CreateLabel(tabContent,
            "When enabled, elements hide while mounted regardless of the settings above.",
            11, C.textMuted)
        ufMountedHint:SetPoint("TOPLEFT", PADDING, y)
        ufMountedHint:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        ufMountedHint:SetJustifyH("LEFT")
        y = y - 20

        -- =====================================================
        -- CUSTOM TRACKERS VISIBILITY SECTION
        -- =====================================================
        if not db.customTrackersVisibility then db.customTrackersVisibility = {} end
        local ctVis = db.customTrackersVisibility
        if ctVis.showAlways == nil then ctVis.showAlways = true end
        if ctVis.showWhenTargetExists == nil then ctVis.showWhenTargetExists = false end
        if ctVis.showInCombat == nil then ctVis.showInCombat = false end
        if ctVis.showInGroup == nil then ctVis.showInGroup = false end
        if ctVis.showInInstance == nil then ctVis.showInInstance = false end
        if ctVis.showOnMouseover == nil then ctVis.showOnMouseover = false end
        if ctVis.fadeDuration == nil then ctVis.fadeDuration = 0.2 end
        if ctVis.fadeOutAlpha == nil then ctVis.fadeOutAlpha = 0 end

        local function RefreshCustomTrackersVisibility()
            if _G.LuheyUI_RefreshCustomTrackersVisibility then
                _G.LuheyUI_RefreshCustomTrackersVisibility()
            end
        end

        local ctHeader = GUI:CreateSectionHeader(tabContent, "Custom Items/Spells Bars")
        ctHeader:SetPoint("TOPLEFT", PADDING, y)
        y = y - ctHeader.gap

        local ctTip = GUI:CreateLabel(tabContent,
            "Show custom tracker bars. Uncheck 'Show Always' to use conditional visibility.",
            11, C.textMuted)
        ctTip:SetPoint("TOPLEFT", PADDING, y)
        ctTip:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        ctTip:SetJustifyH("LEFT")
        y = y - 28

        local ctConditionChecks = {}

        local function UpdateCTConditionState()
            local enabled = not ctVis.showAlways
            for _, check in ipairs(ctConditionChecks) do
                if enabled then
                    check:SetAlpha(1)
                    if check.track then check.track:EnableMouse(true) end
                else
                    check:SetAlpha(0.4)
                    if check.track then check.track:EnableMouse(false) end
                end
            end
        end

        local ctAlwaysCheck = GUI:CreateFormCheckbox(tabContent, "Show Always", "showAlways", ctVis, function()
            RefreshCustomTrackersVisibility()
            UpdateCTConditionState()
        end)
        ctAlwaysCheck:SetPoint("TOPLEFT", PADDING, y)
        ctAlwaysCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        y = y - FORM_ROW

        local ctTargetCheck = GUI:CreateFormCheckbox(tabContent, "Show When Target Exists", "showWhenTargetExists", ctVis, RefreshCustomTrackersVisibility)
        ctTargetCheck:SetPoint("TOPLEFT", PADDING, y)
        ctTargetCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        table.insert(ctConditionChecks, ctTargetCheck)
        y = y - FORM_ROW

        local ctCombatCheck = GUI:CreateFormCheckbox(tabContent, "Show In Combat", "showInCombat", ctVis, RefreshCustomTrackersVisibility)
        ctCombatCheck:SetPoint("TOPLEFT", PADDING, y)
        ctCombatCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        table.insert(ctConditionChecks, ctCombatCheck)
        y = y - FORM_ROW

        local ctGroupCheck = GUI:CreateFormCheckbox(tabContent, "Show In Group", "showInGroup", ctVis, RefreshCustomTrackersVisibility)
        ctGroupCheck:SetPoint("TOPLEFT", PADDING, y)
        ctGroupCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        table.insert(ctConditionChecks, ctGroupCheck)
        y = y - FORM_ROW

        local ctInstanceCheck = GUI:CreateFormCheckbox(tabContent, "Show In Instance", "showInInstance", ctVis, RefreshCustomTrackersVisibility)
        ctInstanceCheck:SetPoint("TOPLEFT", PADDING, y)
        ctInstanceCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        table.insert(ctConditionChecks, ctInstanceCheck)
        y = y - FORM_ROW

        local ctMouseoverCheck = GUI:CreateFormCheckbox(tabContent, "Show On Mouseover", "showOnMouseover", ctVis, function()
            RefreshCustomTrackersVisibility()
            if _G.LuheyUI_RefreshCustomTrackersMouseover then
                _G.LuheyUI_RefreshCustomTrackersMouseover()
            end
        end)
        ctMouseoverCheck:SetPoint("TOPLEFT", PADDING, y)
        ctMouseoverCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        table.insert(ctConditionChecks, ctMouseoverCheck)
        y = y - FORM_ROW

        local ctFadeSlider = GUI:CreateFormSlider(tabContent, "Fade Duration (sec)", 0.1, 1.0, 0.05, "fadeDuration", ctVis, RefreshCustomTrackersVisibility)
        ctFadeSlider:SetPoint("TOPLEFT", PADDING, y)
        ctFadeSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        y = y - FORM_ROW

        local ctFadeAlpha = GUI:CreateFormSlider(tabContent, "Fade Out Opacity", 0, 1.0, 0.05, "fadeOutAlpha", ctVis, RefreshCustomTrackersVisibility)
        ctFadeAlpha:SetPoint("TOPLEFT", PADDING, y)
        ctFadeAlpha:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        y = y - FORM_ROW

        if ctVis.hideWhenMounted == nil then ctVis.hideWhenMounted = false end
        local ctMountedCheck = GUI:CreateFormCheckbox(tabContent, "Hide When Mounted", "hideWhenMounted", ctVis, RefreshCustomTrackersVisibility)
        ctMountedCheck:SetPoint("TOPLEFT", PADDING, y)
        ctMountedCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        y = y - FORM_ROW

        local ctMountedHint = GUI:CreateLabel(tabContent,
            "When enabled, elements hide while mounted regardless of the settings above.",
            11, C.textMuted)
        ctMountedHint:SetPoint("TOPLEFT", PADDING, y)
        ctMountedHint:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        ctMountedHint:SetJustifyH("LEFT")
        y = y - 20

        UpdateCTConditionState()

        tabContent:SetHeight(math.abs(y) + 50)
    end

    -- =====================================================
    -- SUB-TAB: CURSOR & CROSSHAIR
    -- =====================================================
    local function BuildCrosshairTab(tabContent)
        local y = -10
        local FORM_ROW = 32

        -- Set search context for auto-registration
        GUI:SetSearchContext({tabIndex = 1, tabName = "General & QoL", subTabIndex = 3, subTabName = "Cursor & Crosshair"})

        -- ========== CURSOR RING SECTION (before crosshair) ==========
        local cursorHeader = GUI:CreateSectionHeader(tabContent, "Cursor Ring")
        cursorHeader:SetPoint("TOPLEFT", PADDING, y)
        y = y - cursorHeader.gap

        if db and db.reticle then
            local cr = db.reticle

            local enableCheck = GUI:CreateFormCheckbox(tabContent, "Enable Reticle", "enabled", cr, RefreshReticle)
            enableCheck:SetPoint("TOPLEFT", PADDING, y)
            enableCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
            y = y - FORM_ROW

            -- Reticle Style dropdown
            local reticleOptions = {
                {value = "dot", text = "Dot"},
                {value = "cross", text = "Cross"},
                {value = "chevron", text = "Chevron"},
                {value = "diamond", text = "Diamond"},
            }
            local reticleDropdown = GUI:CreateFormDropdown(tabContent, "Reticle Style", reticleOptions, "reticleStyle", cr, RefreshReticle)
            reticleDropdown:SetPoint("TOPLEFT", PADDING, y)
            reticleDropdown:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
            y = y - FORM_ROW

            local reticleSizeSlider = GUI:CreateFormSlider(tabContent, "Reticle Size", 4, 20, 1, "reticleSize", cr, RefreshReticle)
            reticleSizeSlider:SetPoint("TOPLEFT", PADDING, y)
            reticleSizeSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
            y = y - FORM_ROW

            -- Ring Style dropdown
            local ringStyleOptions = {
                {value = "thin", text = "Thin"},
                {value = "standard", text = "Standard"},
                {value = "thick", text = "Thick"},
                {value = "solid", text = "Solid"},
            }
            local ringStyleDropdown = GUI:CreateFormDropdown(tabContent, "Ring Style", ringStyleOptions, "ringStyle", cr, RefreshReticle)
            ringStyleDropdown:SetPoint("TOPLEFT", PADDING, y)
            ringStyleDropdown:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
            y = y - FORM_ROW

            local ringSizeSlider = GUI:CreateFormSlider(tabContent, "Ring Size", 20, 80, 1, "ringSize", cr, RefreshReticle)
            ringSizeSlider:SetPoint("TOPLEFT", PADDING, y)
            ringSizeSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
            y = y - FORM_ROW

            local classColorCheck = GUI:CreateFormCheckbox(tabContent, "Use Class Color", "useClassColor", cr, RefreshReticle)
            classColorCheck:SetPoint("TOPLEFT", PADDING, y)
            classColorCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
            y = y - FORM_ROW

            local customColorPicker = GUI:CreateFormColorPicker(tabContent, "Custom Color", "customColor", cr, RefreshReticle)
            customColorPicker:SetPoint("TOPLEFT", PADDING, y)
            customColorPicker:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
            y = y - FORM_ROW

            local combatAlphaSlider = GUI:CreateFormSlider(tabContent, "Combat Opacity", 0, 1, 0.05, "inCombatAlpha", cr, RefreshReticle)
            combatAlphaSlider:SetPoint("TOPLEFT", PADDING, y)
            combatAlphaSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
            y = y - FORM_ROW

            local oocAlphaSlider = GUI:CreateFormSlider(tabContent, "Out-of-Combat Opacity", 0, 1, 0.05, "outCombatAlpha", cr, RefreshReticle)
            oocAlphaSlider:SetPoint("TOPLEFT", PADDING, y)
            oocAlphaSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
            y = y - FORM_ROW

            local hideOOCCheck = GUI:CreateFormCheckbox(tabContent, "Hide Outside Combat", "hideOutOfCombat", cr, RefreshReticle)
            hideOOCCheck:SetPoint("TOPLEFT", PADDING, y)
            hideOOCCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
            y = y - FORM_ROW

            -- GCD Settings sub-section
            y = y - 10  -- Extra spacing before sub-section
            local gcdLabel = GUI:CreateLabel(tabContent, "GCD Settings", 12, C.accent)
            gcdLabel:SetPoint("TOPLEFT", PADDING, y)
            y = y - 20

            local gcdEnableCheck = GUI:CreateFormCheckbox(tabContent, "Enable GCD Swipe", "gcdEnabled", cr, RefreshReticle)
            gcdEnableCheck:SetPoint("TOPLEFT", PADDING, y)
            gcdEnableCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
            y = y - FORM_ROW

            local gcdFadeSlider = GUI:CreateFormSlider(tabContent, "Ring Fade During GCD", 0, 1, 0.05, "gcdFadeRing", cr, RefreshReticle)
            gcdFadeSlider:SetPoint("TOPLEFT", PADDING, y)
            gcdFadeSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
            y = y - FORM_ROW

            local gcdReverseCheck = GUI:CreateFormCheckbox(tabContent, "Reverse Swipe", "gcdReverse", cr, RefreshReticle)
            gcdReverseCheck:SetPoint("TOPLEFT", PADDING, y)
            gcdReverseCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
            y = y - FORM_ROW

            local rightClickCheck = GUI:CreateFormCheckbox(tabContent, "Hide on Right-Click", "hideOnRightClick", cr, RefreshReticle)
            rightClickCheck:SetPoint("TOPLEFT", PADDING, y)
            rightClickCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
            y = y - FORM_ROW

            local cursorTipText = GUI:CreateLabel(tabContent, "Note that cursor replacements consume some CPU resources due to continuous tracking. Negligible on modern CPUs.", 11, C.textMuted)
            cursorTipText:SetPoint("TOPLEFT", PADDING, y)
            cursorTipText:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
            cursorTipText:SetJustifyH("LEFT")
            cursorTipText:SetWordWrap(true)
            y = y - 40
        end

        y = y - 20  -- Spacing between sections

        -- ========== LUI CROSSHAIR SECTION ==========
        local crossHeader = GUI:CreateSectionHeader(tabContent, "LUI Crosshair")
        crossHeader:SetPoint("TOPLEFT", PADDING, y)
        y = y - crossHeader.gap

        if db and db.crosshair then
            local ch = db.crosshair

            local enableCheck = GUI:CreateFormCheckbox(tabContent, "Show Crosshair", "enabled", ch, RefreshCrosshair)
            enableCheck:SetPoint("TOPLEFT", PADDING, y)
            enableCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
            y = y - FORM_ROW

            local combatCheck = GUI:CreateFormCheckbox(tabContent, "Combat Only", "onlyInCombat", ch, RefreshCrosshair)
            combatCheck:SetPoint("TOPLEFT", PADDING, y)
            combatCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
            y = y - FORM_ROW

            -- Out of melee range color change
            local outOfRangeColorPicker  -- Forward declare
            local rangeColorCombatOnlyCheck  -- Forward declare
            local hideUntilOutOfRangeCheck  -- Forward declare

            local rangeColorCheck = GUI:CreateFormCheckbox(tabContent, "Out of Melee Range Check", "changeColorOnRange", ch, function(val)
                RefreshCrosshair()
                -- Enable/disable the related controls based on toggle
                if outOfRangeColorPicker and outOfRangeColorPicker.SetEnabled then
                    outOfRangeColorPicker:SetEnabled(val)
                end
                if rangeColorCombatOnlyCheck and rangeColorCombatOnlyCheck.SetEnabled then
                    rangeColorCombatOnlyCheck:SetEnabled(val)
                end
                if hideUntilOutOfRangeCheck and hideUntilOutOfRangeCheck.SetEnabled then
                    hideUntilOutOfRangeCheck:SetEnabled(val)
                end
            end)
            rangeColorCheck:SetPoint("TOPLEFT", PADDING, y)
            rangeColorCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
            y = y - FORM_ROW

            rangeColorCombatOnlyCheck = GUI:CreateFormCheckbox(tabContent, "Check Only In Combat", "rangeColorInCombatOnly", ch, RefreshCrosshair)
            rangeColorCombatOnlyCheck:SetPoint("TOPLEFT", PADDING, y)
            rangeColorCombatOnlyCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
            -- Initial state based on setting
            if rangeColorCombatOnlyCheck.SetEnabled then
                rangeColorCombatOnlyCheck:SetEnabled(ch.changeColorOnRange == true)
            end
            y = y - FORM_ROW

            hideUntilOutOfRangeCheck = GUI:CreateFormCheckbox(tabContent, "Only Show When Out of Range", "hideUntilOutOfRange", ch, RefreshCrosshair)
            hideUntilOutOfRangeCheck:SetPoint("TOPLEFT", PADDING, y)
            hideUntilOutOfRangeCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
            -- Initial state based on setting
            if hideUntilOutOfRangeCheck.SetEnabled then
                hideUntilOutOfRangeCheck:SetEnabled(ch.changeColorOnRange == true)
            end
            y = y - FORM_ROW

            if not ch.outOfRangeColor then
                ch.outOfRangeColor = { 1, 0.2, 0.2, 1 }
            end
            outOfRangeColorPicker = GUI:CreateFormColorPicker(tabContent, "Out of Melee Range Color", "outOfRangeColor", ch, function()
                RefreshCrosshair()
            end)
            outOfRangeColorPicker:SetPoint("TOPLEFT", PADDING, y)
            outOfRangeColorPicker:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
            -- Initial state based on setting
            if outOfRangeColorPicker.SetEnabled then
                outOfRangeColorPicker:SetEnabled(ch.changeColorOnRange == true)
            end
            y = y - FORM_ROW

            if not ch.lineColor then
                ch.lineColor = { ch.r or 0.286, ch.g or 0.929, ch.b or 1, ch.a or 1 }
            end
            local crossColor = GUI:CreateFormColorPicker(tabContent, "Crosshair Color", "lineColor", ch, function()
                ch.r, ch.g, ch.b, ch.a = ch.lineColor[1], ch.lineColor[2], ch.lineColor[3], ch.lineColor[4]
                RefreshCrosshair()
            end)
            crossColor:SetPoint("TOPLEFT", PADDING, y)
            crossColor:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
            y = y - FORM_ROW

            if not ch.borderColorTable then
                ch.borderColorTable = { ch.borderR or 0, ch.borderG or 0, ch.borderB or 0, ch.borderA or 1 }
            end
            local borderColor = GUI:CreateFormColorPicker(tabContent, "Outline Color", "borderColorTable", ch, function()
                ch.borderR, ch.borderG, ch.borderB, ch.borderA = ch.borderColorTable[1], ch.borderColorTable[2], ch.borderColorTable[3], ch.borderColorTable[4]
                RefreshCrosshair()
            end)
            borderColor:SetPoint("TOPLEFT", PADDING, y)
            borderColor:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
            y = y - FORM_ROW

            local sizeSlider = GUI:CreateFormSlider(tabContent, "Length", 5, 50, 1, "size", ch, RefreshCrosshair)
            sizeSlider:SetPoint("TOPLEFT", PADDING, y)
            sizeSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
            y = y - FORM_ROW

            local thickSlider = GUI:CreateFormSlider(tabContent, "Thickness", 1, 10, 1, "thickness", ch, RefreshCrosshair)
            thickSlider:SetPoint("TOPLEFT", PADDING, y)
            thickSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
            y = y - FORM_ROW

            local borderSlider = GUI:CreateFormSlider(tabContent, "Outline Size", 0, 5, 1, "borderSize", ch, RefreshCrosshair)
            borderSlider:SetPoint("TOPLEFT", PADDING, y)
            borderSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
            y = y - FORM_ROW

            local strataOptions = {
                {value = "BACKGROUND", text = "Background"},
                {value = "LOW", text = "Low"},
                {value = "MEDIUM", text = "Medium"},
                {value = "HIGH", text = "High"},
                {value = "DIALOG", text = "Dialog"},
            }
            local strataDropdown = GUI:CreateFormDropdown(tabContent, "Frame Strata", strataOptions, "strata", ch, RefreshCrosshair)
            strataDropdown:SetPoint("TOPLEFT", PADDING, y)
            strataDropdown:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
            if strataDropdown.menuFrame then
                strataDropdown.menuFrame.openUpward = true
            end
            y = y - FORM_ROW

            local xOffsetSlider = GUI:CreateFormSlider(tabContent, "X-Offset", -500, 500, 1, "offsetX", ch, RefreshCrosshair)
            xOffsetSlider:SetPoint("TOPLEFT", PADDING, y)
            xOffsetSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
            y = y - FORM_ROW

            local yOffsetSlider = GUI:CreateFormSlider(tabContent, "Y-Offset", -500, 500, 1, "offsetY", ch, RefreshCrosshair)
            yOffsetSlider:SetPoint("TOPLEFT", PADDING, y)
            yOffsetSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
            y = y - FORM_ROW
        end

        tabContent:SetHeight(math.abs(y) + 50)
    end

    -- =====================================================
    -- SUB-TAB: BUFF & DEBUFF
    -- =====================================================
    local function BuildBuffDebuffTab(tabContent)
        local y = -10
        local FORM_ROW = 32

        -- Set search context for auto-registration
        GUI:SetSearchContext({tabIndex = 1, tabName = "General & QoL", subTabIndex = 4, subTabName = "Buff & Debuff"})

        -- Section Header
        local header = GUI:CreateSectionHeader(tabContent, "Buff & Debuff Borders")
        header:SetPoint("TOPLEFT", PADDING, y)
        y = y - header.gap

        -- Description
        local desc = GUI:CreateLabel(tabContent, "Modifies borders and font size of Blizzard default Buff and Debuff frames, normally placed beside minimap.", 11, C.textMuted)
        desc:SetPoint("TOPLEFT", PADDING, y)
        desc:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        desc:SetJustifyH("LEFT")
        desc:SetWordWrap(true)
        desc:SetHeight(30)
        y = y - 40

        if db and db.buffBorders then
            -- Enable Buff Borders
            local enableBuffs = GUI:CreateFormCheckbox(tabContent, "Enable Buff Borders",
                "enableBuffs", db.buffBorders, RefreshBuffBorders)
            enableBuffs:SetPoint("TOPLEFT", PADDING, y)
            enableBuffs:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
            y = y - FORM_ROW

            -- Enable Debuff Borders
            local enableDebuffs = GUI:CreateFormCheckbox(tabContent, "Enable Debuff Borders",
                "enableDebuffs", db.buffBorders, RefreshBuffBorders)
            enableDebuffs:SetPoint("TOPLEFT", PADDING, y)
            enableDebuffs:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
            y = y - FORM_ROW

            -- Border Size slider
            local borderSlider = GUI:CreateFormSlider(tabContent, "Border Size", 1, 5, 0.5,
                "borderSize", db.buffBorders, RefreshBuffBorders)
            borderSlider:SetPoint("TOPLEFT", PADDING, y)
            borderSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
            y = y - FORM_ROW

            -- Font Size slider
            local fontSlider = GUI:CreateFormSlider(tabContent, "Font Size", 6, 24, 1,
                "fontSize", db.buffBorders, RefreshBuffBorders)
            fontSlider:SetPoint("TOPLEFT", PADDING, y)
            fontSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
            y = y - FORM_ROW

            -- Section Header: Hide Blizzard Default Buffs and Debuffs
            local hideHeader = GUI:CreateSectionHeader(tabContent, "Hide Blizzard Default Buffs and Debuffs")
            hideHeader:SetPoint("TOPLEFT", PADDING, y)
            y = y - hideHeader.gap

            -- Hide Buffs
            local hideBuffs = GUI:CreateFormCheckbox(tabContent, "Hide Buffs",
                "hideBuffFrame", db.buffBorders, RefreshBuffBorders)
            hideBuffs:SetPoint("TOPLEFT", PADDING, y)
            hideBuffs:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
            y = y - FORM_ROW

            -- Hide Debuffs
            local hideDebuffs = GUI:CreateFormCheckbox(tabContent, "Hide Debuffs",
                "hideDebuffFrame", db.buffBorders, RefreshBuffBorders)
            hideDebuffs:SetPoint("TOPLEFT", PADDING, y)
            hideDebuffs:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
            y = y - FORM_ROW
        else
            local info = GUI:CreateLabel(tabContent, "Buff/Debuff settings not available", 12, C.textMuted)
            info:SetPoint("TOPLEFT", PADDING, y)
        end

        tabContent:SetHeight(math.abs(y) + 50)
    end

    -- =====================================================
    -- SUB-TAB: CHAT
    -- =====================================================
    local function BuildChatTab(tabContent)
        local y = -10
        local FORM_ROW = 32

        -- Set search context for auto-registration
        GUI:SetSearchContext({tabIndex = 1, tabName = "General & QoL", subTabIndex = 5, subTabName = "Chat"})

        -- Refresh callback
        local function RefreshChat()
            if _G.LuheyUI_RefreshChat then
                _G.LuheyUI_RefreshChat()
            end
        end

        if db and db.chat then
            local chat = db.chat

            -- SECTION: Enable/Disable
            local enableHeader = GUI:CreateSectionHeader(tabContent, "Enable/Disable LUI Chat Module")
            enableHeader:SetPoint("TOPLEFT", PADDING, y)
            y = y - enableHeader.gap

            local enableCheck = GUI:CreateFormCheckbox(tabContent, "LUI Chat Module", "enabled", chat, RefreshChat)
            enableCheck:SetPoint("TOPLEFT", PADDING, y)
            enableCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
            y = y - FORM_ROW

            local enableInfo = GUI:CreateLabel(tabContent, "If you are using a dedicated chat addon, toggle this off.", 10, C.textMuted)
            enableInfo:SetPoint("TOPLEFT", PADDING, y)
            enableInfo:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
            enableInfo:SetJustifyH("LEFT")
            y = y - 20

            -- SECTION: Intro Message
            local introHeader = GUI:CreateSectionHeader(tabContent, "Intro Message")
            introHeader:SetPoint("TOPLEFT", PADDING, y)
            y = y - introHeader.gap

            local introCheck = GUI:CreateFormCheckbox(tabContent, "Show Login Message", "showIntroMessage", chat, nil)
            introCheck:SetPoint("TOPLEFT", PADDING, y)
            introCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
            y = y - FORM_ROW

            local introInfo = GUI:CreateLabel(tabContent, "Display the LUI reminder tips when you log in.", 10, C.textMuted)
            introInfo:SetPoint("TOPLEFT", PADDING, y)
            introInfo:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
            introInfo:SetJustifyH("LEFT")
            y = y - 20

            -- SECTION: Chat Background
            local glassHeader = GUI:CreateSectionHeader(tabContent, "Chat Background")
            glassHeader:SetPoint("TOPLEFT", PADDING, y)
            y = y - glassHeader.gap

            if chat.glass then
                local glassCheck = GUI:CreateFormCheckbox(tabContent, "Chat Background Texture", "enabled", chat.glass, RefreshChat)
                glassCheck:SetPoint("TOPLEFT", PADDING, y)
                glassCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
                y = y - FORM_ROW

                local alphaSlider = GUI:CreateFormSlider(tabContent, "Background Opacity", 0, 1.0, 0.05, "bgAlpha", chat.glass, RefreshChat)
                alphaSlider:SetPoint("TOPLEFT", PADDING, y)
                alphaSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
                y = y - FORM_ROW

                local bgColorPicker = GUI:CreateFormColorPicker(tabContent, "Background Color", "bgColor", chat.glass, RefreshChat)
                bgColorPicker:SetPoint("TOPLEFT", PADDING, y)
                bgColorPicker:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
                y = y - FORM_ROW
            end

            -- SECTION: Input Box Background
            local editBoxHeader = GUI:CreateSectionHeader(tabContent, "Input Box Background")
            editBoxHeader:SetPoint("TOPLEFT", PADDING, y)
            y = y - editBoxHeader.gap

            if chat.editBox then
                local editBoxCheck = GUI:CreateFormCheckbox(tabContent, "Input Box Background Texture", "enabled", chat.editBox, RefreshChat)
                editBoxCheck:SetPoint("TOPLEFT", PADDING, y)
                editBoxCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
                y = y - FORM_ROW

                local editBoxAlphaSlider = GUI:CreateFormSlider(tabContent, "Background Opacity", 0, 1.0, 0.05, "bgAlpha", chat.editBox, RefreshChat)
                editBoxAlphaSlider:SetPoint("TOPLEFT", PADDING, y)
                editBoxAlphaSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
                y = y - FORM_ROW

                local editBoxColorPicker = GUI:CreateFormColorPicker(tabContent, "Background Color", "bgColor", chat.editBox, RefreshChat)
                editBoxColorPicker:SetPoint("TOPLEFT", PADDING, y)
                editBoxColorPicker:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
                y = y - FORM_ROW

                local positionTopCheck = GUI:CreateFormCheckbox(tabContent, "Position Input Box at Top", "positionTop", chat.editBox, RefreshChat)
                positionTopCheck:SetPoint("TOPLEFT", PADDING, y)
                positionTopCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
                y = y - FORM_ROW

                local positionTopInfo = GUI:CreateLabel(tabContent, "Moves input box above chat tabs with opaque background.", 10, C.textMuted)
                positionTopInfo:SetPoint("TOPLEFT", PADDING, y)
                positionTopInfo:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
                positionTopInfo:SetJustifyH("LEFT")
                y = y - 20
            end

            -- SECTION: Message Fade
            local fadeHeader = GUI:CreateSectionHeader(tabContent, "Message Fade")
            fadeHeader:SetPoint("TOPLEFT", PADDING, y)
            y = y - fadeHeader.gap

            if chat.fade then
                local fadeCheck = GUI:CreateFormCheckbox(tabContent, "Fade Messages After Inactivity", "enabled", chat.fade, RefreshChat)
                fadeCheck:SetPoint("TOPLEFT", PADDING, y)
                fadeCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
                y = y - FORM_ROW

                local delaySlider = GUI:CreateFormSlider(tabContent, "Fade Delay (seconds)", 1, 120, 1, "delay", chat.fade, RefreshChat)
                delaySlider:SetPoint("TOPLEFT", PADDING, y)
                delaySlider:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
                y = y - FORM_ROW
            end

            -- SECTION: URL Detection
            local urlHeader = GUI:CreateSectionHeader(tabContent, "URL Detection")
            urlHeader:SetPoint("TOPLEFT", PADDING, y)
            y = y - urlHeader.gap

            if chat.urls then
                local urlCheck = GUI:CreateFormCheckbox(tabContent, "Make URLs Clickable", "enabled", chat.urls, RefreshChat)
                urlCheck:SetPoint("TOPLEFT", PADDING, y)
                urlCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
                y = y - FORM_ROW

                local urlInfo = GUI:CreateLabel(tabContent, "Click any URL in chat to open a copy dialog.", 10, C.textMuted)
                urlInfo:SetPoint("TOPLEFT", PADDING, y)
                urlInfo:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
                urlInfo:SetJustifyH("LEFT")
                y = y - 20
            end

            -- SECTION: Timestamps
            local timestampHeader = GUI:CreateSectionHeader(tabContent, "Timestamps")
            timestampHeader:SetPoint("TOPLEFT", PADDING, y)
            y = y - timestampHeader.gap

            if not chat.timestamps then chat.timestamps = {enabled = false, format = "24h", color = {0.6, 0.6, 0.6}} end

            local timestampCheck = GUI:CreateFormCheckbox(tabContent, "Show Timestamps", "enabled", chat.timestamps, RefreshChat)
            timestampCheck:SetPoint("TOPLEFT", PADDING, y)
            timestampCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
            y = y - FORM_ROW

            local timestampInfo = GUI:CreateLabel(tabContent, "Timestamps only appear on new messages after enabling.", 10, C.textMuted)
            timestampInfo:SetPoint("TOPLEFT", PADDING, y)
            timestampInfo:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
            timestampInfo:SetJustifyH("LEFT")
            y = y - 20

            local formatOptions = {
                {value = "24h", text = "24-Hour (15:27)"},
                {value = "12h", text = "12-Hour (3:27 PM)"},
            }
            local formatDropdown = GUI:CreateFormDropdown(tabContent, "Format", formatOptions, "format", chat.timestamps, RefreshChat)
            formatDropdown:SetPoint("TOPLEFT", PADDING, y)
            formatDropdown:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
            y = y - FORM_ROW

            local timestampColorPicker = GUI:CreateFormColorPicker(tabContent, "Timestamp Color", "color", chat.timestamps, RefreshChat)
            timestampColorPicker:SetPoint("TOPLEFT", PADDING, y)
            timestampColorPicker:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
            y = y - FORM_ROW

            -- SECTION: UI Cleanup
            local cleanupHeader = GUI:CreateSectionHeader(tabContent, "UI Cleanup")
            cleanupHeader:SetPoint("TOPLEFT", PADDING, y)
            y = y - cleanupHeader.gap

            local hideButtonsCheck = GUI:CreateFormCheckbox(tabContent, "Hide Chat Buttons", "hideButtons", chat, RefreshChat)
            hideButtonsCheck:SetPoint("TOPLEFT", PADDING, y)
            hideButtonsCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
            y = y - FORM_ROW

            local hideButtonsInfo = GUI:CreateLabel(tabContent, "Hides social, channel, and scroll buttons. Mouse wheel still scrolls.", 10, C.textMuted)
            hideButtonsInfo:SetPoint("TOPLEFT", PADDING, y)
            hideButtonsInfo:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
            hideButtonsInfo:SetJustifyH("LEFT")
            y = y - 20

            y = y - FORM_ROW

            -- SECTION: Copy Button
            local copyHeader = GUI:CreateSectionHeader(tabContent, "Copy Button")
            copyHeader:SetPoint("TOPLEFT", PADDING, y)
            y = y - copyHeader.gap

            local copyButtonOptions = {
                {value = "always", text = "Show Always"},
                {value = "hover", text = "Show on Hover"},
                {value = "disabled", text = "Disabled"},
            }
            local copyButtonDropdown = GUI:CreateFormDropdown(tabContent, "Copy Button", copyButtonOptions, "copyButtonMode", chat, RefreshChat)
            copyButtonDropdown:SetPoint("TOPLEFT", PADDING, y)
            copyButtonDropdown:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
            if copyButtonDropdown.menuFrame then
                copyButtonDropdown.menuFrame.openUpward = true
            end
            y = y - FORM_ROW

            local copyButtonInfo = GUI:CreateLabel(tabContent, "Controls the copy button on each chat frame for copying chat history.", 10, C.textMuted)
            copyButtonInfo:SetPoint("TOPLEFT", PADDING, y)
            copyButtonInfo:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
            copyButtonInfo:SetJustifyH("LEFT")
            y = y - 20
        end

        tabContent:SetHeight(math.abs(y) + 50)
    end

    -- =====================================================
    -- SUB-TAB: TOOLTIP
    -- =====================================================
    local function BuildTooltipTab(tabContent)
        local y = -10
        local FORM_ROW = 32

        -- Set search context for auto-registration
        GUI:SetSearchContext({tabIndex = 1, tabName = "General & QoL", subTabIndex = 6, subTabName = "Tooltip"})

        -- Refresh callback
        local function RefreshTooltips()
            if _G.LuheyUI_RefreshTooltips then
                _G.LuheyUI_RefreshTooltips()
            end
        end

        local tooltip = db and db.tooltip
        if not tooltip then return end

        -- Visibility dropdown options
        local visibilityOptions = {
            {value = "SHOW", text = "Always Show"},
            {value = "HIDE", text = "Always Hide"},
            {value = "SHIFT", text = "Shift to Show"},
            {value = "CTRL", text = "Ctrl to Show"},
            {value = "ALT", text = "Alt to Show"},
        }

        -- Combat override dropdown options
        local combatOverrideOptions = {
            {value = "NONE", text = "None"},
            {value = "SHIFT", text = "Shift"},
            {value = "CTRL", text = "Ctrl"},
            {value = "ALT", text = "Alt"},
        }

        -- SECTION: Enable/Disable
        GUI:SetSearchSection("Enable/Disable")
        local enableHeader = GUI:CreateSectionHeader(tabContent, "Enable/Disable QUI Tooltip Module")
        enableHeader:SetPoint("TOPLEFT", PADDING, y)
        y = y - enableHeader.gap

        local enableCheck = GUI:CreateFormCheckbox(tabContent, "LUI Tooltip Module", "enabled", tooltip, RefreshTooltips)
        enableCheck:SetPoint("TOPLEFT", PADDING, y)
        enableCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        y = y - FORM_ROW

        local enableInfo = GUI:CreateLabel(tabContent, "Controls tooltip positioning and per-context visibility.", 10, C.textMuted)
        enableInfo:SetPoint("TOPLEFT", PADDING, y)
        enableInfo:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        enableInfo:SetJustifyH("LEFT")
        y = y - 20

        -- SECTION: Cursor Anchor
        GUI:SetSearchSection("Cursor Anchor")
        local cursorHeader = GUI:CreateSectionHeader(tabContent, "Cursor Anchor")
        cursorHeader:SetPoint("TOPLEFT", PADDING, y)
        y = y - cursorHeader.gap

        local cursorCheck = GUI:CreateFormCheckbox(tabContent, "Anchor Tooltip to Cursor", "anchorToCursor", tooltip, RefreshTooltips)
        cursorCheck:SetPoint("TOPLEFT", PADDING, y)
        cursorCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        y = y - FORM_ROW

        local cursorInfo = GUI:CreateLabel(tabContent, "Tooltip follows your mouse cursor instead of default position.", 10, C.textMuted)
        cursorInfo:SetPoint("TOPLEFT", PADDING, y)
        cursorInfo:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        cursorInfo:SetJustifyH("LEFT")
        y = y - 20

        -- Class Color Name option
        local classColorCheck = GUI:CreateFormCheckbox(tabContent, "Class Color Player Names", "classColorName", tooltip, RefreshTooltips)
        classColorCheck:SetPoint("TOPLEFT", PADDING, y)
        classColorCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        y = y - FORM_ROW

        local classColorInfo = GUI:CreateLabel(tabContent, "Color player names in tooltips by their class.", 10, C.textMuted)
        classColorInfo:SetPoint("TOPLEFT", PADDING, y)
        classColorInfo:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        classColorInfo:SetJustifyH("LEFT")
        y = y - 20

        -- Hide Health Bar option
        local hideHealthBarCheck = GUI:CreateFormCheckbox(tabContent, "Hide Tooltip Health Bar", "hideHealthBar", tooltip, RefreshTooltips)
        hideHealthBarCheck:SetPoint("TOPLEFT", PADDING, y)
        hideHealthBarCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        y = y - FORM_ROW

        local hideHealthBarInfo = GUI:CreateLabel(tabContent, "Hides the health bar shown at the bottom of unit tooltips.", 10, C.textMuted)
        hideHealthBarInfo:SetPoint("TOPLEFT", PADDING, y)
        hideHealthBarInfo:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        hideHealthBarInfo:SetJustifyH("LEFT")
        y = y - 20

        -- SECTION: Tooltip Visibility
        GUI:SetSearchSection("Tooltip Visibility")
        local visHeader = GUI:CreateSectionHeader(tabContent, "Tooltip Visibility")
        visHeader:SetPoint("TOPLEFT", PADDING, y)
        y = y - visHeader.gap

        local visInfo = GUI:CreateLabel(tabContent, "Control tooltip visibility per element type. Choose a modifier key to only show tooltips while holding that key.", 10, C.textMuted)
        visInfo:SetPoint("TOPLEFT", PADDING, y)
        visInfo:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        visInfo:SetJustifyH("LEFT")
        y = y - 24

        if tooltip.visibility then
            local npcsDropdown = GUI:CreateFormDropdown(tabContent, "NPCs & Players", visibilityOptions, "npcs", tooltip.visibility, RefreshTooltips)
            npcsDropdown:SetPoint("TOPLEFT", PADDING, y)
            npcsDropdown:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
            y = y - FORM_ROW

            local abilitiesDropdown = GUI:CreateFormDropdown(tabContent, "Abilities", visibilityOptions, "abilities", tooltip.visibility, RefreshTooltips)
            abilitiesDropdown:SetPoint("TOPLEFT", PADDING, y)
            abilitiesDropdown:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
            y = y - FORM_ROW

            local itemsDropdown = GUI:CreateFormDropdown(tabContent, "Inventory", visibilityOptions, "items", tooltip.visibility, RefreshTooltips)
            itemsDropdown:SetPoint("TOPLEFT", PADDING, y)
            itemsDropdown:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
            y = y - FORM_ROW

            local framesDropdown = GUI:CreateFormDropdown(tabContent, "Frames", visibilityOptions, "frames", tooltip.visibility, RefreshTooltips)
            framesDropdown:SetPoint("TOPLEFT", PADDING, y)
            framesDropdown:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
            y = y - FORM_ROW

            local cdmDropdown = GUI:CreateFormDropdown(tabContent, "Cooldown Manager", visibilityOptions, "cdm", tooltip.visibility, RefreshTooltips)
            cdmDropdown:SetPoint("TOPLEFT", PADDING, y)
            cdmDropdown:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
            y = y - FORM_ROW

            local customTrackersDropdown = GUI:CreateFormDropdown(tabContent, "Custom Items/Spells", visibilityOptions, "customTrackers", tooltip.visibility, RefreshTooltips)
            customTrackersDropdown:SetPoint("TOPLEFT", PADDING, y)
            customTrackersDropdown:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
            y = y - FORM_ROW
        end

        y = y - 10

        -- SECTION: Visual Styling
        GUI:SetSearchSection("Visual Styling")
        local styleHeader = GUI:CreateSectionHeader(tabContent, "Visual Styling")
        styleHeader:SetPoint("TOPLEFT", PADDING, y)
        y = y - styleHeader.gap

        local scaleSlider = GUI:CreateFormSlider(tabContent, "Tooltip Scale", 0.5, 1.5, 0.05, "scale", tooltip, RefreshTooltips)
        scaleSlider:SetPoint("TOPLEFT", PADDING, y)
        scaleSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        y = y - FORM_ROW - 10

        local bgColorPicker = GUI:CreateFormColorPicker(tabContent, "Background Color", "backgroundColor", tooltip, RefreshTooltips)
        bgColorPicker:SetPoint("TOPLEFT", PADDING, y)
        bgColorPicker:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        y = y - FORM_ROW

        local borderColorPicker = GUI:CreateFormColorPicker(tabContent, "Border Color", "borderColor", tooltip, RefreshTooltips)
        borderColorPicker:SetPoint("TOPLEFT", PADDING, y)
        borderColorPicker:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        y = y - FORM_ROW

        -- Forward declarations for mutual references
        local classColoredBorderCheck, reactionColoredBorderCheck

        -- Helper to update all border-related controls enabled state
        local function UpdateBorderControlsEnabled()
            -- Border color picker disabled if either colored border option is enabled
            if borderColorPicker and borderColorPicker.SetEnabled then
                local disabled = tooltip.classColoredBorder or tooltip.reactionColoredBorder
                borderColorPicker:SetEnabled(not disabled)
            end
            -- Disable reaction-colored if class-colored is enabled
            if reactionColoredBorderCheck and reactionColoredBorderCheck.SetEnabled then
                reactionColoredBorderCheck:SetEnabled(not tooltip.classColoredBorder)
            end
            -- Disable class-colored if reaction-colored is enabled
            if classColoredBorderCheck and classColoredBorderCheck.SetEnabled then
                classColoredBorderCheck:SetEnabled(not tooltip.reactionColoredBorder)
            end
        end

        classColoredBorderCheck = GUI:CreateFormCheckbox(tabContent, "Class-Colored Border (Players)", "classColoredBorder", tooltip, function(val)
            RefreshTooltips()
            UpdateBorderControlsEnabled()
        end)
        classColoredBorderCheck:SetPoint("TOPLEFT", PADDING, y)
        classColoredBorderCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        y = y - FORM_ROW

        local classColoredBorderInfo = GUI:CreateLabel(tabContent, "Border color matches player's class. Overrides border color for players.", 10, C.textMuted)
        classColoredBorderInfo:SetPoint("TOPLEFT", PADDING, y)
        classColoredBorderInfo:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        classColoredBorderInfo:SetJustifyH("LEFT")
        y = y - 20

        reactionColoredBorderCheck = GUI:CreateFormCheckbox(tabContent, "Reaction-Colored Border", "reactionColoredBorder", tooltip, function(val)
            RefreshTooltips()
            UpdateBorderControlsEnabled()
        end)
        reactionColoredBorderCheck:SetPoint("TOPLEFT", PADDING, y)
        reactionColoredBorderCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        y = y - FORM_ROW

        -- Set initial enabled states
        UpdateBorderControlsEnabled()

        local reactionColoredBorderInfo = GUI:CreateLabel(tabContent, "Border color based on unit reaction (hostile=red, neutral=yellow, friendly=green).", 10, C.textMuted)
        reactionColoredBorderInfo:SetPoint("TOPLEFT", PADDING, y)
        reactionColoredBorderInfo:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        reactionColoredBorderInfo:SetJustifyH("LEFT")
        y = y - 20

        -- SECTION: Information Display
        GUI:SetSearchSection("Information Display")
        local infoHeader = GUI:CreateSectionHeader(tabContent, "Information Display")
        infoHeader:SetPoint("TOPLEFT", PADDING, y)
        y = y - infoHeader.gap

        local showTargetCheck = GUI:CreateFormCheckbox(tabContent, "Show Target", "showTarget", tooltip, RefreshTooltips)
        showTargetCheck:SetPoint("TOPLEFT", PADDING, y)
        showTargetCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        y = y - FORM_ROW

        local showTargetInfo = GUI:CreateLabel(tabContent, "Shows who the unit is targeting. Displays custom text when targeting you.", 10, C.textMuted)
        showTargetInfo:SetPoint("TOPLEFT", PADDING, y)
        showTargetInfo:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        showTargetInfo:SetJustifyH("LEFT")
        y = y - 20

        -- Custom "Targeting You" text input row
        local targetYouContainer = CreateFrame("Frame", nil, tabContent)
        targetYouContainer:SetHeight(26)
        targetYouContainer:SetPoint("TOPLEFT", PADDING, y)
        targetYouContainer:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)

        local targetYouLabel = targetYouContainer:CreateFontString(nil, "OVERLAY")
        targetYouLabel:SetFont(GUI.FONT_PATH, 11, "")
        targetYouLabel:SetTextColor(unpack(C.text))
        targetYouLabel:SetPoint("LEFT", 0, 0)
        targetYouLabel:SetText("\"Targeting You\" Text")

        -- OK Button (created first so we can anchor the input to it)
        local targetYouOKBtn = CreateFrame("Button", nil, targetYouContainer, "BackdropTemplate")
        targetYouOKBtn:SetSize(32, 22)
        targetYouOKBtn:SetPoint("RIGHT", 0, 0)
        targetYouOKBtn:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        targetYouOKBtn:SetBackdropColor(C.accent[1], C.accent[2], C.accent[3], 0.8)
        targetYouOKBtn:SetBackdropBorderColor(C.accent[1] * 0.8, C.accent[2] * 0.8, C.accent[3] * 0.8, 1)

        local targetYouOKText = targetYouOKBtn:CreateFontString(nil, "OVERLAY")
        targetYouOKText:SetFont(GUI.FONT_PATH, 10, "")
        targetYouOKText:SetTextColor(unpack(C.text))
        targetYouOKText:SetPoint("CENTER", 0, 0)
        targetYouOKText:SetText("OK")

        -- Hover effects for OK button
        targetYouOKBtn:SetScript("OnEnter", function(self)
            self:SetBackdropColor(C.accentHover[1], C.accentHover[2], C.accentHover[3], 1)
        end)
        targetYouOKBtn:SetScript("OnLeave", function(self)
            self:SetBackdropColor(C.accent[1], C.accent[2], C.accent[3], 0.8)
        end)

        local targetYouInputBg = CreateFrame("Frame", nil, targetYouContainer, "BackdropTemplate")
        targetYouInputBg:SetSize(120, 22)
        targetYouInputBg:SetPoint("RIGHT", targetYouOKBtn, "LEFT", -4, 0)
        targetYouInputBg:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        targetYouInputBg:SetBackdropColor(0.08, 0.08, 0.08, 1)
        targetYouInputBg:SetBackdropBorderColor(0.25, 0.25, 0.25, 1)

        local targetYouInput = CreateFrame("EditBox", nil, targetYouInputBg)
        targetYouInput:SetPoint("LEFT", 6, 0)
        targetYouInput:SetPoint("RIGHT", -6, 0)
        targetYouInput:SetHeight(20)
        targetYouInput:SetFont(GUI.FONT_PATH, 11, "")
        targetYouInput:SetTextColor(unpack(C.text))
        targetYouInput:SetAutoFocus(false)
        targetYouInput:SetText(tooltip.targetYouText or "<<YOU>>")
        targetYouInput:SetScript("OnEnterPressed", function(self)
            tooltip.targetYouText = self:GetText()
            self:ClearFocus()
            RefreshTooltips()
        end)
        targetYouInput:SetScript("OnEscapePressed", function(self)
            self:SetText(tooltip.targetYouText or "<<YOU>>")
            self:ClearFocus()
        end)
        targetYouInput:SetScript("OnEditFocusGained", function(self)
            targetYouInputBg:SetBackdropBorderColor(unpack(C.accent))
        end)
        targetYouInput:SetScript("OnEditFocusLost", function(self)
            targetYouInputBg:SetBackdropBorderColor(0.25, 0.25, 0.25, 1)
            tooltip.targetYouText = self:GetText()
            RefreshTooltips()
        end)

        -- Click handler for OK button (same as Enter press)
        targetYouOKBtn:SetScript("OnClick", function()
            tooltip.targetYouText = targetYouInput:GetText()
            targetYouInput:ClearFocus()
            RefreshTooltips()
        end)

        y = y - FORM_ROW

        -- Realm display options
        local realmDisplayOptions = {
            {value = "always", text = "Always Show"},
            {value = "never", text = "Never Show"},
            {value = "crossrealm", text = "Cross-Realm Only"},
        }
        local realmDisplayDropdown = GUI:CreateFormDropdown(tabContent, "Realm Display", realmDisplayOptions, "realmDisplay", tooltip, RefreshTooltips)
        realmDisplayDropdown:SetPoint("TOPLEFT", PADDING, y)
        realmDisplayDropdown:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        y = y - FORM_ROW

        local realmFormatOptions = {
            {value = "full", text = "Full Realm Name"},
            {value = "asterisk", text = "Asterisk (*)"},
        }
        local realmFormatDropdown = GUI:CreateFormDropdown(tabContent, "Realm Format", realmFormatOptions, "realmFormat", tooltip, RefreshTooltips)
        realmFormatDropdown:SetPoint("TOPLEFT", PADDING, y)
        realmFormatDropdown:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        y = y - FORM_ROW

        local showMountCheck = GUI:CreateFormCheckbox(tabContent, "Show Mount Name", "showMount", tooltip, RefreshTooltips)
        showMountCheck:SetPoint("TOPLEFT", PADDING, y)
        showMountCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        y = y - FORM_ROW

        local showMountInfo = GUI:CreateLabel(tabContent, "Shows the mount name when hovering over mounted players.", 10, C.textMuted)
        showMountInfo:SetPoint("TOPLEFT", PADDING, y)
        showMountInfo:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        showMountInfo:SetJustifyH("LEFT")
        y = y - 20

        -- Raider.IO option (with detection)
        local raiderIOInstalled = _G.RaiderIO ~= nil
        local showRaiderIOCheck = GUI:CreateFormCheckbox(tabContent, "Show Raider.IO Score", "showRaiderIO", tooltip, RefreshTooltips)
        showRaiderIOCheck:SetPoint("TOPLEFT", PADDING, y)
        showRaiderIOCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        -- Grey out toggle if Raider.IO is not installed
        showRaiderIOCheck:SetEnabled(raiderIOInstalled)
        y = y - FORM_ROW

        local raiderIOInfoText = raiderIOInstalled
            and "Shows Mythic+ score from Raider.IO addon."
            or "Raider.IO addon not detected. Install it to use this feature."
        local raiderIOInfoColor = raiderIOInstalled and C.textMuted or {0.7, 0.5, 0.5, 1}
        local showRaiderIOInfo = GUI:CreateLabel(tabContent, raiderIOInfoText, 10, raiderIOInfoColor)
        showRaiderIOInfo:SetPoint("TOPLEFT", PADDING, y)
        showRaiderIOInfo:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        showRaiderIOInfo:SetJustifyH("LEFT")
        y = y - 20

        -- SECTION: Combat
        GUI:SetSearchSection("Combat")
        local combatHeader = GUI:CreateSectionHeader(tabContent, "Combat")
        combatHeader:SetPoint("TOPLEFT", PADDING, y)
        y = y - combatHeader.gap

        local hideInCombatCheck = GUI:CreateFormCheckbox(tabContent, "Hide Tooltips in Combat", "hideInCombat", tooltip, RefreshTooltips)
        hideInCombatCheck:SetPoint("TOPLEFT", PADDING, y)
        hideInCombatCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        y = y - FORM_ROW

        local hideInCombatInfo = GUI:CreateLabel(tabContent, "Suppresses tooltips during combat. Use the modifier key below to force-show tooltips when needed.", 10, C.textMuted)
        hideInCombatInfo:SetPoint("TOPLEFT", PADDING, y)
        hideInCombatInfo:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        hideInCombatInfo:SetJustifyH("LEFT")
        y = y - 24

        local combatDropdown = GUI:CreateFormDropdown(tabContent, "Combat Modifier Key", combatOverrideOptions, "combatKey", tooltip, RefreshTooltips)
        combatDropdown:SetPoint("TOPLEFT", PADDING, y)
        combatDropdown:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        -- Reposition menu to open upward to avoid overflow
        if combatDropdown.menuFrame then
            combatDropdown.menuFrame.openUpward = true
        end
        y = y - FORM_ROW

        tabContent:SetHeight(math.abs(y) + 50)
    end

    -- =====================================================
    -- SUB-TAB: CHARACTER PANE
    -- =====================================================
    local function BuildCharacterPaneTab(tabContent)
        local y = -10

        -- Set search context for auto-registration
        GUI:SetSearchContext({tabIndex = 1, tabName = "General & QoL", subTabIndex = 7, subTabName = "Character Pane"})

        local char = db and db.character
        if not char then return end

        local FORM_ROW = 32

        -- SECTION: Enable/Disable
        local enableHeader = GUI:CreateSectionHeader(tabContent, "Enable/Disable LUI Character Module")
        enableHeader:SetPoint("TOPLEFT", PADDING, y)
        y = y - enableHeader.gap

        local enableCheck = GUI:CreateFormCheckbox(tabContent, "LUI Character Module",
            "enabled", char, function(val)
                GUI:ShowConfirmation({
                    title = "Reload Required",
                    message = "Character Pane styling requires a UI reload to take effect.",
                    acceptText = "Reload Now",
                    cancelText = "Later",
                    isDestructive = false,
                    onAccept = function()
                        LuheyUI:SafeReload()
                    end,
                })
            end)
        enableCheck:SetPoint("TOPLEFT", PADDING, y)
        enableCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        y = y - FORM_ROW

        local enableInfo = GUI:CreateLabel(tabContent, "If you are using a dedicated character stats addon, toggle this off.", 10, C.textMuted)
        enableInfo:SetPoint("TOPLEFT", PADDING, y)
        enableInfo:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        enableInfo:SetJustifyH("LEFT")
        y = y - 20

        -- Section Header
        local header = GUI:CreateSectionHeader(tabContent, "Character Pane Settings")
        header:SetPoint("TOPLEFT", PADDING, y)
        y = y - header.gap

        -- Description
        local desc = GUI:CreateLabel(tabContent, "Character Pane settings are now accessed from the Character Panel itself.\n\nOpen your Character Frame (C) and click the gear icon to access all settings.", 11, C.textMuted)
        desc:SetPoint("TOPLEFT", PADDING, y)
        desc:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        desc:SetJustifyH("LEFT")
        desc:SetWordWrap(true)
        desc:SetHeight(50)
        y = y - 60

        -- ───────────────────────────────────────────────────────────────
        -- INSPECT FRAME Section
        -- ───────────────────────────────────────────────────────────────
        local inspectHeader = GUI:CreateSectionHeader(tabContent, "Inspect Frame")
        inspectHeader:SetPoint("TOPLEFT", PADDING, y)
        y = y - inspectHeader.gap

        local inspectDesc = GUI:CreateLabel(tabContent, "Display item levels on the Blizzard inspect frame when inspecting other players.", 11, C.textMuted)
        inspectDesc:SetPoint("TOPLEFT", PADDING, y)
        inspectDesc:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        inspectDesc:SetJustifyH("LEFT")
        inspectDesc:SetWordWrap(true)
        inspectDesc:SetHeight(20)
        y = y - 28

        -- Refresh callback for inspect settings
        local function RefreshInspectLite()
            if _G.LuheyUI_RefreshInspectLite then
                _G.LuheyUI_RefreshInspectLite()
            end
        end

        -- Initialize defaults if missing
        if char.inspectLiteEnabled == nil then char.inspectLiteEnabled = true end
        if char.inspectLiteShowOverall == nil then char.inspectLiteShowOverall = true end
        if char.inspectLiteShowPerSlot == nil then char.inspectLiteShowPerSlot = true end
        if char.inspectLiteSlotFontSize == nil then char.inspectLiteSlotFontSize = 15 end

        local liteEnabled = GUI:CreateFormCheckbox(tabContent, "Enable Inspect iLvL Display", "inspectLiteEnabled", char, function(val)
            RefreshInspectLite()
        end)
        liteEnabled:SetPoint("TOPLEFT", PADDING, y)
        liteEnabled:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        y = y - FORM_ROW

        local liteOverall = GUI:CreateFormCheckbox(tabContent, "Show Overall Average iLvL", "inspectLiteShowOverall", char, RefreshInspectLite)
        liteOverall:SetPoint("TOPLEFT", PADDING, y)
        liteOverall:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        y = y - FORM_ROW

        -- Overall iLvL font settings
        if char.inspectLiteOverallFont == nil then char.inspectLiteOverallFont = "Quazii" end
        local overallFontList = {}
        local LSM = LibStub("LibSharedMedia-3.0", true)
        if LSM then
            for name in pairs(LSM:HashTable("font")) do
                table.insert(overallFontList, {value = name, text = name})
            end
            table.sort(overallFontList, function(a, b) return a.text < b.text end)
        else
            overallFontList = {{value = "Friz Quadrata TT", text = "Friz Quadrata TT"}}
        end
        local overallFontDropdown = GUI:CreateFormDropdown(tabContent, "Overall iLvL Font", overallFontList, "inspectLiteOverallFont", char, RefreshInspectLite)
        overallFontDropdown:SetPoint("TOPLEFT", PADDING, y)
        overallFontDropdown:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        y = y - FORM_ROW

        if char.inspectLiteOverallOutline == nil then char.inspectLiteOverallOutline = "OUTLINE" end
        local overallOutlineOptions = {
            {value = "", text = "None"},
            {value = "OUTLINE", text = "Outline"},
            {value = "THICKOUTLINE", text = "Thick Outline"},
        }
        local overallOutlineDropdown = GUI:CreateFormDropdown(tabContent, "Overall iLvL Outline", overallOutlineOptions, "inspectLiteOverallOutline", char, RefreshInspectLite)
        overallOutlineDropdown:SetPoint("TOPLEFT", PADDING, y)
        overallOutlineDropdown:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        y = y - FORM_ROW

        if char.inspectLiteOverallFontSize == nil then char.inspectLiteOverallFontSize = 11 end
        local overallFontSize = GUI:CreateFormSlider(tabContent, "Overall iLvL Font Size", 8, 24, 1, "inspectLiteOverallFontSize", char, RefreshInspectLite)
        overallFontSize:SetPoint("TOPLEFT", PADDING, y)
        overallFontSize:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        y = y - FORM_ROW

        if char.inspectLiteOverallOffsetX == nil then char.inspectLiteOverallOffsetX = 0 end
        local overallOffsetX = GUI:CreateFormSlider(tabContent, "Overall iLvL X Offset", -100, 100, 1, "inspectLiteOverallOffsetX", char, RefreshInspectLite)
        overallOffsetX:SetPoint("TOPLEFT", PADDING, y)
        overallOffsetX:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        y = y - FORM_ROW

        if char.inspectLiteOverallOffsetY == nil then char.inspectLiteOverallOffsetY = -8 end
        local overallOffsetY = GUI:CreateFormSlider(tabContent, "Overall iLvL Y Offset", -100, 100, 1, "inspectLiteOverallOffsetY", char, RefreshInspectLite)
        overallOffsetY:SetPoint("TOPLEFT", PADDING, y)
        overallOffsetY:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        y = y - FORM_ROW

        local litePerSlot = GUI:CreateFormCheckbox(tabContent, "Show Per-Slot iLvL", "inspectLiteShowPerSlot", char, RefreshInspectLite)
        litePerSlot:SetPoint("TOPLEFT", PADDING, y)
        litePerSlot:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        y = y - FORM_ROW

        local liteFontSize = GUI:CreateFormSlider(tabContent, "Per-Slot Font Size", 8, 24, 1, "inspectLiteSlotFontSize", char, RefreshInspectLite)
        liteFontSize:SetPoint("TOPLEFT", PADDING, y)
        liteFontSize:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        y = y - FORM_ROW

        -- Font dropdown for lite mode (opens upward due to position near bottom)
        if char.inspectLiteFont == nil then char.inspectLiteFont = "Friz Quadrata TT" end
        local liteFontList = {}
        local LSM = LibStub("LibSharedMedia-3.0", true)
        if LSM then
            for name in pairs(LSM:HashTable("font")) do
                table.insert(liteFontList, {value = name, text = name})
            end
            table.sort(liteFontList, function(a, b) return a.text < b.text end)
        else
            liteFontList = {{value = "Friz Quadrata TT", text = "Friz Quadrata TT"}}
        end
        local liteFontDropdown = GUI:CreateFormDropdown(tabContent, "Per-Slot Font", liteFontList, "inspectLiteFont", char, RefreshInspectLite)
        liteFontDropdown:SetPoint("TOPLEFT", PADDING, y)
        liteFontDropdown:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        -- Force this dropdown to open upward
        if liteFontDropdown.menuFrame then
            liteFontDropdown.menuFrame.openUpward = true
        end
        y = y - FORM_ROW

        -- Outline dropdown for lite mode (opens upward due to position near bottom)
        if char.inspectLiteOutline == nil then char.inspectLiteOutline = "OUTLINE" end
        local liteOutlineOptions = {
            {value = "", text = "None"},
            {value = "OUTLINE", text = "Outline"},
            {value = "THICKOUTLINE", text = "Thick Outline"},
        }
        local liteOutlineDropdown = GUI:CreateFormDropdown(tabContent, "Font Outline", liteOutlineOptions, "inspectLiteOutline", char, RefreshInspectLite)
        liteOutlineDropdown:SetPoint("TOPLEFT", PADDING, y)
        liteOutlineDropdown:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        -- Force this dropdown to open upward
        if liteOutlineDropdown.menuFrame then
            liteOutlineDropdown.menuFrame.openUpward = true
        end
        y = y - FORM_ROW

        y = y - 10

        -- Open Character Panel button
        local openBtn = GUI:CreateButton(tabContent, "Open Character Panel", 200, 32, function()
            -- Open character frame if not open
            if not CharacterFrame:IsShown() then
                ToggleCharacter("PaperDollFrame")
            end
            -- Show settings panel after a short delay
            C_Timer.After(0.1, function()
                local settingsPanel = _G["LuheyUI_CharSettingsPanel"]
                if settingsPanel then
                    settingsPanel:Show()
                end
            end)
        end)
        openBtn:SetPoint("TOPLEFT", PADDING, y)

        tabContent:SetHeight(math.abs(y) + 50)
    end

    -- =====================================================
    -- SUB-TAB: Dragonriding
    -- =====================================================
    local function BuildDragonridingTab(tabContent)
        local y = -10
        local FORM_ROW = 32

        -- Set search context for auto-registration
        GUI:SetSearchContext({tabIndex = 1, tabName = "General & QoL", subTabIndex = 8, subTabName = "Dragonriding"})

        -- Refresh callback
        local function RefreshSkyriding()
            if _G.LuheyUI_RefreshSkyriding then
                _G.LuheyUI_RefreshSkyriding()
            end
        end

        -- Get skyriding settings
        if not db.skyriding then db.skyriding = {} end
        local sr = db.skyriding

        -- Initialize defaults if missing
        if sr.enabled == nil then sr.enabled = true end
        if sr.width == nil then sr.width = 250 end
        if sr.vigorHeight == nil then sr.vigorHeight = 12 end
        if sr.secondWindHeight == nil then sr.secondWindHeight = 6 end
        if sr.offsetX == nil then sr.offsetX = 0 end
        if sr.offsetY == nil then sr.offsetY = -150 end
        if sr.locked == nil then sr.locked = true end
        if sr.barTexture == nil then sr.barTexture = "Solid" end
        if sr.showSegments == nil then sr.showSegments = true end
        if sr.showSpeed == nil then sr.showSpeed = true end
        if sr.showVigorText == nil then sr.showVigorText = true end
        if sr.secondWindMode == nil then sr.secondWindMode = "PIPS" end
        if sr.visibility == nil then sr.visibility = "AUTO" end
        if sr.fadeDelay == nil then sr.fadeDelay = 3 end
        if sr.speedFormat == nil then sr.speedFormat = "PERCENT" end
        if sr.vigorTextFormat == nil then sr.vigorTextFormat = "FRACTION" end
        if sr.useClassColorVigor == nil then sr.useClassColorVigor = false end
        if sr.useClassColorSecondWind == nil then sr.useClassColorSecondWind = false end

        -- ═══════════════════════════════════════════════════════════════
        -- SECTION: Enable
        -- ═══════════════════════════════════════════════════════════════
        GUI:SetSearchSection("Enable")
        local header = GUI:CreateSectionHeader(tabContent, "Skyriding Vigor Bar")
        header:SetPoint("TOPLEFT", PADDING, y)
        y = y - header.gap

        local enableCheck = GUI:CreateFormCheckbox(tabContent, "Enable Vigor Bar", "enabled", sr, RefreshSkyriding)
        enableCheck:SetPoint("TOPLEFT", PADDING, y)
        enableCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        y = y - FORM_ROW

        local desc = GUI:CreateLabel(tabContent, "Displays vigor charges, recharge progress, and speed while skyriding.", 10, C.textMuted)
        desc:SetPoint("TOPLEFT", PADDING, y)
        desc:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        desc:SetJustifyH("LEFT")
        y = y - 24

        -- ═══════════════════════════════════════════════════════════════
        -- SECTION: Visibility
        -- ═══════════════════════════════════════════════════════════════
        GUI:SetSearchSection("Visibility")
        local visHeader = GUI:CreateSectionHeader(tabContent, "Visibility")
        visHeader:SetPoint("TOPLEFT", PADDING, y)
        y = y - visHeader.gap

        local visOptions = {
            {value = "ALWAYS", text = "Always Visible"},
            {value = "FLYING_ONLY", text = "Only When Flying"},
            {value = "AUTO", text = "Auto (fade when grounded)"},
        }
        local visDropdown = GUI:CreateFormDropdown(tabContent, "Visibility Mode", visOptions, "visibility", sr, RefreshSkyriding)
        visDropdown:SetPoint("TOPLEFT", PADDING, y)
        visDropdown:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        y = y - FORM_ROW

        local fadeDelaySlider = GUI:CreateFormSlider(tabContent, "Fade Delay (sec)", 0, 10, 0.5, "fadeDelay", sr, RefreshSkyriding)
        fadeDelaySlider:SetPoint("TOPLEFT", PADDING, y)
        fadeDelaySlider:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        y = y - FORM_ROW

        local fadeDurationSlider = GUI:CreateFormSlider(tabContent, "Fade Speed (sec)", 0.1, 1.0, 0.1, "fadeDuration", sr, RefreshSkyriding)
        fadeDurationSlider:SetPoint("TOPLEFT", PADDING, y)
        fadeDurationSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        y = y - FORM_ROW

        local visInfo = GUI:CreateLabel(tabContent, "Auto mode shows the bar while in a skyriding zone and fades after landing.", 10, C.textMuted)
        visInfo:SetPoint("TOPLEFT", PADDING, y)
        visInfo:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        visInfo:SetJustifyH("LEFT")
        visInfo:SetWordWrap(true)
        y = y - 30

        -- ═══════════════════════════════════════════════════════════════
        -- SECTION: Bar Size
        -- ═══════════════════════════════════════════════════════════════
        GUI:SetSearchSection("Bar Size")
        local sizeHeader = GUI:CreateSectionHeader(tabContent, "Bar Size")
        sizeHeader:SetPoint("TOPLEFT", PADDING, y)
        y = y - sizeHeader.gap

        local widthSlider = GUI:CreateFormSlider(tabContent, "Width", 100, 500, 1, "width", sr, RefreshSkyriding)
        widthSlider:SetPoint("TOPLEFT", PADDING, y)
        widthSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        y = y - FORM_ROW

        local vigorHeightSlider = GUI:CreateFormSlider(tabContent, "Vigor Height", 4, 30, 1, "vigorHeight", sr, RefreshSkyriding)
        vigorHeightSlider:SetPoint("TOPLEFT", PADDING, y)
        vigorHeightSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        y = y - FORM_ROW

        local swHeightSlider = GUI:CreateFormSlider(tabContent, "Second Wind Height", 2, 20, 1, "secondWindHeight", sr, RefreshSkyriding)
        swHeightSlider:SetPoint("TOPLEFT", PADDING, y)
        swHeightSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        y = y - FORM_ROW

        local textureDropdown = GUI:CreateFormDropdown(tabContent, "Bar Texture", GetTextureList(), "barTexture", sr, RefreshSkyriding)
        textureDropdown:SetPoint("TOPLEFT", PADDING, y)
        textureDropdown:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        y = y - FORM_ROW

        -- ═══════════════════════════════════════════════════════════════
        -- SECTION: Position
        -- ═══════════════════════════════════════════════════════════════
        GUI:SetSearchSection("Position")
        local posHeader = GUI:CreateSectionHeader(tabContent, "Position")
        posHeader:SetPoint("TOPLEFT", PADDING, y)
        y = y - posHeader.gap

        local lockCheck = GUI:CreateFormCheckbox(tabContent, "Lock Position", "locked", sr, RefreshSkyriding)
        lockCheck:SetPoint("TOPLEFT", PADDING, y)
        lockCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        y = y - FORM_ROW

        local lockInfo = GUI:CreateLabel(tabContent, "Uncheck to drag the bar to a new position.", 10, C.textMuted)
        lockInfo:SetPoint("TOPLEFT", PADDING, y)
        lockInfo:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        lockInfo:SetJustifyH("LEFT")
        y = y - 20

        local xSlider = GUI:CreateFormSlider(tabContent, "X Offset", -1000, 1000, 1, "offsetX", sr, RefreshSkyriding)
        xSlider:SetPoint("TOPLEFT", PADDING, y)
        xSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        y = y - FORM_ROW

        local ySlider = GUI:CreateFormSlider(tabContent, "Y Offset", -1000, 1000, 1, "offsetY", sr, RefreshSkyriding)
        ySlider:SetPoint("TOPLEFT", PADDING, y)
        ySlider:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        y = y - FORM_ROW

        -- ═══════════════════════════════════════════════════════════════
        -- SECTION: Fill Colors
        -- ═══════════════════════════════════════════════════════════════
        GUI:SetSearchSection("Fill Colors")
        local fillHeader = GUI:CreateSectionHeader(tabContent, "Fill Colors")
        fillHeader:SetPoint("TOPLEFT", PADDING, y)
        y = y - fillHeader.gap

        local barColorPicker  -- Forward declaration for conditional disable
        local function UpdateVigorColorState()
            if barColorPicker then
                barColorPicker:SetAlpha(sr.useClassColorVigor and 0.4 or 1)
            end
            RefreshSkyriding()
        end

        local useClassVigorCheck = GUI:CreateFormCheckbox(tabContent, "Use Class Color for Vigor", "useClassColorVigor", sr, UpdateVigorColorState)
        useClassVigorCheck:SetPoint("TOPLEFT", PADDING, y)
        useClassVigorCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        y = y - FORM_ROW

        barColorPicker = GUI:CreateFormColorPicker(tabContent, "Vigor Fill Color", "barColor", sr, RefreshSkyriding)
        barColorPicker:SetPoint("TOPLEFT", PADDING, y)
        barColorPicker:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        barColorPicker:SetAlpha(sr.useClassColorVigor and 0.4 or 1)
        y = y - FORM_ROW

        local swColorPicker  -- Forward declaration for conditional disable
        local function UpdateSWColorState()
            if swColorPicker then
                swColorPicker:SetAlpha(sr.useClassColorSecondWind and 0.4 or 1)
            end
            RefreshSkyriding()
        end

        local useClassSWCheck = GUI:CreateFormCheckbox(tabContent, "Use Class Color for Second Wind", "useClassColorSecondWind", sr, UpdateSWColorState)
        useClassSWCheck:SetPoint("TOPLEFT", PADDING, y)
        useClassSWCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        y = y - FORM_ROW

        swColorPicker = GUI:CreateFormColorPicker(tabContent, "Second Wind Color", "secondWindColor", sr, RefreshSkyriding)
        swColorPicker:SetPoint("TOPLEFT", PADDING, y)
        swColorPicker:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        swColorPicker:SetAlpha(sr.useClassColorSecondWind and 0.4 or 1)
        y = y - FORM_ROW

        -- ═══════════════════════════════════════════════════════════════
        -- SECTION: Background & Effects
        -- ═══════════════════════════════════════════════════════════════
        GUI:SetSearchSection("Background & Effects")
        local bgHeader = GUI:CreateSectionHeader(tabContent, "Background & Effects")
        bgHeader:SetPoint("TOPLEFT", PADDING, y)
        y = y - bgHeader.gap

        local bgColorPicker = GUI:CreateFormColorPicker(tabContent, "Background Color", "backgroundColor", sr, RefreshSkyriding)
        bgColorPicker:SetPoint("TOPLEFT", PADDING, y)
        bgColorPicker:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        y = y - FORM_ROW

        local swBgColorPicker = GUI:CreateFormColorPicker(tabContent, "Second Wind Background", "secondWindBackgroundColor", sr, RefreshSkyriding)
        swBgColorPicker:SetPoint("TOPLEFT", PADDING, y)
        swBgColorPicker:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        y = y - FORM_ROW

        local segColorPicker = GUI:CreateFormColorPicker(tabContent, "Segment Marker Color", "segmentColor", sr, RefreshSkyriding)
        segColorPicker:SetPoint("TOPLEFT", PADDING, y)
        segColorPicker:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        y = y - FORM_ROW

        local rechargeColorPicker = GUI:CreateFormColorPicker(tabContent, "Recharge Animation Color", "rechargeColor", sr, RefreshSkyriding)
        rechargeColorPicker:SetPoint("TOPLEFT", PADDING, y)
        rechargeColorPicker:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        y = y - FORM_ROW

        -- ═══════════════════════════════════════════════════════════════
        -- SECTION: Text Display
        -- ═══════════════════════════════════════════════════════════════
        GUI:SetSearchSection("Text Display")
        local textHeader = GUI:CreateSectionHeader(tabContent, "Text Display")
        textHeader:SetPoint("TOPLEFT", PADDING, y)
        y = y - textHeader.gap

        local showVigorCheck = GUI:CreateFormCheckbox(tabContent, "Show Vigor Count", "showVigorText", sr, RefreshSkyriding)
        showVigorCheck:SetPoint("TOPLEFT", PADDING, y)
        showVigorCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        y = y - FORM_ROW

        local vigorFormatOptions = {
            {value = "FRACTION", text = "Fraction (4/6)"},
            {value = "CURRENT", text = "Current Only (4)"},
        }
        local vigorFormatDropdown = GUI:CreateFormDropdown(tabContent, "Vigor Format", vigorFormatOptions, "vigorTextFormat", sr, RefreshSkyriding)
        vigorFormatDropdown:SetPoint("TOPLEFT", PADDING, y)
        vigorFormatDropdown:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        y = y - FORM_ROW

        local showSpeedCheck = GUI:CreateFormCheckbox(tabContent, "Show Speed", "showSpeed", sr, RefreshSkyriding)
        showSpeedCheck:SetPoint("TOPLEFT", PADDING, y)
        showSpeedCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        y = y - FORM_ROW

        local speedFormatOptions = {
            {value = "PERCENT", text = "Percentage (312%)"},
            {value = "RAW", text = "Raw Speed (9.5)"},
        }
        local speedFormatDropdown = GUI:CreateFormDropdown(tabContent, "Speed Format", speedFormatOptions, "speedFormat", sr, RefreshSkyriding)
        speedFormatDropdown:SetPoint("TOPLEFT", PADDING, y)
        speedFormatDropdown:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        y = y - FORM_ROW

        local showAbilityIconCheck = GUI:CreateFormCheckbox(tabContent, "Show Whirling Surge Icon", "showAbilityIcon", sr, RefreshSkyriding)
        showAbilityIconCheck:SetPoint("TOPLEFT", PADDING, y)
        showAbilityIconCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        y = y - FORM_ROW

        local fontSizeSlider = GUI:CreateFormSlider(tabContent, "Text Font Size", 8, 24, 1, "vigorFontSize", sr, function()
            sr.speedFontSize = sr.vigorFontSize  -- Keep both in sync
            RefreshSkyriding()
        end)
        fontSizeSlider:SetPoint("TOPLEFT", PADDING, y)
        fontSizeSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PADDING, 0)
        y = y - FORM_ROW

        tabContent:SetHeight(math.abs(y) + 50)
    end

    -- =====================================================
    -- CREATE SUB-TABS
    -- =====================================================
    local subTabs = GUI:CreateSubTabs(content, {
        {name = "General", builder = BuildGeneralTab},
        {name = "HUD Visibility", builder = BuildHUDVisibilityTab},
        {name = "Cursor & Crosshair", builder = BuildCrosshairTab},
        {name = "Buff & Debuff", builder = BuildBuffDebuffTab},
        {name = "Chat", builder = BuildChatTab},
        {name = "Tooltip", builder = BuildTooltipTab},
        {name = "Character Pane", builder = BuildCharacterPaneTab},
        {name = "Dragonriding", builder = BuildDragonridingTab},
    })
    subTabs:SetPoint("TOPLEFT", 5, -5)
    subTabs:SetPoint("TOPRIGHT", -5, -5)
    subTabs:SetHeight(600)

    content:SetHeight(650)
end

---------------------------------------------------------------------------
-- PAGE: Autohide & Skinning (with sub-tabs)
---------------------------------------------------------------------------
local function CreateAutohidesPage(parent)
    local scroll, content = CreateScrollableContent(parent)
    local db = GetDB()

    -- Build Autohide sub-tab
    local function BuildAutohideTab(tabContent)
        local y = -10
        local PAD = 10
        local FORM_ROW = 32

        GUI:SetSearchContext({tabIndex = 5, tabName = "Autohide & Skinning", subTabIndex = 1, subTabName = "Autohide"})
        GUI:SetSearchSection("Autohide Settings")

        if db then
            if not db.uiHider then db.uiHider = {} end

            -- ═══════════════════════════════════════════════════════════════
            -- SECTION: Objective Tracker
            -- ═══════════════════════════════════════════════════════════════
            local objHeader = GUI:CreateSectionHeader(tabContent, "Objective Tracker")
            objHeader:SetPoint("TOPLEFT", PAD, y)
            y = y - objHeader.gap

            local checkAlways = GUI:CreateFormCheckbox(tabContent, "Hide Always", "hideObjectiveTrackerAlways", db.uiHider, RefreshUIHider)
            checkAlways:SetPoint("TOPLEFT", PAD, y)
            checkAlways:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            -- Ensure instance types table exists
            if not db.uiHider.hideObjectiveTrackerInstanceTypes then
                db.uiHider.hideObjectiveTrackerInstanceTypes = {
                    mythicPlus = false,
                    mythicDungeon = false,
                    normalDungeon = false,
                    heroicDungeon = false,
                    followerDungeon = false,
                    raid = false,
                    pvp = false,
                    arena = false,
                }
            end

            local instanceTypes = {
                {key = "mythicPlus", label = "Hide in Mythic+"},
                {key = "mythicDungeon", label = "Hide in Mythic Dungeons"},
                {key = "heroicDungeon", label = "Hide in Heroic Dungeons"},
                {key = "normalDungeon", label = "Hide in Normal Dungeons"},
                {key = "followerDungeon", label = "Hide in Follower Dungeons"},
                {key = "raid", label = "Hide in Raids"},
                {key = "pvp", label = "Hide in Battlegrounds"},
                {key = "arena", label = "Hide in Arenas"},
            }

            for _, instanceType in ipairs(instanceTypes) do
                local checkInstance = GUI:CreateFormCheckbox(tabContent, instanceType.label, instanceType.key, db.uiHider.hideObjectiveTrackerInstanceTypes, RefreshUIHider)
                checkInstance:SetPoint("TOPLEFT", PAD, y)
                checkInstance:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
                y = y - FORM_ROW
            end

            -- ═══════════════════════════════════════════════════════════════
            -- SECTION: Frames & Buttons
            -- ═══════════════════════════════════════════════════════════════
            local framesHeader = GUI:CreateSectionHeader(tabContent, "Frames & Buttons")
            framesHeader:SetPoint("TOPLEFT", PAD, y)
            y = y - framesHeader.gap

            local frameOptions = {
                {key = "hideRaidFrameManager", label = "Hide Compact Raid Frame Manager"},
                {key = "hideBuffCollapseButton", label = "Hide Buff Frame Collapse Button"},
                {key = "hideTalkingHead", label = "Hide Talking Head Frame"},
                {key = "muteTalkingHead", label = "Mute Talking Head Voice"},
                {key = "hideWorldMapBlackout", label = "Hide World Map Blackout"},
            }

            for _, opt in ipairs(frameOptions) do
                local check = GUI:CreateFormCheckbox(tabContent, opt.label, opt.key, db.uiHider, RefreshUIHider)
                check:SetPoint("TOPLEFT", PAD, y)
                check:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
                y = y - FORM_ROW
            end

            -- ═══════════════════════════════════════════════════════════════
            -- SECTION: Nameplates
            -- ═══════════════════════════════════════════════════════════════
            local nameplatesHeader = GUI:CreateSectionHeader(tabContent, "Nameplates")
            nameplatesHeader:SetPoint("TOPLEFT", PAD, y)
            y = y - nameplatesHeader.gap

            local nameplateOptions = {
                {key = "hideFriendlyPlayerNameplates", label = "Hide Friendly Player Nameplates"},
                {key = "hideFriendlyNPCNameplates", label = "Hide Friendly NPC Nameplates"},
            }

            for _, opt in ipairs(nameplateOptions) do
                local check = GUI:CreateFormCheckbox(tabContent, opt.label, opt.key, db.uiHider, RefreshUIHider)
                check:SetPoint("TOPLEFT", PAD, y)
                check:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
                y = y - FORM_ROW
            end

            -- ═══════════════════════════════════════════════════════════════
            -- SECTION: Status Bars
            -- ═══════════════════════════════════════════════════════════════
            local barsHeader = GUI:CreateSectionHeader(tabContent, "Status Bars")
            barsHeader:SetPoint("TOPLEFT", PAD, y)
            y = y - barsHeader.gap

            local barOptions = {
                {key = "hideExperienceBar", label = "Hide Experience Bar (XP)"},
                {key = "hideReputationBar", label = "Hide Reputation Bar"},
            }

            for _, opt in ipairs(barOptions) do
                local check = GUI:CreateFormCheckbox(tabContent, opt.label, opt.key, db.uiHider, RefreshUIHider)
                check:SetPoint("TOPLEFT", PAD, y)
                check:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
                y = y - FORM_ROW
            end

            -- ═══════════════════════════════════════════════════════════════
            -- SECTION: Combat & Messages
            -- ═══════════════════════════════════════════════════════════════
            local combatHeader = GUI:CreateSectionHeader(tabContent, "Combat & Messages")
            combatHeader:SetPoint("TOPLEFT", PAD, y)
            y = y - combatHeader.gap

            local combatOptions = {
                {key = "hideErrorMessages", label = "Hide Error Messages (Red Text)"},
            }

            for _, opt in ipairs(combatOptions) do
                local check = GUI:CreateFormCheckbox(tabContent, opt.label, opt.key, db.uiHider, RefreshUIHider)
                check:SetPoint("TOPLEFT", PAD, y)
                check:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
                y = y - FORM_ROW
            end
        end

        tabContent:SetHeight(math.abs(y) + 50)
    end

    -- Build Skinning sub-tab
    local function BuildSkinningTab(tabContent)
        local y = -10
        local PAD = 10
        local FORM_ROW = 32

        GUI:SetSearchContext({tabIndex = 5, tabName = "Autohide & Skinning", subTabIndex = 2, subTabName = "Skinning"})

        if db and db.general then
            local general = db.general

            -- Initialize defaults
            if general.skinUseClassColor == nil then general.skinUseClassColor = true end
            if general.skinCustomColor == nil then general.skinCustomColor = {0.2, 1.0, 0.6, 1} end
            if general.skinKeystoneFrame == nil then general.skinKeystoneFrame = true end

            -- ═══════════════════════════════════════════════════════════════
            -- CHOOSE DEFAULT COLOR SECTION
            -- ═══════════════════════════════════════════════════════════════
            GUI:SetSearchSection("Choose Default Color")

            local colorHeader = GUI:CreateSectionHeader(tabContent, "Choose Default Color")
            colorHeader:SetPoint("TOPLEFT", PAD, y)
            y = y - colorHeader.gap

            local customColorPicker  -- Forward declare for closure

            -- Helper to refresh all skinned frames when colors change
            local function RefreshAllSkinning()
                if _G.LuheyUI_RefreshKeystoneColors then
                    _G.LuheyUI_RefreshKeystoneColors()
                end
                if _G.LuheyUI_RefreshAlertColors then
                    _G.LuheyUI_RefreshAlertColors()
                end
                if _G.LuheyUI_RefreshLootColors then
                    _G.LuheyUI_RefreshLootColors()
                end
                if _G.LuheyUI_RefreshMPlusTimerColors then
                    _G.LuheyUI_RefreshMPlusTimerColors()
                end
                if _G.LuheyUI_RefreshCharacterFrameColors then
                    _G.LuheyUI_RefreshCharacterFrameColors()
                end
                if _G.LuheyUI_RefreshInspectColors then
                    _G.LuheyUI_RefreshInspectColors()
                end
                if _G.LuheyUI_RefreshPowerBarAltColors then
                    _G.LuheyUI_RefreshPowerBarAltColors()
                end
                if _G.LuheyUI_RefreshGameMenuColors then
                    _G.LuheyUI_RefreshGameMenuColors()
                end
                if _G.LuheyUI_RefreshOverrideActionBarColors then
                    _G.LuheyUI_RefreshOverrideActionBarColors()
                end
                if _G.LuheyUI_RefreshObjectiveTrackerColors then
                    _G.LuheyUI_RefreshObjectiveTrackerColors()
                end
                if _G.LuheyUI_RefreshInstanceFramesColors then
                    _G.LuheyUI_RefreshInstanceFramesColors()
                end
                if _G.LuheyUI_RefreshReadyCheckColors then
                    _G.LuheyUI_RefreshReadyCheckColors()
                end
                if _G.LuheyUI_RefreshBagColors then
                    _G.LuheyUI_RefreshBagColors()
                end
            end

            local useClassColorCheck = GUI:CreateFormCheckbox(tabContent, "Use Class Colors", "skinUseClassColor", general, function()
                if customColorPicker then
                    customColorPicker:SetEnabled(not general.skinUseClassColor)
                end
                RefreshAllSkinning()
            end)
            useClassColorCheck:SetPoint("TOPLEFT", PAD, y)
            useClassColorCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            customColorPicker = GUI:CreateFormColorPicker(tabContent, "Custom Color", "skinCustomColor", general, RefreshAllSkinning, { noAlpha = true })
            customColorPicker:SetPoint("TOPLEFT", PAD, y)
            customColorPicker:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            customColorPicker:SetEnabled(not general.skinUseClassColor)  -- Initial state
            y = y - FORM_ROW

            y = y - 10  -- Extra padding before background color

            -- Background color (with alpha for transparency)
            if general.skinBgColor == nil then general.skinBgColor = { 0.05, 0.05, 0.05, 0.95 } end

            local bgColorPicker = GUI:CreateFormColorPicker(tabContent, "Background Color", "skinBgColor", general, RefreshAllSkinning, { hasAlpha = true })
            bgColorPicker:SetPoint("TOPLEFT", PAD, y)
            bgColorPicker:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            y = y - 10  -- Extra padding before next section

            -- ═══════════════════════════════════════════════════════════════
            -- GAME MENU SECTION
            -- ═══════════════════════════════════════════════════════════════
            GUI:SetSearchSection("Game Menu")

            if general.skinGameMenu == nil then general.skinGameMenu = false end
            if general.addLuheyUIButton == nil then general.addLuheyUIButton = false end
            if general.gameMenuFontSize == nil then general.gameMenuFontSize = 12 end

            local gameMenuHeader = GUI:CreateSectionHeader(tabContent, "Game Menu")
            gameMenuHeader:SetPoint("TOPLEFT", PAD, y)
            y = y - gameMenuHeader.gap

            local gameMenuDesc = GUI:CreateLabel(tabContent, "Customize the ESC menu appearance and add a quick access button.", 11, C.textMuted)
            gameMenuDesc:SetPoint("TOPLEFT", PAD, y)
            gameMenuDesc:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            gameMenuDesc:SetJustifyH("LEFT")
            gameMenuDesc:SetWordWrap(true)
            gameMenuDesc:SetHeight(20)
            y = y - 28

            local gameMenuCheck = GUI:CreateFormCheckbox(tabContent, "Skin Game Menu", "skinGameMenu", general, function()
                GUI:ShowConfirmation({
                    title = "Reload UI?",
                    message = "Skinning changes require a reload to take effect.",
                    acceptText = "Reload",
                    cancelText = "Later",
                    onAccept = function() LuheyUI:SafeReload() end,
                })
            end)
            gameMenuCheck:SetPoint("TOPLEFT", PAD, y)
            gameMenuCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            local addQUIButtonCheck = GUI:CreateFormCheckbox(tabContent, "Add Luhey UI Button", "addLuheyUIButton", general, function()
                GUI:ShowConfirmation({
                    title = "Reload UI?",
                    message = "Button changes require a reload to take effect.",
                    acceptText = "Reload",
                    cancelText = "Later",
                    onAccept = function() LuheyUI:SafeReload() end,
                })
            end)
            addQUIButtonCheck:SetPoint("TOPLEFT", PAD, y)
            addQUIButtonCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            local gameMenuFontSlider = GUI:CreateFormSlider(tabContent, "Button Font Size", 8, 18, 1, "gameMenuFontSize", general, function()
                if _G.LuheyUI_RefreshGameMenuFontSize then
                    _G.LuheyUI_RefreshGameMenuFontSize()
                end
            end)
            gameMenuFontSlider:SetPoint("TOPLEFT", PAD, y)
            gameMenuFontSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            y = y - 10  -- Extra padding before next section

            -- ═══════════════════════════════════════════════════════════════
            -- READY CHECK FRAME SECTION
            -- ═══════════════════════════════════════════════════════════════
            GUI:SetSearchSection("Ready Check Frame")

            if general.skinReadyCheck == nil then general.skinReadyCheck = true end

            local readyCheckHeader = GUI:CreateSectionHeader(tabContent, "Ready Check Frame")
            readyCheckHeader:SetPoint("TOPLEFT", PAD, y)
            y = y - readyCheckHeader.gap

            local readyCheckDesc = GUI:CreateLabel(tabContent, "Skin the ready check popup with LUI styling.", 11, C.textMuted)
            readyCheckDesc:SetPoint("TOPLEFT", PAD, y)
            readyCheckDesc:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            readyCheckDesc:SetJustifyH("LEFT")
            readyCheckDesc:SetWordWrap(true)
            readyCheckDesc:SetHeight(20)
            y = y - 28

            local skinReadyCheckCheck = GUI:CreateFormCheckbox(tabContent, "Skin Ready Check Frame", "skinReadyCheck", general, function()
                GUI:ShowConfirmation({
                    title = "Reload UI?",
                    message = "Skinning changes require a reload to take effect.",
                    acceptText = "Reload",
                    cancelText = "Later",
                    onAccept = function() LuheyUI:SafeReload() end,
                })
            end)
            skinReadyCheckCheck:SetPoint("TOPLEFT", PAD, y)
            skinReadyCheckCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            -- Move/Reset buttons for Ready Check frame position
            local rcMoveBtn = GUI:CreateButton(tabContent, "Toggle Mover", 140, 28, function()
                if _G.LuheyUI_ToggleReadyCheckMover then
                    _G.LuheyUI_ToggleReadyCheckMover()
                end
            end)
            rcMoveBtn:SetPoint("TOPLEFT", PAD, y)

            local rcResetBtn = GUI:CreateButton(tabContent, "Reset Position", 140, 28, function()
                if _G.LuheyUI_ResetReadyCheckPosition then
                    _G.LuheyUI_ResetReadyCheckPosition()
                    print("|cFF56D1FF[QUI]|r Ready Check position reset to default.")
                end
            end)
            rcResetBtn:SetPoint("LEFT", rcMoveBtn, "RIGHT", 10, 0)
            y = y - 36

            y = y - 10  -- Extra padding before next section

            -- ═══════════════════════════════════════════════════════════════
            -- KEYSTONE FRAME SECTION
            -- ═══════════════════════════════════════════════════════════════
            GUI:SetSearchSection("Keystone Frame")

            local header = GUI:CreateSectionHeader(tabContent, "Keystone Frame")
            header:SetPoint("TOPLEFT", PAD, y)
            y = y - header.gap

            local desc = GUI:CreateLabel(tabContent, "Skin the M+ keystone insertion window with LUI styling.", 11, C.textMuted)
            desc:SetPoint("TOPLEFT", PAD, y)
            desc:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            desc:SetJustifyH("LEFT")
            desc:SetWordWrap(true)
            desc:SetHeight(20)
            y = y - 28

            local skinCheck = GUI:CreateFormCheckbox(tabContent, "Skin Keystone Window", "skinKeystoneFrame", general, function()
                GUI:ShowConfirmation({
                    title = "Reload UI?",
                    message = "Skinning changes require a reload to take effect.",
                    acceptText = "Reload",
                    cancelText = "Later",
                    onAccept = function() LuheyUI:SafeReload() end,
                })
            end)
            skinCheck:SetPoint("TOPLEFT", PAD, y)
            skinCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            y = y - 10  -- Extra padding before next section

            -- ═══════════════════════════════════════════════════════════════
            -- ENCOUNTER POWER BAR SECTION
            -- ═══════════════════════════════════════════════════════════════
            GUI:SetSearchSection("Encounter Power Bar")

            if general.skinPowerBarAlt == nil then general.skinPowerBarAlt = true end

            local powerBarHeader = GUI:CreateSectionHeader(tabContent, "Encounter Power Bar")
            powerBarHeader:SetPoint("TOPLEFT", PAD, y)
            y = y - powerBarHeader.gap

            local powerBarDesc = GUI:CreateLabel(tabContent, "Skin the encounter/quest-specific power bar (Atramedes sound, Darkmoon games, etc.).", 11, C.textMuted)
            powerBarDesc:SetPoint("TOPLEFT", PAD, y)
            powerBarDesc:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            powerBarDesc:SetJustifyH("LEFT")
            powerBarDesc:SetWordWrap(true)
            powerBarDesc:SetHeight(20)
            y = y - 28

            local powerBarAltCheck = GUI:CreateFormCheckbox(tabContent, "Skin Encounter Power Bar", "skinPowerBarAlt", general, function()
                GUI:ShowConfirmation({
                    title = "Reload UI?",
                    message = "Skinning changes require a reload to take effect.",
                    acceptText = "Reload",
                    cancelText = "Later",
                    onAccept = function() LuheyUI:SafeReload() end,
                })
            end)
            powerBarAltCheck:SetPoint("TOPLEFT", PAD, y)
            powerBarAltCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            local powerBarMoverBtn = GUI:CreateButton(tabContent, "Toggle Position Mover", 160, 28, function()
                if _G.LuheyUI_TogglePowerBarAltMover then
                    _G.LuheyUI_TogglePowerBarAltMover()
                end
            end)
            powerBarMoverBtn:SetPoint("TOPLEFT", PAD, y)
            y = y - 36

            y = y - 10  -- Extra padding before next section

            -- ═══════════════════════════════════════════════════════════════
            -- ALERT FRAMES SECTION
            -- ═══════════════════════════════════════════════════════════════
            GUI:SetSearchSection("Alert Frames")

            if general.skinAlerts == nil then general.skinAlerts = true end

            local alertHeader = GUI:CreateSectionHeader(tabContent, "Alert Frames")
            alertHeader:SetPoint("TOPLEFT", PAD, y)
            y = y - alertHeader.gap

            local alertDesc = GUI:CreateLabel(tabContent, "Style loot alerts, achievements, mounts, toys, and other popup frames.", 11, C.textMuted)
            alertDesc:SetPoint("TOPLEFT", PAD, y)
            alertDesc:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            alertDesc:SetJustifyH("LEFT")
            alertDesc:SetWordWrap(true)
            alertDesc:SetHeight(20)
            y = y - 28

            local alertCheck = GUI:CreateFormCheckbox(tabContent, "Skin Alert Frames", "skinAlerts", general, function()
                GUI:ShowConfirmation({
                    title = "Reload UI?",
                    message = "Skinning changes require a reload to take effect.",
                    acceptText = "Reload",
                    cancelText = "Later",
                    onAccept = function() LuheyUI:SafeReload() end,
                })
            end)
            alertCheck:SetPoint("TOPLEFT", PAD, y)
            alertCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            -- Toggle movers button
            local moverBtn = GUI:CreateButton(tabContent, "Toggle Position Movers", 200, 28, function()
                local LUICore = _G.LuheyUI and _G.LuheyUI.LUICore
                if LUICore and LUICore.Alerts then
                    LUICore.Alerts:ToggleMovers()
                end
            end)
            moverBtn:SetPoint("TOPLEFT", PAD, y)
            y = y - 40

            local moverInfo = GUI:CreateLabel(tabContent, "Drag the mover frames to reposition alerts and toasts.", 10, C.textMuted)
            moverInfo:SetPoint("TOPLEFT", PAD, y)
            moverInfo:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            moverInfo:SetJustifyH("LEFT")
            y = y - 25

            y = y - 10  -- Extra padding before next section

            -- ═══════════════════════════════════════════════════════════════
            -- LOOT WINDOW SECTION
            -- ═══════════════════════════════════════════════════════════════
            GUI:SetSearchSection("Loot Window")

            -- Get loot settings from profile root (not general)
            -- Ensure tables and individual keys exist
            if not db.loot then db.loot = {} end
            if db.loot.enabled == nil then db.loot.enabled = true end
            if db.loot.lootUnderMouse == nil then db.loot.lootUnderMouse = false end
            if db.loot.showTransmogMarker == nil then db.loot.showTransmogMarker = true end

            if not db.lootRoll then db.lootRoll = {} end
            if db.lootRoll.enabled == nil then db.lootRoll.enabled = false end
            if db.lootRoll.growDirection == nil then db.lootRoll.growDirection = "DOWN" end
            if db.lootRoll.spacing == nil then db.lootRoll.spacing = 4 end
            if db.lootRoll.maxFrames == nil then db.lootRoll.maxFrames = 4 end

            if not db.lootResults then db.lootResults = {} end
            if db.lootResults.enabled == nil then db.lootResults.enabled = true end

            local lootDB = db.loot
            local lootRollDB = db.lootRoll
            local lootResultsDB = db.lootResults

            local lootHeader = GUI:CreateSectionHeader(tabContent, "Loot Window")
            lootHeader:SetPoint("TOPLEFT", PAD, y)
            y = y - lootHeader.gap

            local lootDesc = GUI:CreateLabel(tabContent, "Replace Blizzard's loot window with a custom LUI-styled frame.", 11, C.textMuted)
            lootDesc:SetPoint("TOPLEFT", PAD, y)
            lootDesc:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            lootDesc:SetJustifyH("LEFT")
            lootDesc:SetWordWrap(true)
            lootDesc:SetHeight(20)
            y = y - 28

            local lootCheck = GUI:CreateFormCheckbox(tabContent, "Skin Loot Window", "enabled", lootDB, function()
                GUI:ShowConfirmation({
                    title = "Reload UI?",
                    message = "Skinning changes require a reload to take effect.",
                    acceptText = "Reload",
                    cancelText = "Later",
                    onAccept = function() LuheyUI:SafeReload() end,
                })
            end)
            lootCheck:SetPoint("TOPLEFT", PAD, y)
            lootCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            local lootUnderMouseCheck = GUI:CreateFormCheckbox(tabContent, "Loot Under Mouse", "lootUnderMouse", lootDB)
            lootUnderMouseCheck:SetPoint("TOPLEFT", PAD, y)
            lootUnderMouseCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            local transmogCheck = GUI:CreateFormCheckbox(tabContent, "Show Transmog Markers", "showTransmogMarker", lootDB)
            transmogCheck:SetPoint("TOPLEFT", PAD, y)
            transmogCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            y = y - 10  -- Extra padding before next section

            -- ═══════════════════════════════════════════════════════════════
            -- ROLL FRAMES SECTION
            -- ═══════════════════════════════════════════════════════════════
            GUI:SetSearchSection("Roll Frames")

            local rollHeader = GUI:CreateSectionHeader(tabContent, "Roll Frames")
            rollHeader:SetPoint("TOPLEFT", PAD, y)
            y = y - rollHeader.gap

            local rollDesc = GUI:CreateLabel(tabContent, "Replace Blizzard's loot roll frames with custom QUI-styled frames.", 11, C.textMuted)
            rollDesc:SetPoint("TOPLEFT", PAD, y)
            rollDesc:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            rollDesc:SetJustifyH("LEFT")
            rollDesc:SetWordWrap(true)
            rollDesc:SetHeight(20)
            y = y - 28

            local rollCheck = GUI:CreateFormCheckbox(tabContent, "Skin Roll Frames", "enabled", lootRollDB, function()
                GUI:ShowConfirmation({
                    title = "Reload UI?",
                    message = "Skinning changes require a reload to take effect.",
                    acceptText = "Reload",
                    cancelText = "Later",
                    onAccept = function() LuheyUI:SafeReload() end,
                })
            end)
            rollCheck:SetPoint("TOPLEFT", PAD, y)
            rollCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            -- Helper to refresh roll preview live when settings change
            local function RefreshRollPreview()
                local LUICore = _G.LuheyUI and _G.LuheyUI.LUICore
                if LUICore and LUICore.Loot and LUICore.Loot:IsRollPreviewActive() then
                    LUICore.Loot:HideRollPreview()
                    LUICore.Loot:ShowRollPreview()
                end
            end

            local growOptions = {
                { value = "DOWN", text = "Down" },
                { value = "UP", text = "Up" },
            }
            local growDropdown = GUI:CreateFormDropdown(tabContent, "Grow Direction", growOptions, "growDirection", lootRollDB, RefreshRollPreview)
            growDropdown:SetPoint("TOPLEFT", PAD, y)
            growDropdown:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            local maxFramesSlider = GUI:CreateFormSlider(tabContent, "Max Visible Frames", 1, 8, 1, "maxFrames", lootRollDB, RefreshRollPreview)
            maxFramesSlider:SetPoint("TOPLEFT", PAD, y)
            maxFramesSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            local spacingSlider = GUI:CreateFormSlider(tabContent, "Frame Spacing", 0, 20, 1, "spacing", lootRollDB, RefreshRollPreview)
            spacingSlider:SetPoint("TOPLEFT", PAD, y)
            spacingSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            -- Toggle movers button
            local rollMoverBtn = GUI:CreateButton(tabContent, "Toggle Position Movers", 200, 28, function()
                local LUICore = _G.LuheyUI and _G.LuheyUI.LUICore
                if LUICore and LUICore.Loot then
                    LUICore.Loot:ToggleMovers()
                end
            end)
            rollMoverBtn:SetPoint("TOPLEFT", PAD, y)
            y = y - 40

            local rollMoverInfo = GUI:CreateLabel(tabContent, "Drag the mover frame to reposition roll frames. Shows preview rolls.", 10, C.textMuted)
            rollMoverInfo:SetPoint("TOPLEFT", PAD, y)
            rollMoverInfo:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            rollMoverInfo:SetJustifyH("LEFT")
            y = y - 25

            y = y - 10  -- Extra padding before next section

            -- ═══════════════════════════════════════════════════════════════
            -- LOOT HISTORY SECTION
            -- ═══════════════════════════════════════════════════════════════
            GUI:SetSearchSection("Loot History")

            local historyHeader = GUI:CreateSectionHeader(tabContent, "Loot History")
            historyHeader:SetPoint("TOPLEFT", PAD, y)
            y = y - historyHeader.gap

            local historyDesc = GUI:CreateLabel(tabContent, "Apply LUI styling to the loot roll results panel.", 11, C.textMuted)
            historyDesc:SetPoint("TOPLEFT", PAD, y)
            historyDesc:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            historyDesc:SetJustifyH("LEFT")
            historyDesc:SetWordWrap(true)
            historyDesc:SetHeight(20)
            y = y - 28

            local historyCheck = GUI:CreateFormCheckbox(tabContent, "Skin Loot History", "enabled", lootResultsDB, function()
                GUI:ShowConfirmation({
                    title = "Reload UI?",
                    message = "Skinning changes require a reload to take effect.",
                    acceptText = "Reload",
                    cancelText = "Later",
                    onAccept = function() LuheyUI:SafeReload() end,
                })
            end)
            historyCheck:SetPoint("TOPLEFT", PAD, y)
            historyCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            y = y - 10  -- Extra padding before next section

            -- ═══════════════════════════════════════════════════════════════
            -- LUI M+ TIMER SECTION
            -- ═══════════════════════════════════════════════════════════════
            GUI:SetSearchSection("LUI M+ Timer")

            local mplusTimer = db.mplusTimer
            if not mplusTimer then
                db.mplusTimer = {
                    enabled = false,
                    layoutMode = "full",
                    showTimer = true,
                    showBorder = true,
                    showDeaths = true,
                    showAffixes = true,
                    showObjectives = true,
                    scale = 1.0,
                }
                mplusTimer = db.mplusTimer
            end
            -- Ensure new fields exist for existing profiles
            if mplusTimer.layoutMode == nil then mplusTimer.layoutMode = "full" end
            if mplusTimer.showTimer == nil then mplusTimer.showTimer = true end
            if mplusTimer.showBorder == nil then mplusTimer.showBorder = true end
            if mplusTimer.scale == nil then mplusTimer.scale = 1.0 end

            local quiMplusHeader = GUI:CreateSectionHeader(tabContent, "LUI M+ Timer")
            quiMplusHeader:SetPoint("TOPLEFT", PAD, y)
            y = y - quiMplusHeader.gap

            local quiMplusDesc = GUI:CreateLabel(tabContent, "Custom M+ timer with LUI styling. Replaces the Blizzard timer with a clean, compact frame.", 11, C.textMuted)
            quiMplusDesc:SetPoint("TOPLEFT", PAD, y)
            quiMplusDesc:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            quiMplusDesc:SetJustifyH("LEFT")
            quiMplusDesc:SetWordWrap(true)
            quiMplusDesc:SetHeight(20)
            y = y - 24

            local quiMplusNote = GUI:CreateLabel(tabContent, "Disabled by default — most M+ players prefer dedicated timer addons. Enable for an all-in-one solution.", 10, {1.0, 0.75, 0.2, 1})
            quiMplusNote:SetPoint("TOPLEFT", PAD, y)
            quiMplusNote:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            quiMplusNote:SetJustifyH("LEFT")
            quiMplusNote:SetWordWrap(true)
            quiMplusNote:SetHeight(20)
            y = y - 28

            local quiMplusCheck = GUI:CreateFormCheckbox(tabContent, "Enable QUI M+ Timer", "enabled", mplusTimer, function()
                GUI:ShowConfirmation({
                    title = "Reload UI?",
                    message = "Timer changes require a reload to take effect.",
                    acceptText = "Reload",
                    cancelText = "Later",
                    onAccept = function() LuheyUI:SafeReload() end,
                })
            end)
            quiMplusCheck:SetPoint("TOPLEFT", PAD, y)
            quiMplusCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            -- Layout mode dropdown
            local layoutOptions = {
                { text = "Compact", value = "compact" },
                { text = "Full", value = "full" },
                { text = "Sleek", value = "sleek" },
            }
            local layoutDropdown = GUI:CreateFormDropdown(tabContent, "Layout Mode", layoutOptions, "layoutMode", mplusTimer, function()
                local MPlusTimer = _G.LuheyUI_MPlusTimer
                if MPlusTimer and MPlusTimer.UpdateLayout then
                    MPlusTimer:UpdateLayout()
                end
                if _G.LuheyUI_ApplyMPlusTimerSkin then
                    _G.LuheyUI_ApplyMPlusTimerSkin()
                end
            end)
            layoutDropdown:SetPoint("TOPLEFT", PAD, y)
            layoutDropdown:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            -- Scale slider
            local scaleSlider = GUI:CreateFormSlider(tabContent, "Timer Scale", 0.5, 2.0, 0.05, "scale", mplusTimer, function()
                local MPlusTimer = _G.LuheyUI_MPlusTimer
                if MPlusTimer and MPlusTimer.ApplyScale then
                    MPlusTimer:ApplyScale()
                end
            end, { deferOnDrag = true })
            scaleSlider:SetPoint("TOPLEFT", PAD, y)
            scaleSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            -- Show Timer checkbox (full mode only)
            local quiMplusTimerCheck = GUI:CreateFormCheckbox(tabContent, "Show Timer Text (Full mode)", "showTimer", mplusTimer, function()
                local MPlusTimer = _G.LuheyUI_MPlusTimer
                if MPlusTimer and MPlusTimer.UpdateLayout then
                    MPlusTimer:UpdateLayout()
                end
            end)
            quiMplusTimerCheck:SetPoint("TOPLEFT", PAD, y)
            quiMplusTimerCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            -- Show Border checkbox
            local quiMplusBorderCheck = GUI:CreateFormCheckbox(tabContent, "Show Border", "showBorder", mplusTimer, function()
                if _G.LuheyUI_ApplyMPlusTimerSkin then
                    _G.LuheyUI_ApplyMPlusTimerSkin()
                end
            end)
            quiMplusBorderCheck:SetPoint("TOPLEFT", PAD, y)
            quiMplusBorderCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            local quiMplusDeathsCheck = GUI:CreateFormCheckbox(tabContent, "Show Deaths", "showDeaths", mplusTimer, function()
                local MPlusTimer = _G.LuheyUI_MPlusTimer
                if MPlusTimer and MPlusTimer.UpdateLayout then
                    MPlusTimer:UpdateLayout()
                end
            end)
            quiMplusDeathsCheck:SetPoint("TOPLEFT", PAD, y)
            quiMplusDeathsCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            local quiMplusAffixCheck = GUI:CreateFormCheckbox(tabContent, "Show Affixes", "showAffixes", mplusTimer, function()
                local MPlusTimer = _G.LuheyUI_MPlusTimer
                if MPlusTimer and MPlusTimer.UpdateLayout then
                    MPlusTimer:UpdateLayout()
                end
            end)
            quiMplusAffixCheck:SetPoint("TOPLEFT", PAD, y)
            quiMplusAffixCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            local quiMplusObjCheck = GUI:CreateFormCheckbox(tabContent, "Show Objectives", "showObjectives", mplusTimer, function()
                local MPlusTimer = _G.LuheyUI_MPlusTimer
                if MPlusTimer and MPlusTimer.UpdateLayout then
                    MPlusTimer:UpdateLayout()
                end
            end)
            quiMplusObjCheck:SetPoint("TOPLEFT", PAD, y)
            quiMplusObjCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            -- Demo mode button
            local quiMplusDemoBtn = GUI:CreateButton(tabContent, "Toggle Demo Mode", 200, 28, function()
                local MPlusTimer = _G.LuheyUI_MPlusTimer
                if MPlusTimer then
                    MPlusTimer:ToggleDemoMode()
                end
            end)
            quiMplusDemoBtn:SetPoint("TOPLEFT", PAD, y)
            y = y - 40

            local quiMplusDemoInfo = GUI:CreateLabel(tabContent, "Demo mode shows a preview timer for testing.", 10, C.textMuted)
            quiMplusDemoInfo:SetPoint("TOPLEFT", PAD, y)
            quiMplusDemoInfo:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            quiMplusDemoInfo:SetJustifyH("LEFT")
            y = y - 25

            -- ═══════════════════════════════════════════════════════════════
            -- REPUTATION/CURRENCY SECTION
            -- ═══════════════════════════════════════════════════════════════
            GUI:SetSearchSection("Reputation/Currency")

            if general.skinCharacterFrame == nil then general.skinCharacterFrame = true end

            local charFrameHeader = GUI:CreateSectionHeader(tabContent, "Reputation/Currency")
            charFrameHeader:SetPoint("TOPLEFT", PAD, y)
            y = y - charFrameHeader.gap

            local charFrameDesc = GUI:CreateLabel(tabContent, "Apply dark themed styling to the Reputation and Currency tabs with accent-colored borders.", 11, C.textMuted)
            charFrameDesc:SetPoint("TOPLEFT", PAD, y)
            charFrameDesc:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            charFrameDesc:SetJustifyH("LEFT")
            charFrameDesc:SetWordWrap(true)
            charFrameDesc:SetHeight(20)
            y = y - 28

            local charFrameCheck = GUI:CreateFormCheckbox(tabContent, "Skin Reputation/Currency", "skinCharacterFrame", general, function()
                GUI:ShowConfirmation({
                    title = "Reload UI?",
                    message = "Skinning changes require a reload to take effect.",
                    acceptText = "Reload",
                    cancelText = "Later",
                    onAccept = function() LuheyUI:SafeReload() end,
                })
            end)
            charFrameCheck:SetPoint("TOPLEFT", PAD, y)
            charFrameCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            y = y - 10  -- Extra padding before next section

            -- ═══════════════════════════════════════════════════════════════
            -- INSPECT FRAME SECTION
            -- ═══════════════════════════════════════════════════════════════
            GUI:SetSearchSection("Inspect Frame")

            if general.skinInspectFrame == nil then general.skinInspectFrame = true end

            local inspectFrameHeader = GUI:CreateSectionHeader(tabContent, "Inspect Frame")
            inspectFrameHeader:SetPoint("TOPLEFT", PAD, y)
            y = y - inspectFrameHeader.gap

            local inspectFrameDesc = GUI:CreateLabel(tabContent, "Skin the Inspect Frame to match Character Frame styling.", 11, C.textMuted)
            inspectFrameDesc:SetPoint("TOPLEFT", PAD, y)
            inspectFrameDesc:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            inspectFrameDesc:SetJustifyH("LEFT")
            inspectFrameDesc:SetWordWrap(true)
            inspectFrameDesc:SetHeight(20)
            y = y - 28

            local inspectFrameCheck = GUI:CreateFormCheckbox(tabContent, "Skin Inspect Frame", "skinInspectFrame", general, function()
                GUI:ShowConfirmation({
                    title = "Reload UI?",
                    message = "Skinning changes require a reload to take effect.",
                    acceptText = "Reload",
                    cancelText = "Later",
                    onAccept = function() LuheyUI:SafeReload() end,
                })
            end)
            inspectFrameCheck:SetPoint("TOPLEFT", PAD, y)
            inspectFrameCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            y = y - 10  -- Extra padding before next section

            -- ═══════════════════════════════════════════════════════════════
            -- BAG FRAMES SECTION
            -- ═══════════════════════════════════════════════════════════════
            GUI:SetSearchSection("Bag Frames")

            if general.skinBagFrames == nil then general.skinBagFrames = true end

            local bagFrameHeader = GUI:CreateSectionHeader(tabContent, "Bag Frames")
            bagFrameHeader:SetPoint("TOPLEFT", PAD, y)
            y = y - bagFrameHeader.gap

            local bagFrameDesc = GUI:CreateLabel(tabContent, "Skin bag container frames and bank with LUI styling.", 11, C.textMuted)
            bagFrameDesc:SetPoint("TOPLEFT", PAD, y)
            bagFrameDesc:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            bagFrameDesc:SetJustifyH("LEFT")
            bagFrameDesc:SetWordWrap(true)
            bagFrameDesc:SetHeight(20)
            y = y - 28

            local bagFrameCheck = GUI:CreateFormCheckbox(tabContent, "Skin Bag Frames", "skinBagFrames", general, function()
                GUI:ShowConfirmation({
                    title = "Reload UI?",
                    message = "Skinning changes require a reload to take effect.",
                    acceptText = "Reload",
                    cancelText = "Later",
                    onAccept = function() LuheyUI:SafeReload() end,
                })
            end)
            bagFrameCheck:SetPoint("TOPLEFT", PAD, y)
            bagFrameCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            y = y - 10  -- Extra padding before next section

            -- ═══════════════════════════════════════════════════════════════
            -- OVERRIDE ACTION BAR SECTION
            -- ═══════════════════════════════════════════════════════════════
            GUI:SetSearchSection("Override Action Bar")

            if general.skinOverrideActionBar == nil then general.skinOverrideActionBar = false end

            local overrideBarHeader = GUI:CreateSectionHeader(tabContent, "Override Action Bar")
            overrideBarHeader:SetPoint("TOPLEFT", PAD, y)
            y = y - overrideBarHeader.gap

            local overrideBarDesc = GUI:CreateLabel(tabContent, "Skin the vehicle/override action bar (dragonriding, possession, etc.).", 11, C.textMuted)
            overrideBarDesc:SetPoint("TOPLEFT", PAD, y)
            overrideBarDesc:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            overrideBarDesc:SetJustifyH("LEFT")
            overrideBarDesc:SetWordWrap(true)
            overrideBarDesc:SetHeight(20)
            y = y - 28

            local overrideBarCheck = GUI:CreateFormCheckbox(tabContent, "Skin Override Action Bar", "skinOverrideActionBar", general, function()
                GUI:ShowConfirmation({
                    title = "Reload UI?",
                    message = "Skinning changes require a reload to take effect.",
                    acceptText = "Reload",
                    cancelText = "Later",
                    onAccept = function() LuheyUI:SafeReload() end,
                })
            end)
            overrideBarCheck:SetPoint("TOPLEFT", PAD, y)
            overrideBarCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            y = y - 10  -- Extra padding before next section

            -- ═══════════════════════════════════════════════════════════════
            -- OBJECTIVE TRACKER SECTION
            -- ═══════════════════════════════════════════════════════════════
            GUI:SetSearchSection("Objective Tracker")

            if general.skinObjectiveTracker == nil then general.skinObjectiveTracker = false end

            local objTrackerHeader = GUI:CreateSectionHeader(tabContent, "Objective Tracker")
            objTrackerHeader:SetPoint("TOPLEFT", PAD, y)
            y = y - objTrackerHeader.gap

            local objTrackerDesc = GUI:CreateLabel(tabContent, "Apply LUI styling to quest objectives, achievement tracking, and bonus objectives.", 11, C.textMuted)
            objTrackerDesc:SetPoint("TOPLEFT", PAD, y)
            objTrackerDesc:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            objTrackerDesc:SetJustifyH("LEFT")
            objTrackerDesc:SetWordWrap(true)
            objTrackerDesc:SetHeight(20)
            y = y - 28

            local objTrackerCheck = GUI:CreateFormCheckbox(tabContent, "Skin Objective Tracker", "skinObjectiveTracker", general, function()
                GUI:ShowConfirmation({
                    title = "Reload UI?",
                    message = "Skinning changes require a reload to take effect.",
                    acceptText = "Reload",
                    cancelText = "Later",
                    onAccept = function() LuheyUI:SafeReload() end,
                })
            end)
            objTrackerCheck:SetPoint("TOPLEFT", PAD, y)
            objTrackerCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            if general.objectiveTrackerHeight == nil then general.objectiveTrackerHeight = 600 end
            local objTrackerHeightSlider = GUI:CreateFormSlider(tabContent, "Max Height", 200, 1000, 10,
                "objectiveTrackerHeight", general, function()
                    if _G.LuheyUI_RefreshObjectiveTracker then _G.LuheyUI_RefreshObjectiveTracker() end
                end)
            objTrackerHeightSlider:SetPoint("TOPLEFT", PAD, y)
            objTrackerHeightSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            if general.objectiveTrackerModuleFontSize == nil then general.objectiveTrackerModuleFontSize = 12 end
            local objTrackerModuleFontSlider = GUI:CreateFormSlider(tabContent, "Module Header Font (QUESTS, etc.)", 6, 18, 1,
                "objectiveTrackerModuleFontSize", general, function()
                    if _G.LuheyUI_RefreshObjectiveTracker then _G.LuheyUI_RefreshObjectiveTracker() end
                end)
            objTrackerModuleFontSlider:SetPoint("TOPLEFT", PAD, y)
            objTrackerModuleFontSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            if general.objectiveTrackerTitleFontSize == nil then general.objectiveTrackerTitleFontSize = 10 end
            local objTrackerTitleFontSlider = GUI:CreateFormSlider(tabContent, "Quest/Achievement Title Font", 6, 18, 1,
                "objectiveTrackerTitleFontSize", general, function()
                    if _G.LuheyUI_RefreshObjectiveTracker then _G.LuheyUI_RefreshObjectiveTracker() end
                end)
            objTrackerTitleFontSlider:SetPoint("TOPLEFT", PAD, y)
            objTrackerTitleFontSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            if general.objectiveTrackerTextFontSize == nil then general.objectiveTrackerTextFontSize = 10 end
            local objTrackerTextFontSlider = GUI:CreateFormSlider(tabContent, "Objective Text Font", 6, 18, 1,
                "objectiveTrackerTextFontSize", general, function()
                    if _G.LuheyUI_RefreshObjectiveTracker then _G.LuheyUI_RefreshObjectiveTracker() end
                end)
            objTrackerTextFontSlider:SetPoint("TOPLEFT", PAD, y)
            objTrackerTextFontSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            if general.objectiveTrackerWidth == nil then general.objectiveTrackerWidth = 260 end
            local objTrackerWidthSlider = GUI:CreateFormSlider(tabContent, "Max Width", 150, 400, 10,
                "objectiveTrackerWidth", general, function()
                    if _G.LuheyUI_RefreshObjectiveTracker then _G.LuheyUI_RefreshObjectiveTracker() end
                end)
            objTrackerWidthSlider:SetPoint("TOPLEFT", PAD, y)
            objTrackerWidthSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            if general.hideObjectiveTrackerBorder == nil then general.hideObjectiveTrackerBorder = false end
            local hideBorderCheck = GUI:CreateFormCheckbox(tabContent, "Hide Border", "hideObjectiveTrackerBorder", general, function()
                if _G.LuheyUI_RefreshObjectiveTracker then _G.LuheyUI_RefreshObjectiveTracker() end
            end)
            hideBorderCheck:SetPoint("TOPLEFT", PAD, y)
            hideBorderCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            if general.objectiveTrackerModuleColor == nil then general.objectiveTrackerModuleColor = { 1.0, 0.82, 0.0, 1.0 } end
            local moduleColorPicker = GUI:CreateFormColorPicker(tabContent, "Module Header Color (QUESTS, etc.)", "objectiveTrackerModuleColor", general, function()
                if _G.LuheyUI_RefreshObjectiveTracker then _G.LuheyUI_RefreshObjectiveTracker() end
            end)
            moduleColorPicker:SetPoint("TOPLEFT", PAD, y)
            moduleColorPicker:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            if general.objectiveTrackerTitleColor == nil then general.objectiveTrackerTitleColor = { 1.0, 1.0, 1.0, 1.0 } end
            local titleColorPicker = GUI:CreateFormColorPicker(tabContent, "Quest/Achievement Title Color", "objectiveTrackerTitleColor", general, function()
                if _G.LuheyUI_RefreshObjectiveTracker then _G.LuheyUI_RefreshObjectiveTracker() end
            end)
            titleColorPicker:SetPoint("TOPLEFT", PAD, y)
            titleColorPicker:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            if general.objectiveTrackerTextColor == nil then general.objectiveTrackerTextColor = { 0.8, 0.8, 0.8, 1.0 } end
            local textColorPicker = GUI:CreateFormColorPicker(tabContent, "Objective Text Color", "objectiveTrackerTextColor", general, function()
                if _G.LuheyUI_RefreshObjectiveTracker then _G.LuheyUI_RefreshObjectiveTracker() end
            end)
            textColorPicker:SetPoint("TOPLEFT", PAD, y)
            textColorPicker:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            -- Note: Background opacity is controlled via Edit Mode's built-in opacity slider

            y = y - 10  -- Extra padding before next section

            -- ═══════════════════════════════════════════════════════════════
            -- INSTANCE FRAMES SECTION
            -- ═══════════════════════════════════════════════════════════════
            GUI:SetSearchSection("Instance Frames")

            if general.skinInstanceFrames == nil then general.skinInstanceFrames = false end

            local instanceHeader = GUI:CreateSectionHeader(tabContent, "Instance Frames")
            instanceHeader:SetPoint("TOPLEFT", PAD, y)
            y = y - instanceHeader.gap

            local instanceDesc = GUI:CreateLabel(tabContent, "Skin the Dungeons & Raids window, PVP queue, and M+ Dungeons tab.", 11, C.textMuted)
            instanceDesc:SetPoint("TOPLEFT", PAD, y)
            instanceDesc:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            instanceDesc:SetJustifyH("LEFT")
            instanceDesc:SetWordWrap(true)
            instanceDesc:SetHeight(20)
            y = y - 28

            local instanceCheck = GUI:CreateFormCheckbox(tabContent, "Skin Instance Frames", "skinInstanceFrames", general, function()
                GUI:ShowConfirmation({
                    title = "Reload UI?",
                    message = "Skinning changes require a reload to take effect.",
                    acceptText = "Reload",
                    cancelText = "Later",
                    onAccept = function() LuheyUI:SafeReload() end,
                })
            end)
            instanceCheck:SetPoint("TOPLEFT", PAD, y)
            instanceCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            y = y - 10
        end

        tabContent:SetHeight(math.abs(y) + 50)
    end

    -- Create sub-tabs
    local subTabs = GUI:CreateSubTabs(content, {
        {name = "Autohide", builder = BuildAutohideTab},
        {name = "Skinning", builder = BuildSkinningTab},
    })
    subTabs:SetPoint("TOPLEFT", 5, -5)
    subTabs:SetPoint("TOPRIGHT", -5, -5)
    subTabs:SetHeight(600)

    content:SetHeight(650)
end

---------------------------------------------------------------------------
-- PAGE: Minimap & Datatext (with sub-tabs like old GUI)
---------------------------------------------------------------------------
local function CreateMinimapPage(parent)
    local scroll, content = CreateScrollableContent(parent)
    local db = GetDB()
    
    -- Build Minimap sub-tab
    local function BuildMinimapTab(tabContent)
        local y = -10
        local PAD = 10
        local FORM_ROW = 32

        -- Set search context for auto-registration
        GUI:SetSearchContext({tabIndex = 3, tabName = "Minimap & Datatext", subTabIndex = 1, subTabName = "Minimap"})

        -- Early return if database not ready
        if not db then
            local errorLabel = GUI:CreateLabel(tabContent, "Database not ready. Please /reload.", 12, {1, 0.3, 0.3, 1})
            errorLabel:SetPoint("TOPLEFT", PAD, y)
            tabContent:SetHeight(50)
            return
        end

        -- Ensure minimap table exists (for fresh installs where AceDB defaults may not initialize)
        if not db.minimap then
            db.minimap = {}
        end
        local mm = db.minimap

        if true then  -- Always build widgets (was: if db and db.minimap then)

            -- SECTION 1: General
            local generalHeader = GUI:CreateSectionHeader(tabContent, "General")
            generalHeader:SetPoint("TOPLEFT", PAD, y)
            y = y - generalHeader.gap

            local enableCheck = GUI:CreateFormCheckbox(tabContent, "Enable QUI Minimap", "enabled", mm, RefreshMinimap)
            enableCheck:SetPoint("TOPLEFT", PAD, y)
            enableCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            local lockCheck = GUI:CreateFormCheckbox(tabContent, "Lock QUI Minimap", "lock", mm, RefreshMinimap)
            lockCheck:SetPoint("TOPLEFT", PAD, y)
            lockCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            local sizeSlider = GUI:CreateFormSlider(tabContent, "Map Dimensions (Pixels)", 120, 380, 1, "size", mm, RefreshMinimap)
            sizeSlider:SetPoint("TOPLEFT", PAD, y)
            sizeSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            local scaleSlider = GUI:CreateFormSlider(tabContent, "Minimap Scale", 0.5, 2.0, 0.01, "scale", mm, RefreshMinimap, { deferOnDrag = true })
            scaleSlider:SetPoint("TOPLEFT", PAD, y)
            scaleSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            local scaleDesc = GUI:CreateLabel(tabContent, "Scales minimap and datatext panel together without changing base pixel size.", 11, C.textMuted)
            scaleDesc:SetPoint("TOPLEFT", PAD, y + 4)
            scaleDesc:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            scaleDesc:SetJustifyH("LEFT")
            y = y - 20

            y = y - 10

            -- SECTION 2: Frame Styling
            local styleHeader = GUI:CreateSectionHeader(tabContent, "Frame Styling")
            styleHeader:SetPoint("TOPLEFT", PAD, y)
            y = y - styleHeader.gap

            local borderSlider = GUI:CreateFormSlider(tabContent, "Border Size", 1, 16, 1, "borderSize", mm, RefreshMinimap)
            borderSlider:SetPoint("TOPLEFT", PAD, y)
            borderSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            local borderColor = GUI:CreateFormColorPicker(tabContent, "Custom Border Color", "borderColor", mm, RefreshMinimap)
            borderColor:SetPoint("TOPLEFT", PAD, y)
            borderColor:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            local classBorderCheck = GUI:CreateFormCheckbox(tabContent, "Use Class Color for Edge", "useClassColorBorder", mm, RefreshMinimap)
            classBorderCheck:SetPoint("TOPLEFT", PAD, y)
            classBorderCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            y = y - 10

            -- SECTION 3: Hide Minimap Elements
            local hideHeader = GUI:CreateSectionHeader(tabContent, "Hide Minimap Elements")
            hideHeader:SetPoint("TOPLEFT", PAD, y)
            y = y - hideHeader.gap

            -- Using inverted checkboxes: checked = hide (DB false), unchecked = show (DB true)
            local hideMail = GUI:CreateFormCheckboxInverted(tabContent, "Hide Mail (reload after)", "showMail", mm, RefreshMinimap)
            hideMail:SetPoint("TOPLEFT", PAD, y)
            hideMail:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            local hideTracking = GUI:CreateFormCheckboxInverted(tabContent, "Hide Tracking", "showTracking", mm, RefreshMinimap)
            hideTracking:SetPoint("TOPLEFT", PAD, y)
            hideTracking:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            local hideDifficulty = GUI:CreateFormCheckboxInverted(tabContent, "Hide Difficulty", "showDifficulty", mm, RefreshMinimap)
            hideDifficulty:SetPoint("TOPLEFT", PAD, y)
            hideDifficulty:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            local hideExpansion = GUI:CreateFormCheckboxInverted(tabContent, "Hide Progress Report", "showMissions", mm, RefreshMinimap)
            hideExpansion:SetPoint("TOPLEFT", PAD, y)
            hideExpansion:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            -- UIHider minimap controls (uses db.uiHider)
            local hideBorder = GUI:CreateFormCheckbox(tabContent, "Hide Border (Top)", "hideMinimapBorder", db.uiHider, RefreshUIHider)
            hideBorder:SetPoint("TOPLEFT", PAD, y)
            hideBorder:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            local hideClock = GUI:CreateFormCheckbox(tabContent, "Hide Clock Button", "hideTimeManager", db.uiHider, RefreshUIHider)
            hideClock:SetPoint("TOPLEFT", PAD, y)
            hideClock:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            local hideCalendar = GUI:CreateFormCheckbox(tabContent, "Hide Calendar Button", "hideGameTime", db.uiHider, RefreshUIHider)
            hideCalendar:SetPoint("TOPLEFT", PAD, y)
            hideCalendar:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            local hideZoneText = GUI:CreateFormCheckbox(tabContent, "Hide Zone Text (Native)", "hideMinimapZoneText", db.uiHider, RefreshUIHider)
            hideZoneText:SetPoint("TOPLEFT", PAD, y)
            hideZoneText:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            local hideZoom = GUI:CreateFormCheckboxInverted(tabContent, "Hide Zoom Buttons", "showZoomButtons", mm, RefreshMinimap)
            hideZoom:SetPoint("TOPLEFT", PAD, y)
            hideZoom:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            y = y - 10

            -- SECTION 4: Zone Label
            local zoneHeader = GUI:CreateSectionHeader(tabContent, "Zone Label")
            zoneHeader:SetPoint("TOPLEFT", PAD, y)
            y = y - zoneHeader.gap

            local showZoneCheck = GUI:CreateFormCheckbox(tabContent, "Show Zone Label", "showZoneText", mm, RefreshMinimap)
            showZoneCheck:SetPoint("TOPLEFT", PAD, y)
            showZoneCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            if mm.zoneTextConfig then
                local zoneOffsetX = GUI:CreateFormSlider(tabContent, "Horizontal Offset", -150, 150, 1, "offsetX", mm.zoneTextConfig, RefreshMinimap)
                zoneOffsetX:SetPoint("TOPLEFT", PAD, y)
                zoneOffsetX:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
                y = y - FORM_ROW

                local zoneOffsetY = GUI:CreateFormSlider(tabContent, "Vertical Offset", -150, 150, 1, "offsetY", mm.zoneTextConfig, RefreshMinimap)
                zoneOffsetY:SetPoint("TOPLEFT", PAD, y)
                zoneOffsetY:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
                y = y - FORM_ROW

                local zoneSize = GUI:CreateFormSlider(tabContent, "Label Size", 8, 20, 1, "fontSize", mm.zoneTextConfig, RefreshMinimap)
                zoneSize:SetPoint("TOPLEFT", PAD, y)
                zoneSize:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
                y = y - FORM_ROW

                local zoneAllCaps = GUI:CreateFormCheckbox(tabContent, "Uppercase Text", "allCaps", mm.zoneTextConfig, RefreshMinimap)
                zoneAllCaps:SetPoint("TOPLEFT", PAD, y)
                zoneAllCaps:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
                y = y - FORM_ROW

                local zoneClassColor = GUI:CreateFormCheckbox(tabContent, "Use Class Color", "useClassColor", mm.zoneTextConfig, RefreshMinimap)
                zoneClassColor:SetPoint("TOPLEFT", PAD, y)
                zoneClassColor:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
                y = y - FORM_ROW
            end
        end

        -- SECTION 5: Dungeon Eye (LFG Queue Button)
        if true then  -- Always build (mm already guaranteed above)
            y = y - 10
            GUI:SetSearchSection("Dungeon Eye")
            local eyeHeader = GUI:CreateSectionHeader(tabContent, "Dungeon Eye (LFG Queue)")
            eyeHeader:SetPoint("TOPLEFT", PAD, y)
            y = y - eyeHeader.gap

            -- Description text
            local eyeDesc = GUI:CreateLabel(tabContent, "When enabled, the queue eye automatically appears on the minimap when you join a queue.", 11, C.textMuted)
            eyeDesc:SetPoint("TOPLEFT", PAD, y)
            eyeDesc:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            eyeDesc:SetJustifyH("LEFT")
            y = y - 20

            -- Ensure dungeonEye settings exist
            if not mm.dungeonEye then
                mm.dungeonEye = {
                    enabled = true,
                    corner = "BOTTOMLEFT",
                    scale = 0.6,
                    offsetX = 0,
                    offsetY = 0,
                }
            end
            local eye = mm.dungeonEye

            -- Enable toggle
            local eyeEnable = GUI:CreateFormCheckbox(tabContent, "Enable Dungeon Eye", "enabled", eye, RefreshMinimap)
            eyeEnable:SetPoint("TOPLEFT", PAD, y)
            eyeEnable:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            -- Corner dropdown
            local cornerOptions = {
                {value = "TOPRIGHT", text = "Top Right"},
                {value = "TOPLEFT", text = "Top Left"},
                {value = "BOTTOMRIGHT", text = "Bottom Right"},
                {value = "BOTTOMLEFT", text = "Bottom Left"},
            }
            local eyeCorner = GUI:CreateFormDropdown(tabContent, "Corner Position", cornerOptions, "corner", eye, RefreshMinimap)
            eyeCorner:SetPoint("TOPLEFT", PAD, y)
            eyeCorner:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            -- Scale slider
            local eyeScale = GUI:CreateFormSlider(tabContent, "Icon Scale", 0.1, 2.0, 0.1, "scale", eye, RefreshMinimap)
            eyeScale:SetPoint("TOPLEFT", PAD, y)
            eyeScale:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            -- X Offset slider
            local eyeOffsetX = GUI:CreateFormSlider(tabContent, "X Offset", -30, 30, 1, "offsetX", eye, RefreshMinimap)
            eyeOffsetX:SetPoint("TOPLEFT", PAD, y)
            eyeOffsetX:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            -- Y Offset slider
            local eyeOffsetY = GUI:CreateFormSlider(tabContent, "Y Offset", -30, 30, 1, "offsetY", eye, RefreshMinimap)
            eyeOffsetY:SetPoint("TOPLEFT", PAD, y)
            eyeOffsetY:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW
        end

        tabContent:SetHeight(math.abs(y) + 50)
    end
    
    -- Build Datatext sub-tab
    local function BuildDatatextTab(tabContent)
        local y = -10
        local PAD = 10
        local FORM_ROW = 32

        -- Set search context for auto-registration
        GUI:SetSearchContext({tabIndex = 3, tabName = "Minimap & Datatext", subTabIndex = 2, subTabName = "Datatext"})

        -- Early return if database not ready
        if not db then
            local errorLabel = GUI:CreateLabel(tabContent, "Database not ready. Please /reload.", 12, {1, 0.3, 0.3, 1})
            errorLabel:SetPoint("TOPLEFT", PAD, y)
            tabContent:SetHeight(50)
            return
        end

        -- Ensure datatext table exists (for fresh installs where AceDB defaults may not initialize)
        if not db.datatext then
            db.datatext = {}
        end
        local dt = db.datatext

        if true then  -- Always build widgets (was: if db and db.datatext then)

            -- SECTION 1: Minimap Datatext Settings
            GUI:SetSearchSection("Minimap Datatext Settings")
            local panelHeader = GUI:CreateSectionHeader(tabContent, "Minimap Datatext Settings")
            panelHeader:SetPoint("TOPLEFT", PAD, y)
            y = y - panelHeader.gap

            -- Description text (grouped together)
            local noteLabel = GUI:CreateLabel(tabContent, "This datatext panel is anchored below the minimap and cannot be moved. To create additional movable panels, scroll down to 'Custom Movable Panels'.", 11, C.textMuted)
            noteLabel:SetPoint("TOPLEFT", PAD, y)
            noteLabel:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            noteLabel:SetJustifyH("LEFT")
            y = y - 38

            local enableCheck = GUI:CreateFormCheckbox(tabContent, "Enable Minimap Datatext", "enabled", dt, RefreshMinimap)
            enableCheck:SetPoint("TOPLEFT", PAD, y)
            enableCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            local forceSingleLine = GUI:CreateFormCheckbox(tabContent, "Force Single Line", "forceSingleLine", dt, RefreshMinimap)
            forceSingleLine:SetPoint("TOPLEFT", PAD, y)
            forceSingleLine:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            local heightSlider = GUI:CreateFormSlider(tabContent, "Panel Height (Per Row)", 18, 50, 1, "height", dt, RefreshMinimap)
            heightSlider:SetPoint("TOPLEFT", PAD, y)
            heightSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            local bgOpacitySlider = GUI:CreateFormSlider(tabContent, "Background Transparency", 0, 100, 5, "bgOpacity", dt, RefreshMinimap)
            bgOpacitySlider:SetPoint("TOPLEFT", PAD, y)
            bgOpacitySlider:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            local borderSizeSlider = GUI:CreateFormSlider(tabContent, "Border Size (0=hidden)", 0, 8, 1, "borderSize", dt, RefreshMinimap)
            borderSizeSlider:SetPoint("TOPLEFT", PAD, y)
            borderSizeSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            local borderColorPicker = GUI:CreateFormColorPicker(tabContent, "Border Color", "borderColor", dt, RefreshMinimap)
            borderColorPicker:SetPoint("TOPLEFT", PAD, y)
            borderColorPicker:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            local offsetYSlider = GUI:CreateFormSlider(tabContent, "Vertical Offset", -40, 40, 1, "offsetY", dt, RefreshMinimap)
            offsetYSlider:SetPoint("TOPLEFT", PAD, y)
            offsetYSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            y = y - 10

            -- Build datatext options from registry (no section header - flows from Vertical Offset)
            -- NOTE: Use LUICore.Datatexts:GetAll() for consistent behavior with extra panels (#89)
            local dtOptions = {{value = "", text = "(empty)"}}
            if LUICore and LUICore.Datatexts then
                local allDatatexts = LUICore.Datatexts:GetAll()
                for _, datatextDef in ipairs(allDatatexts) do
                    table.insert(dtOptions, {value = datatextDef.id, text = datatextDef.displayName})
                end
            end

            -- Ensure slots table and per-slot configs exist
            if not dt.slots then
                dt.slots = {"time", "friends", "guild"}
            end
            if not dt.slot1 then dt.slot1 = { shortLabel = false, noLabel = false, xOffset = 0, yOffset = 0 } end
            if not dt.slot2 then dt.slot2 = { shortLabel = false, noLabel = false, xOffset = 0, yOffset = 0 } end
            if not dt.slot3 then dt.slot3 = { shortLabel = false, noLabel = false, xOffset = 0, yOffset = 0 } end
            if dt.slot1.noLabel == nil then dt.slot1.noLabel = false end
            if dt.slot2.noLabel == nil then dt.slot2.noLabel = false end
            if dt.slot3.noLabel == nil then dt.slot3.noLabel = false end

            -- Slot 1 Group
            local slot1 = GUI:CreateFormDropdown(tabContent, "Slot 1 (Left)", dtOptions, nil, nil, function(val)
                dt.slots[1] = val
                RefreshMinimap()
            end)
            slot1:SetPoint("TOPLEFT", PAD, y)
            slot1:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            if slot1.SetValue then slot1.SetValue(dt.slots[1] or "") end
            y = y - FORM_ROW

            local slot1NoLabel  -- Forward declare for mutual reference
            local slot1Short = GUI:CreateFormCheckbox(tabContent, "Slot 1 Short Label", "shortLabel", dt.slot1, function()
                if slot1NoLabel then slot1NoLabel:SetEnabled(not dt.slot1.shortLabel) end
                RefreshMinimap()
            end)
            slot1Short:SetPoint("TOPLEFT", PAD, y)
            slot1Short:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            slot1NoLabel = GUI:CreateFormCheckbox(tabContent, "Slot 1 No Label", "noLabel", dt.slot1, function()
                if slot1Short then slot1Short:SetEnabled(not dt.slot1.noLabel) end
                RefreshMinimap()
            end)
            slot1NoLabel:SetPoint("TOPLEFT", PAD, y)
            slot1NoLabel:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            slot1NoLabel:SetEnabled(not dt.slot1.shortLabel)
            slot1Short:SetEnabled(not dt.slot1.noLabel)
            y = y - FORM_ROW

            local slot1XOff = GUI:CreateFormSlider(tabContent, "Slot 1 X Offset", -50, 50, 1, "xOffset", dt.slot1, RefreshMinimap)
            slot1XOff:SetPoint("TOPLEFT", PAD, y)
            slot1XOff:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            local slot1YOff = GUI:CreateFormSlider(tabContent, "Slot 1 Y Offset", -20, 20, 1, "yOffset", dt.slot1, RefreshMinimap)
            slot1YOff:SetPoint("TOPLEFT", PAD, y)
            slot1YOff:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            y = y - 10  -- Gap before Slot 2

            -- Slot 2 Group
            local slot2 = GUI:CreateFormDropdown(tabContent, "Slot 2 (Center)", dtOptions, nil, nil, function(val)
                dt.slots[2] = val
                RefreshMinimap()
            end)
            slot2:SetPoint("TOPLEFT", PAD, y)
            slot2:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            if slot2.SetValue then slot2.SetValue(dt.slots[2] or "") end
            y = y - FORM_ROW

            local slot2NoLabel  -- Forward declare for mutual reference
            local slot2Short = GUI:CreateFormCheckbox(tabContent, "Slot 2 Short Label", "shortLabel", dt.slot2, function()
                if slot2NoLabel then slot2NoLabel:SetEnabled(not dt.slot2.shortLabel) end
                RefreshMinimap()
            end)
            slot2Short:SetPoint("TOPLEFT", PAD, y)
            slot2Short:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            slot2NoLabel = GUI:CreateFormCheckbox(tabContent, "Slot 2 No Label", "noLabel", dt.slot2, function()
                if slot2Short then slot2Short:SetEnabled(not dt.slot2.noLabel) end
                RefreshMinimap()
            end)
            slot2NoLabel:SetPoint("TOPLEFT", PAD, y)
            slot2NoLabel:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            slot2NoLabel:SetEnabled(not dt.slot2.shortLabel)
            slot2Short:SetEnabled(not dt.slot2.noLabel)
            y = y - FORM_ROW

            local slot2XOff = GUI:CreateFormSlider(tabContent, "Slot 2 X Offset", -50, 50, 1, "xOffset", dt.slot2, RefreshMinimap)
            slot2XOff:SetPoint("TOPLEFT", PAD, y)
            slot2XOff:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            local slot2YOff = GUI:CreateFormSlider(tabContent, "Slot 2 Y Offset", -20, 20, 1, "yOffset", dt.slot2, RefreshMinimap)
            slot2YOff:SetPoint("TOPLEFT", PAD, y)
            slot2YOff:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            y = y - 10  -- Gap before Slot 3

            -- Slot 3 Group
            local slot3 = GUI:CreateFormDropdown(tabContent, "Slot 3 (Right)", dtOptions, nil, nil, function(val)
                dt.slots[3] = val
                RefreshMinimap()
            end)
            slot3:SetPoint("TOPLEFT", PAD, y)
            slot3:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            if slot3.SetValue then slot3.SetValue(dt.slots[3] or "") end
            y = y - FORM_ROW

            local slot3NoLabel  -- Forward declare for mutual reference
            local slot3Short = GUI:CreateFormCheckbox(tabContent, "Slot 3 Short Label", "shortLabel", dt.slot3, function()
                if slot3NoLabel then slot3NoLabel:SetEnabled(not dt.slot3.shortLabel) end
                RefreshMinimap()
            end)
            slot3Short:SetPoint("TOPLEFT", PAD, y)
            slot3Short:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            slot3NoLabel = GUI:CreateFormCheckbox(tabContent, "Slot 3 No Label", "noLabel", dt.slot3, function()
                if slot3Short then slot3Short:SetEnabled(not dt.slot3.noLabel) end
                RefreshMinimap()
            end)
            slot3NoLabel:SetPoint("TOPLEFT", PAD, y)
            slot3NoLabel:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            slot3NoLabel:SetEnabled(not dt.slot3.shortLabel)
            slot3Short:SetEnabled(not dt.slot3.noLabel)
            y = y - FORM_ROW

            local slot3XOff = GUI:CreateFormSlider(tabContent, "Slot 3 X Offset", -50, 50, 1, "xOffset", dt.slot3, RefreshMinimap)
            slot3XOff:SetPoint("TOPLEFT", PAD, y)
            slot3XOff:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            local slot3YOff = GUI:CreateFormSlider(tabContent, "Slot 3 Y Offset", -20, 20, 1, "yOffset", dt.slot3, RefreshMinimap)
            slot3YOff:SetPoint("TOPLEFT", PAD, y)
            slot3YOff:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            -- Hint text explaining flexible slot behavior
            local hintText = GUI:CreateLabel(tabContent, "Empty slots are hidden. Using 2 datatexts gives each 50% width.", 11, C.textMuted)
            hintText:SetPoint("TOPLEFT", PAD, y)
            hintText:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            hintText:SetJustifyH("LEFT")
            y = y - 28

            y = y - 10

            -- SECTION 3: Spec Display Options
            local specHeader = GUI:CreateSectionHeader(tabContent, "Spec Display Options")
            specHeader:SetPoint("TOPLEFT", PAD, y)
            y = y - specHeader.gap

            local specDisplayDropdown = GUI:CreateFormDropdown(tabContent, "Spec Display Mode", {
                {value = "icon", text = "Icon Only"},
                {value = "loadout", text = "Icon + Loadout"},
                {value = "full", text = "Full (Spec / Loadout)"},
            }, "specDisplayMode", dt, function()
                -- Refresh all datatexts to apply the new display mode immediately
                if LUICore and LUICore.Datatexts and LUICore.Datatexts.UpdateAll then
                    LUICore.Datatexts:UpdateAll()
                end
            end)
            specDisplayDropdown:SetPoint("TOPLEFT", PAD, y)
            specDisplayDropdown:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            y = y - 10

            -- SECTION 4: Time Options
            local timeHeader = GUI:CreateSectionHeader(tabContent, "Time Options")
            timeHeader:SetPoint("TOPLEFT", PAD, y)
            y = y - timeHeader.gap

            local timeFormatDropdown = GUI:CreateFormDropdown(tabContent, "Time Format", {
                {value = "local", text = "Local Time"},
                {value = "server", text = "Server Time"},
            }, "timeFormat", dt, RefreshMinimap)
            timeFormatDropdown:SetPoint("TOPLEFT", PAD, y)
            timeFormatDropdown:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            local clockFormatDropdown = GUI:CreateFormDropdown(tabContent, "Clock Format", {
                {value = true, text = "24-Hour Clock"},
                {value = false, text = "AM/PM"},
            }, "use24Hour", dt, RefreshMinimap)
            clockFormatDropdown:SetPoint("TOPLEFT", PAD, y)
            clockFormatDropdown:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            y = y - 10

            -- SECTION 5: Text Styling
            local fontHeader = GUI:CreateSectionHeader(tabContent, "Text Styling")
            fontHeader:SetPoint("TOPLEFT", PAD, y)
            y = y - fontHeader.gap

            local fontSizeSlider = GUI:CreateFormSlider(tabContent, "Text Size", 9, 18, 1, "fontSize", dt, RefreshMinimap)
            fontSizeSlider:SetPoint("TOPLEFT", PAD, y)
            fontSizeSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            local useClassColor = GUI:CreateFormCheckbox(tabContent, "Use Class Color", "useClassColor", dt, function()
                RefreshMinimap()
                -- Also update custom datapanels
                if LUICore and LUICore.Datatexts and LUICore.Datatexts.UpdateAll then
                    LUICore.Datatexts:UpdateAll()
                end
            end)
            useClassColor:SetPoint("TOPLEFT", PAD, y)
            useClassColor:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            local valueColor = GUI:CreateFormColorPicker(tabContent, "Custom Text Color", "valueColor", dt, function()
                RefreshMinimap()
                -- Also update custom datapanels
                if LUICore and LUICore.Datatexts and LUICore.Datatexts.UpdateAll then
                    LUICore.Datatexts:UpdateAll()
                end
            end)
            valueColor:SetPoint("TOPLEFT", PAD, y)
            valueColor:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            y = y - 10

            -- SECTION 5b: Time Datatext Settings
            local timeHeader = GUI:CreateSectionHeader(tabContent, "Time Datatext")
            timeHeader:SetPoint("TOPLEFT", PAD, y)
            y = y - timeHeader.gap

            local lockoutCacheSlider = GUI:CreateFormSlider(tabContent, "Lockout Refresh (minutes)", 1, 30, 1, "lockoutCacheMinutes", dt, nil)
            lockoutCacheSlider:SetPoint("TOPLEFT", PAD, y)
            lockoutCacheSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            local lockoutNote = GUI:CreateLabel(tabContent, "How often to refresh raid lockout data when hovering the Time datatext.", 11, C.textMuted)
            lockoutNote:SetPoint("TOPLEFT", PAD, y)
            lockoutNote:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            lockoutNote:SetJustifyH("LEFT")
            y = y - 20

            y = y - 10

            -- SECTION 6: Custom Movable Datapanels
            local customPanelsHeader = GUI:CreateSectionHeader(tabContent, "Custom Movable Panels")
            customPanelsHeader:SetPoint("TOPLEFT", PAD, y)
            y = y - customPanelsHeader.gap

            local panelsNote = GUI:CreateLabel(tabContent, "Create additional datatext panels that can be freely positioned anywhere on screen.", 11, C.textMuted)
            panelsNote:SetPoint("TOPLEFT", PAD, y)
            panelsNote:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            panelsNote:SetJustifyH("LEFT")
            y = y - 28

            local panelsWarning = GUI:CreateLabel(tabContent, "Note: Panels will only appear if at least one slot has a datatext assigned.", 11, C.textMuted)
            panelsWarning:SetPoint("TOPLEFT", PAD, y)
            panelsWarning:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            panelsWarning:SetJustifyH("LEFT")
            y = y - 28
            
            -- Ensure quiDatatexts.panels exists
            if not db.quiDatatexts then
                db.quiDatatexts = {panels = {}}
            end
            if not db.quiDatatexts.panels then
                db.quiDatatexts.panels = {}
            end
            
            -- List existing panels
            local panels = db.quiDatatexts.panels

            -- Track all edit frames for mutual exclusion (only one config open at a time)
            local openEditFrames = {}

            if #panels > 0 then
                for i, panelConfig in ipairs(panels) do
                    local panelFrame = CreateFrame("Frame", nil, tabContent, "BackdropTemplate")
                    panelFrame:SetHeight(60)
                    panelFrame:SetPoint("TOPLEFT", PAD, y)
                    panelFrame:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
                    panelFrame:SetBackdrop({
                        bgFile = "Interface\\Buttons\\WHITE8x8",
                        edgeFile = "Interface\\Buttons\\WHITE8x8",
                        edgeSize = 1,
                    })
                    panelFrame:SetBackdropColor(C.bgLight[1], C.bgLight[2], C.bgLight[3], 0.8)
                    panelFrame:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], 1)
                    
                    -- Panel name
                    local nameLabel = panelFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                    nameLabel:SetPoint("TOPLEFT", 10, -10)
                    nameLabel:SetText(string.format("Panel %d: %s", i, panelConfig.name or ("Panel " .. i)))
                    nameLabel:SetTextColor(C.accentLight[1], C.accentLight[2], C.accentLight[3], 1)
                    
                    -- Status (simplified - just slot count, other info visible via checkbox or Edit)
                    local statusLabel = panelFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                    statusLabel:SetPoint("TOPLEFT", 10, -30)
                    statusLabel:SetText(string.format("%d slots", panelConfig.numSlots or 3))
                    statusLabel:SetTextColor(0.7, 0.7, 0.7, 1)
                    
                    -- Edit button - opens configuration frame
                    local editBtn = GUI:CreateButton(panelFrame, "Edit", 60, 22)
                    editBtn:SetPoint("RIGHT", -140, 0)
                    
                    -- Create edit frame (initially hidden) - will set height dynamically
                    local editFrame = CreateFrame("Frame", nil, panelFrame, "BackdropTemplate")
                    editFrame:SetPoint("TOPLEFT", panelFrame, "BOTTOMLEFT", 0, -5)
                    editFrame:SetPoint("RIGHT", panelFrame, "RIGHT", 0, 0)
                    editFrame:SetBackdrop({
                        bgFile = "Interface\\Buttons\\WHITE8x8",
                        edgeFile = "Interface\\Buttons\\WHITE8x8",
                        edgeSize = 1,
                    })
                    editFrame:SetBackdropColor(C.bg[1], C.bg[2], C.bg[3], 0.98)
                    editFrame:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 1)
                    editFrame:Hide()

                    -- Register for mutual exclusion
                    table.insert(openEditFrames, {frame = editFrame, button = editBtn})

                    -- Edit frame content
                    local editY = -10
                    local editPad = 15
                    
                    -- Title
                    local editTitle = editFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
                    editTitle:SetPoint("TOPLEFT", editPad, editY)
                    editTitle:SetText("Configure " .. (panelConfig.name or ("Panel " .. i)))
                    editTitle:SetTextColor(C.accentLight[1], C.accentLight[2], C.accentLight[3], 1)
                    editY = editY - 30
                    
                    -- Panel Name
                    local nameLabel = editFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                    nameLabel:SetPoint("TOPLEFT", editPad, editY)
                    nameLabel:SetText("Panel Name:")
                    editY = editY - 20
                    
                    local nameInput = CreateFrame("EditBox", nil, editFrame, "InputBoxTemplate")
                    nameInput:SetSize(250, 20)
                    nameInput:SetPoint("TOPLEFT", editPad, editY)
                    nameInput:SetAutoFocus(false)
                    nameInput:SetText(panelConfig.name or ("Panel " .. i))
                    nameInput:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
                    nameInput:SetScript("OnTextChanged", function(self)
                        panelConfig.name = self:GetText()
                    end)
                    editY = editY - 35
                    
                    -- Slot configuration section (MOVED TO TOP)
                    local slotsHeader = editFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                    slotsHeader:SetPoint("TOPLEFT", editPad, editY)
                    slotsHeader:SetText("Slot Configuration:")
                    slotsHeader:SetTextColor(C.accentLight[1], C.accentLight[2], C.accentLight[3], 1)
                    editY = editY - 25
                    
                    -- Create dropdown for each slot
                    if not panelConfig.slots then panelConfig.slots = {} end
                    if not panelConfig.slotSettings then panelConfig.slotSettings = {} end

                    local slotDropdowns = {}
                    for slotIdx = 1, 6 do
                        local slotLabel = editFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                        slotLabel:SetPoint("TOPLEFT", editPad, editY)
                        slotLabel:SetText("Slot " .. slotIdx .. ":")

                        -- Build datatext options
                        local datatextOptions = {{value = "", text = "(empty)"}}
                        if LUICore and LUICore.Datatexts then
                            local allDatatexts = LUICore.Datatexts:GetAll()
                            for _, datatextDef in ipairs(allDatatexts) do
                                table.insert(datatextOptions, {
                                    value = datatextDef.id,
                                    text = datatextDef.displayName
                                })
                            end
                        end

                        -- Ensure slot entry exists (use "" for empty, not nil - SavedVariables can't persist nil)
                        if not panelConfig.slots[slotIdx] then
                            panelConfig.slots[slotIdx] = ""
                        end

                        -- Ensure slotSettings entry exists for shortLabel/noLabel (#119)
                        if not panelConfig.slotSettings[slotIdx] then
                            panelConfig.slotSettings[slotIdx] = { shortLabel = false, noLabel = false }
                        end

                        -- Create a wrapper table for the dropdown to reference
                        local slotWrapper = {value = panelConfig.slots[slotIdx] or ""}

                        local slotDropdown = GUI:CreateDropdown(editFrame, "", datatextOptions, "value", slotWrapper, function()
                            panelConfig.slots[slotIdx] = slotWrapper.value
                            if LUICore and LUICore.Datapanels then
                                LUICore.Datapanels:UpdatePanel(panelConfig.id)
                            end
                        end)
                        slotDropdown:SetPoint("LEFT", slotLabel, "RIGHT", 10, 0)
                        slotDropdown:SetWidth(200)

                        -- #119: Per-slot label options (Short/Hide)
                        -- Uses compact inline GUI:CreateCheckbox (vs minimap's full-width CreateFormCheckbox)
                        -- Pattern mirrors dt.slot1/slot2/slot3 but with array-based storage for dynamic slots
                        local slotSettings = panelConfig.slotSettings[slotIdx]
                        local shortLabelCb, noLabelCb  -- Forward declare for mutual reference

                        shortLabelCb = GUI:CreateCheckbox(editFrame, "Short", "shortLabel", slotSettings, function(val)
                            -- Mutual exclusion: if enabling short, disable hide
                            if val and noLabelCb then
                                noLabelCb.SetValue(false)
                            end
                            if LUICore and LUICore.Datapanels then
                                LUICore.Datapanels:UpdatePanel(panelConfig.id)
                            end
                        end)
                        shortLabelCb:SetSize(70, 20)  -- Compact for inline display
                        shortLabelCb:SetPoint("LEFT", slotDropdown, "RIGHT", 10, 0)

                        -- Hide Label checkbox (#119) - using themed GUI checkbox
                        noLabelCb = GUI:CreateCheckbox(editFrame, "Hide", "noLabel", slotSettings, function(val)
                            -- Mutual exclusion: if enabling hide, disable short
                            if val and shortLabelCb then
                                shortLabelCb.SetValue(false)
                            end
                            if LUICore and LUICore.Datapanels then
                                LUICore.Datapanels:UpdatePanel(panelConfig.id)
                            end
                        end)
                        noLabelCb:SetSize(60, 20)  -- Compact inline layout (vs minimap's full-width form checkboxes)
                        noLabelCb:SetPoint("LEFT", shortLabelCb, "RIGHT", 5, 0)

                        -- #119: Resolve conflict if both are true in SavedVariables (noLabel wins per GetLabel behavior)
                        if slotSettings.shortLabel and slotSettings.noLabel then
                            slotSettings.shortLabel = false
                        end

                        -- #119: Sync checkbox visual state with stored values
                        if shortLabelCb.SetValue then shortLabelCb.SetValue(slotSettings.shortLabel) end
                        if noLabelCb.SetValue then noLabelCb.SetValue(slotSettings.noLabel) end

                        -- Show/hide based on numSlots
                        if slotIdx <= (panelConfig.numSlots or 3) then
                            slotLabel:Show()
                            slotDropdown:Show()
                            shortLabelCb:Show()
                            noLabelCb:Show()
                        else
                            slotLabel:Hide()
                            slotDropdown:Hide()
                            shortLabelCb:Hide()
                            noLabelCb:Hide()
                        end

                        slotDropdowns[slotIdx] = {
                            label = slotLabel,
                            dropdown = slotDropdown,
                            shortLabelCb = shortLabelCb,
                            noLabelCb = noLabelCb
                        }
                        editY = editY - 30
                    end
                    
                    editY = editY - 10
                    
                    -- Panel Settings Section
                    local settingsHeader = editFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                    settingsHeader:SetPoint("TOPLEFT", editPad, editY)
                    settingsHeader:SetText("Panel Settings:")
                    settingsHeader:SetTextColor(C.accentLight[1], C.accentLight[2], C.accentLight[3], 1)
                    editY = editY - 25
                    
                    -- Width slider
                    local widthSlider = GUI:CreateSlider(editFrame, "Width", 100, 800, 1, "width", panelConfig, function()
                        if LUICore and LUICore.Datapanels then
                            LUICore.Datapanels:UpdatePanel(panelConfig.id)
                        end
                    end)
                    widthSlider:SetPoint("TOPLEFT", editPad, editY)
                    widthSlider:SetWidth(200)  -- Fixed width that works at all panel sizes
                    
                    -- Height slider
                    local heightSlider = GUI:CreateSlider(editFrame, "Height", 16, 50, 1, "height", panelConfig, function()
                        if LUICore and LUICore.Datapanels then
                            LUICore.Datapanels:UpdatePanel(panelConfig.id)
                        end
                    end)
                    heightSlider:SetPoint("LEFT", widthSlider, "RIGHT", 10, 0)
                    heightSlider:SetWidth(200)  -- Fixed width that works at all panel sizes
                    editY = editY - 65
                    
                    -- Number of slots slider (callback will be set after slotDropdowns are created)
                    local slotsSlider = GUI:CreateSlider(editFrame, "Number of Slots", 1, 6, 1, "numSlots", panelConfig, nil)
                    slotsSlider:SetPoint("TOPLEFT", editPad, editY)
                    slotsSlider:SetWidth(200)  -- Fixed width that works at all panel sizes
                    
                    -- Font size slider
                    local fontSlider = GUI:CreateSlider(editFrame, "Font Size", 8, 18, 1, "fontSize", panelConfig, function()
                        if LUICore and LUICore.Datapanels then
                            LUICore.Datapanels:UpdatePanel(panelConfig.id)
                        end
                    end)
                    fontSlider:SetPoint("LEFT", slotsSlider, "RIGHT", 10, 0)
                    fontSlider:SetWidth(200)  -- Fixed width that works at all panel sizes
                    editY = editY - 65
                    
                    -- Background opacity slider
                    local opacitySlider = GUI:CreateSlider(editFrame, "Background Opacity", 0, 100, 5, "bgOpacity", panelConfig, function()
                        if LUICore and LUICore.Datapanels then
                            LUICore.Datapanels:UpdatePanel(panelConfig.id)
                        end
                    end)
                    opacitySlider:SetPoint("TOPLEFT", editPad, editY)
                    opacitySlider:SetWidth(200)  -- Fixed width that works at all panel sizes
                    
                    -- Border size slider (0=hidden) (#90)
                    local borderSlider = GUI:CreateSlider(editFrame, "Border (0=hidden)", 0, 8, 1, "borderSize", panelConfig, function()
                        if LUICore and LUICore.Datapanels then
                            LUICore.Datapanels:UpdatePanel(panelConfig.id)
                        end
                    end)
                    borderSlider:SetPoint("LEFT", opacitySlider, "RIGHT", 10, 0)
                    borderSlider:SetWidth(200)  -- Fixed width that works at all panel sizes
                    editY = editY - 65

                    -- Border color picker (#90)
                    local borderColorPicker = GUI:CreateColorPicker(editFrame, "Border Color", "borderColor", panelConfig, function()
                        if LUICore and LUICore.Datapanels then
                            LUICore.Datapanels:UpdatePanel(panelConfig.id)
                        end
                    end)
                    borderColorPicker:SetPoint("TOPLEFT", editPad, editY)
                    editY = editY - 25

                    -- Lock toggle
                    local lockCheck = GUI:CreateCheckbox(editFrame, "Lock Position (prevents dragging)", "locked", panelConfig, function()
                        if LUICore and LUICore.Datapanels then
                            LUICore.Datapanels:SetLocked(panelConfig.id, panelConfig.locked)
                        end
                    end)
                    lockCheck:SetPoint("TOPLEFT", editPad, editY)
                    editY = editY - 35
                    
                    -- Set up callback for numSlots slider to update dropdown visibility
                    local originalOnValueChanged = slotsSlider.slider:GetScript("OnValueChanged")
                    slotsSlider.slider:SetScript("OnValueChanged", function(self, value)
                        -- Call original callback first
                        if originalOnValueChanged then
                            originalOnValueChanged(self, value)
                        end
                        
                        -- Update panel
                        if LUICore and LUICore.Datapanels then
                            LUICore.Datapanels:UpdatePanel(panelConfig.id)
                        end
                        
                        -- Update dropdown visibility based on new numSlots value
                        local numSlots = math.floor(value + 0.5) -- Round to nearest integer
                        for idx, controls in ipairs(slotDropdowns) do
                            if idx <= numSlots then
                                controls.label:Show()
                                controls.dropdown:Show()
                                if controls.shortLabelCb then controls.shortLabelCb:Show() end
                                if controls.noLabelCb then controls.noLabelCb:Show() end
                            else
                                controls.label:Hide()
                                controls.dropdown:Hide()
                                if controls.shortLabelCb then controls.shortLabelCb:Hide() end
                                if controls.noLabelCb then controls.noLabelCb:Hide() end
                            end
                        end

                        -- Update status label on main panel list
                        statusLabel:SetText(string.format("%d slots", numSlots))
                    end)
                    
                    -- Set dynamic height based on content
                    local editFrameHeight = math.abs(editY) + 50 -- Add padding at bottom
                    editFrame:SetHeight(editFrameHeight)
                    
                    -- Close button
                    local closeBtn = GUI:CreateButton(editFrame, "Close", 80, 25, function()
                        editFrame:Hide()
                        editBtn.text:SetText("Edit")
                    end)
                    closeBtn:SetPoint("BOTTOM", 0, 10)
                    
                    -- Toggle edit frame
                    editBtn:SetScript("OnClick", function()
                        if editFrame:IsShown() then
                            editFrame:Hide()
                            editBtn.text:SetText("Edit")
                        else
                            -- Close all other open edit frames first (mutual exclusion)
                            for _, entry in ipairs(openEditFrames) do
                                if entry.frame:IsShown() and entry.frame ~= editFrame then
                                    entry.frame:Hide()
                                    entry.button.text:SetText("Edit")
                                end
                            end

                            editFrame:Show()
                            editBtn.text:SetText("Close")

                            -- Update dropdown visibility when opening (in case numSlots changed externally)
                            local numSlots = panelConfig.numSlots or 3
                            for idx, controls in ipairs(slotDropdowns) do
                                if idx <= numSlots then
                                    controls.label:Show()
                                    controls.dropdown:Show()
                                    if controls.shortLabelCb then controls.shortLabelCb:Show() end
                                    if controls.noLabelCb then controls.noLabelCb:Show() end
                                else
                                    controls.label:Hide()
                                    controls.dropdown:Hide()
                                    if controls.shortLabelCb then controls.shortLabelCb:Hide() end
                                    if controls.noLabelCb then controls.noLabelCb:Hide() end
                                end
                            end
                        end
                    end)
                    
                    -- Enable toggle
                    local enableCheck = GUI:CreateCheckbox(panelFrame, "Enabled", "enabled", panelConfig, function()
                        if LUICore and LUICore.Datapanels then
                            LUICore.Datapanels:UpdatePanel(panelConfig.id)
                        end
                    end)
                    enableCheck:SetPoint("RIGHT", -80, 0)
                    
                    -- Delete button
                    local delBtn = GUI:CreateButton(panelFrame, "Delete", 60, 22, function()
                        table.remove(db.quiDatatexts.panels, i)
                        if LUICore and LUICore.Datapanels then
                            LUICore.Datapanels:DeletePanel(panelConfig.id)
                            LUICore.Datapanels:RefreshAll()
                        end
                        -- Rebuild the tab to reflect changes
                        GUI:ShowConfirmation({
                            title = "Reload UI?",
                            message = "Panel deleted. Reload UI to see changes?",
                            acceptText = "Reload",
                            cancelText = "Later",
                            onAccept = function() LuheyUI:SafeReload() end,
                        })
                    end)
                    delBtn:SetPoint("RIGHT", -10, 0)
                    
                    y = y - 70
                end
            else
                local noPanelsLabel = GUI:CreateLabel(tabContent, "No custom panels created yet. Click 'Add Panel' below to get started.", 11, C.textDim)
                noPanelsLabel:SetPoint("TOPLEFT", PAD, y)
                y = y - 30
            end
            
            -- Add Panel button
            local addPanelBtn = GUI:CreateButton(tabContent, "Add Panel", 120, 28, function()
                local newID = "panel" .. (time() % 100000)
                local newPanel = {
                    id = newID,
                    name = "Panel " .. (#panels + 1),
                    enabled = true,
                    locked = false,
                    numSlots = 3,
                    width = 300,
                    height = 22,
                    bgOpacity = 50,
                    borderSize = 2,
                    fontSize = 12,
                    position = {"CENTER", "CENTER", 0, 300},
                    slots = {},
                }
                table.insert(db.quiDatatexts.panels, newPanel)
                
                if LUICore and LUICore.Datapanels then
                    LUICore.Datapanels:RefreshAll()
                end
                
                -- Rebuild the tab to show the new panel
                GUI:ShowConfirmation({
                    title = "Reload UI?",
                    message = "Panel created. Reload UI to configure it?",
                    acceptText = "Reload",
                    cancelText = "Later",
                    onAccept = function() LuheyUI:SafeReload() end,
                })
            end)
            addPanelBtn:SetPoint("TOPLEFT", PAD, y)
            y = y - 40
        end
        
        tabContent:SetHeight(math.abs(y) + 50)
    end
    
    -- Create sub-tabs
    local subTabs = GUI:CreateSubTabs(content, {
        {name = "Minimap", builder = BuildMinimapTab},
        {name = "Datatext", builder = BuildDatatextTab},
    })
    subTabs:SetPoint("TOPLEFT", 5, -5)
    subTabs:SetPoint("TOPRIGHT", -5, -5)
    subTabs:SetHeight(700)
    
    content:SetHeight(750)
end

---------------------------------------------------------------------------
-- PAGE: CDM Setup (New Cooldown Display Manager - QUI NCDM)
-- Per-row configuration for Essential, Utility, and Buff viewers
---------------------------------------------------------------------------

-- Refresh callback for NCDM changes
local function RefreshNCDM()
    -- Trigger the layout engine
    if _G.LuheyUI_RefreshNCDM then
        _G.LuheyUI_RefreshNCDM()
    end
end

-- Initialize NCDM defaults for existing profiles that don't have them
local function EnsureNCDMDefaults(db)
    if not db then return end
    
    -- Default row settings
    local defaultRow = {
        iconCount = 4,
        iconSize = 50,
        borderSize = 2,
        shape = "square",
        zoom = 0,
        padding = -8,
        yOffset = 0,
        opacity = 1.0,
    }
    
    -- Ensure ncdm table exists
    if not db.ncdm then
        db.ncdm = {}
    end
    
    -- Ensure essential exists
    if not db.ncdm.essential then
        db.ncdm.essential = { enabled = true }
    end
    for i = 1, 3 do
        local rowKey = "row" .. i
        if not db.ncdm.essential[rowKey] then
            db.ncdm.essential[rowKey] = {}
            for k, v in pairs(defaultRow) do
                db.ncdm.essential[rowKey][k] = v
            end
            -- Row 3 disabled by default
            if i == 3 then
                db.ncdm.essential[rowKey].iconCount = 0
            end
        end
    end
    
    -- Ensure utility exists
    if not db.ncdm.utility then
        db.ncdm.utility = { enabled = true }
    end
    for i = 1, 3 do
        local rowKey = "row" .. i
        if not db.ncdm.utility[rowKey] then
            db.ncdm.utility[rowKey] = {}
            for k, v in pairs(defaultRow) do
                db.ncdm.utility[rowKey][k] = v
            end
            db.ncdm.utility[rowKey].iconSize = 42
            db.ncdm.utility[rowKey].iconCount = 6
            db.ncdm.utility[rowKey].zoom = 0.08
            -- Row 3 disabled by default
            if i == 3 then
                db.ncdm.utility[rowKey].iconCount = 0
            end
        end
    end
    
    -- Ensure buff exists
    if not db.ncdm.buff then
        db.ncdm.buff = { enabled = false }
    end
end

local function CreateCDMSetupPage(parent)
    local scroll, content = CreateScrollableContent(parent)
    local db = GetDB()
    
    -- Ensure NCDM tables exist for this profile
    EnsureNCDMDefaults(db)
    
    -- Helper to copy all settings from one row to another
    local function CopyRowSettings(sourceRow, targetRow)
        if not sourceRow or not targetRow then return end

        -- Copy all numeric and string settings
        local keys = {"iconCount", "iconSize", "borderSize", "shape", "zoom", "padding", "yOffset",
                      "durationSize", "durationOffsetX", "durationOffsetY", "durationAnchor",
                      "stackSize", "stackOffsetX", "stackOffsetY", "stackAnchor", "opacity"}
        for _, key in ipairs(keys) do
            if sourceRow[key] ~= nil then
                targetRow[key] = sourceRow[key]
            end
        end

        -- Copy color tables (deep copy)
        if sourceRow.durationTextColor then
            targetRow.durationTextColor = {sourceRow.durationTextColor[1], sourceRow.durationTextColor[2], sourceRow.durationTextColor[3], sourceRow.durationTextColor[4]}
        end
        if sourceRow.stackTextColor then
            targetRow.stackTextColor = {sourceRow.stackTextColor[1], sourceRow.stackTextColor[2], sourceRow.stackTextColor[3], sourceRow.stackTextColor[4]}
        end
    end
    
    -- Helper to build a single row's settings (form layout - single column)
    -- trackerData is the parent table (e.g., db.ncdm.essential) containing row1, row2, row3
    local function BuildRowSettings(tabContent, rowNum, rowData, trackerName, trackerData, rebuildCallback)
        local y = tabContent._currentY or -10
        local PAD = 10
        local FORM_ROW = 32

        -- Ensure offset and text size defaults exist
        if rowData.xOffset == nil then rowData.xOffset = 0 end
        if rowData.durationSize == nil then rowData.durationSize = 14 end
        if rowData.durationOffsetX == nil then rowData.durationOffsetX = 0 end
        if rowData.durationOffsetY == nil then rowData.durationOffsetY = 0 end
        if rowData.durationTextColor == nil then rowData.durationTextColor = {1, 1, 1, 1} end
        if rowData.durationAnchor == nil then rowData.durationAnchor = "CENTER" end
        if rowData.stackSize == nil then rowData.stackSize = 14 end
        if rowData.stackOffsetX == nil then rowData.stackOffsetX = 0 end
        if rowData.stackOffsetY == nil then rowData.stackOffsetY = 0 end
        if rowData.stackTextColor == nil then rowData.stackTextColor = {1, 1, 1, 1} end
        if rowData.stackAnchor == nil then rowData.stackAnchor = "BOTTOMRIGHT" end
        if rowData.opacity == nil then rowData.opacity = 1.0 end

        -- Row Header
        local rowHeader = GUI:CreateSectionHeader(tabContent, string.format("Row %d Configuration", rowNum))
        rowHeader:SetPoint("TOPLEFT", PAD, y)
        y = y - rowHeader.gap

        -- Icon settings
        local countSlider = GUI:CreateFormSlider(tabContent, "Icons in Row", 0, 20, 1, "iconCount", rowData, RefreshNCDM)
        countSlider:SetPoint("TOPLEFT", PAD, y)
        countSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local sizeSlider = GUI:CreateFormSlider(tabContent, "Icon Size", 5, 80, 1, "iconSize", rowData, RefreshNCDM)
        sizeSlider:SetPoint("TOPLEFT", PAD, y)
        sizeSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local borderSlider = GUI:CreateFormSlider(tabContent, "Border Size", 0, 5, 1, "borderSize", rowData, RefreshNCDM)
        borderSlider:SetPoint("TOPLEFT", PAD, y)
        borderSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local borderColorPicker = GUI:CreateFormColorPicker(tabContent, "Border Color", "borderColorTable", rowData, RefreshNCDM)
        borderColorPicker:SetPoint("TOPLEFT", PAD, y)
        borderColorPicker:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local zoomSlider = GUI:CreateFormSlider(tabContent, "Icon Zoom", 0, 0.2, 0.01, "zoom", rowData, RefreshNCDM)
        zoomSlider:SetPoint("TOPLEFT", PAD, y)
        zoomSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local paddingSlider = GUI:CreateFormSlider(tabContent, "Padding", -20, 20, 1, "padding", rowData, RefreshNCDM)
        paddingSlider:SetPoint("TOPLEFT", PAD, y)
        paddingSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local yOffsetSlider = GUI:CreateFormSlider(tabContent, "Row Y-Offset", -500, 500, 1, "yOffset", rowData, RefreshNCDM)
        yOffsetSlider:SetPoint("TOPLEFT", PAD, y)
        yOffsetSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local xOffsetSlider = GUI:CreateFormSlider(tabContent, "Row X-Offset", -500, 500, 1, "xOffset", rowData, RefreshNCDM)
        xOffsetSlider:SetPoint("TOPLEFT", PAD, y)
        xOffsetSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local opacitySlider = GUI:CreateFormSlider(tabContent, "Row Opacity", 0, 1.0, 0.05, "opacity", rowData, RefreshNCDM)
        opacitySlider:SetPoint("TOPLEFT", PAD, y)
        opacitySlider:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local anchorOptions = {
            {value = "TOPLEFT", text = "Top Left"},
            {value = "TOP", text = "Top"},
            {value = "TOPRIGHT", text = "Top Right"},
            {value = "LEFT", text = "Left"},
            {value = "CENTER", text = "Center"},
            {value = "RIGHT", text = "Right"},
            {value = "BOTTOMLEFT", text = "Bottom Left"},
            {value = "BOTTOM", text = "Bottom"},
            {value = "BOTTOMRIGHT", text = "Bottom Right"},
        }

        local durationSlider = GUI:CreateFormSlider(tabContent, "Duration Text Size", 8, 50, 1, "durationSize", rowData, RefreshNCDM)
        durationSlider:SetPoint("TOPLEFT", PAD, y)
        durationSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local durationAnchorDD = GUI:CreateFormDropdown(tabContent, "Anchor Duration To", anchorOptions, "durationAnchor", rowData, RefreshNCDM)
        durationAnchorDD:SetPoint("TOPLEFT", PAD, y)
        durationAnchorDD:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local durationXSlider = GUI:CreateFormSlider(tabContent, "Duration X-Offset", -80, 80, 1, "durationOffsetX", rowData, RefreshNCDM)
        durationXSlider:SetPoint("TOPLEFT", PAD, y)
        durationXSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local durationYSlider = GUI:CreateFormSlider(tabContent, "Duration Y-Offset", -80, 80, 1, "durationOffsetY", rowData, RefreshNCDM)
        durationYSlider:SetPoint("TOPLEFT", PAD, y)
        durationYSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local durationColorPicker = GUI:CreateFormColorPicker(tabContent, "Duration Text Color", "durationTextColor", rowData, RefreshNCDM)
        durationColorPicker:SetPoint("TOPLEFT", PAD, y)
        durationColorPicker:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local stackSlider = GUI:CreateFormSlider(tabContent, "Stack Text Size", 8, 50, 1, "stackSize", rowData, RefreshNCDM)
        stackSlider:SetPoint("TOPLEFT", PAD, y)
        stackSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local stackAnchorDD = GUI:CreateFormDropdown(tabContent, "Anchor Stack To", anchorOptions, "stackAnchor", rowData, RefreshNCDM)
        stackAnchorDD:SetPoint("TOPLEFT", PAD, y)
        stackAnchorDD:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local stackXSlider = GUI:CreateFormSlider(tabContent, "Stack X-Offset", -80, 80, 1, "stackOffsetX", rowData, RefreshNCDM)
        stackXSlider:SetPoint("TOPLEFT", PAD, y)
        stackXSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local stackYSlider = GUI:CreateFormSlider(tabContent, "Stack Y-Offset", -80, 80, 1, "stackOffsetY", rowData, RefreshNCDM)
        stackYSlider:SetPoint("TOPLEFT", PAD, y)
        stackYSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local stackColorPicker = GUI:CreateFormColorPicker(tabContent, "Stack Text Color", "stackTextColor", rowData, RefreshNCDM)
        stackColorPicker:SetPoint("TOPLEFT", PAD, y)
        stackColorPicker:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local shapeSlider = GUI:CreateFormSlider(tabContent, "Icon Shape", 1.0, 2.0, 0.01, "aspectRatioCrop", rowData, RefreshNCDM)
        shapeSlider:SetPoint("TOPLEFT", PAD, y)
        shapeSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local shapeTip = GUI:CreateLabel(tabContent, "Higher values imply flatter icons.", 11, C.textMuted)
        shapeTip:SetPoint("TOPLEFT", PAD, y)
        shapeTip:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        shapeTip:SetJustifyH("LEFT")
        y = y - 20

        -- Copy from dropdown (if trackerData is provided)
        if trackerData then
            local copyOptions = {}
            for i = 1, 3 do
                if i ~= rowNum then
                    table.insert(copyOptions, {value = "row" .. i, text = "Row " .. i})
                end
            end

            -- Copy Settings From - using form dropdown with Apply button
            local copyWrapper = { selected = copyOptions[1] and copyOptions[1].value or nil }
            local copyRow = CreateFrame("Frame", nil, tabContent)
            copyRow:SetHeight(FORM_ROW)
            copyRow:SetPoint("TOPLEFT", PAD, y)
            copyRow:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)

            local applyBtn = GUI:CreateButton(copyRow, "Apply", 60, 24, function()
                if copyWrapper.selected and trackerData[copyWrapper.selected] then
                    CopyRowSettings(trackerData[copyWrapper.selected], rowData)
                    RefreshNCDM()
                    if rebuildCallback then rebuildCallback() end
                end
            end)
            applyBtn:SetPoint("RIGHT", copyRow, "RIGHT", 0, 2)

            local copyDropdown = GUI:CreateFormDropdown(copyRow, "Copy Settings From", copyOptions, "selected", copyWrapper, nil)
            copyDropdown:SetPoint("TOPLEFT", 0, 0)
            copyDropdown:SetPoint("RIGHT", applyBtn, "LEFT", -8, 0)

            y = y - FORM_ROW
        end
        
        -- Add spacing between rows
        y = y - 15
        
        tabContent._currentY = y
        return y
    end
    
    -- Build Essential sub-tab
    local function BuildEssentialTab(tabContent)
        tabContent._currentY = -10
        local PAD = 10
        local y = tabContent._currentY

        -- Set search context for auto-registration
        GUI:SetSearchContext({tabIndex = 6, tabName = "CDM Setup & Class Bars", subTabIndex = 1, subTabName = "Essential"})

        if db and db.ncdm and db.ncdm.essential then
            local ess = db.ncdm.essential
            
            -- Rebuild callback to refresh the tab after copying
            local function rebuildEssential()
                -- Clear and rebuild the tab content
                for _, child in pairs({tabContent:GetChildren()}) do
                    child:Hide()
                    child:SetParent(nil)
                end
                for _, region in pairs({tabContent:GetRegions()}) do
                    region:Hide()
                end
                BuildEssentialTab(tabContent)
            end
            
            -- Enable checkbox
            local FORM_ROW = 32
            local enableCheck = GUI:CreateFormCheckbox(tabContent, "Enable Essential Cooldowns Display", "enabled", ess, RefreshNCDM)
            enableCheck:SetPoint("TOPLEFT", PAD, y)
            enableCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW
            tabContent._currentY = y

            -- Layout Direction dropdown
            ess.layoutDirection = ess.layoutDirection or "HORIZONTAL"
            local directionOptions = {
                {value = "HORIZONTAL", text = "Horizontal"},
                {value = "VERTICAL", text = "Vertical"},
            }
            local directionDropdown = GUI:CreateFormDropdown(tabContent, "Layout Direction", directionOptions, "layoutDirection", ess, RefreshNCDM)
            directionDropdown:SetPoint("TOPLEFT", PAD, y)
            directionDropdown:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW
            tabContent._currentY = y

            -- Hint text
            local hintText = GUI:CreateLabel(tabContent, "Tip: Set Icon Size to 100% in Edit Mode for best results.", 11, C.textMuted)
            hintText:SetPoint("TOPLEFT", PAD, y)
            hintText:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            hintText:SetJustifyH("LEFT")
            y = y - 24
            tabContent._currentY = y

            -- Row 1
            if ess.row1 then
                BuildRowSettings(tabContent, 1, ess.row1, "Essential", ess, rebuildEssential)
            end
            
            -- Row 2
            if ess.row2 then
                BuildRowSettings(tabContent, 2, ess.row2, "Essential", ess, rebuildEssential)
            end
            
            -- Row 3
            if ess.row3 then
                BuildRowSettings(tabContent, 3, ess.row3, "Essential", ess, rebuildEssential)
            end
        else
            local info = GUI:CreateLabel(tabContent, "NCDM Essential settings not found. Please reload UI.", 12, C.accentLight)
            info:SetPoint("TOPLEFT", PAD, y)
        end
        
        tabContent:SetHeight(math.abs(tabContent._currentY) + 50)
    end
    
    -- Build Utility sub-tab
    local function BuildUtilityTab(tabContent)
        tabContent._currentY = -10
        local PAD = 10
        local y = tabContent._currentY

        -- Set search context for auto-registration
        GUI:SetSearchContext({tabIndex = 6, tabName = "CDM Setup & Class Bars", subTabIndex = 2, subTabName = "Utility"})

        if db and db.ncdm and db.ncdm.utility then
            local util = db.ncdm.utility
            
            -- Rebuild callback to refresh the tab after copying
            local function rebuildUtility()
                -- Clear and rebuild the tab content
                for _, child in pairs({tabContent:GetChildren()}) do
                    child:Hide()
                    child:SetParent(nil)
                end
                for _, region in pairs({tabContent:GetRegions()}) do
                    region:Hide()
                end
                BuildUtilityTab(tabContent)
            end
            
            -- Enable checkbox
            local FORM_ROW = 32
            local enableCheck = GUI:CreateFormCheckbox(tabContent, "Enable Utility Cooldowns Display", "enabled", util, RefreshNCDM)
            enableCheck:SetPoint("TOPLEFT", PAD, y)
            enableCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW
            tabContent._currentY = y

            -- Anchor Below Essential toggle
            local anchorCheck = GUI:CreateFormCheckbox(tabContent, "Anchor Below Essential Rows", "anchorBelowEssential", util, function()
                RefreshNCDM()
                if _G.LuheyUI_ApplyUtilityAnchor then
                    _G.LuheyUI_ApplyUtilityAnchor()
                end
            end)
            anchorCheck:SetPoint("TOPLEFT", PAD, y)
            anchorCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW
            tabContent._currentY = y

            -- Anchor Gap slider
            local gapSlider = GUI:CreateFormSlider(tabContent, "Anchor Gap", -200, 200, 1, "anchorGap", util, function()
                RefreshNCDM()
                if _G.LuheyUI_ApplyUtilityAnchor then
                    _G.LuheyUI_ApplyUtilityAnchor()
                end
            end)
            gapSlider:SetPoint("TOPLEFT", PAD, y)
            gapSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW
            tabContent._currentY = y

            -- Layout Direction dropdown
            util.layoutDirection = util.layoutDirection or "HORIZONTAL"
            local directionOptions = {
                {value = "HORIZONTAL", text = "Horizontal"},
                {value = "VERTICAL", text = "Vertical"},
            }
            local directionDropdown = GUI:CreateFormDropdown(tabContent, "Layout Direction", directionOptions, "layoutDirection", util, RefreshNCDM)
            directionDropdown:SetPoint("TOPLEFT", PAD, y)
            directionDropdown:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW
            tabContent._currentY = y

            -- Hint text
            local hintText = GUI:CreateLabel(tabContent, "Tip: Set Icon Size to 100% in Edit Mode for best results.", 11, C.textMuted)
            hintText:SetPoint("TOPLEFT", PAD, y)
            hintText:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            hintText:SetJustifyH("LEFT")
            y = y - 24
            tabContent._currentY = y

            -- Row 1
            if util.row1 then
                BuildRowSettings(tabContent, 1, util.row1, "Utility", util, rebuildUtility)
            end
            
            -- Row 2
            if util.row2 then
                BuildRowSettings(tabContent, 2, util.row2, "Utility", util, rebuildUtility)
            end
            
            -- Row 3
            if util.row3 then
                BuildRowSettings(tabContent, 3, util.row3, "Utility", util, rebuildUtility)
            end
        else
            local info = GUI:CreateLabel(tabContent, "NCDM Utility settings not found. Please reload UI.", 12, C.accentLight)
            info:SetPoint("TOPLEFT", PAD, y)
        end
        
        tabContent:SetHeight(math.abs(tabContent._currentY) + 50)
    end
    
    -- Build Buff sub-tab with customization options
    local function BuildBuffTab(tabContent)
        local PAD = 10
        local y = -10

        -- Set search context for widget auto-registration
        GUI:SetSearchContext({tabIndex = 6, tabName = "CDM Setup & Class Bars", subTabIndex = 3, subTabName = "Buff"})

        -- Ensure buff settings exist with all required fields
        if not db.ncdm then db.ncdm = {} end
        if not db.ncdm.buff then db.ncdm.buff = {} end
        
        -- Ensure all fields exist with defaults
        local buffData = db.ncdm.buff
        if buffData.enabled == nil then buffData.enabled = true end
        if buffData.iconSize == nil then buffData.iconSize = 42 end
        if buffData.borderSize == nil then buffData.borderSize = 2 end
        if buffData.shape == nil then buffData.shape = "square" end  -- DEPRECATED
        if buffData.aspectRatioCrop == nil then buffData.aspectRatioCrop = 1.0 end
        if buffData.growthDirection == nil then buffData.growthDirection = "CENTERED_HORIZONTAL" end
        if buffData.zoom == nil then buffData.zoom = 0 end
        if buffData.padding == nil then buffData.padding = 0 end
        if buffData.durationSize == nil then buffData.durationSize = 12 end
        if buffData.stackSize == nil then buffData.stackSize = 12 end
        if buffData.opacity == nil then buffData.opacity = 1.0 end

        -- Callback to refresh buff bar
        local function RefreshBuff()
            if _G.LuheyUI_RefreshBuffBar then
                _G.LuheyUI_RefreshBuffBar()
            end
        end
        
        -- Header
        local FORM_ROW = 32
        local header = GUI:CreateSectionHeader(tabContent, "Buff Icon Settings")
        header:SetPoint("TOPLEFT", PAD, y)
        y = y - 24

        local enableCb = GUI:CreateFormCheckbox(tabContent, "Enable Buff Icon Styling", "enabled", buffData, RefreshBuff)
        enableCb:SetPoint("TOPLEFT", PAD, y)
        enableCb:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local sizeSlider = GUI:CreateFormSlider(tabContent, "Icon Size", 20, 80, 1, "iconSize", buffData, RefreshBuff)
        sizeSlider:SetPoint("TOPLEFT", PAD, y)
        sizeSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local borderSlider = GUI:CreateFormSlider(tabContent, "Border Size", 0, 8, 1, "borderSize", buffData, RefreshBuff)
        borderSlider:SetPoint("TOPLEFT", PAD, y)
        borderSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local zoomSlider = GUI:CreateFormSlider(tabContent, "Icon Zoom", 0, 0.2, 0.01, "zoom", buffData, RefreshBuff)
        zoomSlider:SetPoint("TOPLEFT", PAD, y)
        zoomSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local paddingSlider = GUI:CreateFormSlider(tabContent, "Icon Padding", -20, 20, 1, "padding", buffData, RefreshBuff)
        paddingSlider:SetPoint("TOPLEFT", PAD, y)
        paddingSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local opacitySlider = GUI:CreateFormSlider(tabContent, "Buff Opacity", 0, 1.0, 0.05, "opacity", buffData, RefreshBuff)
        opacitySlider:SetPoint("TOPLEFT", PAD, y)
        opacitySlider:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local durationSlider = GUI:CreateFormSlider(tabContent, "Duration Size", 8, 50, 1, "durationSize", buffData, RefreshBuff)
        durationSlider:SetPoint("TOPLEFT", PAD, y)
        durationSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local anchorOptions = {
            {value = "TOPLEFT", text = "Top Left"},
            {value = "TOP", text = "Top"},
            {value = "TOPRIGHT", text = "Top Right"},
            {value = "LEFT", text = "Left"},
            {value = "CENTER", text = "Center"},
            {value = "RIGHT", text = "Right"},
            {value = "BOTTOMLEFT", text = "Bottom Left"},
            {value = "BOTTOM", text = "Bottom"},
            {value = "BOTTOMRIGHT", text = "Bottom Right"},
        }

        local durationAnchorDD = GUI:CreateFormDropdown(tabContent, "Anchor Duration To", anchorOptions, "durationAnchor", buffData, RefreshBuff)
        durationAnchorDD:SetPoint("TOPLEFT", PAD, y)
        durationAnchorDD:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local durationXSlider = GUI:CreateFormSlider(tabContent, "Duration X Offset", -20, 20, 1, "durationOffsetX", buffData, RefreshBuff)
        durationXSlider:SetPoint("TOPLEFT", PAD, y)
        durationXSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local durationYSlider = GUI:CreateFormSlider(tabContent, "Duration Y Offset", -20, 20, 1, "durationOffsetY", buffData, RefreshBuff)
        durationYSlider:SetPoint("TOPLEFT", PAD, y)
        durationYSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local stackSlider = GUI:CreateFormSlider(tabContent, "Stack Size", 8, 50, 1, "stackSize", buffData, RefreshBuff)
        stackSlider:SetPoint("TOPLEFT", PAD, y)
        stackSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local stackAnchorDD = GUI:CreateFormDropdown(tabContent, "Anchor Stack To", anchorOptions, "stackAnchor", buffData, RefreshBuff)
        stackAnchorDD:SetPoint("TOPLEFT", PAD, y)
        stackAnchorDD:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local stackXSlider = GUI:CreateFormSlider(tabContent, "Stack X Offset", -20, 20, 1, "stackOffsetX", buffData, RefreshBuff)
        stackXSlider:SetPoint("TOPLEFT", PAD, y)
        stackXSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local stackYSlider = GUI:CreateFormSlider(tabContent, "Stack Y Offset", -20, 20, 1, "stackOffsetY", buffData, RefreshBuff)
        stackYSlider:SetPoint("TOPLEFT", PAD, y)
        stackYSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local growthDropdown = GUI:CreateFormDropdown(tabContent, "Growth Direction", {
            {value = "CENTERED_HORIZONTAL", text = "Centered"},
            {value = "UP", text = "Grow Up"},
            {value = "DOWN", text = "Grow Down"},
        }, "growthDirection", buffData, RefreshBuff)
        growthDropdown:SetPoint("TOPLEFT", PAD, y)
        growthDropdown:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local shapeSlider = GUI:CreateFormSlider(tabContent, "Icon Shape", 1.0, 2.0, 0.01, "aspectRatioCrop", buffData, RefreshBuff)
        shapeSlider:SetPoint("TOPLEFT", PAD, y)
        shapeSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local shapeTip = GUI:CreateLabel(tabContent, "Higher values imply flatter icons.", 11, C.textMuted)
        shapeTip:SetPoint("TOPLEFT", PAD, y)
        shapeTip:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        shapeTip:SetJustifyH("LEFT")
        y = y - 20

        y = y - 10 -- Spacer

        local info = GUI:CreateLabel(tabContent, "Position the Buff Icons using Edit Mode (Esc > Edit Mode).", 11, C.textMuted)
        info:SetPoint("TOPLEFT", PAD, y)
        info:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        info:SetJustifyH("LEFT")
        y = y - FORM_ROW

        -----------------------------------------------------------------------
        -- TRACKED BAR SECTION
        -----------------------------------------------------------------------

        -- Ensure trackedBar settings exist with defaults
        if not db.ncdm.trackedBar then db.ncdm.trackedBar = {} end
        local trackedData = db.ncdm.trackedBar
        if trackedData.enabled == nil then trackedData.enabled = true end
        if trackedData.hideIcon == nil then trackedData.hideIcon = false end
        if trackedData.barHeight == nil then trackedData.barHeight = 24 end
        if trackedData.barWidth == nil then trackedData.barWidth = 200 end
        if trackedData.texture == nil then trackedData.texture = "Quazii v5" end
        if trackedData.useClassColor == nil then trackedData.useClassColor = true end
        if trackedData.barColor == nil then trackedData.barColor = {0.204, 0.827, 0.6, 1} end
        if trackedData.barOpacity == nil then trackedData.barOpacity = 1.0 end
        if trackedData.borderSize == nil then trackedData.borderSize = 1 end
        if trackedData.bgColor == nil then trackedData.bgColor = {0, 0, 0, 1} end
        if trackedData.bgOpacity == nil then trackedData.bgOpacity = 0.7 end
        if trackedData.textSize == nil then trackedData.textSize = 12 end
        if trackedData.spacing == nil then trackedData.spacing = 4 end
        if trackedData.growUp == nil then trackedData.growUp = true end
        if trackedData.hideText == nil then trackedData.hideText = false end
        -- Vertical bar settings
        if trackedData.orientation == nil then trackedData.orientation = "horizontal" end
        if trackedData.fillDirection == nil then trackedData.fillDirection = "up" end
        if trackedData.iconPosition == nil then trackedData.iconPosition = "top" end
        if trackedData.showTextOnVertical == nil then trackedData.showTextOnVertical = false end

        y = y - 10 -- Extra spacing before new section

        local trackedHeader = GUI:CreateSectionHeader(tabContent, "Tracked Bar")
        trackedHeader:SetPoint("TOPLEFT", PAD, y)
        y = y - trackedHeader.gap

        -- Description text
        local trackedDesc = GUI:CreateLabel(tabContent, "Controls the appearance of buff duration bars for spells under 'Tracked Bars' of your CDM. Hint: Most players will opt to display buffs via the Buff Icon section above.", 11, C.textMuted)
        trackedDesc:SetPoint("TOPLEFT", PAD, y)
        trackedDesc:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        trackedDesc:SetJustifyH("LEFT")
        trackedDesc:SetWordWrap(true)
        trackedDesc:SetHeight(30)
        y = y - 40

        -- Enable toggle
        local trackedEnable = GUI:CreateFormCheckbox(tabContent, "Enable Tracked Bar Styling", "enabled", trackedData, RefreshBuff)
        trackedEnable:SetPoint("TOPLEFT", PAD, y)
        trackedEnable:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        -- Hide Icon toggle
        local hideIconCheck = GUI:CreateFormCheckbox(tabContent, "Hide Icon", "hideIcon", trackedData, RefreshBuff)
        hideIconCheck:SetPoint("TOPLEFT", PAD, y)
        hideIconCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        -- Bar Height
        local heightSlider = GUI:CreateFormSlider(tabContent, "Bar Height", 2, 48, 1, "barHeight", trackedData, RefreshBuff)
        heightSlider:SetPoint("TOPLEFT", PAD, y)
        heightSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        -- Bar Width
        local widthSlider = GUI:CreateFormSlider(tabContent, "Bar Width", 100, 400, 1, "barWidth", trackedData, RefreshBuff)
        widthSlider:SetPoint("TOPLEFT", PAD, y)
        widthSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        -- Bar Texture
        local textureDropdown = GUI:CreateFormDropdown(tabContent, "Bar Texture", GetTextureList(), "texture", trackedData, RefreshBuff)
        textureDropdown:SetPoint("TOPLEFT", PAD, y)
        textureDropdown:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        -- Forward reference for orientation change callback
        local updateVerticalStates

        -- Bar Orientation
        local orientationDropdown = GUI:CreateFormDropdown(tabContent, "Bar Orientation", {
            {value = "horizontal", text = "Horizontal"},
            {value = "vertical", text = "Vertical"},
        }, "orientation", trackedData, function()
            RefreshBuff()
            if updateVerticalStates then updateVerticalStates() end
            GUI:ShowConfirmation({
                title = "Reload Required",
                message = "Changing bar orientation requires a UI reload to take full effect.",
                acceptText = "Reload Now",
                cancelText = "Later",
                isDestructive = false,
                onAccept = function()
                    LuheyUI:SafeReload()
                end,
            })
        end)
        orientationDropdown:SetPoint("TOPLEFT", PAD, y)
        orientationDropdown:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        -- Stack Direction (renamed from Growth Direction, context-dependent)
        local growthDropdown = GUI:CreateFormDropdown(tabContent, "Stack Direction", {
            {value = true, text = "Up / Right"},
            {value = false, text = "Down / Left"},
        }, "growUp", trackedData, RefreshBuff)
        growthDropdown:SetPoint("TOPLEFT", PAD, y)
        growthDropdown:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local stackTip = GUI:CreateLabel(tabContent, "Up/Down for horizontal bars, Right/Left for vertical bars.", 11, C.textMuted)
        stackTip:SetPoint("TOPLEFT", PAD, y)
        stackTip:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        stackTip:SetJustifyH("LEFT")
        y = y - 20

        -- Fill Direction (Vertical only)
        local fillDropdown = GUI:CreateFormDropdown(tabContent, "Fill Direction (Vertical)", {
            {value = "up", text = "Fill Up"},
            {value = "down", text = "Fill Down"},
        }, "fillDirection", trackedData, RefreshBuff)
        fillDropdown:SetPoint("TOPLEFT", PAD, y)
        fillDropdown:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local fillTip = GUI:CreateLabel(tabContent, "Direction the progress bar fills as buff duration decreases.", 11, C.textMuted)
        fillTip:SetPoint("TOPLEFT", PAD, y)
        fillTip:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        fillTip:SetJustifyH("LEFT")
        y = y - 20

        -- Icon Position (Vertical only)
        local iconPosDropdown = GUI:CreateFormDropdown(tabContent, "Icon Position (Vertical)", {
            {value = "top", text = "Top"},
            {value = "bottom", text = "Bottom"},
        }, "iconPosition", trackedData, RefreshBuff)
        iconPosDropdown:SetPoint("TOPLEFT", PAD, y)
        iconPosDropdown:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local iconPosTip = GUI:CreateLabel(tabContent, "Where the spell icon appears on vertical bars.", 11, C.textMuted)
        iconPosTip:SetPoint("TOPLEFT", PAD, y)
        iconPosTip:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        iconPosTip:SetJustifyH("LEFT")
        y = y - 20

        -- Show Text (Vertical only)
        local showTextCheck = GUI:CreateFormCheckbox(tabContent, "Show Text (Vertical)", "showTextOnVertical", trackedData, RefreshBuff)
        showTextCheck:SetPoint("TOPLEFT", PAD, y)
        showTextCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local textTip = GUI:CreateLabel(tabContent, "Text hidden by default on vertical bars. Enable for bars 48+ pixels wide.", 11, C.textMuted)
        textTip:SetPoint("TOPLEFT", PAD, y)
        textTip:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        textTip:SetJustifyH("LEFT")
        y = y - 20

        -- UX: Dim vertical-only options when horizontal, swap height/width labels
        -- Assign to forward reference so orientation dropdown onChange can call it
        updateVerticalStates = function()
            local isVertical = trackedData.orientation == "vertical"
            local alpha = isVertical and 1.0 or 0.4
            fillDropdown:SetAlpha(alpha)
            iconPosDropdown:SetAlpha(alpha)
            showTextCheck:SetAlpha(alpha)
            -- Swap height/width labels based on orientation
            if heightSlider.label and widthSlider.label then
                if isVertical then
                    heightSlider.label:SetText("Bar Width")
                    widthSlider.label:SetText("Bar Length")
                else
                    heightSlider.label:SetText("Bar Height")
                    widthSlider.label:SetText("Bar Width")
                end
            end
        end
        updateVerticalStates()  -- Initial state

        -- Use Class Color
        local classColorCheck = GUI:CreateFormCheckbox(tabContent, "Use Class Color", "useClassColor", trackedData, RefreshBuff)
        classColorCheck:SetPoint("TOPLEFT", PAD, y)
        classColorCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        -- Bar Color (fallback)
        local barColorPicker = GUI:CreateFormColorPicker(tabContent, "Bar Color (Fallback)", "barColor", trackedData, RefreshBuff)
        barColorPicker:SetPoint("TOPLEFT", PAD, y)
        barColorPicker:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        -- Bar Opacity
        local barOpacitySlider = GUI:CreateFormSlider(tabContent, "Bar Opacity", 0, 1, 0.05, "barOpacity", trackedData, RefreshBuff)
        barOpacitySlider:SetPoint("TOPLEFT", PAD, y)
        barOpacitySlider:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        -- Border Size
        local trackedBorderSlider = GUI:CreateFormSlider(tabContent, "Border Size", 0, 4, 1, "borderSize", trackedData, RefreshBuff)
        trackedBorderSlider:SetPoint("TOPLEFT", PAD, y)
        trackedBorderSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        -- Background Color
        local bgColorPicker = GUI:CreateFormColorPicker(tabContent, "Background Color", "bgColor", trackedData, RefreshBuff)
        bgColorPicker:SetPoint("TOPLEFT", PAD, y)
        bgColorPicker:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        -- Background Opacity
        local bgOpacitySlider = GUI:CreateFormSlider(tabContent, "Background Opacity", 0, 1, 0.1, "bgOpacity", trackedData, RefreshBuff)
        bgOpacitySlider:SetPoint("TOPLEFT", PAD, y)
        bgOpacitySlider:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        -- Text Size
        local trackedTextSlider = GUI:CreateFormSlider(tabContent, "Text Size", 8, 24, 1, "textSize", trackedData, RefreshBuff)
        trackedTextSlider:SetPoint("TOPLEFT", PAD, y)
        trackedTextSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        -- Hide Text
        local hideTextCheck = GUI:CreateFormCheckbox(tabContent, "Hide Text", "hideText", trackedData, RefreshBuff)
        hideTextCheck:SetPoint("TOPLEFT", PAD, y)
        hideTextCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        -- Bar Spacing
        local spacingSlider = GUI:CreateFormSlider(tabContent, "Bar Spacing", 0, 20, 1, "spacing", trackedData, RefreshBuff)
        spacingSlider:SetPoint("TOPLEFT", PAD, y)
        spacingSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        tabContent:SetHeight(math.abs(y) + 20)
    end
    
    -- Build Powerbar sub-tab
    local function BuildPowerbarTab(tabContent)
        local PAD = 10
        local y = -10

        -- Set search context for widget auto-registration
        GUI:SetSearchContext({tabIndex = 6, tabName = "CDM Setup & Class Bars", subTabIndex = 4, subTabName = "Class Resource Bar"})

        -- Ensure powerBar settings exist
        if not db.powerBar then db.powerBar = {} end
        if not db.secondaryPowerBar then db.secondaryPowerBar = {} end
        
        -- Ensure all fields exist with defaults
        local primary = db.powerBar
        if primary.enabled == nil then primary.enabled = true end
        if primary.autoAttach == nil then primary.autoAttach = true end
        if primary.width == nil then primary.width = 310 end
        if primary.height == nil then primary.height = 8 end
        if primary.offsetX == nil then primary.offsetX = 0 end
        if primary.offsetY == nil then primary.offsetY = 25 end
        if primary.texture == nil then primary.texture = "Solid" end
        if primary.colorMode == nil then primary.colorMode = "power" end  -- "power", "class", or "custom"
        if primary.usePowerColor == nil then primary.usePowerColor = true end  -- Default to power type color
        if primary.useClassColor == nil then primary.useClassColor = false end
        if primary.useCustomColor == nil then primary.useCustomColor = false end
        if primary.customColor == nil then primary.customColor = {0.2, 0.6, 1.0, 1} end
        if primary.bgColor == nil then primary.bgColor = {0.1, 0.1, 0.1, 0.8} end
        if primary.showText == nil then primary.showText = true end
        if primary.showPercent == nil then primary.showPercent = true end
        if primary.textSize == nil then primary.textSize = 14 end
        if primary.textX == nil then primary.textX = 0 end
        if primary.textY == nil then primary.textY = 2 end
        if primary.borderSize == nil then primary.borderSize = 1 end
        if primary.orientation == nil then primary.orientation = "AUTO" end
        if primary.snapGap == nil then primary.snapGap = 5 end

        local secondary = db.secondaryPowerBar
        if secondary.enabled == nil then secondary.enabled = true end
        if secondary.autoAttach == nil then secondary.autoAttach = true end
        if secondary.width == nil then secondary.width = 310 end
        if secondary.height == nil then secondary.height = 8 end
        if secondary.lockedBaseX == nil then secondary.lockedBaseX = 0 end
        if secondary.lockedBaseY == nil then secondary.lockedBaseY = 0 end
        if secondary.offsetX == nil then secondary.offsetX = 0 end
        if secondary.offsetY == nil then secondary.offsetY = 0 end
        if secondary.texture == nil then secondary.texture = "Solid" end
        if secondary.colorMode == nil then secondary.colorMode = "power" end  -- "power", "class", or "custom"
        if secondary.usePowerColor == nil then secondary.usePowerColor = true end  -- Default to power type color
        if secondary.useClassColor == nil then secondary.useClassColor = false end
        if secondary.useCustomColor == nil then secondary.useCustomColor = false end
        if secondary.customColor == nil then secondary.customColor = {1.0, 0.8, 0.2, 1} end
        if secondary.bgColor == nil then secondary.bgColor = {0.1, 0.1, 0.1, 0.8} end
        if secondary.showText == nil then secondary.showText = true end
        if secondary.showPercent == nil then secondary.showPercent = false end
        if secondary.showFragmentedPowerBarText == nil then secondary.showFragmentedPowerBarText = true end
        if secondary.textSize == nil then secondary.textSize = 14 end
        if secondary.textX == nil then secondary.textX = 0 end
        if secondary.textY == nil then secondary.textY = 2 end
        if secondary.borderSize == nil then secondary.borderSize = 1 end
        if secondary.orientation == nil then secondary.orientation = "AUTO" end
        if secondary.snapGap == nil then secondary.snapGap = 5 end

        -- Callback to refresh power bars
        local function RefreshPowerBars()
            if _G.LuheyUI and _G.LuheyUI.LUICore then
                local LUICore = _G.LuheyUI.LUICore
                if LUICore.UpdatePowerBar then LUICore:UpdatePowerBar() end
                if LUICore.UpdateSecondaryPowerBar then LUICore:UpdateSecondaryPowerBar() end
            end
        end
        
        -- Get texture options from LSM
        local function GetTextureOptions()
            local options = {}
            local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
            if LSM then
                local textures = LSM:HashTable("statusbar")
                for name, _ in pairs(textures) do
                    table.insert(options, {value = name, text = name})
                end
                table.sort(options, function(a, b) return a.text < b.text end)
            else
                options = {
                    {value = "Quazii", text = "Quazii"},
                    {value = "Smooth", text = "Smooth"},
                    {value = "Flat", text = "Flat"},
                }
            end
            return options
        end
        
        -- Forward declare slider references
        local widthPrimarySlider, widthSecondarySlider
        local yOffsetPrimarySlider, yOffsetSecondarySlider

        local FORM_ROW = 32

        -- =====================================================
        -- GENERAL SETTINGS
        -- =====================================================
        local generalHeader = GUI:CreateSectionHeader(tabContent, "General")
        generalHeader:SetPoint("TOPLEFT", PAD, y)
        y = y - generalHeader.gap

        -- Reload prompt for enable/standalone toggles
        local function PromptResourceBarReload()
            GUI:ShowConfirmation({
                title = "Reload UI?",
                message = "Changing resource bar settings requires a UI reload to take effect.",
                acceptText = "Reload",
                cancelText = "Later",
                onAccept = function() LuheyUI:SafeReload() end,
            })
        end

        -- Enable toggles
        local enablePrimary = GUI:CreateFormToggle(tabContent, "Enable Primary Class Resource Bar", "enabled", primary, PromptResourceBarReload)
        enablePrimary:SetPoint("TOPLEFT", PAD, y)
        enablePrimary:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local enableSecondary = GUI:CreateFormToggle(tabContent, "Enable Secondary Class Resource Bar", "enabled", secondary, PromptResourceBarReload)
        enableSecondary:SetPoint("TOPLEFT", PAD, y)
        enableSecondary:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        -- Standalone toggles
        local standalonePrimary = GUI:CreateFormToggle(tabContent, "Primary Standalone Mode", "standaloneMode", primary, PromptResourceBarReload)
        standalonePrimary:SetPoint("TOPLEFT", PAD, y)
        standalonePrimary:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local standaloneSecondary = GUI:CreateFormToggle(tabContent, "Secondary Standalone Mode", "standaloneMode", secondary, PromptResourceBarReload)
        standaloneSecondary:SetPoint("TOPLEFT", PAD, y)
        standaloneSecondary:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local secondaryImptText = GUI:CreateLabel(tabContent, "IMPT: If you choose NOT to display a Primary Bar, and ONLY want a Secondary Bar, toggle this ON. Else it will not show.", 11, C.warning)
        secondaryImptText:SetPoint("TOPLEFT", PAD, y)
        secondaryImptText:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        secondaryImptText:SetJustifyH("LEFT")
        y = y - 25

        local standaloneDesc = GUI:CreateLabel(tabContent, "Standalone Mode: Bar won't fade or hide with CDM visibility. Use if you don't use Essential/Utility cooldown displays.", 11, C.textMuted)
        standaloneDesc:SetPoint("TOPLEFT", PAD, y)
        standaloneDesc:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        standaloneDesc:SetJustifyH("LEFT")
        y = y - 25

        -- Unthrottled CPU Use toggle (affects both primary and secondary)
        local unthrottledToggle = GUI:CreateFormToggle(tabContent, "Unthrottled CPU Use", "unthrottledCPU", primary, RefreshPowerBars)
        unthrottledToggle:SetPoint("TOPLEFT", PAD, y)
        unthrottledToggle:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local unthrottledDesc = GUI:CreateLabel(tabContent, "Remove throttle on the number of updates per second. Toggle on for smoother updates, but higher CPU Usage.", 11, C.textMuted)
        unthrottledDesc:SetPoint("TOPLEFT", PAD, y)
        unthrottledDesc:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        unthrottledDesc:SetJustifyH("LEFT")
        y = y - 25

        -- Spacer before Primary section
        y = y - 10

        -- =====================================================
        -- PRIMARY POWER BAR SECTION
        -- =====================================================
        local primaryHeader = GUI:CreateSectionHeader(tabContent, "Primary Class Resource Bar")
        primaryHeader:SetPoint("TOPLEFT", PAD, y)
        y = y - primaryHeader.gap

        local primaryDesc = GUI:CreateLabel(tabContent, "Customize individual resource colors in the Resource Colors section at the bottom. Applied when 'Use Resource Type Color' is enabled.", 11, C.textMuted)
        primaryDesc:SetPoint("TOPLEFT", PAD, y)
        primaryDesc:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        primaryDesc:SetJustifyH("LEFT")
        y = y - 20

        local primaryWarning = GUI:CreateLabel(tabContent, "Designed for horizontal layouts used by most players. Vertical mode requires extra setup (row offsets, orientation toggles).", 11, C.warning)
        primaryWarning:SetPoint("TOPLEFT", PAD, y)
        primaryWarning:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        primaryWarning:SetJustifyH("LEFT")
        y = y - 20

        -- Orientation dropdown
        local orientationOptions = {
            {value = "HORIZONTAL", text = "Horizontal"},
            {value = "VERTICAL", text = "Vertical"},
        }
        local orientationPrimary = GUI:CreateFormDropdown(tabContent, "Orientation", orientationOptions, "orientation", primary, RefreshPowerBars)
        orientationPrimary:SetPoint("TOPLEFT", PAD, y)
        orientationPrimary:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        -- Snap to Essential button (form style with label)
        local snapPrimaryContainer = CreateFrame("Frame", nil, tabContent)
        snapPrimaryContainer:SetHeight(FORM_ROW)
        snapPrimaryContainer:SetPoint("TOPLEFT", PAD, y)
        snapPrimaryContainer:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)

        local snapPrimaryLabel = snapPrimaryContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        snapPrimaryLabel:SetPoint("LEFT", 0, 0)
        snapPrimaryLabel:SetText("Quick Position")
        snapPrimaryLabel:SetTextColor(C.text[1], C.text[2], C.text[3], 1)

        local snapPrimaryBtn = CreateFrame("Button", nil, snapPrimaryContainer, "BackdropTemplate")
        snapPrimaryBtn:SetSize(115, 24)
        snapPrimaryBtn:SetPoint("LEFT", snapPrimaryContainer, "LEFT", 180, 0)
        snapPrimaryBtn:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        snapPrimaryBtn:SetBackdropColor(0.15, 0.15, 0.15, 1)
        snapPrimaryBtn:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], 1)

        local snapPrimaryText = snapPrimaryBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        snapPrimaryText:SetPoint("CENTER")
        snapPrimaryText:SetText("Snap to Essentials")
        snapPrimaryText:SetTextColor(C.text[1], C.text[2], C.text[3], 1)

        snapPrimaryBtn:SetScript("OnEnter", function(self)
            self:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 1)
        end)
        snapPrimaryBtn:SetScript("OnLeave", function(self)
            self:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], 1)
        end)
        snapPrimaryBtn:SetScript("OnClick", function()
            -- Force CDM refresh to ensure __cdmIconWidth is current
            if _G.LuheyUI_RefreshNCDM then
                _G.LuheyUI_RefreshNCDM()
            end

            local essentialViewer = _G.EssentialCooldownViewer

            if essentialViewer and essentialViewer:IsShown() then
                local rawCenterX, rawCenterY = essentialViewer:GetCenter()
                local rawScreenX, rawScreenY = UIParent:GetCenter()

                if rawCenterX and rawCenterY and rawScreenX and rawScreenY then
                    local essentialCenterX = math.floor(rawCenterX + 0.5)
                    local essentialCenterY = math.floor(rawCenterY + 0.5)
                    local screenCenterX = math.floor(rawScreenX + 0.5)
                    local screenCenterY = math.floor(rawScreenY + 0.5)
                    local barBorderSize = primary.borderSize or 1
                    local isVertical = primary.orientation == "VERTICAL"

                    if isVertical then
                        -- Vertical bar: goes to the RIGHT of Essential, length matches total height
                        local totalHeight = essentialViewer.__cdmTotalHeight or essentialViewer:GetHeight() or 100
                        local topBottomBorderSize = essentialViewer.__cdmRow1BorderSize or 0
                        local targetWidth = totalHeight + (2 * topBottomBorderSize) - (2 * barBorderSize)

                        local totalWidth = essentialViewer.__cdmIconWidth or essentialViewer:GetWidth()
                        local barThickness = primary.height or 8
                        local rightColBorderSize = essentialViewer.__cdmBottomRowBorderSize or 0

                        local cdmVisualRight = essentialCenterX + (totalWidth / 2) + rightColBorderSize
                        local powerBarCenterX = cdmVisualRight + (barThickness / 2) + barBorderSize

                        primary.offsetX = math.floor(powerBarCenterX - screenCenterX + 0.5) - 4
                        primary.offsetY = math.floor(essentialCenterY - screenCenterY + 0.5)
                        primary.width = math.floor(targetWidth + 0.5)
                    else
                        -- Horizontal bar: goes ABOVE Essential, width matches row width
                        local rowWidth = essentialViewer.__cdmRow1Width or essentialViewer.__cdmIconWidth or 300
                        local totalHeight = essentialViewer.__cdmTotalHeight or essentialViewer:GetHeight() or 100
                        local row1BorderSize = essentialViewer.__cdmRow1BorderSize or 2
                        local targetWidth = rowWidth + (2 * row1BorderSize) - (2 * barBorderSize)
                        local barHeight = primary.height or 8
                        local cdmVisualTop = essentialCenterY + (totalHeight / 2) + row1BorderSize
                        local powerBarCenterY = cdmVisualTop + (barHeight / 2) + barBorderSize

                        primary.offsetY = math.floor(powerBarCenterY - screenCenterY + 0.5) - 1
                        primary.offsetX = math.floor(essentialCenterX - screenCenterX + 0.5)
                        primary.width = math.floor(targetWidth + 0.5)
                    end

                    primary.autoAttach = false
                    primary.useRawPixels = true
                    RefreshPowerBars()

                    if widthPrimarySlider and widthPrimarySlider.SetValue then
                        widthPrimarySlider.SetValue(primary.width, true)
                    end
                    if yOffsetPrimarySlider and yOffsetPrimarySlider.SetValue then
                        yOffsetPrimarySlider.SetValue(primary.offsetY, true)
                    end
                else
                    print("|cFF56D1FFLuheyUI:|r Could not get screen positions. Try again.")
                end
            else
                print("|cFF56D1FFLuheyUI:|r Essential Cooldowns viewer not found or not visible.")
            end
        end)

        -- Snap to Utility button (side by side with Essential)
        local snapUtilityBtn = CreateFrame("Button", nil, snapPrimaryContainer, "BackdropTemplate")
        snapUtilityBtn:SetSize(115, 24)
        snapUtilityBtn:SetPoint("LEFT", snapPrimaryBtn, "RIGHT", 5, 0)
        snapUtilityBtn:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        snapUtilityBtn:SetBackdropColor(0.15, 0.15, 0.15, 1)
        snapUtilityBtn:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], 1)

        local snapUtilityText = snapUtilityBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        snapUtilityText:SetPoint("CENTER")
        snapUtilityText:SetText("Snap to Utility")
        snapUtilityText:SetTextColor(C.text[1], C.text[2], C.text[3], 1)

        snapUtilityBtn:SetScript("OnEnter", function(self)
            self:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 1)
        end)
        snapUtilityBtn:SetScript("OnLeave", function(self)
            self:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], 1)
        end)
        snapUtilityBtn:SetScript("OnClick", function()
            -- Force CDM refresh to ensure dimensions are current
            if _G.LuheyUI_RefreshNCDM then
                _G.LuheyUI_RefreshNCDM()
            end

            local utilityViewer = _G.UtilityCooldownViewer

            if utilityViewer and utilityViewer:IsShown() then
                local rawCenterX, rawCenterY = utilityViewer:GetCenter()
                local rawScreenX, rawScreenY = UIParent:GetCenter()

                if rawCenterX and rawCenterY and rawScreenX and rawScreenY then
                    local utilityCenterX = math.floor(rawCenterX + 0.5)
                    local utilityCenterY = math.floor(rawCenterY + 0.5)
                    local screenCenterX = math.floor(rawScreenX + 0.5)
                    local screenCenterY = math.floor(rawScreenY + 0.5)
                    local barBorderSize = primary.borderSize or 1
                    local isVertical = primary.orientation == "VERTICAL"

                    if isVertical then
                        -- Vertical bar: goes to the LEFT of Utility, length matches total height
                        local totalHeight = utilityViewer.__cdmTotalHeight or utilityViewer:GetHeight() or 100
                        local topBottomBorderSize = utilityViewer.__cdmRow1BorderSize or 0
                        local targetWidth = totalHeight + (2 * topBottomBorderSize) - (2 * barBorderSize)

                        local totalWidth = utilityViewer.__cdmIconWidth or utilityViewer:GetWidth()
                        local barThickness = primary.height or 8
                        local row1BorderSize = utilityViewer.__cdmRow1BorderSize or 0

                        local cdmVisualLeft = utilityCenterX - (totalWidth / 2) - row1BorderSize
                        local powerBarCenterX = cdmVisualLeft - (barThickness / 2) - barBorderSize

                        primary.offsetX = math.floor(powerBarCenterX - screenCenterX + 0.5) + 1
                        primary.offsetY = math.floor(utilityCenterY - screenCenterY + 0.5)
                        primary.width = math.floor(targetWidth + 0.5)
                    else
                        -- Horizontal bar: goes BELOW Utility, width matches row width
                        local rowWidth = utilityViewer.__cdmBottomRowWidth or utilityViewer.__cdmIconWidth or 300
                        local totalHeight = utilityViewer.__cdmTotalHeight or utilityViewer:GetHeight() or 100
                        local bottomRowBorderSize = utilityViewer.__cdmBottomRowBorderSize or 2
                        local targetWidth = rowWidth + (2 * bottomRowBorderSize) - (2 * barBorderSize)
                        local barHeight = primary.height or 8
                        local cdmVisualBottom = utilityCenterY - (totalHeight / 2) - bottomRowBorderSize
                        local powerBarCenterY = cdmVisualBottom - (barHeight / 2) - barBorderSize

                        primary.offsetY = math.floor(powerBarCenterY - screenCenterY + 0.5) + 1
                        primary.offsetX = math.floor(utilityCenterX - screenCenterX + 0.5)
                        primary.width = math.floor(targetWidth + 0.5)
                    end

                    primary.autoAttach = false
                    primary.useRawPixels = true
                    RefreshPowerBars()

                    if widthPrimarySlider and widthPrimarySlider.SetValue then
                        widthPrimarySlider.SetValue(primary.width, true)
                    end
                    if yOffsetPrimarySlider and yOffsetPrimarySlider.SetValue then
                        yOffsetPrimarySlider.SetValue(primary.offsetY, true)
                    end
                else
                    print("|cFF56D1FFLuheyUI:|r Could not get screen positions. Try again.")
                end
            else
                print("|cFF56D1FFLuheyUI:|r Utility Cooldowns viewer not found or not visible.")
            end
        end)
        y = y - FORM_ROW

        -- Lock buttons (auto-resize when CDM changes)
        local lockContainer = CreateFrame("Frame", nil, tabContent)
        lockContainer:SetHeight(FORM_ROW)
        lockContainer:SetPoint("TOPLEFT", PAD, y)
        lockContainer:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)

        local lockLabel = lockContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        lockLabel:SetPoint("LEFT", 0, 0)
        lockLabel:SetText("Auto-Resize")
        lockLabel:SetTextColor(C.text[1], C.text[2], C.text[3], 1)

        -- Lock to Essentials button
        local lockEssentialBtn = CreateFrame("Button", nil, lockContainer, "BackdropTemplate")
        lockEssentialBtn:SetSize(115, 24)
        lockEssentialBtn:SetPoint("LEFT", lockContainer, "LEFT", 180, 0)
        lockEssentialBtn:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        lockEssentialBtn:SetBackdropColor(0.15, 0.15, 0.15, 1)

        local lockEssentialText = lockEssentialBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        lockEssentialText:SetPoint("CENTER")
        lockEssentialText:SetTextColor(C.text[1], C.text[2], C.text[3], 1)

        -- Lock to Utility button
        local lockUtilityBtn = CreateFrame("Button", nil, lockContainer, "BackdropTemplate")
        lockUtilityBtn:SetSize(115, 24)
        lockUtilityBtn:SetPoint("LEFT", lockEssentialBtn, "RIGHT", 5, 0)
        lockUtilityBtn:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        lockUtilityBtn:SetBackdropColor(0.15, 0.15, 0.15, 1)

        local lockUtilityText = lockUtilityBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        lockUtilityText:SetPoint("CENTER")
        lockUtilityText:SetTextColor(C.text[1], C.text[2], C.text[3], 1)

        local function UpdateLockButtonStates()
            -- Essential button state
            if primary.lockedToEssential then
                lockEssentialText:SetText("Unlock Essential")
                lockEssentialBtn:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 1)
            else
                lockEssentialText:SetText("Lock to Essential")
                lockEssentialBtn:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], 1)
            end
            -- Utility button state
            if primary.lockedToUtility then
                lockUtilityText:SetText("Unlock Utility")
                lockUtilityBtn:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 1)
            else
                lockUtilityText:SetText("Lock to Utility")
                lockUtilityBtn:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], 1)
            end
            -- Disable Width slider when locked
            if widthPrimarySlider and widthPrimarySlider.SetEnabled then
                widthPrimarySlider:SetEnabled(not primary.lockedToEssential and not primary.lockedToUtility)
            end
        end
        UpdateLockButtonStates()

        -- Essential button hover
        lockEssentialBtn:SetScript("OnEnter", function(self)
            self:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 1)
        end)
        lockEssentialBtn:SetScript("OnLeave", function(self)
            if not primary.lockedToEssential then
                self:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], 1)
            end
        end)

        -- Utility button hover
        lockUtilityBtn:SetScript("OnEnter", function(self)
            self:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 1)
        end)
        lockUtilityBtn:SetScript("OnLeave", function(self)
            if not primary.lockedToUtility then
                self:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], 1)
            end
        end)

        -- Lock to Essentials click handler
        lockEssentialBtn:SetScript("OnClick", function()
            if primary.lockedToEssential then
                -- Unlock
                primary.lockedToEssential = false
                UpdateLockButtonStates()
            else
                -- Lock: do snap first, then enable lock
                if _G.LuheyUI_RefreshNCDM then
                    _G.LuheyUI_RefreshNCDM()
                end

                local essentialViewer = _G.EssentialCooldownViewer
                if essentialViewer and essentialViewer:IsShown() then
                    local rawCenterX, rawCenterY = essentialViewer:GetCenter()
                    local rawScreenX, rawScreenY = UIParent:GetCenter()

                    if rawCenterX and rawCenterY and rawScreenX and rawScreenY then
                        local essentialCenterX = math.floor(rawCenterX + 0.5)
                        local essentialCenterY = math.floor(rawCenterY + 0.5)
                        local screenCenterX = math.floor(rawScreenX + 0.5)
                        local screenCenterY = math.floor(rawScreenY + 0.5)

                        local barBorderSize = primary.borderSize or 1
                        local isVertical = primary.orientation == "VERTICAL"

                        if isVertical then
                            -- Vertical bar: goes to the RIGHT of Essential
                            local totalHeight = essentialViewer.__cdmTotalHeight or essentialViewer:GetHeight() or 100
                            local topBottomBorderSize = essentialViewer.__cdmRow1BorderSize or 0
                            local targetWidth = totalHeight + (2 * topBottomBorderSize) - (2 * barBorderSize)
                            local totalWidth = essentialViewer.__cdmIconWidth or essentialViewer:GetWidth()
                            local barThickness = primary.height or 8
                            local rightColBorderSize = essentialViewer.__cdmBottomRowBorderSize or 0
                            local cdmVisualRight = essentialCenterX + (totalWidth / 2) + rightColBorderSize
                            local powerBarCenterX = cdmVisualRight + (barThickness / 2) + barBorderSize
                            primary.offsetX = math.floor(powerBarCenterX - screenCenterX + 0.5) - 4
                            primary.offsetY = math.floor(essentialCenterY - screenCenterY + 0.5)
                            primary.width = math.floor(targetWidth + 0.5)
                        else
                            -- Horizontal bar: goes ABOVE Essential
                            local rowWidth = essentialViewer.__cdmRow1Width or essentialViewer.__cdmIconWidth or 300
                            local totalHeight = essentialViewer.__cdmTotalHeight or essentialViewer:GetHeight() or 100
                            local row1BorderSize = essentialViewer.__cdmRow1BorderSize or 2
                            local targetWidth = rowWidth + (2 * row1BorderSize) - (2 * barBorderSize)
                            local barHeight = primary.height or 8
                            local cdmVisualTop = essentialCenterY + (totalHeight / 2) + row1BorderSize
                            local powerBarCenterY = cdmVisualTop + (barHeight / 2) + barBorderSize
                            primary.offsetY = math.floor(powerBarCenterY - screenCenterY + 0.5) - 1
                            primary.offsetX = math.floor(essentialCenterX - screenCenterX + 0.5)
                            primary.width = math.floor(targetWidth + 0.5)
                        end
                        primary.autoAttach = false
                        primary.useRawPixels = true
                        primary.lockedToEssential = true
                        primary.lockedToUtility = false  -- Mutually exclusive

                        RefreshPowerBars()
                        UpdateLockButtonStates()

                        if widthPrimarySlider and widthPrimarySlider.SetValue then
                            widthPrimarySlider.SetValue(primary.width, true)
                        end
                        if yOffsetPrimarySlider and yOffsetPrimarySlider.SetValue then
                            yOffsetPrimarySlider.SetValue(primary.offsetY, true)
                        end
                    else
                        print("|cFF56D1FFLuheyUI:|r Could not get screen positions. Try again.")
                    end
                else
                    print("|cFF56D1FFLuheyUI:|r Essential Cooldowns viewer not found or not visible.")
                end
            end
        end)

        -- Lock to Utility click handler
        lockUtilityBtn:SetScript("OnClick", function()
            if primary.lockedToUtility then
                -- Unlock
                primary.lockedToUtility = false
                UpdateLockButtonStates()
            else
                -- Lock: do snap first, then enable lock
                if _G.LuheyUI_RefreshNCDM then
                    _G.LuheyUI_RefreshNCDM()
                end

                local utilityViewer = _G.UtilityCooldownViewer
                if utilityViewer and utilityViewer:IsShown() then
                    local rawCenterX, rawCenterY = utilityViewer:GetCenter()
                    local rawScreenX, rawScreenY = UIParent:GetCenter()

                    if rawCenterX and rawCenterY and rawScreenX and rawScreenY then
                        local utilityCenterX = math.floor(rawCenterX + 0.5)
                        local utilityCenterY = math.floor(rawCenterY + 0.5)
                        local screenCenterX = math.floor(rawScreenX + 0.5)
                        local screenCenterY = math.floor(rawScreenY + 0.5)

                        local barBorderSize = primary.borderSize or 1
                        local isVertical = primary.orientation == "VERTICAL"

                        if isVertical then
                            -- Vertical bar: goes to the LEFT of Utility
                            local totalHeight = utilityViewer.__cdmTotalHeight or utilityViewer:GetHeight() or 100
                            local topBottomBorderSize = utilityViewer.__cdmRow1BorderSize or 0
                            local targetWidth = totalHeight + (2 * topBottomBorderSize) - (2 * barBorderSize)
                            local totalWidth = utilityViewer.__cdmIconWidth or utilityViewer:GetWidth()
                            local barThickness = primary.height or 8
                            local row1BorderSize = utilityViewer.__cdmRow1BorderSize or 0
                            local cdmVisualLeft = utilityCenterX - (totalWidth / 2) - row1BorderSize
                            local powerBarCenterX = cdmVisualLeft - (barThickness / 2) - barBorderSize
                            primary.offsetX = math.floor(powerBarCenterX - screenCenterX + 0.5) + 1
                            primary.offsetY = math.floor(utilityCenterY - screenCenterY + 0.5)
                            primary.width = math.floor(targetWidth + 0.5)
                        else
                            -- Horizontal bar: goes BELOW Utility
                            local rowWidth = utilityViewer.__cdmBottomRowWidth or utilityViewer.__cdmIconWidth or 300
                            local totalHeight = utilityViewer.__cdmTotalHeight or utilityViewer:GetHeight() or 100
                            local bottomRowBorderSize = utilityViewer.__cdmBottomRowBorderSize or 2
                            local targetWidth = rowWidth + (2 * bottomRowBorderSize) - (2 * barBorderSize)
                            local barHeight = primary.height or 8
                            local cdmVisualBottom = utilityCenterY - (totalHeight / 2) - bottomRowBorderSize
                            local powerBarCenterY = cdmVisualBottom - (barHeight / 2) - barBorderSize
                            primary.offsetY = math.floor(powerBarCenterY - screenCenterY + 0.5) + 1
                            primary.offsetX = math.floor(utilityCenterX - screenCenterX + 0.5)
                            primary.width = math.floor(targetWidth + 0.5)
                        end
                        primary.autoAttach = false
                        primary.useRawPixels = true
                        primary.lockedToUtility = true
                        primary.lockedToEssential = false  -- Mutually exclusive

                        RefreshPowerBars()
                        UpdateLockButtonStates()

                        if widthPrimarySlider and widthPrimarySlider.SetValue then
                            widthPrimarySlider.SetValue(primary.width, true)
                        end
                        if yOffsetPrimarySlider and yOffsetPrimarySlider.SetValue then
                            yOffsetPrimarySlider.SetValue(primary.offsetY, true)
                        end
                    else
                        print("|cFF56D1FFLuheyUI:|r Could not get screen positions. Try again.")
                    end
                else
                    print("|cFF56D1FFLuheyUI:|r Utility Cooldowns viewer not found or not visible.")
                end
            end
        end)
        y = y - FORM_ROW

        -- Color options (form style) - radio-button behavior: clicking one turns off the others
        local customColorPickerPrimary

        local powerColorPrimary = GUI:CreateFormCheckbox(tabContent, "Use Resource Type Color", "usePowerColor", primary, function()
            if primary.usePowerColor then
                primary.useClassColor = false
                primary.useCustomColor = false
                primary.colorMode = "power"
            else
                -- Fallback: if turning off and nothing else is on, re-enable this
                if not primary.useClassColor and not primary.useCustomColor then
                    primary.usePowerColor = true
                end
            end
            if customColorPickerPrimary then
                customColorPickerPrimary:SetEnabled(primary.useCustomColor)
            end
            RefreshPowerBars()
        end)
        powerColorPrimary:SetPoint("TOPLEFT", PAD, y)
        powerColorPrimary:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local resourceColorDescPrimary = GUI:CreateLabel(tabContent, "Uses per-resource colors from the Resource Colors section below.", 11)
        resourceColorDescPrimary:SetPoint("TOPLEFT", PAD, y + 4)
        resourceColorDescPrimary:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        resourceColorDescPrimary:SetJustifyH("LEFT")
        resourceColorDescPrimary:SetTextColor(0.6, 0.6, 0.6)
        y = y - FORM_ROW

        local classColorPrimary = GUI:CreateFormCheckbox(tabContent, "Use Class Color", "useClassColor", primary, function()
            if primary.useClassColor then
                primary.usePowerColor = false
                primary.useCustomColor = false
                primary.colorMode = "class"
            else
                -- Fallback: if turning off and nothing else is on, enable Resource Type Color
                if not primary.usePowerColor and not primary.useCustomColor then
                    primary.usePowerColor = true
                end
            end
            if customColorPickerPrimary then
                customColorPickerPrimary:SetEnabled(primary.useCustomColor)
            end
            RefreshPowerBars()
        end)
        classColorPrimary:SetPoint("TOPLEFT", PAD, y)
        classColorPrimary:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local bgColorPrimary = GUI:CreateFormColorPicker(tabContent, "Background Color", "bgColor", primary, RefreshPowerBars)
        bgColorPrimary:SetPoint("TOPLEFT", PAD, y)
        bgColorPrimary:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local customColorOverridePrimary = GUI:CreateFormCheckbox(tabContent, "Custom Color Override", "useCustomColor", primary, function()
            if primary.useCustomColor then
                primary.usePowerColor = false
                primary.useClassColor = false
                primary.colorMode = "custom"
            else
                -- Fallback: if turning off and nothing else is on, enable Resource Type Color
                if not primary.usePowerColor and not primary.useClassColor then
                    primary.usePowerColor = true
                end
            end
            if customColorPickerPrimary then
                customColorPickerPrimary:SetEnabled(primary.useCustomColor)
            end
            RefreshPowerBars()
        end)
        customColorOverridePrimary:SetPoint("TOPLEFT", PAD, y)
        customColorOverridePrimary:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        customColorPickerPrimary = GUI:CreateFormColorPicker(tabContent, "Custom Color", "customColor", primary, RefreshPowerBars)
        customColorPickerPrimary:SetPoint("TOPLEFT", PAD, y)
        customColorPickerPrimary:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        customColorPickerPrimary:SetEnabled(primary.useCustomColor)
        y = y - FORM_ROW

        -- Text display options
        local showTextPrimary = GUI:CreateFormCheckbox(tabContent, "Show Number", "showText", primary, RefreshPowerBars)
        showTextPrimary:SetPoint("TOPLEFT", PAD, y)
        showTextPrimary:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local showPercentPrimary = GUI:CreateFormCheckbox(tabContent, "Show as Percent", "showPercent", primary, RefreshPowerBars)
        showPercentPrimary:SetPoint("TOPLEFT", PAD, y)
        showPercentPrimary:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        -- Tick marks
        local showTicksPrimary = GUI:CreateFormCheckbox(tabContent, "Show Tick Marks", "showTicks", primary, RefreshPowerBars)
        showTicksPrimary:SetPoint("TOPLEFT", PAD, y)
        showTicksPrimary:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local tickThicknessPrimary = GUI:CreateFormSlider(tabContent, "Tick Thickness", 1, 4, 1, "tickThickness", primary, RefreshPowerBars)
        tickThicknessPrimary:SetPoint("TOPLEFT", PAD, y)
        tickThicknessPrimary:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local tickColorPrimary = GUI:CreateFormColorPicker(tabContent, "Tick Color", "tickColor", primary, RefreshPowerBars)
        tickColorPrimary:SetPoint("TOPLEFT", PAD, y)
        tickColorPrimary:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        -- Size sliders (form style)
        widthPrimarySlider = GUI:CreateFormSlider(tabContent, "Width", 0, 2000, 1, "width", primary, RefreshPowerBars)
        widthPrimarySlider:SetPoint("TOPLEFT", PAD, y)
        widthPrimarySlider:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        widthPrimarySlider:SetEnabled(not primary.lockedToEssential and not primary.lockedToUtility)  -- Disabled when locked
        y = y - FORM_ROW

        local heightPrimary = GUI:CreateFormSlider(tabContent, "Height", 1, 100, 1, "height", primary, RefreshPowerBars)
        heightPrimary:SetPoint("TOPLEFT", PAD, y)
        heightPrimary:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local borderPrimary = GUI:CreateFormSlider(tabContent, "Border Size", 0, 8, 1, "borderSize", primary, RefreshPowerBars)
        borderPrimary:SetPoint("TOPLEFT", PAD, y)
        borderPrimary:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        -- Position sliders
        local xOffsetPrimarySlider = GUI:CreateFormSlider(tabContent, "X Offset", -1000, 1000, 1, "offsetX", primary, RefreshPowerBars)
        xOffsetPrimarySlider:SetPoint("TOPLEFT", PAD, y)
        xOffsetPrimarySlider:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        yOffsetPrimarySlider = GUI:CreateFormSlider(tabContent, "Y Offset", -1000, 1000, 1, "offsetY", primary, RefreshPowerBars)
        yOffsetPrimarySlider:SetPoint("TOPLEFT", PAD, y)
        yOffsetPrimarySlider:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        -- Register sliders for real-time sync during Edit Mode
        if _G.LuheyUI and _G.LuheyUI.LUICore and _G.LuheyUI.LUICore.RegisterPowerBarEditModeSliders then
            _G.LuheyUI.LUICore:RegisterPowerBarEditModeSliders("primary", xOffsetPrimarySlider, yOffsetPrimarySlider)
        end

        -- Text sliders
        local textSizePrimary = GUI:CreateFormSlider(tabContent, "Text Size", 8, 50, 1, "textSize", primary, RefreshPowerBars)
        textSizePrimary:SetPoint("TOPLEFT", PAD, y)
        textSizePrimary:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local textXPrimary = GUI:CreateFormSlider(tabContent, "Text X Offset", -500, 500, 1, "textX", primary, RefreshPowerBars)
        textXPrimary:SetPoint("TOPLEFT", PAD, y)
        textXPrimary:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local textYPrimary = GUI:CreateFormSlider(tabContent, "Text Y Offset", -500, 500, 1, "textY", primary, RefreshPowerBars)
        textYPrimary:SetPoint("TOPLEFT", PAD, y)
        textYPrimary:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        -- Text color settings
        local textCustomColorPrimary  -- Forward declare for mutual reference

        local textUseClassColorPrimary = GUI:CreateFormCheckbox(tabContent, "Use Class Color for Text", "textUseClassColor", primary, function()
            if textCustomColorPrimary then
                textCustomColorPrimary:SetEnabled(not primary.textUseClassColor)
            end
            RefreshPowerBars()
        end)
        textUseClassColorPrimary:SetPoint("TOPLEFT", PAD, y)
        textUseClassColorPrimary:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        textCustomColorPrimary = GUI:CreateFormColorPicker(tabContent, "Custom Text Color", "textCustomColor", primary, RefreshPowerBars)
        textCustomColorPrimary:SetPoint("TOPLEFT", PAD, y)
        textCustomColorPrimary:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        textCustomColorPrimary:SetEnabled(not primary.textUseClassColor)  -- Initial state
        y = y - FORM_ROW

        local texturePrimary = GUI:CreateFormDropdown(tabContent, "Bar Texture", GetTextureList(), "texture", primary, RefreshPowerBars)
        texturePrimary:SetPoint("TOPLEFT", PAD, y)
        texturePrimary:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        -- Spacer between sections
        y = y - 15
        
        -- =====================================================
        -- SECONDARY POWER BAR SECTION
        -- =====================================================
        local secondaryHeader = GUI:CreateSectionHeader(tabContent, "Secondary Class Resource Bar")
        secondaryHeader:SetPoint("TOPLEFT", PAD, y)
        y = y - secondaryHeader.gap

        local secondaryDesc = GUI:CreateLabel(tabContent, "Customize individual resource colors in the Resource Colors section at the bottom. Applied when 'Use Resource Type Color' is enabled.", 11, C.textMuted)
        secondaryDesc:SetPoint("TOPLEFT", PAD, y)
        secondaryDesc:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        secondaryDesc:SetJustifyH("LEFT")
        y = y - 20

        local secondaryWarning = GUI:CreateLabel(tabContent, "Designed for horizontal layouts used by most players. Vertical mode requires extra setup (row offsets, orientation toggles).", 11, C.warning)
        secondaryWarning:SetPoint("TOPLEFT", PAD, y)
        secondaryWarning:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        secondaryWarning:SetJustifyH("LEFT")
        y = y - 20

        -- Orientation dropdown
        local orientationOptionsSecondary = {
            {value = "HORIZONTAL", text = "Horizontal"},
            {value = "VERTICAL", text = "Vertical"},
        }
        local orientationSecondary = GUI:CreateFormDropdown(tabContent, "Orientation", orientationOptionsSecondary, "orientation", secondary, RefreshPowerBars)
        orientationSecondary:SetPoint("TOPLEFT", PAD, y)
        orientationSecondary:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        -- Quick Position row with 3 buttons: Snap to Essentials, Snap to Utility, Snap to Primary
        local snapSecondaryContainer = CreateFrame("Frame", nil, tabContent)
        snapSecondaryContainer:SetHeight(FORM_ROW)
        snapSecondaryContainer:SetPoint("TOPLEFT", PAD, y)
        snapSecondaryContainer:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)

        local snapSecondaryLabel = snapSecondaryContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        snapSecondaryLabel:SetPoint("LEFT", 0, 0)
        snapSecondaryLabel:SetText("Quick Position")
        snapSecondaryLabel:SetTextColor(C.text[1], C.text[2], C.text[3], 1)

        -- Snap to Essentials button
        local snapSecEssentialBtn = CreateFrame("Button", nil, snapSecondaryContainer, "BackdropTemplate")
        snapSecEssentialBtn:SetSize(100, 24)
        snapSecEssentialBtn:SetPoint("LEFT", snapSecondaryContainer, "LEFT", 180, 0)
        snapSecEssentialBtn:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        snapSecEssentialBtn:SetBackdropColor(0.15, 0.15, 0.15, 1)
        snapSecEssentialBtn:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], 1)

        local snapSecEssentialText = snapSecEssentialBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        snapSecEssentialText:SetPoint("CENTER")
        snapSecEssentialText:SetText("Essentials")
        snapSecEssentialText:SetTextColor(C.text[1], C.text[2], C.text[3], 1)

        snapSecEssentialBtn:SetScript("OnEnter", function(self)
            self:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 1)
        end)
        snapSecEssentialBtn:SetScript("OnLeave", function(self)
            self:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], 1)
        end)
        snapSecEssentialBtn:SetScript("OnClick", function()
            if _G.LuheyUI_RefreshNCDM then _G.LuheyUI_RefreshNCDM() end
            local essentialViewer = _G.EssentialCooldownViewer
            if essentialViewer and essentialViewer:IsShown() then
                local rawCenterX, rawCenterY = essentialViewer:GetCenter()
                local rawScreenX, rawScreenY = UIParent:GetCenter()
                if rawCenterX and rawCenterY and rawScreenX and rawScreenY then
                    local essentialCenterX = math.floor(rawCenterX + 0.5)
                    local essentialCenterY = math.floor(rawCenterY + 0.5)
                    local screenCenterX = math.floor(rawScreenX + 0.5)
                    local screenCenterY = math.floor(rawScreenY + 0.5)
                    local barBorderSize = secondary.borderSize or 1
                    local isVertical = secondary.orientation == "VERTICAL"

                    if isVertical then
                        -- Vertical bar: goes to the RIGHT of Essential
                        local totalHeight = essentialViewer.__cdmTotalHeight or essentialViewer:GetHeight() or 100
                        local topBottomBorderSize = essentialViewer.__cdmRow1BorderSize or 0
                        local targetWidth = totalHeight + (2 * topBottomBorderSize) - (2 * barBorderSize)
                        local totalWidth = essentialViewer.__cdmIconWidth or essentialViewer:GetWidth()
                        local barThickness = secondary.height or 8
                        local rightColBorderSize = essentialViewer.__cdmBottomRowBorderSize or 0
                        local cdmVisualRight = essentialCenterX + (totalWidth / 2) + rightColBorderSize
                        local powerBarCenterX = cdmVisualRight + (barThickness / 2) + barBorderSize
                        secondary.lockedBaseX = math.floor(powerBarCenterX - screenCenterX + 0.5) - 4
                        secondary.lockedBaseY = math.floor(essentialCenterY - screenCenterY + 0.5)
                        secondary.width = math.floor(targetWidth + 0.5)
                    else
                        -- Horizontal bar: goes ABOVE Essential
                        local rowWidth = essentialViewer.__cdmRow1Width or essentialViewer.__cdmIconWidth or 300
                        local totalHeight = essentialViewer.__cdmTotalHeight or essentialViewer:GetHeight() or 100
                        local row1BorderSize = essentialViewer.__cdmRow1BorderSize or 2
                        local targetWidth = rowWidth + (2 * row1BorderSize) - (2 * barBorderSize)
                        local barHeight = secondary.height or 8
                        local cdmVisualTop = essentialCenterY + (totalHeight / 2) + row1BorderSize
                        local powerBarCenterY = cdmVisualTop + (barHeight / 2) + barBorderSize
                        secondary.lockedBaseY = math.floor(powerBarCenterY - screenCenterY + 0.5) - 1
                        secondary.lockedBaseX = math.floor(essentialCenterX - screenCenterX + 0.5)
                        secondary.width = math.floor(targetWidth + 0.5)
                    end

                    secondary.offsetX = 0  -- Reset user adjustment
                    secondary.offsetY = 0
                    secondary.autoAttach = false
                    secondary.useRawPixels = true
                    RefreshPowerBars()
                    if widthSecondarySlider and widthSecondarySlider.SetValue then widthSecondarySlider.SetValue(secondary.width, true) end
                    if yOffsetSecondarySlider and yOffsetSecondarySlider.SetValue then yOffsetSecondarySlider.SetValue(secondary.offsetY, true) end
                else
                    print("|cFF56D1FFLuheyUI:|r Could not get screen positions. Try again.")
                end
            else
                print("|cFF56D1FFLuheyUI:|r Essential Cooldowns viewer not found or not visible.")
            end
        end)

        -- Snap to Utility button
        local snapSecUtilityBtn = CreateFrame("Button", nil, snapSecondaryContainer, "BackdropTemplate")
        snapSecUtilityBtn:SetSize(100, 24)
        snapSecUtilityBtn:SetPoint("LEFT", snapSecEssentialBtn, "RIGHT", 5, 0)
        snapSecUtilityBtn:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        snapSecUtilityBtn:SetBackdropColor(0.15, 0.15, 0.15, 1)
        snapSecUtilityBtn:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], 1)

        local snapSecUtilityText = snapSecUtilityBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        snapSecUtilityText:SetPoint("CENTER")
        snapSecUtilityText:SetText("Utility")
        snapSecUtilityText:SetTextColor(C.text[1], C.text[2], C.text[3], 1)

        snapSecUtilityBtn:SetScript("OnEnter", function(self)
            self:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 1)
        end)
        snapSecUtilityBtn:SetScript("OnLeave", function(self)
            self:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], 1)
        end)
        snapSecUtilityBtn:SetScript("OnClick", function()
            if _G.LuheyUI_RefreshNCDM then _G.LuheyUI_RefreshNCDM() end
            local utilityViewer = _G.UtilityCooldownViewer
            if utilityViewer and utilityViewer:IsShown() then
                local rawCenterX, rawCenterY = utilityViewer:GetCenter()
                local rawScreenX, rawScreenY = UIParent:GetCenter()
                if rawCenterX and rawCenterY and rawScreenX and rawScreenY then
                    local utilityCenterX = math.floor(rawCenterX + 0.5)
                    local utilityCenterY = math.floor(rawCenterY + 0.5)
                    local screenCenterX = math.floor(rawScreenX + 0.5)
                    local screenCenterY = math.floor(rawScreenY + 0.5)
                    local barBorderSize = secondary.borderSize or 1
                    local isVertical = secondary.orientation == "VERTICAL"

                    if isVertical then
                        -- Vertical bar: goes to the LEFT of Utility
                        local totalHeight = utilityViewer.__cdmTotalHeight or utilityViewer:GetHeight() or 100
                        local topBottomBorderSize = utilityViewer.__cdmRow1BorderSize or 0
                        local targetWidth = totalHeight + (2 * topBottomBorderSize) - (2 * barBorderSize)
                        local totalWidth = utilityViewer.__cdmIconWidth or utilityViewer:GetWidth()
                        local barThickness = secondary.height or 8
                        local cdmVisualLeft = utilityCenterX - (totalWidth / 2)
                        local powerBarCenterX = cdmVisualLeft - (barThickness / 2)
                        secondary.lockedBaseX = math.floor(powerBarCenterX - screenCenterX + 0.5)
                        secondary.lockedBaseY = math.floor(utilityCenterY - screenCenterY + 0.5)
                        secondary.width = math.floor(targetWidth + 0.5)
                    else
                        -- Horizontal bar: goes BELOW Utility
                        local rowWidth = utilityViewer.__cdmBottomRowWidth or utilityViewer.__cdmIconWidth or 300
                        local totalHeight = utilityViewer.__cdmTotalHeight or utilityViewer:GetHeight() or 100
                        local bottomRowBorderSize = utilityViewer.__cdmBottomRowBorderSize or 2
                        local targetWidth = rowWidth + (2 * bottomRowBorderSize) - (2 * barBorderSize)
                        local barHeight = secondary.height or 8
                        local cdmVisualBottom = utilityCenterY - (totalHeight / 2) - bottomRowBorderSize
                        local powerBarCenterY = cdmVisualBottom - (barHeight / 2) - barBorderSize
                        secondary.lockedBaseY = math.floor(powerBarCenterY - screenCenterY + 0.5) + 1
                        secondary.lockedBaseX = math.floor(utilityCenterX - screenCenterX + 0.5)
                        secondary.width = math.floor(targetWidth + 0.5)
                    end

                    secondary.offsetX = 0  -- Reset user adjustment
                    secondary.offsetY = 0
                    secondary.autoAttach = false
                    secondary.useRawPixels = true
                    RefreshPowerBars()
                    if widthSecondarySlider and widthSecondarySlider.SetValue then widthSecondarySlider.SetValue(secondary.width, true) end
                    if yOffsetSecondarySlider and yOffsetSecondarySlider.SetValue then yOffsetSecondarySlider.SetValue(secondary.offsetY, true) end
                else
                    print("|cFF56D1FFLuheyUI:|r Could not get screen positions. Try again.")
                end
            else
                print("|cFF56D1FFLuheyUI:|r Utility Cooldowns viewer not found or not visible.")
            end
        end)

        -- Snap to Primary button
        local snapSecPrimaryBtn = CreateFrame("Button", nil, snapSecondaryContainer, "BackdropTemplate")
        snapSecPrimaryBtn:SetSize(100, 24)
        snapSecPrimaryBtn:SetPoint("LEFT", snapSecUtilityBtn, "RIGHT", 5, 0)
        snapSecPrimaryBtn:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        snapSecPrimaryBtn:SetBackdropColor(0.15, 0.15, 0.15, 1)
        snapSecPrimaryBtn:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], 1)

        local snapSecPrimaryText = snapSecPrimaryBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        snapSecPrimaryText:SetPoint("CENTER")
        snapSecPrimaryText:SetText("Primary")
        snapSecPrimaryText:SetTextColor(C.text[1], C.text[2], C.text[3], 1)

        snapSecPrimaryBtn:SetScript("OnEnter", function(self)
            self:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 1)
        end)
        snapSecPrimaryBtn:SetScript("OnLeave", function(self)
            self:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], 1)
        end)
        snapSecPrimaryBtn:SetScript("OnClick", function()
            local LUICore = _G.LuheyUI and _G.LuheyUI.LUICore
            local primaryBar = LUICore and LUICore.powerBar
            local primaryCfg = LUICore and LUICore.db and LUICore.db.profile.powerBar
            if primaryBar and primaryBar:IsShown() and primaryCfg then
                local primaryCenterX, primaryCenterY = primaryBar:GetCenter()
                local screenCenterX, screenCenterY = UIParent:GetCenter()
                if primaryCenterX and primaryCenterY and screenCenterX and screenCenterY then
                    primaryCenterX = math.floor(primaryCenterX + 0.5)
                    primaryCenterY = math.floor(primaryCenterY + 0.5)
                    screenCenterX = math.floor(screenCenterX + 0.5)
                    screenCenterY = math.floor(screenCenterY + 0.5)
                    local primaryHeight = primaryCfg.height or 8
                    local primaryWidth = primaryCfg.width or primaryBar:GetWidth() or 300
                    local primaryBorderSize = primaryCfg.borderSize or 1
                    local secondaryHeight = secondary.height or 8
                    local secondaryBorderSize = secondary.borderSize or 1
                    local isVertical = secondary.orientation == "VERTICAL"

                    if isVertical then
                        -- Vertical secondary: goes to the RIGHT of Primary
                        local primaryActualWidth = primaryBar:GetWidth()
                        local primaryVisualRight = primaryCenterX + (primaryActualWidth / 2)
                        local secondaryBarCenterX = primaryVisualRight + (secondaryHeight / 2)
                        local targetWidth = primaryWidth + (2 * primaryBorderSize) - (2 * secondaryBorderSize)
                        secondary.lockedBaseX = math.floor(secondaryBarCenterX - screenCenterX + 0.5)
                        secondary.lockedBaseY = math.floor(primaryCenterY - screenCenterY + 0.5)
                        secondary.width = math.floor(targetWidth + 0.5)
                    else
                        -- Horizontal bar: Secondary goes ABOVE Primary
                        local primaryVisualTop = primaryCenterY + (primaryHeight / 2) + primaryBorderSize
                        local secondaryBarCenterY = primaryVisualTop + (secondaryHeight / 2) + secondaryBorderSize
                        local targetWidth = primaryWidth + (2 * primaryBorderSize) - (2 * secondaryBorderSize)
                        secondary.lockedBaseY = math.floor(secondaryBarCenterY - screenCenterY + 0.5) - 1
                        secondary.lockedBaseX = math.floor(primaryCenterX - screenCenterX + 0.5)
                        secondary.width = math.floor(targetWidth + 0.5)
                    end

                    secondary.offsetX = 0  -- Reset user adjustment
                    secondary.offsetY = 0
                    secondary.autoAttach = false
                    secondary.useRawPixels = true
                    RefreshPowerBars()
                    if widthSecondarySlider and widthSecondarySlider.SetValue then widthSecondarySlider.SetValue(secondary.width, true) end
                    if yOffsetSecondarySlider and yOffsetSecondarySlider.SetValue then yOffsetSecondarySlider.SetValue(secondary.offsetY, true) end
                else
                    print("|cFF56D1FFLuheyUI:|r Could not get screen positions. Try again.")
                end
            else
                print("|cFF56D1FFLuheyUI:|r Primary Class Resource Bar not found or not visible. Enable it first.")
            end
        end)
        y = y - FORM_ROW

        -- Auto-Resize row with 3 buttons: Lock to Essential, Lock to Utility, Lock to Primary
        local lockSecContainer = CreateFrame("Frame", nil, tabContent)
        lockSecContainer:SetHeight(FORM_ROW)
        lockSecContainer:SetPoint("TOPLEFT", PAD, y)
        lockSecContainer:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)

        local lockSecLabel = lockSecContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        lockSecLabel:SetPoint("LEFT", 0, 0)
        lockSecLabel:SetText("Auto-Resize")
        lockSecLabel:SetTextColor(C.text[1], C.text[2], C.text[3], 1)

        -- Lock to Essential button
        local lockSecEssentialBtn = CreateFrame("Button", nil, lockSecContainer, "BackdropTemplate")
        lockSecEssentialBtn:SetSize(100, 24)
        lockSecEssentialBtn:SetPoint("LEFT", lockSecContainer, "LEFT", 180, 0)
        lockSecEssentialBtn:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        lockSecEssentialBtn:SetBackdropColor(0.15, 0.15, 0.15, 1)
        lockSecEssentialBtn:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], 1)

        local lockSecEssentialText = lockSecEssentialBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        lockSecEssentialText:SetPoint("CENTER")
        lockSecEssentialText:SetTextColor(C.text[1], C.text[2], C.text[3], 1)

        -- Lock to Utility button
        local lockSecUtilityBtn = CreateFrame("Button", nil, lockSecContainer, "BackdropTemplate")
        lockSecUtilityBtn:SetSize(100, 24)
        lockSecUtilityBtn:SetPoint("LEFT", lockSecEssentialBtn, "RIGHT", 5, 0)
        lockSecUtilityBtn:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        lockSecUtilityBtn:SetBackdropColor(0.15, 0.15, 0.15, 1)
        lockSecUtilityBtn:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], 1)

        local lockSecUtilityText = lockSecUtilityBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        lockSecUtilityText:SetPoint("CENTER")
        lockSecUtilityText:SetTextColor(C.text[1], C.text[2], C.text[3], 1)

        -- Lock to Primary button
        local lockSecPrimaryBtn = CreateFrame("Button", nil, lockSecContainer, "BackdropTemplate")
        lockSecPrimaryBtn:SetSize(100, 24)
        lockSecPrimaryBtn:SetPoint("LEFT", lockSecUtilityBtn, "RIGHT", 5, 0)
        lockSecPrimaryBtn:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        lockSecPrimaryBtn:SetBackdropColor(0.15, 0.15, 0.15, 1)
        lockSecPrimaryBtn:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], 1)

        local lockSecPrimaryText = lockSecPrimaryBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        lockSecPrimaryText:SetPoint("CENTER")
        lockSecPrimaryText:SetTextColor(C.text[1], C.text[2], C.text[3], 1)

        -- Function to update lock button states (visual + width slider)
        local function UpdateSecLockButtonStates()
            -- Essential button state
            if secondary.lockedToEssential then
                lockSecEssentialText:SetText("Unlock")
                lockSecEssentialBtn:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 1)
            else
                lockSecEssentialText:SetText("Essential")
                lockSecEssentialBtn:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], 1)
            end
            -- Utility button state
            if secondary.lockedToUtility then
                lockSecUtilityText:SetText("Unlock")
                lockSecUtilityBtn:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 1)
            else
                lockSecUtilityText:SetText("Utility")
                lockSecUtilityBtn:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], 1)
            end
            -- Primary button state
            if secondary.lockedToPrimary then
                lockSecPrimaryText:SetText("Unlock")
                lockSecPrimaryBtn:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 1)
            else
                lockSecPrimaryText:SetText("Primary")
                lockSecPrimaryBtn:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], 1)
            end
            -- Disable Width slider when any lock is active
            if widthSecondarySlider and widthSecondarySlider.SetEnabled then
                widthSecondarySlider:SetEnabled(not secondary.lockedToEssential and not secondary.lockedToUtility and not secondary.lockedToPrimary)
            end
        end

        -- Hover effects (preserve lock state color on leave)
        lockSecEssentialBtn:SetScript("OnEnter", function(self)
            self:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 1)
        end)
        lockSecEssentialBtn:SetScript("OnLeave", function(self)
            if not secondary.lockedToEssential then
                self:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], 1)
            end
        end)
        lockSecUtilityBtn:SetScript("OnEnter", function(self)
            self:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 1)
        end)
        lockSecUtilityBtn:SetScript("OnLeave", function(self)
            if not secondary.lockedToUtility then
                self:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], 1)
            end
        end)
        lockSecPrimaryBtn:SetScript("OnEnter", function(self)
            self:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 1)
        end)
        lockSecPrimaryBtn:SetScript("OnLeave", function(self)
            if not secondary.lockedToPrimary then
                self:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], 1)
            end
        end)

        -- Lock to Essential click handler
        lockSecEssentialBtn:SetScript("OnClick", function()
            if secondary.lockedToEssential then
                secondary.lockedToEssential = false
                UpdateSecLockButtonStates()
            else
                if _G.LuheyUI_RefreshNCDM then _G.LuheyUI_RefreshNCDM() end
                local essentialViewer = _G.EssentialCooldownViewer
                if essentialViewer and essentialViewer:IsShown() then
                    local rawCenterX, rawCenterY = essentialViewer:GetCenter()
                    local rawScreenX, rawScreenY = UIParent:GetCenter()
                    if rawCenterX and rawCenterY and rawScreenX and rawScreenY then
                        local essentialCenterX = math.floor(rawCenterX + 0.5)
                        local essentialCenterY = math.floor(rawCenterY + 0.5)
                        local screenCenterX = math.floor(rawScreenX + 0.5)
                        local screenCenterY = math.floor(rawScreenY + 0.5)
                        local totalHeight = essentialViewer.__cdmTotalHeight or essentialViewer:GetHeight() or 100
                        local row1BorderSize = essentialViewer.__cdmRow1BorderSize or 2
                        local barBorderSize = secondary.borderSize or 1
                        local isVertical = secondary.orientation == "VERTICAL"

                        if isVertical then
                            -- Vertical bar: goes to the RIGHT of Essential
                            local topBottomBorderSize = essentialViewer.__cdmRow1BorderSize or 0
                            local targetWidth = totalHeight + (2 * topBottomBorderSize) - (2 * barBorderSize)
                            local totalWidth = essentialViewer.__cdmIconWidth or essentialViewer:GetWidth()
                            local barThickness = secondary.height or 8
                            local rightColBorderSize = essentialViewer.__cdmBottomRowBorderSize or 0
                            local cdmVisualRight = essentialCenterX + (totalWidth / 2) + rightColBorderSize
                            local powerBarCenterX = cdmVisualRight + (barThickness / 2) + barBorderSize
                            secondary.lockedBaseX = math.floor(powerBarCenterX - screenCenterX + 0.5) - 4
                            secondary.lockedBaseY = math.floor(essentialCenterY - screenCenterY + 0.5)
                            secondary.width = math.floor(targetWidth + 0.5)
                        else
                            -- Horizontal bar: goes ABOVE Essential
                            local rowWidth = essentialViewer.__cdmRow1Width or essentialViewer.__cdmIconWidth or 300
                            local barHeight = secondary.height or 8
                            local targetWidth = rowWidth + (2 * row1BorderSize) - (2 * barBorderSize)
                            local cdmVisualTop = essentialCenterY + (totalHeight / 2) + row1BorderSize
                            local powerBarCenterY = cdmVisualTop + (barHeight / 2) + barBorderSize
                            secondary.lockedBaseY = math.floor(powerBarCenterY - screenCenterY + 0.5) - 1
                            secondary.lockedBaseX = math.floor(essentialCenterX - screenCenterX + 0.5)
                            secondary.width = math.floor(targetWidth + 0.5)
                        end
                        secondary.offsetX = 0  -- Reset user adjustment
                        secondary.offsetY = 0
                        secondary.autoAttach = false
                        secondary.useRawPixels = true
                        secondary.lockedToEssential = true
                        secondary.lockedToUtility = false
                        secondary.lockedToPrimary = false
                        RefreshPowerBars()
                        UpdateSecLockButtonStates()
                        if widthSecondarySlider and widthSecondarySlider.SetValue then widthSecondarySlider.SetValue(secondary.width, true) end
                        if yOffsetSecondarySlider and yOffsetSecondarySlider.SetValue then yOffsetSecondarySlider.SetValue(secondary.offsetY, true) end
                    else
                        print("|cFF56D1FFLuheyUI:|r Could not get screen positions. Try again.")
                    end
                else
                    print("|cFF56D1FFLuheyUI:|r Essential Cooldowns viewer not found or not visible.")
                end
            end
        end)

        -- Lock to Utility click handler
        lockSecUtilityBtn:SetScript("OnClick", function()
            if secondary.lockedToUtility then
                secondary.lockedToUtility = false
                UpdateSecLockButtonStates()
            else
                if _G.LuheyUI_RefreshNCDM then _G.LuheyUI_RefreshNCDM() end
                local utilityViewer = _G.UtilityCooldownViewer
                if utilityViewer and utilityViewer:IsShown() then
                    local rawCenterX, rawCenterY = utilityViewer:GetCenter()
                    local rawScreenX, rawScreenY = UIParent:GetCenter()
                    if rawCenterX and rawCenterY and rawScreenX and rawScreenY then
                        local utilityCenterX = math.floor(rawCenterX + 0.5)
                        local utilityCenterY = math.floor(rawCenterY + 0.5)
                        local screenCenterX = math.floor(rawScreenX + 0.5)
                        local screenCenterY = math.floor(rawScreenY + 0.5)
                        local totalHeight = utilityViewer.__cdmTotalHeight or utilityViewer:GetHeight() or 100
                        local bottomRowBorderSize = utilityViewer.__cdmBottomRowBorderSize or 2
                        local barBorderSize = secondary.borderSize or 1
                        local isVertical = secondary.orientation == "VERTICAL"

                        if isVertical then
                            -- Vertical bar: goes to the LEFT of Utility
                            local row1BorderSize = utilityViewer.__cdmRow1BorderSize or 0
                            local targetWidth = totalHeight + (2 * row1BorderSize) - (2 * barBorderSize)
                            local totalWidth = utilityViewer.__cdmIconWidth or utilityViewer:GetWidth()
                            local barThickness = secondary.height or 8
                            local cdmVisualLeft = utilityCenterX - (totalWidth / 2)
                            local powerBarCenterX = cdmVisualLeft - (barThickness / 2)
                            secondary.lockedBaseX = math.floor(powerBarCenterX - screenCenterX + 0.5)
                            secondary.lockedBaseY = math.floor(utilityCenterY - screenCenterY + 0.5)
                            secondary.width = math.floor(targetWidth + 0.5)
                        else
                            -- Horizontal bar: goes BELOW Utility
                            local rowWidth = utilityViewer.__cdmBottomRowWidth or utilityViewer.__cdmIconWidth or 300
                            local barHeight = secondary.height or 8
                            local targetWidth = rowWidth + (2 * bottomRowBorderSize) - (2 * barBorderSize)
                            local cdmVisualBottom = utilityCenterY - (totalHeight / 2) - bottomRowBorderSize
                            local powerBarCenterY = cdmVisualBottom - (barHeight / 2) - barBorderSize
                            secondary.lockedBaseY = math.floor(powerBarCenterY - screenCenterY + 0.5) + 1
                            secondary.lockedBaseX = math.floor(utilityCenterX - screenCenterX + 0.5)
                            secondary.width = math.floor(targetWidth + 0.5)
                        end
                        secondary.offsetX = 0  -- Reset user adjustment
                        secondary.offsetY = 0
                        secondary.autoAttach = false
                        secondary.useRawPixels = true
                        secondary.lockedToUtility = true
                        secondary.lockedToEssential = false
                        secondary.lockedToPrimary = false
                        RefreshPowerBars()
                        UpdateSecLockButtonStates()
                        if widthSecondarySlider and widthSecondarySlider.SetValue then widthSecondarySlider.SetValue(secondary.width, true) end
                        if yOffsetSecondarySlider and yOffsetSecondarySlider.SetValue then yOffsetSecondarySlider.SetValue(secondary.offsetY, true) end
                    else
                        print("|cFF56D1FFLuheyUI:|r Could not get screen positions. Try again.")
                    end
                else
                    print("|cFF56D1FFLuheyUI:|r Utility Cooldowns viewer not found or not visible.")
                end
            end
        end)

        -- Lock to Primary click handler
        lockSecPrimaryBtn:SetScript("OnClick", function()
            if secondary.lockedToPrimary then
                secondary.lockedToPrimary = false
                UpdateSecLockButtonStates()
            else
                local LUICore = _G.LuheyUI and _G.LuheyUI.LUICore
                local primaryBar = LUICore and LUICore.powerBar
                local primaryCfg = LUICore and LUICore.db and LUICore.db.profile.powerBar
                if primaryBar and primaryBar:IsShown() and primaryCfg then
                    local primaryCenterX, primaryCenterY = primaryBar:GetCenter()
                    local screenCenterX, screenCenterY = UIParent:GetCenter()
                    if primaryCenterX and primaryCenterY and screenCenterX and screenCenterY then
                        primaryCenterX = math.floor(primaryCenterX + 0.5)
                        primaryCenterY = math.floor(primaryCenterY + 0.5)
                        screenCenterX = math.floor(screenCenterX + 0.5)
                        screenCenterY = math.floor(screenCenterY + 0.5)
                        local primaryHeight = primaryCfg.height or 8
                        local primaryWidth = primaryCfg.width or primaryBar:GetWidth() or 300
                        local primaryBorderSize = primaryCfg.borderSize or 1
                        local secondaryHeight = secondary.height or 8
                        local secondaryBorderSize = secondary.borderSize or 1
                        local isVertical = secondary.orientation == "VERTICAL"

                        if isVertical then
                            local primaryActualWidth = primaryBar:GetWidth()
                            local targetWidth = primaryWidth + (2 * primaryBorderSize) - (2 * secondaryBorderSize)
                            secondary.width = math.floor(targetWidth + 0.5)
                        else
                            local targetWidth = primaryWidth + (2 * primaryBorderSize) - (2 * secondaryBorderSize)
                            secondary.width = math.floor(targetWidth + 0.5)
                        end
                    end

                    -- Reset user adjustment (base position is calculated live from primary bar)
                    secondary.offsetX = 0
                    secondary.offsetY = 0
                    secondary.lockedToPrimary = true
                    secondary.lockedToEssential = false
                    secondary.lockedToUtility = false
                    secondary.autoAttach = false
                    secondary.useRawPixels = true
                    RefreshPowerBars()
                    UpdateSecLockButtonStates()
                    if widthSecondarySlider and widthSecondarySlider.SetValue then widthSecondarySlider.SetValue(secondary.width, true) end
                    if yOffsetSecondarySlider and yOffsetSecondarySlider.SetValue then yOffsetSecondarySlider.SetValue(secondary.offsetY, true) end
                else
                    print("|cFF56D1FFLuheyUI:|r Primary Class Resource Bar not found or not visible. Enable it first.")
                end
            end
        end)

        -- Initialize button states
        UpdateSecLockButtonStates()
        y = y - FORM_ROW

        -- Color options (form style) - radio-button behavior: clicking one turns off the others
        local customColorPickerSecondary

        local powerColorSecondary = GUI:CreateFormCheckbox(tabContent, "Use Resource Type Color", "usePowerColor", secondary, function()
            if secondary.usePowerColor then
                secondary.useClassColor = false
                secondary.useCustomColor = false
                secondary.colorMode = "power"
            else
                -- Fallback: if turning off and nothing else is on, re-enable this
                if not secondary.useClassColor and not secondary.useCustomColor then
                    secondary.usePowerColor = true
                end
            end
            if customColorPickerSecondary then
                customColorPickerSecondary:SetEnabled(secondary.useCustomColor)
            end
            RefreshPowerBars()
        end)
        powerColorSecondary:SetPoint("TOPLEFT", PAD, y)
        powerColorSecondary:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local resourceColorDescSecondary = GUI:CreateLabel(tabContent, "Uses per-resource colors from the Resource Colors section below.", 11)
        resourceColorDescSecondary:SetPoint("TOPLEFT", PAD, y + 4)
        resourceColorDescSecondary:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        resourceColorDescSecondary:SetJustifyH("LEFT")
        resourceColorDescSecondary:SetTextColor(0.6, 0.6, 0.6)
        y = y - FORM_ROW

        local classColorSecondary = GUI:CreateFormCheckbox(tabContent, "Use Class Color", "useClassColor", secondary, function()
            if secondary.useClassColor then
                secondary.usePowerColor = false
                secondary.useCustomColor = false
                secondary.colorMode = "class"
            else
                -- Fallback: if turning off and nothing else is on, enable Resource Type Color
                if not secondary.usePowerColor and not secondary.useCustomColor then
                    secondary.usePowerColor = true
                end
            end
            if customColorPickerSecondary then
                customColorPickerSecondary:SetEnabled(secondary.useCustomColor)
            end
            RefreshPowerBars()
        end)
        classColorSecondary:SetPoint("TOPLEFT", PAD, y)
        classColorSecondary:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local bgColorSecondary = GUI:CreateFormColorPicker(tabContent, "Background Color", "bgColor", secondary, RefreshPowerBars)
        bgColorSecondary:SetPoint("TOPLEFT", PAD, y)
        bgColorSecondary:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local customColorOverrideSecondary = GUI:CreateFormCheckbox(tabContent, "Custom Color Override", "useCustomColor", secondary, function()
            if secondary.useCustomColor then
                secondary.usePowerColor = false
                secondary.useClassColor = false
                secondary.colorMode = "custom"
            else
                -- Fallback: if turning off and nothing else is on, enable Resource Type Color
                if not secondary.usePowerColor and not secondary.useClassColor then
                    secondary.usePowerColor = true
                end
            end
            if customColorPickerSecondary then
                customColorPickerSecondary:SetEnabled(secondary.useCustomColor)
            end
            RefreshPowerBars()
        end)
        customColorOverrideSecondary:SetPoint("TOPLEFT", PAD, y)
        customColorOverrideSecondary:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        customColorPickerSecondary = GUI:CreateFormColorPicker(tabContent, "Custom Color", "customColor", secondary, RefreshPowerBars)
        customColorPickerSecondary:SetPoint("TOPLEFT", PAD, y)
        customColorPickerSecondary:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        customColorPickerSecondary:SetEnabled(secondary.useCustomColor)
        y = y - FORM_ROW

        -- Text display options
        local showTextSecondary = GUI:CreateFormCheckbox(tabContent, "Show Number", "showText", secondary, RefreshPowerBars)
        showTextSecondary:SetPoint("TOPLEFT", PAD, y)
        showTextSecondary:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local showPercentSecondary = GUI:CreateFormCheckbox(tabContent, "Show as Percent", "showPercent", secondary, RefreshPowerBars)
        showPercentSecondary:SetPoint("TOPLEFT", PAD, y)
        showPercentSecondary:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local showRuneTextSecondary = GUI:CreateFormCheckbox(tabContent, "Show Rune CD Text (DKs)", "showFragmentedPowerBarText", secondary, RefreshPowerBars)
        showRuneTextSecondary:SetPoint("TOPLEFT", PAD, y)
        showRuneTextSecondary:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        local _, playerClass = UnitClass("player")
        showRuneTextSecondary:SetEnabled(playerClass == "DEATHKNIGHT")
        y = y - FORM_ROW

        -- Tick marks
        local showTicksSecondary = GUI:CreateFormCheckbox(tabContent, "Show Tick Marks", "showTicks", secondary, RefreshPowerBars)
        showTicksSecondary:SetPoint("TOPLEFT", PAD, y)
        showTicksSecondary:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local tickThicknessSecondary = GUI:CreateFormSlider(tabContent, "Tick Thickness", 1, 4, 1, "tickThickness", secondary, RefreshPowerBars)
        tickThicknessSecondary:SetPoint("TOPLEFT", PAD, y)
        tickThicknessSecondary:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local tickColorSecondary = GUI:CreateFormColorPicker(tabContent, "Tick Color", "tickColor", secondary, RefreshPowerBars)
        tickColorSecondary:SetPoint("TOPLEFT", PAD, y)
        tickColorSecondary:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        -- Size sliders (form style)
        widthSecondarySlider = GUI:CreateFormSlider(tabContent, "Width", 0, 2000, 1, "width", secondary, RefreshPowerBars)
        widthSecondarySlider:SetPoint("TOPLEFT", PAD, y)
        widthSecondarySlider:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local heightSecondary = GUI:CreateFormSlider(tabContent, "Height", 1, 100, 1, "height", secondary, RefreshPowerBars)
        heightSecondary:SetPoint("TOPLEFT", PAD, y)
        heightSecondary:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local borderSecondary = GUI:CreateFormSlider(tabContent, "Border Size", 0, 8, 1, "borderSize", secondary, RefreshPowerBars)
        borderSecondary:SetPoint("TOPLEFT", PAD, y)
        borderSecondary:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        -- Position sliders
        local xOffsetSecondarySlider = GUI:CreateFormSlider(tabContent, "X Offset", -1000, 1000, 1, "offsetX", secondary, RefreshPowerBars)
        xOffsetSecondarySlider:SetPoint("TOPLEFT", PAD, y)
        xOffsetSecondarySlider:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        yOffsetSecondarySlider = GUI:CreateFormSlider(tabContent, "Y Offset", -1000, 1000, 1, "offsetY", secondary, RefreshPowerBars)
        yOffsetSecondarySlider:SetPoint("TOPLEFT", PAD, y)
        yOffsetSecondarySlider:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        -- Register sliders for real-time sync during Edit Mode
        if _G.LuheyUI and _G.LuheyUI.LUICore and _G.LuheyUI.LUICore.RegisterPowerBarEditModeSliders then
            _G.LuheyUI.LUICore:RegisterPowerBarEditModeSliders("secondary", xOffsetSecondarySlider, yOffsetSecondarySlider)
        end

        -- Text sliders
        local textSizeSecondary = GUI:CreateFormSlider(tabContent, "Text Size", 8, 50, 1, "textSize", secondary, RefreshPowerBars)
        textSizeSecondary:SetPoint("TOPLEFT", PAD, y)
        textSizeSecondary:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local textXSecondary = GUI:CreateFormSlider(tabContent, "Text X Offset", -500, 500, 1, "textX", secondary, RefreshPowerBars)
        textXSecondary:SetPoint("TOPLEFT", PAD, y)
        textXSecondary:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local textYSecondary = GUI:CreateFormSlider(tabContent, "Text Y Offset", -500, 500, 1, "textY", secondary, RefreshPowerBars)
        textYSecondary:SetPoint("TOPLEFT", PAD, y)
        textYSecondary:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        -- Text color settings
        local textCustomColorSecondary  -- Forward declare for mutual reference

        local textUseClassColorSecondary = GUI:CreateFormCheckbox(tabContent, "Use Class Color for Text", "textUseClassColor", secondary, function()
            if textCustomColorSecondary then
                textCustomColorSecondary:SetEnabled(not secondary.textUseClassColor)
            end
            RefreshPowerBars()
        end)
        textUseClassColorSecondary:SetPoint("TOPLEFT", PAD, y)
        textUseClassColorSecondary:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        textCustomColorSecondary = GUI:CreateFormColorPicker(tabContent, "Custom Text Color", "textCustomColor", secondary, RefreshPowerBars)
        textCustomColorSecondary:SetPoint("TOPLEFT", PAD, y)
        textCustomColorSecondary:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        textCustomColorSecondary:SetEnabled(not secondary.textUseClassColor)  -- Initial state
        y = y - FORM_ROW

        local textureSecondary = GUI:CreateFormDropdown(tabContent, "Bar Texture", GetTextureList(), "texture", secondary, RefreshPowerBars)
        textureSecondary:SetPoint("TOPLEFT", PAD, y)
        textureSecondary:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        -- =====================================================
        -- POWER COLORS (Global - affects both bars)
        -- =====================================================
        y = y - 20  -- Spacer between sections

        local powerColorsHeader = GUI:CreateSectionHeader(tabContent, "Reset Resource Bar Colors To Default")
        powerColorsHeader:SetPoint("TOPLEFT", PAD, y)
        y = y - powerColorsHeader.gap

        -- Get powerColors DB table
        local pc = db.powerColors
        if not pc then
            db.powerColors = {}
            pc = db.powerColors
        end

        -- Default power colors (used for Reset button)
        local defaultPowerColors = {
            rage = { 1.00, 0.00, 0.00, 1 },
            energy = { 1.00, 1.00, 0.00, 1 },
            mana = { 0.00, 0.00, 1.00, 1 },
            focus = { 1.00, 0.50, 0.25, 1 },
            runicPower = { 0.00, 0.82, 1.00, 1 },
            fury = { 0.79, 0.26, 0.99, 1 },
            insanity = { 0.40, 0.00, 0.80, 1 },
            maelstrom = { 0.00, 0.50, 1.00, 1 },
            lunarPower = { 0.30, 0.52, 0.90, 1 },
            holyPower = { 0.95, 0.90, 0.60, 1 },
            chi = { 0.00, 1.00, 0.59, 1 },
            comboPoints = { 1.00, 0.96, 0.41, 1 },
            soulShards = { 0.58, 0.51, 0.79, 1 },
            arcaneCharges = { 0.10, 0.10, 0.98, 1 },
            essence = { 0.20, 0.58, 0.50, 1 },
            stagger = { 0.00, 1.00, 0.59, 1 },
            soulFragments = { 0.64, 0.19, 0.79, 1 },
            runes = { 0.77, 0.12, 0.23, 1 },
            bloodRunes = { 0.77, 0.12, 0.23, 1 },
            frostRunes = { 0.00, 0.82, 1.00, 1 },
            unholyRunes = { 0.00, 0.80, 0.00, 1 },
        }

        -- Initialize defaults if missing
        for key, value in pairs(defaultPowerColors) do
            if pc[key] == nil then pc[key] = {value[1], value[2], value[3], value[4]} end
        end

        -- Store widget references for Reset button
        local powerColorWidgets = {}

        -- Reset to Defaults button
        local resetPowerColorsContainer = CreateFrame("Frame", nil, tabContent)
        resetPowerColorsContainer:SetHeight(FORM_ROW)
        resetPowerColorsContainer:SetPoint("TOPLEFT", PAD, y)
        resetPowerColorsContainer:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)

        local resetPowerColorsLabel = resetPowerColorsContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        resetPowerColorsLabel:SetPoint("LEFT", 0, 0)
        resetPowerColorsLabel:SetText("Reset Colors")
        resetPowerColorsLabel:SetTextColor(C.text[1], C.text[2], C.text[3], 1)

        local resetPowerColorsBtn = CreateFrame("Button", nil, resetPowerColorsContainer, "BackdropTemplate")
        resetPowerColorsBtn:SetSize(140, 24)
        resetPowerColorsBtn:SetPoint("LEFT", resetPowerColorsContainer, "LEFT", 180, 0)
        resetPowerColorsBtn:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        resetPowerColorsBtn:SetBackdropColor(0.15, 0.15, 0.15, 1)
        resetPowerColorsBtn:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], 1)

        local resetPowerColorsText = resetPowerColorsBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        resetPowerColorsText:SetPoint("CENTER")
        resetPowerColorsText:SetText("Reset to Defaults")
        resetPowerColorsText:SetTextColor(C.text[1], C.text[2], C.text[3], 1)

        resetPowerColorsBtn:SetScript("OnEnter", function(self)
            self:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 1)
        end)
        resetPowerColorsBtn:SetScript("OnLeave", function(self)
            self:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], 1)
        end)
        resetPowerColorsBtn:SetScript("OnClick", function()
            for key, value in pairs(defaultPowerColors) do
                pc[key] = {value[1], value[2], value[3], value[4]}
            end
            -- Refresh color swatches
            for _, widget in ipairs(powerColorWidgets) do
                if widget.swatch and pc[widget.dbKey] then
                    local col = pc[widget.dbKey]
                    widget.swatch:SetBackdropColor(col[1], col[2], col[3], col[4] or 1)
                end
            end
            RefreshPowerBars()
            print("|cFF56D1FFLuheyUI:|r Resource colors reset to defaults.")
        end)
        y = y - FORM_ROW

        -- =====================================================
        -- SUB-SECTION: Core Resources
        -- =====================================================
        y = y - 8
        local coreHeader = GUI:CreateSectionHeader(tabContent, "Bar Colors for Core Resources")
        coreHeader:SetPoint("TOPLEFT", PAD, y)
        y = y - coreHeader.gap

        local rageColor = GUI:CreateFormColorPicker(tabContent, "Rage", "rage", pc, RefreshPowerBars)
        rageColor:SetPoint("TOPLEFT", PAD, y)
        rageColor:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        rageColor.dbKey = "rage"
        table.insert(powerColorWidgets, rageColor)
        y = y - FORM_ROW

        local energyColor = GUI:CreateFormColorPicker(tabContent, "Energy", "energy", pc, RefreshPowerBars)
        energyColor:SetPoint("TOPLEFT", PAD, y)
        energyColor:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        energyColor.dbKey = "energy"
        table.insert(powerColorWidgets, energyColor)
        y = y - FORM_ROW

        local manaColor = GUI:CreateFormColorPicker(tabContent, "Mana", "mana", pc, RefreshPowerBars)
        manaColor:SetPoint("TOPLEFT", PAD, y)
        manaColor:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        manaColor.dbKey = "mana"
        table.insert(powerColorWidgets, manaColor)
        y = y - FORM_ROW

        local focusColor = GUI:CreateFormColorPicker(tabContent, "Focus", "focus", pc, RefreshPowerBars)
        focusColor:SetPoint("TOPLEFT", PAD, y)
        focusColor:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        focusColor.dbKey = "focus"
        table.insert(powerColorWidgets, focusColor)
        y = y - FORM_ROW

        local runicPowerColor = GUI:CreateFormColorPicker(tabContent, "Runic Power", "runicPower", pc, RefreshPowerBars)
        runicPowerColor:SetPoint("TOPLEFT", PAD, y)
        runicPowerColor:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        runicPowerColor.dbKey = "runicPower"
        table.insert(powerColorWidgets, runicPowerColor)
        y = y - FORM_ROW

        local furyColor = GUI:CreateFormColorPicker(tabContent, "Fury", "fury", pc, RefreshPowerBars)
        furyColor:SetPoint("TOPLEFT", PAD, y)
        furyColor:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        furyColor.dbKey = "fury"
        table.insert(powerColorWidgets, furyColor)
        y = y - FORM_ROW

        local insanityColor = GUI:CreateFormColorPicker(tabContent, "Insanity", "insanity", pc, RefreshPowerBars)
        insanityColor:SetPoint("TOPLEFT", PAD, y)
        insanityColor:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        insanityColor.dbKey = "insanity"
        table.insert(powerColorWidgets, insanityColor)
        y = y - FORM_ROW

        local maelstromColor = GUI:CreateFormColorPicker(tabContent, "Maelstrom", "maelstrom", pc, RefreshPowerBars)
        maelstromColor:SetPoint("TOPLEFT", PAD, y)
        maelstromColor:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        maelstromColor.dbKey = "maelstrom"
        table.insert(powerColorWidgets, maelstromColor)
        y = y - FORM_ROW

        local lunarPowerColor = GUI:CreateFormColorPicker(tabContent, "Astral Power", "lunarPower", pc, RefreshPowerBars)
        lunarPowerColor:SetPoint("TOPLEFT", PAD, y)
        lunarPowerColor:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        lunarPowerColor.dbKey = "lunarPower"
        table.insert(powerColorWidgets, lunarPowerColor)
        y = y - FORM_ROW

        -- =====================================================
        -- SUB-SECTION: Builder Resources
        -- =====================================================
        y = y - 8
        local builderHeader = GUI:CreateSectionHeader(tabContent, "Bar Colors for Builder Resources")
        builderHeader:SetPoint("TOPLEFT", PAD, y)
        y = y - builderHeader.gap

        local holyPowerColor = GUI:CreateFormColorPicker(tabContent, "Holy Power", "holyPower", pc, RefreshPowerBars)
        holyPowerColor:SetPoint("TOPLEFT", PAD, y)
        holyPowerColor:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        holyPowerColor.dbKey = "holyPower"
        table.insert(powerColorWidgets, holyPowerColor)
        y = y - FORM_ROW

        local chiColor = GUI:CreateFormColorPicker(tabContent, "Chi", "chi", pc, RefreshPowerBars)
        chiColor:SetPoint("TOPLEFT", PAD, y)
        chiColor:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        chiColor.dbKey = "chi"
        table.insert(powerColorWidgets, chiColor)
        y = y - FORM_ROW

        local comboPointsColor = GUI:CreateFormColorPicker(tabContent, "Combo Points", "comboPoints", pc, RefreshPowerBars)
        comboPointsColor:SetPoint("TOPLEFT", PAD, y)
        comboPointsColor:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        comboPointsColor.dbKey = "comboPoints"
        table.insert(powerColorWidgets, comboPointsColor)
        y = y - FORM_ROW

        local soulShardsColor = GUI:CreateFormColorPicker(tabContent, "Soul Shards", "soulShards", pc, RefreshPowerBars)
        soulShardsColor:SetPoint("TOPLEFT", PAD, y)
        soulShardsColor:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        soulShardsColor.dbKey = "soulShards"
        table.insert(powerColorWidgets, soulShardsColor)
        y = y - FORM_ROW

        local arcaneChargesColor = GUI:CreateFormColorPicker(tabContent, "Arcane Charges", "arcaneCharges", pc, RefreshPowerBars)
        arcaneChargesColor:SetPoint("TOPLEFT", PAD, y)
        arcaneChargesColor:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        arcaneChargesColor.dbKey = "arcaneCharges"
        table.insert(powerColorWidgets, arcaneChargesColor)
        y = y - FORM_ROW

        local essenceColor = GUI:CreateFormColorPicker(tabContent, "Essence", "essence", pc, RefreshPowerBars)
        essenceColor:SetPoint("TOPLEFT", PAD, y)
        essenceColor:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        essenceColor.dbKey = "essence"
        table.insert(powerColorWidgets, essenceColor)
        y = y - FORM_ROW

        -- =====================================================
        -- SUB-SECTION: Specialized Resources
        -- =====================================================
        y = y - 8
        local specialHeader = GUI:CreateSectionHeader(tabContent, "Bar Colors for Specialized Resources")
        specialHeader:SetPoint("TOPLEFT", PAD, y)
        y = y - specialHeader.gap

        local staggerColor = GUI:CreateFormColorPicker(tabContent, "Stagger (Fallback)", "stagger", pc, RefreshPowerBars)
        staggerColor:SetPoint("TOPLEFT", PAD, y)
        staggerColor:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        staggerColor.dbKey = "stagger"
        table.insert(powerColorWidgets, staggerColor)
        y = y - FORM_ROW

        local useStaggerLevels = GUI:CreateFormCheckbox(tabContent, "Use Stagger Level Colors", "useStaggerLevelColors", pc, RefreshPowerBars)
        useStaggerLevels:SetPoint("TOPLEFT", PAD, y)
        useStaggerLevels:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local staggerLightColor = GUI:CreateFormColorPicker(tabContent, "Stagger - Light (0-30%)", "staggerLight", pc, RefreshPowerBars)
        staggerLightColor:SetPoint("TOPLEFT", PAD, y)
        staggerLightColor:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        staggerLightColor.dbKey = "staggerLight"
        table.insert(powerColorWidgets, staggerLightColor)
        y = y - FORM_ROW

        local staggerModerateColor = GUI:CreateFormColorPicker(tabContent, "Stagger - Moderate (30-60%)", "staggerModerate", pc, RefreshPowerBars)
        staggerModerateColor:SetPoint("TOPLEFT", PAD, y)
        staggerModerateColor:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        staggerModerateColor.dbKey = "staggerModerate"
        table.insert(powerColorWidgets, staggerModerateColor)
        y = y - FORM_ROW

        local staggerHeavyColor = GUI:CreateFormColorPicker(tabContent, "Stagger - Heavy (60%+)", "staggerHeavy", pc, RefreshPowerBars)
        staggerHeavyColor:SetPoint("TOPLEFT", PAD, y)
        staggerHeavyColor:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        staggerHeavyColor.dbKey = "staggerHeavy"
        table.insert(powerColorWidgets, staggerHeavyColor)
        y = y - FORM_ROW

        local soulFragmentsColor = GUI:CreateFormColorPicker(tabContent, "Soul Fragments", "soulFragments", pc, RefreshPowerBars)
        soulFragmentsColor:SetPoint("TOPLEFT", PAD, y)
        soulFragmentsColor:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        soulFragmentsColor.dbKey = "soulFragments"
        table.insert(powerColorWidgets, soulFragmentsColor)
        y = y - FORM_ROW

        local runesColor = GUI:CreateFormColorPicker(tabContent, "Runes (Generic)", "runes", pc, RefreshPowerBars)
        runesColor:SetPoint("TOPLEFT", PAD, y)
        runesColor:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        runesColor.dbKey = "runes"
        table.insert(powerColorWidgets, runesColor)
        y = y - FORM_ROW

        local bloodRunesColor = GUI:CreateFormColorPicker(tabContent, "Blood Runes", "bloodRunes", pc, RefreshPowerBars)
        bloodRunesColor:SetPoint("TOPLEFT", PAD, y)
        bloodRunesColor:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        bloodRunesColor.dbKey = "bloodRunes"
        table.insert(powerColorWidgets, bloodRunesColor)
        y = y - FORM_ROW

        local frostRunesColor = GUI:CreateFormColorPicker(tabContent, "Frost Runes", "frostRunes", pc, RefreshPowerBars)
        frostRunesColor:SetPoint("TOPLEFT", PAD, y)
        frostRunesColor:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        frostRunesColor.dbKey = "frostRunes"
        table.insert(powerColorWidgets, frostRunesColor)
        y = y - FORM_ROW

        local unholyRunesColor = GUI:CreateFormColorPicker(tabContent, "Unholy Runes", "unholyRunes", pc, RefreshPowerBars)
        unholyRunesColor:SetPoint("TOPLEFT", PAD, y)
        unholyRunesColor:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        unholyRunesColor.dbKey = "unholyRunes"
        table.insert(powerColorWidgets, unholyRunesColor)
        y = y - FORM_ROW

        -- Extra padding at bottom for dropdown menus to expand into
        tabContent:SetHeight(math.abs(y) + 60)
    end

    -- Create sub-tabs
    local subTabs = GUI:CreateSubTabs(content, {
        {name = "Essential", builder = BuildEssentialTab},
        {name = "Utility", builder = BuildUtilityTab},
        {name = "Buff", builder = BuildBuffTab},
        {name = "Class Resource Bar", builder = BuildPowerbarTab},
    })
    subTabs:SetPoint("TOPLEFT", 5, -5)
    subTabs:SetPoint("TOPRIGHT", -5, -5)
    subTabs:SetHeight(700)
    
    content:SetHeight(750)
end

---------------------------------------------------------------------------
-- PAGE: CD Effects + Glow
---------------------------------------------------------------------------
local function CreateCDEffectsPage(parent)
    local scroll, content = CreateScrollableContent(parent)
    local db = GetDB()
    local y = -15
    local FORM_ROW = 32

    -- Set search context for auto-registration
    GUI:SetSearchContext({tabIndex = 7, tabName = "CDM GCD & Effects"})

    -- Refresh functions
    local function RefreshSwipe()
        if _G.LuheyUI_RefreshCooldownSwipe then _G.LuheyUI_RefreshCooldownSwipe() end
    end
    local function RefreshEffects()
        if _G.LuheyUI_RefreshCooldownEffects then _G.LuheyUI_RefreshCooldownEffects() end
    end
    local function RefreshGlows()
        if _G.LuheyUI_RefreshCustomGlows then _G.LuheyUI_RefreshCustomGlows() end
    end
    
    -- Initialize tables if needed
    if db then
        if not db.cooldownSwipe then db.cooldownSwipe = {} end
        if not db.cooldownEffects then db.cooldownEffects = {} end
        if not db.customGlow then db.customGlow = {} end
    end

    -- =====================================================
    -- COOLDOWN SWIPE
    -- =====================================================
    local swipeHeader = GUI:CreateSectionHeader(content, "COOLDOWN SWIPE")
    swipeHeader:SetPoint("TOPLEFT", PADDING, y)
    y = y - swipeHeader.gap

    local swipeDesc = GUI:CreateLabel(content, "Control which animations appear on CDM icons. Quazii's personal setup is to turn OFF all the below.", 11, C.textMuted)
    swipeDesc:SetPoint("TOPLEFT", PADDING, y)
    swipeDesc:SetPoint("RIGHT", content, "RIGHT", -PADDING, 0)
    swipeDesc:SetJustifyH("LEFT")
    y = y - 24

    if db and db.cooldownSwipe then
        local showCooldownSwipe = GUI:CreateFormCheckbox(content, "Radial Darkening", "showCooldownSwipe", db.cooldownSwipe, RefreshSwipe)
        showCooldownSwipe:SetPoint("TOPLEFT", PADDING, y)
        showCooldownSwipe:SetPoint("RIGHT", content, "RIGHT", -PADDING, 0)
        y = y - FORM_ROW
        local cdDesc = GUI:CreateLabel(content, "The radial darkening of icons to signify how long more before a spell is ready again.", 10, C.textMuted)
        cdDesc:SetPoint("TOPLEFT", PADDING, y + 4)
        cdDesc:SetPoint("RIGHT", content, "RIGHT", -PADDING, 0)
        cdDesc:SetJustifyH("LEFT")
        y = y - 14

        local showGCDSwipe = GUI:CreateFormCheckbox(content, "GCD Swipe", "showGCDSwipe", db.cooldownSwipe, RefreshSwipe)
        showGCDSwipe:SetPoint("TOPLEFT", PADDING, y)
        showGCDSwipe:SetPoint("RIGHT", content, "RIGHT", -PADDING, 0)
        y = y - FORM_ROW
        local gcdDesc = GUI:CreateLabel(content, "The quick ~1.5 second animation after pressing any ability (Global Cooldown)", 10, C.textMuted)
        gcdDesc:SetPoint("TOPLEFT", PADDING, y + 4)
        gcdDesc:SetPoint("RIGHT", content, "RIGHT", -PADDING, 0)
        gcdDesc:SetJustifyH("LEFT")
        y = y - 14

        local showBuffSwipe = GUI:CreateFormCheckbox(content, "Buff Swipe on Essential/Utility", "showBuffSwipe", db.cooldownSwipe, RefreshSwipe)
        showBuffSwipe:SetPoint("TOPLEFT", PADDING, y)
        showBuffSwipe:SetPoint("RIGHT", content, "RIGHT", -PADDING, 0)
        y = y - FORM_ROW
        local buffDesc = GUI:CreateLabel(content, "Yellow radial overlay showing duration of aura on Essential and Utility icons", 10, C.textMuted)
        buffDesc:SetPoint("TOPLEFT", PADDING, y + 4)
        buffDesc:SetPoint("RIGHT", content, "RIGHT", -PADDING, 0)
        buffDesc:SetJustifyH("LEFT")
        y = y - 14

        local showBuffIconSwipe = GUI:CreateFormCheckbox(content, "Buff Swipe on Buff Icons Bar", "showBuffIconSwipe", db.cooldownSwipe, RefreshSwipe)
        showBuffIconSwipe:SetPoint("TOPLEFT", PADDING, y)
        showBuffIconSwipe:SetPoint("RIGHT", content, "RIGHT", -PADDING, 0)
        y = y - FORM_ROW
        local buffIconDesc = GUI:CreateLabel(content, "Duration swipe on BuffIcon viewer only (procs, short buffs)", 10, C.textMuted)
        buffIconDesc:SetPoint("TOPLEFT", PADDING, y + 4)
        buffIconDesc:SetPoint("RIGHT", content, "RIGHT", -PADDING, 0)
        buffIconDesc:SetJustifyH("LEFT")
        y = y - 14

        local showRechargeEdge = GUI:CreateFormCheckbox(content, "Recharge Edge", "showRechargeEdge", db.cooldownSwipe, RefreshSwipe)
        showRechargeEdge:SetPoint("TOPLEFT", PADDING, y)
        showRechargeEdge:SetPoint("RIGHT", content, "RIGHT", -PADDING, 0)
        y = y - FORM_ROW
        local rechargeEdgeDesc = GUI:CreateLabel(content, "Yellow radial line that shows cooldown recharge time. Note: This comes with a faint GCD swipe too.", 10, C.textMuted)
        rechargeEdgeDesc:SetPoint("TOPLEFT", PADDING, y + 4)
        rechargeEdgeDesc:SetPoint("RIGHT", content, "RIGHT", -PADDING, 0)
        rechargeEdgeDesc:SetJustifyH("LEFT")
        y = y - 14
    end
    
    -- =====================================================
    -- COOLDOWN EFFECTS
    -- =====================================================
    local effectsHeader = GUI:CreateSectionHeader(content, "COOLDOWN EFFECTS")
    effectsHeader:SetPoint("TOPLEFT", PADDING, y)
    y = y - effectsHeader.gap
    
    local effectsDesc = GUI:CreateLabel(content, "Hides intrusive Blizzard effects: red flashes, golden proc glows, spell activation alerts.", 11, C.textMuted)
    effectsDesc:SetPoint("TOPLEFT", PADDING, y)
    effectsDesc:SetPoint("RIGHT", content, "RIGHT", -PADDING, 0)
    effectsDesc:SetJustifyH("LEFT")
    y = y - 24

    if db and db.cooldownEffects then
        local function PromptEffectsReload()
            GUI:ShowConfirmation({
                title = "Reload UI?",
                message = "Changing cooldown effect visibility requires a UI reload to take effect.",
                acceptText = "Reload",
                cancelText = "Later",
                onAccept = function() LuheyUI:SafeReload() end,
            })
        end

        local hideEssentialEffects = GUI:CreateFormCheckbox(content, "Hide on Essential Cooldowns", "hideEssential", db.cooldownEffects, PromptEffectsReload)
        hideEssentialEffects:SetPoint("TOPLEFT", PADDING, y)
        hideEssentialEffects:SetPoint("RIGHT", content, "RIGHT", -PADDING, 0)
        y = y - FORM_ROW

        local hideUtilityEffects = GUI:CreateFormCheckbox(content, "Hide on Utility Cooldowns", "hideUtility", db.cooldownEffects, PromptEffectsReload)
        hideUtilityEffects:SetPoint("TOPLEFT", PADDING, y)
        hideUtilityEffects:SetPoint("RIGHT", content, "RIGHT", -PADDING, 0)
        y = y - FORM_ROW

        local effectsWarning = GUI:CreateLabel(content, "Note: When toggled off, Blizzard's default effects will appear on top of your custom glows below.", 11, C.warning)
        effectsWarning:SetPoint("TOPLEFT", PADDING, y)
        effectsWarning:SetPoint("RIGHT", content, "RIGHT", -PADDING, 0)
        effectsWarning:SetJustifyH("LEFT")
        y = y - 24
    end
    
    -- =====================================================
    -- CUSTOM GLOW - ESSENTIAL
    -- =====================================================
    local essentialGlowHeader = GUI:CreateSectionHeader(content, "ESSENTIAL COOLDOWNS - CUSTOM GLOW")
    essentialGlowHeader:SetPoint("TOPLEFT", PADDING, y)
    y = y - essentialGlowHeader.gap

    local essentialGlowDesc = GUI:CreateLabel(content, "Replace Blizzard's glow with a custom glow effect when abilities proc.", 11, C.textMuted)
    essentialGlowDesc:SetPoint("TOPLEFT", PADDING, y)
    essentialGlowDesc:SetPoint("RIGHT", content, "RIGHT", -PADDING, 0)
    essentialGlowDesc:SetJustifyH("LEFT")
    y = y - 24

    if db and db.customGlow then
        -- Enable toggle
        local essentialGlowEnable = GUI:CreateFormCheckbox(content, "Enable Custom Glow", "essentialEnabled", db.customGlow, RefreshGlows)
        essentialGlowEnable:SetPoint("TOPLEFT", PADDING, y)
        essentialGlowEnable:SetPoint("RIGHT", content, "RIGHT", -PADDING, 0)
        y = y - FORM_ROW

        -- Glow Type dropdown
        local glowTypeOptions = {
            {value = "Pixel Glow", text = "Pixel Glow"},
            {value = "Autocast Shine", text = "Autocast Shine"},
            -- {value = "Button Glow", text = "Button Glow"},  -- Bugged, disabled for now
        }

        -- Store references to conditional widgets for visibility updates
        local essentialWidgets = {}

        local essentialGlowType = GUI:CreateFormDropdown(content, "Glow Type", glowTypeOptions, "essentialGlowType", db.customGlow, function()
            RefreshGlows()
            -- Update widget visibility based on selected glow type
            local glowType = db.customGlow.essentialGlowType or "Pixel Glow"
            local isPixel = glowType == "Pixel Glow"
            local isAutocast = glowType == "Autocast Shine"
            local isButton = glowType == "Button Glow"

            -- Enable/disable widgets based on glow type (all stay visible)
            if essentialWidgets.lines then essentialWidgets.lines:SetEnabled(isPixel or isAutocast) end
            if essentialWidgets.thickness then essentialWidgets.thickness:SetEnabled(isPixel) end
            if essentialWidgets.scale then essentialWidgets.scale:SetEnabled(isAutocast) end
            if essentialWidgets.speed then essentialWidgets.speed:SetEnabled(true) end
            if essentialWidgets.xOffset then essentialWidgets.xOffset:SetEnabled(not isButton) end
            if essentialWidgets.yOffset then essentialWidgets.yOffset:SetEnabled(not isButton) end
        end)
        essentialGlowType:SetPoint("TOPLEFT", PADDING, y)
        essentialGlowType:SetPoint("RIGHT", content, "RIGHT", -PADDING, 0)
        y = y - FORM_ROW

        -- Color picker
        local essentialGlowColor = GUI:CreateFormColorPicker(content, "Glow Color", "essentialColor", db.customGlow, RefreshGlows)
        essentialGlowColor:SetPoint("TOPLEFT", PADDING, y)
        essentialGlowColor:SetPoint("RIGHT", content, "RIGHT", -PADDING, 0)
        y = y - FORM_ROW

        -- Lines (Pixel Glow and Autocast Shine)
        local essentialLines = GUI:CreateFormSlider(content, "Lines", 1, 30, 1, "essentialLines", db.customGlow, RefreshGlows)
        essentialLines:SetPoint("TOPLEFT", PADDING, y)
        essentialLines:SetPoint("RIGHT", content, "RIGHT", -PADDING, 0)
        essentialWidgets.lines = essentialLines
        y = y - FORM_ROW

        -- Thickness (Pixel Glow only)
        local essentialThickness = GUI:CreateFormSlider(content, "Thickness", 1, 10, 1, "essentialThickness", db.customGlow, RefreshGlows)
        essentialThickness:SetPoint("TOPLEFT", PADDING, y)
        essentialThickness:SetPoint("RIGHT", content, "RIGHT", -PADDING, 0)
        essentialWidgets.thickness = essentialThickness
        y = y - FORM_ROW

        -- Scale (Autocast Shine only)
        local essentialScale = GUI:CreateFormSlider(content, "Shine Scale", 0.5, 3.0, 0.1, "essentialScale", db.customGlow, RefreshGlows)
        essentialScale:SetPoint("TOPLEFT", PADDING, y)
        essentialScale:SetPoint("RIGHT", content, "RIGHT", -PADDING, 0)
        essentialWidgets.scale = essentialScale
        y = y - FORM_ROW

        -- Animation Speed
        local essentialSpeed = GUI:CreateFormSlider(content, "Animation Speed", 0.1, 2.0, 0.05, "essentialFrequency", db.customGlow, RefreshGlows)
        essentialSpeed:SetPoint("TOPLEFT", PADDING, y)
        essentialSpeed:SetPoint("RIGHT", content, "RIGHT", -PADDING, 0)
        essentialWidgets.speed = essentialSpeed
        y = y - FORM_ROW

        -- X Offset
        local essentialXOffset = GUI:CreateFormSlider(content, "X Offset", -20, 20, 1, "essentialXOffset", db.customGlow, RefreshGlows)
        essentialXOffset:SetPoint("TOPLEFT", PADDING, y)
        essentialXOffset:SetPoint("RIGHT", content, "RIGHT", -PADDING, 0)
        essentialWidgets.xOffset = essentialXOffset
        y = y - FORM_ROW

        -- Y Offset
        local essentialYOffset = GUI:CreateFormSlider(content, "Y Offset", -20, 20, 1, "essentialYOffset", db.customGlow, RefreshGlows)
        essentialYOffset:SetPoint("TOPLEFT", PADDING, y)
        essentialYOffset:SetPoint("RIGHT", content, "RIGHT", -PADDING, 0)
        essentialWidgets.yOffset = essentialYOffset
        y = y - FORM_ROW

        -- Initial enable/disable state based on glow type
        local glowType = db.customGlow.essentialGlowType or "Pixel Glow"
        local isPixel = glowType == "Pixel Glow"
        local isAutocast = glowType == "Autocast Shine"
        local isButton = glowType == "Button Glow"

        essentialWidgets.lines:SetEnabled(isPixel or isAutocast)
        essentialWidgets.thickness:SetEnabled(isPixel)
        essentialWidgets.scale:SetEnabled(isAutocast)
        essentialWidgets.speed:SetEnabled(true)
        essentialWidgets.xOffset:SetEnabled(not isButton)
        essentialWidgets.yOffset:SetEnabled(not isButton)
    end

    -- =====================================================
    -- CUSTOM GLOW - UTILITY
    -- =====================================================
    local utilityGlowHeader = GUI:CreateSectionHeader(content, "UTILITY COOLDOWNS - CUSTOM GLOW")
    utilityGlowHeader:SetPoint("TOPLEFT", PADDING, y)
    y = y - utilityGlowHeader.gap

    local utilityGlowDesc = GUI:CreateLabel(content, "Replace Blizzard's glow with a custom glow effect when abilities proc.", 11, C.textMuted)
    utilityGlowDesc:SetPoint("TOPLEFT", PADDING, y)
    utilityGlowDesc:SetPoint("RIGHT", content, "RIGHT", -PADDING, 0)
    utilityGlowDesc:SetJustifyH("LEFT")
    y = y - 24

    if db and db.customGlow then
        -- Enable toggle
        local utilityGlowEnable = GUI:CreateFormCheckbox(content, "Enable Custom Glow", "utilityEnabled", db.customGlow, RefreshGlows)
        utilityGlowEnable:SetPoint("TOPLEFT", PADDING, y)
        utilityGlowEnable:SetPoint("RIGHT", content, "RIGHT", -PADDING, 0)
        y = y - FORM_ROW

        -- Glow Type dropdown (reuse options from Essential section)
        local utilityGlowTypeOptions = {
            {value = "Pixel Glow", text = "Pixel Glow"},
            {value = "Autocast Shine", text = "Autocast Shine"},
            -- {value = "Button Glow", text = "Button Glow"},  -- Bugged, disabled for now
        }

        -- Store references to conditional widgets for visibility updates
        local utilityWidgets = {}

        local utilityGlowType = GUI:CreateFormDropdown(content, "Glow Type", utilityGlowTypeOptions, "utilityGlowType", db.customGlow, function()
            RefreshGlows()
            -- Update widget visibility based on selected glow type
            local glowType = db.customGlow.utilityGlowType or "Pixel Glow"
            local isPixel = glowType == "Pixel Glow"
            local isAutocast = glowType == "Autocast Shine"
            local isButton = glowType == "Button Glow"

            -- Enable/disable widgets based on glow type (all stay visible)
            if utilityWidgets.lines then utilityWidgets.lines:SetEnabled(isPixel or isAutocast) end
            if utilityWidgets.thickness then utilityWidgets.thickness:SetEnabled(isPixel) end
            if utilityWidgets.scale then utilityWidgets.scale:SetEnabled(isAutocast) end
            if utilityWidgets.speed then utilityWidgets.speed:SetEnabled(true) end
            if utilityWidgets.xOffset then utilityWidgets.xOffset:SetEnabled(not isButton) end
            if utilityWidgets.yOffset then utilityWidgets.yOffset:SetEnabled(not isButton) end
        end)
        utilityGlowType:SetPoint("TOPLEFT", PADDING, y)
        utilityGlowType:SetPoint("RIGHT", content, "RIGHT", -PADDING, 0)
        y = y - FORM_ROW

        -- Color picker
        local utilityGlowColor = GUI:CreateFormColorPicker(content, "Glow Color", "utilityColor", db.customGlow, RefreshGlows)
        utilityGlowColor:SetPoint("TOPLEFT", PADDING, y)
        utilityGlowColor:SetPoint("RIGHT", content, "RIGHT", -PADDING, 0)
        y = y - FORM_ROW

        -- Lines (Pixel Glow and Autocast Shine)
        local utilityLines = GUI:CreateFormSlider(content, "Lines", 1, 30, 1, "utilityLines", db.customGlow, RefreshGlows)
        utilityLines:SetPoint("TOPLEFT", PADDING, y)
        utilityLines:SetPoint("RIGHT", content, "RIGHT", -PADDING, 0)
        utilityWidgets.lines = utilityLines
        y = y - FORM_ROW

        -- Thickness (Pixel Glow only)
        local utilityThickness = GUI:CreateFormSlider(content, "Thickness", 1, 10, 1, "utilityThickness", db.customGlow, RefreshGlows)
        utilityThickness:SetPoint("TOPLEFT", PADDING, y)
        utilityThickness:SetPoint("RIGHT", content, "RIGHT", -PADDING, 0)
        utilityWidgets.thickness = utilityThickness
        y = y - FORM_ROW

        -- Scale (Autocast Shine only)
        local utilityScale = GUI:CreateFormSlider(content, "Shine Scale", 0.5, 3.0, 0.1, "utilityScale", db.customGlow, RefreshGlows)
        utilityScale:SetPoint("TOPLEFT", PADDING, y)
        utilityScale:SetPoint("RIGHT", content, "RIGHT", -PADDING, 0)
        utilityWidgets.scale = utilityScale
        y = y - FORM_ROW

        -- Animation Speed
        local utilitySpeed = GUI:CreateFormSlider(content, "Animation Speed", 0.1, 2.0, 0.05, "utilityFrequency", db.customGlow, RefreshGlows)
        utilitySpeed:SetPoint("TOPLEFT", PADDING, y)
        utilitySpeed:SetPoint("RIGHT", content, "RIGHT", -PADDING, 0)
        utilityWidgets.speed = utilitySpeed
        y = y - FORM_ROW

        -- X Offset
        local utilityXOffset = GUI:CreateFormSlider(content, "X Offset", -20, 20, 1, "utilityXOffset", db.customGlow, RefreshGlows)
        utilityXOffset:SetPoint("TOPLEFT", PADDING, y)
        utilityXOffset:SetPoint("RIGHT", content, "RIGHT", -PADDING, 0)
        utilityWidgets.xOffset = utilityXOffset
        y = y - FORM_ROW

        -- Y Offset
        local utilityYOffset = GUI:CreateFormSlider(content, "Y Offset", -20, 20, 1, "utilityYOffset", db.customGlow, RefreshGlows)
        utilityYOffset:SetPoint("TOPLEFT", PADDING, y)
        utilityYOffset:SetPoint("RIGHT", content, "RIGHT", -PADDING, 0)
        utilityWidgets.yOffset = utilityYOffset
        y = y - FORM_ROW

        -- Initial enable/disable state based on glow type
        local glowType = db.customGlow.utilityGlowType or "Pixel Glow"
        local isPixel = glowType == "Pixel Glow"
        local isAutocast = glowType == "Autocast Shine"
        local isButton = glowType == "Button Glow"

        utilityWidgets.lines:SetEnabled(isPixel or isAutocast)
        utilityWidgets.thickness:SetEnabled(isPixel)
        utilityWidgets.scale:SetEnabled(isAutocast)
        utilityWidgets.speed:SetEnabled(true)
        utilityWidgets.xOffset:SetEnabled(not isButton)
        utilityWidgets.yOffset:SetEnabled(not isButton)
    end

    content:SetHeight(math.abs(y) + 50)
end

---------------------------------------------------------------------------
-- PAGE: CDM Keybind & Rotation
---------------------------------------------------------------------------
local function CreateCDKeybindsPage(parent)
    local scroll, content = CreateScrollableContent(parent)
    local db = GetDB()
    local y = -15
    local FORM_ROW = 32

    -- Set search context for auto-registration
    GUI:SetSearchContext({tabIndex = 8, tabName = "CDM Keybind & Rotation"})

    -- Refresh function for keybinds
    local function RefreshKeybinds()
        if _G.LuheyUI_RefreshKeybinds then
            _G.LuheyUI_RefreshKeybinds()
        end
    end

    -- Refresh function for rotation helper
    local function RefreshRotationHelper()
        if _G.LuheyUI_RefreshRotationHelper then
            _G.LuheyUI_RefreshRotationHelper()
        end
    end

    -- Info text at top
    local info = GUI:CreateLabel(content, "Keybind display - shows ability keybinds on cooldown icons", 11, C.textMuted)
    info:SetPoint("TOPLEFT", PADDING, y)
    info:SetPoint("RIGHT", content, "RIGHT", -PADDING, 0)
    info:SetJustifyH("LEFT")
    y = y - 28
    
    if db and db.viewers then
        local essentialViewer = db.viewers.EssentialCooldownViewer
        local utilityViewer = db.viewers.UtilityCooldownViewer
        
        -- =====================================================
        -- ESSENTIAL KEYBIND DISPLAY
        -- =====================================================
        local essentialHeader = GUI:CreateSectionHeader(content, "ESSENTIAL KEYBIND DISPLAY")
        essentialHeader:SetPoint("TOPLEFT", PADDING, y)
        y = y - essentialHeader.gap

        local essentialShowCheck = GUI:CreateFormCheckbox(content, "Show Keybinds", "showKeybinds", essentialViewer, RefreshKeybinds)
        essentialShowCheck:SetPoint("TOPLEFT", PADDING, y)
        essentialShowCheck:SetPoint("RIGHT", content, "RIGHT", -PADDING, 0)
        y = y - FORM_ROW

        local anchorOptions = {
            { value = "TOPLEFT", text = "Top Left" },
            { value = "TOPRIGHT", text = "Top Right" },
            { value = "BOTTOMLEFT", text = "Bottom Left" },
            { value = "BOTTOMRIGHT", text = "Bottom Right" },
            { value = "CENTER", text = "Center" },
        }
        local essentialAnchor = GUI:CreateFormDropdown(content, "Keybind Anchor", anchorOptions, "keybindAnchor", essentialViewer, RefreshKeybinds)
        essentialAnchor:SetPoint("TOPLEFT", PADDING, y)
        essentialAnchor:SetPoint("RIGHT", content, "RIGHT", -PADDING, 0)
        y = y - FORM_ROW

        local essentialSizeSlider = GUI:CreateFormSlider(content, "Keybind Text Size", 6, 18, 1, "keybindTextSize", essentialViewer, RefreshKeybinds)
        essentialSizeSlider:SetPoint("TOPLEFT", PADDING, y)
        essentialSizeSlider:SetPoint("RIGHT", content, "RIGHT", -PADDING, 0)
        y = y - FORM_ROW

        local essentialColorPicker = GUI:CreateFormColorPicker(content, "Keybind Text Color", "keybindTextColor", essentialViewer, RefreshKeybinds)
        essentialColorPicker:SetPoint("TOPLEFT", PADDING, y)
        essentialColorPicker:SetPoint("RIGHT", content, "RIGHT", -PADDING, 0)
        y = y - FORM_ROW

        local essentialOffsetXSlider = GUI:CreateFormSlider(content, "Horizontal Offset", -20, 20, 1, "keybindOffsetX", essentialViewer, RefreshKeybinds)
        essentialOffsetXSlider:SetPoint("TOPLEFT", PADDING, y)
        essentialOffsetXSlider:SetPoint("RIGHT", content, "RIGHT", -PADDING, 0)
        y = y - FORM_ROW

        local essentialOffsetYSlider = GUI:CreateFormSlider(content, "Vertical Offset", -20, 20, 1, "keybindOffsetY", essentialViewer, RefreshKeybinds)
        essentialOffsetYSlider:SetPoint("TOPLEFT", PADDING, y)
        essentialOffsetYSlider:SetPoint("RIGHT", content, "RIGHT", -PADDING, 0)
        y = y - FORM_ROW
        
        -- =====================================================
        -- UTILITY KEYBIND DISPLAY
        -- =====================================================
        y = y - 10 -- Section spacing
        local utilityHeader = GUI:CreateSectionHeader(content, "UTILITY KEYBIND DISPLAY")
        utilityHeader:SetPoint("TOPLEFT", PADDING, y)
        y = y - utilityHeader.gap

        local utilityShowCheck = GUI:CreateFormCheckbox(content, "Show Keybinds", "showKeybinds", utilityViewer, RefreshKeybinds)
        utilityShowCheck:SetPoint("TOPLEFT", PADDING, y)
        utilityShowCheck:SetPoint("RIGHT", content, "RIGHT", -PADDING, 0)
        y = y - FORM_ROW

        local utilityAnchor = GUI:CreateFormDropdown(content, "Keybind Anchor", anchorOptions, "keybindAnchor", utilityViewer, RefreshKeybinds)
        utilityAnchor:SetPoint("TOPLEFT", PADDING, y)
        utilityAnchor:SetPoint("RIGHT", content, "RIGHT", -PADDING, 0)
        y = y - FORM_ROW

        local utilitySizeSlider = GUI:CreateFormSlider(content, "Keybind Text Size", 6, 18, 1, "keybindTextSize", utilityViewer, RefreshKeybinds)
        utilitySizeSlider:SetPoint("TOPLEFT", PADDING, y)
        utilitySizeSlider:SetPoint("RIGHT", content, "RIGHT", -PADDING, 0)
        y = y - FORM_ROW

        local utilityColorPicker = GUI:CreateFormColorPicker(content, "Keybind Text Color", "keybindTextColor", utilityViewer, RefreshKeybinds)
        utilityColorPicker:SetPoint("TOPLEFT", PADDING, y)
        utilityColorPicker:SetPoint("RIGHT", content, "RIGHT", -PADDING, 0)
        y = y - FORM_ROW

        local utilityOffsetXSlider = GUI:CreateFormSlider(content, "Horizontal Offset", -20, 20, 1, "keybindOffsetX", utilityViewer, RefreshKeybinds)
        utilityOffsetXSlider:SetPoint("TOPLEFT", PADDING, y)
        utilityOffsetXSlider:SetPoint("RIGHT", content, "RIGHT", -PADDING, 0)
        y = y - FORM_ROW

        local utilityOffsetYSlider = GUI:CreateFormSlider(content, "Vertical Offset", -20, 20, 1, "keybindOffsetY", utilityViewer, RefreshKeybinds)
        utilityOffsetYSlider:SetPoint("TOPLEFT", PADDING, y)
        utilityOffsetYSlider:SetPoint("RIGHT", content, "RIGHT", -PADDING, 0)
        y = y - FORM_ROW
        
        -- =====================================================
        -- CUSTOM TRACKER KEYBIND DISPLAYS
        -- =====================================================
        y = y - 10 -- Section spacing
        local ctKeybindHeader = GUI:CreateSectionHeader(content, "CUSTOM TRACKER KEYBIND DISPLAYS")
        ctKeybindHeader:SetPoint("TOPLEFT", PADDING, y)
        y = y - ctKeybindHeader.gap

        local ctKeybindInfo = GUI:CreateLabel(content, "Shows keybinds on Custom Item/Spell bar icons. Settings apply globally to all custom tracker bars.", 11, C.textMuted)
        ctKeybindInfo:SetPoint("TOPLEFT", PADDING, y)
        ctKeybindInfo:SetPoint("RIGHT", content, "RIGHT", -PADDING, 0)
        ctKeybindInfo:SetJustifyH("LEFT")
        y = y - 28

        -- Get custom tracker keybind settings from DB
        local ctKeybindDB = db and db.customTrackers and db.customTrackers.keybinds
        if not ctKeybindDB and db and db.customTrackers then
            -- Initialize defaults if missing
            db.customTrackers.keybinds = {
                showKeybinds = false,
                keybindTextSize = 10,
                keybindTextColor = { 1, 0.82, 0, 1 },
                keybindOffsetX = 2,
                keybindOffsetY = -2,
            }
            ctKeybindDB = db.customTrackers.keybinds
        end

        -- Refresh function for custom tracker keybinds
        local function RefreshCustomTrackerKeybinds()
            if _G.LuheyUI_RefreshCustomTrackerKeybinds then
                _G.LuheyUI_RefreshCustomTrackerKeybinds()
            end
        end

        if ctKeybindDB then
            local ctShowCheck = GUI:CreateFormCheckbox(content, "Show Keybinds", "showKeybinds", ctKeybindDB, RefreshCustomTrackerKeybinds)
            ctShowCheck:SetPoint("TOPLEFT", PADDING, y)
            ctShowCheck:SetPoint("RIGHT", content, "RIGHT", -PADDING, 0)
            y = y - FORM_ROW

            local ctSizeSlider = GUI:CreateFormSlider(content, "Keybind Text Size", 6, 18, 1, "keybindTextSize", ctKeybindDB, RefreshCustomTrackerKeybinds)
            ctSizeSlider:SetPoint("TOPLEFT", PADDING, y)
            ctSizeSlider:SetPoint("RIGHT", content, "RIGHT", -PADDING, 0)
            y = y - FORM_ROW

            local ctColorPicker = GUI:CreateFormColorPicker(content, "Keybind Text Color", "keybindTextColor", ctKeybindDB, RefreshCustomTrackerKeybinds)
            ctColorPicker:SetPoint("TOPLEFT", PADDING, y)
            ctColorPicker:SetPoint("RIGHT", content, "RIGHT", -PADDING, 0)
            y = y - FORM_ROW

            local ctOffsetXSlider = GUI:CreateFormSlider(content, "Horizontal Offset", -20, 20, 1, "keybindOffsetX", ctKeybindDB, RefreshCustomTrackerKeybinds)
            ctOffsetXSlider:SetPoint("TOPLEFT", PADDING, y)
            ctOffsetXSlider:SetPoint("RIGHT", content, "RIGHT", -PADDING, 0)
            y = y - FORM_ROW

            local ctOffsetYSlider = GUI:CreateFormSlider(content, "Vertical Offset", -20, 20, 1, "keybindOffsetY", ctKeybindDB, RefreshCustomTrackerKeybinds)
            ctOffsetYSlider:SetPoint("TOPLEFT", PADDING, y)
            ctOffsetYSlider:SetPoint("RIGHT", content, "RIGHT", -PADDING, 0)
            y = y - FORM_ROW
        end

        -- =====================================================
        -- ROTATION HELPER OVERLAY
        -- =====================================================
        y = y - 10 -- Section spacing
        local rotationHeader = GUI:CreateSectionHeader(content, "ROTATION HELPER OVERLAY")
        rotationHeader:SetPoint("TOPLEFT", PADDING, y)
        y = y - rotationHeader.gap

        local rotationInfo = GUI:CreateLabel(content, "Shows a border on the CDM icon recommended by Blizzard's Assisted Combat (Starter Build). Requires 'Starter Build' to be enabled in Game Menu > Options > Gameplay > Combat.", 11, C.textMuted)
        rotationInfo:SetPoint("TOPLEFT", PADDING, y)
        rotationInfo:SetPoint("RIGHT", content, "RIGHT", -PADDING, 0)
        rotationInfo:SetJustifyH("LEFT")
        y = y - 38

        local essentialRotationCheck = GUI:CreateFormCheckbox(content, "Show on Essential CDM", "showRotationHelper", essentialViewer, RefreshRotationHelper)
        essentialRotationCheck:SetPoint("TOPLEFT", PADDING, y)
        essentialRotationCheck:SetPoint("RIGHT", content, "RIGHT", -PADDING, 0)
        y = y - FORM_ROW

        local utilityRotationCheck = GUI:CreateFormCheckbox(content, "Show on Utility CDM", "showRotationHelper", utilityViewer, RefreshRotationHelper)
        utilityRotationCheck:SetPoint("TOPLEFT", PADDING, y)
        utilityRotationCheck:SetPoint("RIGHT", content, "RIGHT", -PADDING, 0)
        y = y - FORM_ROW

        local essentialRotationColor = GUI:CreateFormColorPicker(content, "Essential Border Color", "rotationHelperColor", essentialViewer, RefreshRotationHelper)
        essentialRotationColor:SetPoint("TOPLEFT", PADDING, y)
        essentialRotationColor:SetPoint("RIGHT", content, "RIGHT", -PADDING, 0)
        y = y - FORM_ROW

        local utilityRotationColor = GUI:CreateFormColorPicker(content, "Utility Border Color", "rotationHelperColor", utilityViewer, RefreshRotationHelper)
        utilityRotationColor:SetPoint("TOPLEFT", PADDING, y)
        utilityRotationColor:SetPoint("RIGHT", content, "RIGHT", -PADDING, 0)
        y = y - FORM_ROW

        local essentialThicknessSlider = GUI:CreateFormSlider(content, "Essential Border Thickness", 1, 6, 1, "rotationHelperThickness", essentialViewer, RefreshRotationHelper)
        essentialThicknessSlider:SetPoint("TOPLEFT", PADDING, y)
        essentialThicknessSlider:SetPoint("RIGHT", content, "RIGHT", -PADDING, 0)
        y = y - FORM_ROW

        local utilityThicknessSlider = GUI:CreateFormSlider(content, "Utility Border Thickness", 1, 6, 1, "rotationHelperThickness", utilityViewer, RefreshRotationHelper)
        utilityThicknessSlider:SetPoint("TOPLEFT", PADDING, y)
        utilityThicknessSlider:SetPoint("RIGHT", content, "RIGHT", -PADDING, 0)
        y = y - FORM_ROW

        -- =====================================================
        -- ROTATION ASSIST ICON
        -- =====================================================
        y = y - 10 -- Extra spacing
        local raiHeader = GUI:CreateSectionHeader(content, "ROTATION ASSIST ICON")
        raiHeader:SetPoint("TOPLEFT", PADDING, y)
        y = y - raiHeader.gap

        -- Get rotation assist icon DB
        local raiDB = db and db.rotationAssistIcon

        -- Refresh function
        local function RefreshRAI()
            if _G.LuheyUI_RefreshRotationAssistIcon then
                _G.LuheyUI_RefreshRotationAssistIcon()
            end
        end

        if raiDB then
            -- Form layout constants
            local FORM_ROW = 32  -- Height per form row

            -- Info text
            local raiInfo = GUI:CreateLabel(content, "Displays a standalone movable icon showing Blizzard's next recommended ability.", 11, C.textMuted)
            raiInfo:SetPoint("TOPLEFT", PADDING, y)
            y = y - 18

            local raiInfo2 = GUI:CreateLabel(content, "Requires 'Starter Build' to be enabled in Game Menu > Options > Gameplay > Combat.", 11, C.textMuted)
            raiInfo2:SetPoint("TOPLEFT", PADDING, y)
            y = y - 30

            -- Form rows (label on left, widget on right)
            local raiEnable = GUI:CreateFormCheckbox(content, "Enable", "enabled", raiDB, RefreshRAI)
            raiEnable:SetPoint("TOPLEFT", PADDING, y)
            raiEnable:SetPoint("RIGHT", content, "RIGHT", -PADDING, 0)
            y = y - FORM_ROW

            local raiLock = GUI:CreateFormCheckbox(content, "Lock Position", "isLocked", raiDB, RefreshRAI)
            raiLock:SetPoint("TOPLEFT", PADDING, y)
            raiLock:SetPoint("RIGHT", content, "RIGHT", -PADDING, 0)
            y = y - FORM_ROW

            local raiSwipe = GUI:CreateFormCheckbox(content, "Cooldown Swipe", "cooldownSwipeEnabled", raiDB, RefreshRAI)
            raiSwipe:SetPoint("TOPLEFT", PADDING, y)
            raiSwipe:SetPoint("RIGHT", content, "RIGHT", -PADDING, 0)
            y = y - FORM_ROW

            local visibilityOptions = {
                { value = "always", text = "Always" },
                { value = "combat", text = "In Combat" },
                { value = "hostile", text = "Hostile Target" },
            }
            local raiVisibility = GUI:CreateFormDropdown(content, "Visibility", visibilityOptions, "visibility", raiDB, RefreshRAI)
            raiVisibility:SetPoint("TOPLEFT", PADDING, y)
            raiVisibility:SetPoint("RIGHT", content, "RIGHT", -PADDING, 0)
            y = y - FORM_ROW

            local strataOptions = {
                { value = "LOW", text = "Low" },
                { value = "MEDIUM", text = "Medium" },
                { value = "HIGH", text = "High" },
                { value = "DIALOG", text = "Dialog" },
            }
            local raiStrata = GUI:CreateFormDropdown(content, "Frame Strata", strataOptions, "frameStrata", raiDB, RefreshRAI)
            raiStrata:SetPoint("TOPLEFT", PADDING, y)
            raiStrata:SetPoint("RIGHT", content, "RIGHT", -PADDING, 0)
            y = y - FORM_ROW

            local raiSize = GUI:CreateFormSlider(content, "Icon Size", 16, 400, 1, "iconSize", raiDB, RefreshRAI)
            raiSize:SetPoint("TOPLEFT", PADDING, y)
            raiSize:SetPoint("RIGHT", content, "RIGHT", -PADDING, 0)
            y = y - FORM_ROW

            local raiBorderWidth = GUI:CreateFormSlider(content, "Border Size", 0, 15, 1, "borderThickness", raiDB, RefreshRAI)
            raiBorderWidth:SetPoint("TOPLEFT", PADDING, y)
            raiBorderWidth:SetPoint("RIGHT", content, "RIGHT", -PADDING, 0)
            y = y - FORM_ROW

            local raiBorderColor = GUI:CreateFormColorPicker(content, "Border Color", "borderColor", raiDB, RefreshRAI)
            raiBorderColor:SetPoint("TOPLEFT", PADDING, y)
            raiBorderColor:SetPoint("RIGHT", content, "RIGHT", -PADDING, 0)
            y = y - FORM_ROW

            local raiKeybindShow = GUI:CreateFormCheckbox(content, "Show Keybind", "showKeybind", raiDB, RefreshRAI)
            raiKeybindShow:SetPoint("TOPLEFT", PADDING, y)
            raiKeybindShow:SetPoint("RIGHT", content, "RIGHT", -PADDING, 0)
            y = y - FORM_ROW

            local raiFontColor = GUI:CreateFormColorPicker(content, "Keybind Color", "keybindColor", raiDB, RefreshRAI)
            raiFontColor:SetPoint("TOPLEFT", PADDING, y)
            raiFontColor:SetPoint("RIGHT", content, "RIGHT", -PADDING, 0)
            y = y - FORM_ROW

            local anchorOptions = {
                { value = "TOPLEFT", text = "Top Left" },
                { value = "TOPRIGHT", text = "Top Right" },
                { value = "BOTTOMLEFT", text = "Bottom Left" },
                { value = "BOTTOMRIGHT", text = "Bottom Right" },
                { value = "CENTER", text = "Center" },
            }
            local raiAnchor = GUI:CreateFormDropdown(content, "Keybind Anchor", anchorOptions, "keybindAnchor", raiDB, RefreshRAI)
            raiAnchor:SetPoint("TOPLEFT", PADDING, y)
            raiAnchor:SetPoint("RIGHT", content, "RIGHT", -PADDING, 0)
            y = y - FORM_ROW

            local raiFontSize = GUI:CreateFormSlider(content, "Keybind Size", 6, 48, 1, "keybindSize", raiDB, RefreshRAI)
            raiFontSize:SetPoint("TOPLEFT", PADDING, y)
            raiFontSize:SetPoint("RIGHT", content, "RIGHT", -PADDING, 0)
            y = y - FORM_ROW

            local raiOffsetX = GUI:CreateFormSlider(content, "Keybind X Offset", -50, 50, 1, "keybindOffsetX", raiDB, RefreshRAI)
            raiOffsetX:SetPoint("TOPLEFT", PADDING, y)
            raiOffsetX:SetPoint("RIGHT", content, "RIGHT", -PADDING, 0)
            y = y - FORM_ROW

            local raiOffsetY = GUI:CreateFormSlider(content, "Keybind Y Offset", -50, 50, 1, "keybindOffsetY", raiDB, RefreshRAI)
            raiOffsetY:SetPoint("TOPLEFT", PADDING, y)
            raiOffsetY:SetPoint("RIGHT", content, "RIGHT", -PADDING, 0)
            y = y - FORM_ROW
        else
            local noRAILabel = GUI:CreateLabel(content, "Rotation Assist Icon settings not available - database not loaded", 12, C.textMuted)
            noRAILabel:SetPoint("TOPLEFT", PADDING, y)
            y = y - ROW_GAP
        end
    else
        y = y - 10
        local noDataLabel = GUI:CreateLabel(content, "Keybind settings not available - database not loaded", 12, C.textMuted)
        noDataLabel:SetPoint("TOPLEFT", PADDING, y)
    end
    
    content:SetHeight(math.abs(y) + 50)
end

---------------------------------------------------------------------------
-- PAGE: Custom Trackers (Consumables, Trinkets, Custom Spells)
-- Tab-per-bar layout with form widgets
---------------------------------------------------------------------------

-- Refresh callback for Custom Trackers
local function RefreshCustomTrackers()
    if LUICore and LUICore.CustomTrackers then
        LUICore.CustomTrackers:RefreshAll()
    end
end

-- Refresh bar position when anchor settings change
local function RefreshTrackerPosition(barID)
    if LUICore and LUICore.CustomTrackers then
        LUICore.CustomTrackers:RefreshBarPosition(barID)
    end
end

local function CreateCustomTrackersPage(parent)
    local scroll, content = CreateScrollableContent(parent)
    local db = GetDB()

    -- Set search context for auto-registration
    GUI:SetSearchContext({tabIndex = 9, tabName = "Custom Items/Spells/Buffs"})

    -- Ensure customTrackers.bars exists
    if not db.customTrackers then
        db.customTrackers = {bars = {}}
    end
    if not db.customTrackers.bars then
        db.customTrackers.bars = {}
    end

    local bars = db.customTrackers.bars
    local PAD = 10
    local FORM_ROW = 32

    ---------------------------------------------------------------------------
    -- Helper: Calculate offset relative to LUI_Player frame's top-left corner
    -- Returns screen-center offsets that position a bar relative to player frame
    ---------------------------------------------------------------------------
    local function CalculatePlayerRelativeOffset(playerOffsetX, playerOffsetY)
        local playerFrame = _G.LUI_Player
        if not playerFrame then
            -- Fallback: use default screen-center offsets
            return -406, -152
        end

        local screenCenterX, screenCenterY = UIParent:GetCenter()
        local playerLeft = playerFrame:GetLeft()
        local playerTop = playerFrame:GetTop()

        if not (screenCenterX and screenCenterY and playerLeft and playerTop) then
            return -406, -152
        end

        -- Bar position = player top-left + desired offset
        local barCenterX = playerLeft + playerOffsetX
        local barCenterY = playerTop + playerOffsetY

        -- Convert to screen-center offsets
        local offsetX = math.floor(barCenterX - screenCenterX + 0.5)
        local offsetY = math.floor(barCenterY - screenCenterY + 0.5)

        return offsetX, offsetY
    end

    ---------------------------------------------------------------------------
    -- Helper: Create drop zone for adding items/spells via drag-and-drop
    ---------------------------------------------------------------------------
    local function CreateAddEntrySection(parentFrame, barID, refreshCallback)
        local container = CreateFrame("Frame", nil, parentFrame)
        container:SetHeight(83)  -- 50% taller than original 55

        -- DROP ZONE: Click here while holding an item/spell on cursor
        local dropZone = CreateFrame("Button", nil, container, "BackdropTemplate")
        dropZone:SetHeight(68)  -- 50% taller than original 45
        dropZone:SetPoint("TOPLEFT", 0, 0)
        dropZone:SetPoint("RIGHT", container, "RIGHT", 0, 0)  -- Full width
        dropZone:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        dropZone:SetBackdropColor(C.bg[1], C.bg[2], C.bg[3], 0.8)
        dropZone:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 0.5)

        local dropLabel = dropZone:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        dropLabel:SetPoint("CENTER", 0, 0)
        dropLabel:SetText("Drop Items or Spells here")
        dropLabel:SetTextColor(C.textMuted[1], C.textMuted[2], C.textMuted[3], 1)

        -- Handle drop on mouse release (OnReceiveDrag fires when releasing with item on cursor)
        dropZone:SetScript("OnReceiveDrag", function(self)
            local cursorType, id1, id2, id3, id4 = GetCursorInfo()
            if cursorType == "item" then
                local itemID = id1
                if itemID then
                    local trackerModule = QUI and QUI.LUICore and QUI.LUICore.CustomTrackers
                    if trackerModule then
                        trackerModule:AddEntry(barID, "item", itemID)
                        ClearCursor()
                        if refreshCallback then refreshCallback() end
                    end
                end
            elseif cursorType == "spell" then
                -- id1 is slot index, id2 is bookType ("spell" or "pet")
                -- Need to look up actual spellID from spellbook
                local slotIndex = id1
                local bookType = id2 or "spell"
                local spellID = id4  -- Try direct spellID first (older API)

                -- If no direct spellID, look it up from spellbook
                if not spellID and slotIndex then
                    local spellBank = (bookType == "pet") and Enum.SpellBookSpellBank.Pet or Enum.SpellBookSpellBank.Player
                    local spellBookInfo = C_SpellBook.GetSpellBookItemInfo(slotIndex, spellBank)
                    if spellBookInfo then
                        spellID = spellBookInfo.spellID
                    end
                end

                -- Resolve override spell (talents that replace base spells)
                if spellID then
                    local overrideID = C_Spell.GetOverrideSpell(spellID)
                    if overrideID and overrideID ~= spellID then
                        spellID = overrideID
                    end
                end

                if spellID then
                    local trackerModule = QUI and QUI.LUICore and QUI.LUICore.CustomTrackers
                    if trackerModule then
                        trackerModule:AddEntry(barID, "spell", spellID)
                        ClearCursor()
                        if refreshCallback then refreshCallback() end
                    end
                end
            end
        end)

        -- Also handle OnMouseUp as fallback (some drag modes use this)
        dropZone:SetScript("OnMouseUp", function(self)
            local cursorType = GetCursorInfo()
            if cursorType == "item" or cursorType == "spell" then
                -- Trigger the same logic as OnReceiveDrag
                local handler = dropZone:GetScript("OnReceiveDrag")
                if handler then handler(self) end
            end
        end)

        -- Highlight on hover when cursor has item/spell
        dropZone:SetScript("OnEnter", function(self)
            local cursorType = GetCursorInfo()
            if cursorType == "item" or cursorType == "spell" then
                self:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 1)
                dropLabel:SetTextColor(C.accent[1], C.accent[2], C.accent[3], 1)
            end
        end)
        dropZone:SetScript("OnLeave", function(self)
            self:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 0.5)
            dropLabel:SetTextColor(C.textMuted[1], C.textMuted[2], C.textMuted[3], 1)
        end)

        return container
    end

    -- Helper: Get entry display name (prefers customName if set)
    local function GetEntryDisplayName(entry)
        -- Use custom name if set
        if entry.customName and entry.customName ~= "" then
            return entry.customName
        end
        -- Otherwise, auto-detect from spell/item info
        if entry.type == "spell" then
            local info = C_Spell.GetSpellInfo(entry.id)
            return info and info.name or ("Spell " .. entry.id)
        else
            local name = C_Item.GetItemInfo(entry.id)
            return name or ("Item " .. entry.id)
        end
    end

    ---------------------------------------------------------------------------
    -- Build tab content for a single tracker bar
    ---------------------------------------------------------------------------
    local function BuildTrackerBarTab(tabContent, barConfig, barIndex, subTabsRef)
        GUI:SetSearchContext({tabIndex = 9, tabName = "Custom Items/Spells/Buffs", subTabIndex = barIndex + 1, subTabName = barConfig.name or ("Bar " .. barIndex)})
        local y = -10
        local entryListFrame  -- Forward declaration for refresh callback

        -- Refresh callback for this bar
        local function RefreshThisBar()
            if LUICore and LUICore.CustomTrackers then
                LUICore.CustomTrackers:UpdateBar(barConfig.id)
            end
        end

        -- Refresh position callback
        local function RefreshPosition()
            RefreshTrackerPosition(barConfig.id)
        end

        -----------------------------------------------------------------------
        -- GENERAL SECTION
        -----------------------------------------------------------------------
        local generalHeader = GUI:CreateSectionHeader(tabContent, "General")
        generalHeader:SetPoint("TOPLEFT", PAD, y)
        y = y - generalHeader.gap

        local generalHint = GUI:CreateLabel(tabContent, "Reminder: Enable this bar, else nothing will show. If you are deleting the ONLY remaining bar, it would just restore the original 'Trinket & Pot' bar that is disabled by default.", 11, C.textMuted)
        generalHint:SetPoint("TOPLEFT", PAD, y)
        generalHint:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        generalHint:SetJustifyH("LEFT")
        generalHint:SetWordWrap(true)
        generalHint:SetHeight(30)
        y = y - 40

        -- Enable Bar
        local enableCheck = GUI:CreateFormCheckbox(tabContent, "Enable Bar", "enabled", barConfig, RefreshThisBar)
        enableCheck:SetPoint("TOPLEFT", PAD, y)
        enableCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        -- Bar Name (editable, updates tab text instantly)
        local nameContainer = CreateFrame("Frame", nil, tabContent)
        nameContainer:SetHeight(FORM_ROW)
        nameContainer:SetPoint("TOPLEFT", PAD, y)
        nameContainer:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)

        local nameLabel = nameContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        nameLabel:SetPoint("LEFT", 0, 0)
        nameLabel:SetText("Bar Name")
        nameLabel:SetTextColor(C.text[1], C.text[2], C.text[3], 1)

        -- Custom styled editbox (matches QUI dropdown styling)
        local nameInputBg = CreateFrame("Frame", nil, nameContainer, "BackdropTemplate")
        nameInputBg:SetPoint("LEFT", nameContainer, "LEFT", 180, 0)
        nameInputBg:SetSize(200, 24)
        nameInputBg:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        nameInputBg:SetBackdropColor(0.08, 0.08, 0.08, 1)
        nameInputBg:SetBackdropBorderColor(0.35, 0.35, 0.35, 1)

        local nameInput = CreateFrame("EditBox", nil, nameInputBg)
        nameInput:SetPoint("LEFT", 8, 0)
        nameInput:SetPoint("RIGHT", -8, 0)
        nameInput:SetHeight(22)
        nameInput:SetAutoFocus(false)
        nameInput:SetFont(GUI.FONT_PATH, 11, "")
        nameInput:SetTextColor(C.text[1], C.text[2], C.text[3], 1)
        nameInput:SetText(barConfig.name or "Tracker")
        nameInput:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
        nameInput:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
        nameInput:SetScript("OnEditFocusGained", function()
            nameInputBg:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 1)
        end)
        nameInput:SetScript("OnEditFocusLost", function()
            nameInputBg:SetBackdropBorderColor(0.35, 0.35, 0.35, 1)
        end)
        nameInput:SetScript("OnTextChanged", function(self)
            local newName = self:GetText()
            if newName == "" then newName = "Tracker" end
            barConfig.name = newName

            -- Update sub-tab text instantly
            if subTabsRef and subTabsRef.tabButtons and subTabsRef.tabButtons[barIndex] then
                local displayName = newName
                if #displayName > 20 then
                    displayName = displayName:sub(1, 17) .. "..."
                end
                subTabsRef.tabButtons[barIndex].text:SetText(displayName)
            end
        end)
        y = y - FORM_ROW

        -- Delete Bar button
        y = y - 10
        local deleteBtn = GUI:CreateButton(tabContent, "Delete Bar", 120, 26, function()
            GUI:ShowConfirmation({
                title = "Delete Tracker Bar?",
                message = "Delete this tracker bar?",
                warningText = "This cannot be undone.",
                acceptText = "Delete",
                cancelText = "Cancel",
                isDestructive = true,
                onAccept = function()
                    -- Remove from DB
                    for i, bc in ipairs(db.customTrackers.bars) do
                        if bc.id == barConfig.id then
                            table.remove(db.customTrackers.bars, i)
                            break
                        end
                    end
                    -- Delete the active bar frame
                    if LUICore and LUICore.CustomTrackers then
                        LUICore.CustomTrackers:DeleteBar(barConfig.id)
                    end
                    -- Prompt reload to rebuild tabs
                    GUI:ShowConfirmation({
                        title = "Reload UI?",
                        message = "Tracker deleted. Reload UI to see changes?",
                        acceptText = "Reload",
                        cancelText = "Later",
                onAccept = function() LuheyUI:SafeReload() end,
                    })
                end,
            })
        end)
        deleteBtn:SetPoint("TOPLEFT", PAD, y)
        deleteBtn:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - 36

        -----------------------------------------------------------------------
        -- ADD ITEMS/SPELLS SECTION (moved up for better UX flow)
        -----------------------------------------------------------------------
        local addHeader = GUI:CreateSectionHeader(tabContent, "Add Trinkets/Consumables/Spells")
        addHeader:SetPoint("TOPLEFT", PAD, y)
        y = y - addHeader.gap

        -- Forward declarations for spec-specific helpers (needed by RefreshEntryList)
        local specInfoLabel = nil
        local copyFromDropdown = nil

        -- Get tracker module reference
        local trackerModule = LUICore and LUICore.CustomTrackers

        -- Helper to get current spec key (always uses actual current spec)
        local function getCurrentSpecKey()
            -- Use tracker module's helper if available
            if trackerModule and trackerModule.GetCurrentSpecKey then
                return trackerModule.GetCurrentSpecKey()
            end
            -- Fallback
            local _, className = UnitClass("player")
            local specIndex = GetSpecialization()
            if specIndex then
                local specID = GetSpecializationInfo(specIndex)
                if specID and className then
                    return className .. "-" .. specID
                end
            end
            return nil
        end

        -- Helper to get readable spec name
        local function getSpecDisplayName(specKey)
            if trackerModule and trackerModule.GetClassSpecName then
                return trackerModule.GetClassSpecName(specKey)
            end
            return specKey or "Unknown"
        end

        -- Update info label
        local function updateSpecInfoLabel()
            if specInfoLabel then
                if barConfig.specSpecificSpells then
                    local specKey = getCurrentSpecKey()
                    specInfoLabel:SetText("Currently editing: " .. getSpecDisplayName(specKey))
                    specInfoLabel:Show()
                else
                    specInfoLabel:Hide()
                end
            end
        end

        -- Refresh entry list when spec changes
        local function refreshForSpec()
            RefreshThisBar()
            updateSpecInfoLabel()
            -- Note: Entry list refresh is handled by entryListFrame recreation
        end

        local hintText = GUI:CreateLabel(tabContent, "Drag items from your bags or character pane, spells from your spellbook into the box below.", 11, C.textMuted)
        hintText:SetPoint("TOPLEFT", addHeader, "BOTTOMLEFT", 0, -8)
        hintText:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        hintText:SetJustifyH("LEFT")
        hintText:SetWordWrap(true)
        hintText:SetHeight(30)

        -- Function to refresh entry list (defined later, used in add section)
        local function RefreshEntryList()
            if not entryListFrame then return end
            -- Clear existing children
            for _, child in ipairs({entryListFrame:GetChildren()}) do
                child:Hide()
                child:SetParent(nil)
            end

            -- Use GetBarEntries for spec-aware loading (always uses current spec)
            local entries
            local trackerMod = LUICore and LUICore.CustomTrackers
            if trackerMod and trackerMod.GetBarEntries then
                -- Pass nil to use current spec
                entries = trackerMod.GetBarEntries(barConfig, nil)
            else
                entries = barConfig.entries or {}
            end
            local listY = 0
            for j, entry in ipairs(entries) do
                local entryFrame = CreateFrame("Frame", nil, entryListFrame)
                entryFrame:SetSize(320, 28)
                entryFrame:SetPoint("TOPLEFT", 0, listY)

                -- Icon
                local iconTex = entryFrame:CreateTexture(nil, "ARTWORK")
                iconTex:SetSize(24, 24)
                iconTex:SetPoint("LEFT", 0, 0)
                if entry.type == "spell" then
                    local info = C_Spell.GetSpellInfo(entry.id)
                    iconTex:SetTexture(info and info.iconID or "Interface\\Icons\\INV_Misc_QuestionMark")
                else
                    local _, _, _, _, _, _, _, _, _, icon = C_Item.GetItemInfo(entry.id)
                    iconTex:SetTexture(icon or "Interface\\Icons\\INV_Misc_QuestionMark")
                end
                iconTex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
                entryFrame.iconTex = iconTex  -- Store reference for name resolution

                -- Name (editable input box with subtle styling)
                local nameInputBg = CreateFrame("Frame", nil, entryFrame, "BackdropTemplate")
                nameInputBg:SetPoint("LEFT", iconTex, "RIGHT", 6, 0)
                nameInputBg:SetSize(176, 22)
                nameInputBg:SetBackdrop({
                    bgFile = "Interface\\Buttons\\WHITE8x8",
                    edgeFile = "Interface\\Buttons\\WHITE8x8",
                    edgeSize = 1,
                })
                nameInputBg:SetBackdropColor(0.05, 0.05, 0.05, 0.4)
                nameInputBg:SetBackdropBorderColor(0.25, 0.25, 0.25, 0.6)

                local nameInput = CreateFrame("EditBox", nil, nameInputBg)
                nameInput:SetPoint("LEFT", 6, 0)
                nameInput:SetPoint("RIGHT", -6, 0)
                nameInput:SetHeight(20)
                nameInput:SetAutoFocus(false)
                nameInput:SetFont(GUI.FONT_PATH, 11, "")
                nameInput:SetTextColor(C.text[1], C.text[2], C.text[3], 1)
                nameInput:SetText(GetEntryDisplayName(entry))
                nameInput:SetCursorPosition(0)

                -- Store reference to entry for saving
                nameInput.entry = entry
                nameInput.barConfig = barConfig

                nameInput:SetScript("OnEscapePressed", function(self)
                    self:SetText(GetEntryDisplayName(self.entry))
                    self:ClearFocus()
                end)

                -- Helper to resolve name to spell/item and update entry
                local function ResolveAndUpdateEntry(self)
                    local newName = self:GetText()
                    if newName == "" then
                        -- Clear custom name to restore auto-detected
                        self.entry.customName = nil
                        self:SetText(GetEntryDisplayName(self.entry))
                        return
                    end

                    local currentName = GetEntryDisplayName(self.entry)
                    if newName == currentName then
                        -- No change, don't process
                        return
                    end

                    -- Try to resolve the name to a spell/item ID
                    local resolved = false

                    if self.entry.type == "spell" then
                        -- Try to look up spell by name using C_Spell API
                        local newSpellID = C_Spell.GetSpellIDForSpellIdentifier(newName)
                        if newSpellID then
                            -- Found the spell - update the entry ID
                            self.entry.id = newSpellID
                            self.entry.customName = nil  -- Clear custom name since we resolved
                            resolved = true
                            -- Refresh the bar to use new spell
                            if LUICore and LUICore.CustomTrackers then
                                LUICore.CustomTrackers:UpdateBar(self.barConfig.id)
                            end
                            -- Update display to show resolved name
                            self:SetText(GetEntryDisplayName(self.entry))
                            -- Update icon
                            local iconTexRef = self:GetParent():GetParent().iconTex
                            if iconTexRef then
                                local info = C_Spell.GetSpellInfo(newSpellID)
                                if info and info.iconID then
                                    iconTexRef:SetTexture(info.iconID)
                                end
                            end
                        end
                    elseif self.entry.type == "item" then
                        -- Try to look up item by name
                        local newItemID = C_Item.GetItemIDForItemInfo(newName)
                        if newItemID then
                            -- Found the item - update the entry ID
                            self.entry.id = newItemID
                            self.entry.customName = nil
                            resolved = true
                            -- Refresh the bar
                            if LUICore and LUICore.CustomTrackers then
                                LUICore.CustomTrackers:UpdateBar(self.barConfig.id)
                            end
                            -- Update display
                            self:SetText(GetEntryDisplayName(self.entry))
                            -- Update icon
                            local iconTexRef = self:GetParent():GetParent().iconTex
                            if iconTexRef then
                                local _, _, _, _, _, _, _, _, _, itemIcon = C_Item.GetItemInfo(newItemID)
                                if itemIcon then
                                    iconTexRef:SetTexture(itemIcon)
                                end
                            end
                        end
                    end

                    if not resolved then
                        -- Could not resolve - revert to original name
                        self:SetText(GetEntryDisplayName(self.entry))
                    end
                end

                nameInput:SetScript("OnEnterPressed", function(self)
                    ResolveAndUpdateEntry(self)
                    self:ClearFocus()
                end)
                nameInput:SetScript("OnEditFocusGained", function(self)
                    nameInputBg:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 1)
                    self:HighlightText()
                end)
                nameInput:SetScript("OnEditFocusLost", function(self)
                    nameInputBg:SetBackdropBorderColor(0.25, 0.25, 0.25, 0.6)
                    ResolveAndUpdateEntry(self)
                end)

                -- Store reference for button positioning
                local entryName = nameInputBg

                -- Helper: Create styled chevron button (matches dropdown style)
                local function CreateChevronButton(parent, direction, onClick)
                    local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
                    btn:SetSize(22, 22)
                    btn:SetBackdrop({
                        bgFile = "Interface\\Buttons\\WHITE8x8",
                        edgeFile = "Interface\\Buttons\\WHITE8x8",
                        edgeSize = 1,
                    })
                    btn:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
                    btn:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)

                    -- Chevron made of two rotated lines
                    local chevronLeft = btn:CreateTexture(nil, "OVERLAY")
                    chevronLeft:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 0.7)
                    chevronLeft:SetSize(6, 2)
                    local chevronRight = btn:CreateTexture(nil, "OVERLAY")
                    chevronRight:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 0.7)
                    chevronRight:SetSize(6, 2)

                    if direction == "up" then
                        chevronLeft:SetPoint("CENTER", btn, "CENTER", -2, 1)
                        chevronLeft:SetRotation(math.rad(45))
                        chevronRight:SetPoint("CENTER", btn, "CENTER", 2, 1)
                        chevronRight:SetRotation(math.rad(-45))
                    else
                        chevronLeft:SetPoint("CENTER", btn, "CENTER", -2, -1)
                        chevronLeft:SetRotation(math.rad(-45))
                        chevronRight:SetPoint("CENTER", btn, "CENTER", 2, -1)
                        chevronRight:SetRotation(math.rad(45))
                    end

                    btn.chevronLeft = chevronLeft
                    btn.chevronRight = chevronRight

                    btn:SetScript("OnEnter", function(self)
                        self:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 1)
                        self.chevronLeft:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 1)
                        self.chevronRight:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 1)
                    end)
                    btn:SetScript("OnLeave", function(self)
                        self:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
                        self.chevronLeft:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 0.7)
                        self.chevronRight:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 0.7)
                    end)
                    btn:SetScript("OnClick", onClick)

                    return btn
                end

                -- Move Up button (anchored after fixed-width name)
                local upBtn = CreateChevronButton(entryFrame, "up", function()
                    if LUICore and LUICore.CustomTrackers then
                        LUICore.CustomTrackers:MoveEntry(barConfig.id, j, -1, nil)
                    end
                    RefreshEntryList()
                end)
                upBtn:SetPoint("LEFT", entryName, "RIGHT", 8, 0)
                if j == 1 then
                    upBtn:SetAlpha(0.3)
                    upBtn:EnableMouse(false)
                end

                -- Move Down button
                local downBtn = CreateChevronButton(entryFrame, "down", function()
                    if LUICore and LUICore.CustomTrackers then
                        LUICore.CustomTrackers:MoveEntry(barConfig.id, j, 1, nil)
                    end
                    RefreshEntryList()
                end)
                downBtn:SetPoint("LEFT", upBtn, "RIGHT", 2, 0)
                if j == #entries then
                    downBtn:SetAlpha(0.3)
                    downBtn:EnableMouse(false)
                end

                -- Remove button (styled to match chevrons)
                local removeBtn = CreateFrame("Button", nil, entryFrame, "BackdropTemplate")
                removeBtn:SetSize(22, 22)
                removeBtn:SetBackdrop({
                    bgFile = "Interface\\Buttons\\WHITE8x8",
                    edgeFile = "Interface\\Buttons\\WHITE8x8",
                    edgeSize = 1,
                })
                removeBtn:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
                removeBtn:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
                local xText = removeBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                xText:SetPoint("CENTER", 0, 0)
                xText:SetText("X")
                xText:SetTextColor(C.accent[1], C.accent[2], C.accent[3], 0.7)
                removeBtn:SetScript("OnEnter", function(self)
                    self:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 1)
                    xText:SetTextColor(C.accent[1], C.accent[2], C.accent[3], 1)
                end)
                removeBtn:SetScript("OnLeave", function(self)
                    self:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
                    xText:SetTextColor(C.accent[1], C.accent[2], C.accent[3], 0.7)
                end)
                removeBtn:SetScript("OnClick", function()
                    if LUICore and LUICore.CustomTrackers then
                        LUICore.CustomTrackers:RemoveEntry(barConfig.id, entry.type, entry.id, nil)
                    end
                    RefreshEntryList()
                end)
                removeBtn:SetPoint("LEFT", downBtn, "RIGHT", 4, 0)

                listY = listY - 30
            end

            -- Update entry list frame height
            local listHeight = math.max(20, math.abs(listY))
            entryListFrame:SetHeight(listHeight)
        end

        -- Create add entry section (drop zone) - anchored to hintText
        local addSection = CreateAddEntrySection(tabContent, barConfig.id, RefreshEntryList)
        addSection:SetPoint("TOPLEFT", hintText, "BOTTOMLEFT", 0, -10)
        addSection:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)  -- Full width

        -----------------------------------------------------------------------
        -- TRACKED ITEMS SECTION
        -----------------------------------------------------------------------
        local trackedHeader = GUI:CreateSectionHeader(tabContent, "Tracked Items And Spells")
        trackedHeader:SetPoint("TOPLEFT", addSection, "BOTTOMLEFT", 0, -15)

        -- Entry list container
        entryListFrame = CreateFrame("Frame", nil, tabContent)
        entryListFrame:SetPoint("TOPLEFT", trackedHeader, "BOTTOMLEFT", 0, -8)
        entryListFrame:SetSize(400, 20)
        RefreshEntryList()

        -----------------------------------------------------------------------
        -- LOWER SECTIONS CONTAINER (anchored to entry list for dynamic positioning)
        -----------------------------------------------------------------------
        local lowerContainer = CreateFrame("Frame", nil, tabContent)
        lowerContainer:SetPoint("TOPLEFT", entryListFrame, "BOTTOMLEFT", 0, -10)
        lowerContainer:SetPoint("RIGHT", tabContent, "RIGHT", 0, 0)
        lowerContainer:SetHeight(600)  -- Will contain all sections below
        lowerContainer:EnableMouse(false)  -- Let clicks pass through to widgets
        y = 0  -- Reset y for positioning within lowerContainer

        -----------------------------------------------------------------------
        -- AUTOHIDE NON-USABLES SECTION (moved up per user request - highly useful feature)
        -----------------------------------------------------------------------
        local autohideHeader = GUI:CreateSectionHeader(lowerContainer, "Autohide Non-Usables")
        autohideHeader:SetPoint("TOPLEFT", 0, y)
        y = y - autohideHeader.gap + 12  -- Tighter spacing for description text

        local autohideDesc = GUI:CreateLabel(lowerContainer, "By default, when a consumable has 0 stacks in your bags, a trinket is unequipped from your character, or you have unlearned a spell, those tracked elements are merely desaturated. Toggling this on will hide them entirely.", 11, C.textMuted)
        autohideDesc:SetPoint("TOPLEFT", 0, y)
        autohideDesc:SetPoint("RIGHT", lowerContainer, "RIGHT", -PAD, 0)
        autohideDesc:SetJustifyH("LEFT")
        autohideDesc:SetWordWrap(true)
        autohideDesc:SetHeight(45)
        y = y - 55

        local hideNonUsableCheck = GUI:CreateFormCheckbox(lowerContainer, "Hide Non-Usable", "hideNonUsable", barConfig, RefreshThisBar)
        hideNonUsableCheck:SetPoint("TOPLEFT", 0, y)
        hideNonUsableCheck:SetPoint("RIGHT", lowerContainer, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        -----------------------------------------------------------------------
        -- POSITIONING SECTION (moved to lowerContainer for better flow)
        -----------------------------------------------------------------------
        local posHeader = GUI:CreateSectionHeader(lowerContainer, "Positioning")
        posHeader:SetPoint("TOPLEFT", 0, y)
        y = y - posHeader.gap

        local posHint = GUI:CreateLabel(lowerContainer, "Hint: You can place your custom bar ANYWHERE on screen. Simply toggle off Prevent Mouse Dragging, then left-click drag the bar. Locking to Player Frame is merely for convenience.", 11, C.textMuted)
        posHint:SetPoint("TOPLEFT", 0, y)
        posHint:SetPoint("RIGHT", lowerContainer, "RIGHT", -PAD, 0)
        posHint:SetJustifyH("LEFT")
        posHint:SetWordWrap(true)
        posHint:SetHeight(45)
        y = y - 55

        -- Ensure offset fields exist (migration)
        if not barConfig.offsetX then barConfig.offsetX = 0 end
        if not barConfig.offsetY then barConfig.offsetY = -300 end

        -- Store slider references for external updates (when bar is dragged)
        local xOffsetSlider, yOffsetSlider

        -- Register callback to update sliders when bar is dragged
        if trackerModule then
            trackerModule.onPositionChanged = function(draggedBarID, newX, newY)
                if draggedBarID == barConfig.id and xOffsetSlider and yOffsetSlider then
                    if xOffsetSlider.SetValue then xOffsetSlider.SetValue(newX, true) end
                    if yOffsetSlider.SetValue then yOffsetSlider.SetValue(newY, true) end
                end
            end
        end

        -- Lock to Player Frame section
        local btnGap = 4
        local rowGap = 4

        local lockContainer = CreateFrame("Frame", nil, lowerContainer)
        lockContainer:SetHeight(FORM_ROW + 22 + rowGap)
        lockContainer:SetPoint("TOPLEFT", 0, y)
        lockContainer:SetPoint("RIGHT", lowerContainer, "RIGHT", -PAD, 0)

        local lockLabel = lockContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        lockLabel:SetPoint("LEFT", 0, 0)
        lockLabel:SetText("Lock to Player Frame")
        lockLabel:SetTextColor(C.text[1], C.text[2], C.text[3], 1)

        -- Store button references for state updates
        local lockButtons = {}

        -- Function to update slider enabled state based on lock
        local function UpdateLockState()
            -- No-op: sliders always enabled for fine-tuning locked positions
        end

        -- Function to update button border colors and text based on lock state
        local function UpdateLockButtonStates()
            local currentPos = barConfig.lockedToPlayer and barConfig.lockPosition or nil
            for pos, btn in pairs(lockButtons) do
                if pos == currentPos then
                    btn:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 1)
                    btn.textObj:SetText("Unlock " .. btn.label)
                else
                    btn:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], 1)
                    btn.textObj:SetText(btn.label)
                end
            end
        end

        -- Forward declaration for mutual exclusion (defined in target lock section)
        local UpdateTargetLockButtonStates

        -- Toggle lock: click same button to unlock
        local function LockToPlayer(corner)
            if barConfig.lockedToPlayer and barConfig.lockPosition == corner then
                local bar = LUICore and LUICore.CustomTrackers and LUICore.CustomTrackers.activeBars and LUICore.CustomTrackers.activeBars[barConfig.id]
                if bar then
                    local scX, scY = UIParent:GetCenter()
                    local bX, bY = bar:GetCenter()
                    if bX and bY and scX and scY then
                        barConfig.offsetX = math.floor(bX - scX + 0.5)
                        barConfig.offsetY = math.floor(bY - scY + 0.5)
                    end
                end
                barConfig.lockedToPlayer = false
                barConfig.lockPosition = nil
                if xOffsetSlider and xOffsetSlider.SetValue then xOffsetSlider.SetValue(barConfig.offsetX, true) end
                if yOffsetSlider and yOffsetSlider.SetValue then yOffsetSlider.SetValue(barConfig.offsetY, true) end
            else
                local playerFrame = _G["LUI_Player"]
                if not playerFrame then
                    print("|cffff6666[QUI]|r Player frame not found")
                    return
                end
                if barConfig.lockedToTarget then
                    barConfig.lockedToTarget = false
                    barConfig.targetLockPosition = nil
                    UpdateTargetLockButtonStates()
                end
                barConfig.lockedToPlayer = true
                barConfig.lockPosition = corner
                barConfig.offsetX = 0
                barConfig.offsetY = 0
                if xOffsetSlider and xOffsetSlider.SetValue then xOffsetSlider.SetValue(0, true) end
                if yOffsetSlider and yOffsetSlider.SetValue then yOffsetSlider.SetValue(0, true) end
            end
            RefreshPosition()
            UpdateLockState()
            UpdateLockButtonStates()
        end

        -- Helper to create lock button
        local function CreateLockButton(parent, label, corner)
            local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
            btn:SetSize(75, 22)
            btn:SetBackdrop({
                bgFile = "Interface\\Buttons\\WHITE8x8",
                edgeFile = "Interface\\Buttons\\WHITE8x8",
                edgeSize = 1,
            })
            btn:SetBackdropColor(0.15, 0.15, 0.15, 1)
            btn:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], 1)
            local text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            text:SetPoint("CENTER")
            text:SetText(label)
            text:SetTextColor(C.text[1], C.text[2], C.text[3], 1)
            btn.label = label
            btn.textObj = text
            btn:SetScript("OnClick", function() LockToPlayer(corner) end)
            btn:SetScript("OnEnter", function(self) self:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 1) end)
            btn:SetScript("OnLeave", function(self)
                if not (barConfig.lockedToPlayer and barConfig.lockPosition == corner) then
                    self:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], 1)
                end
            end)
            lockButtons[corner] = btn
            return btn
        end

        local lockTLBtn = CreateLockButton(lockContainer, "Top Left", "topleft")
        local lockTCBtn = CreateLockButton(lockContainer, "Top Center", "topcenter")
        local lockTRBtn = CreateLockButton(lockContainer, "Top Right", "topright")
        local lockBLBtn = CreateLockButton(lockContainer, "Btm Left", "bottomleft")
        local lockBCBtn = CreateLockButton(lockContainer, "Btm Center", "bottomcenter")
        local lockBRBtn = CreateLockButton(lockContainer, "Btm Right", "bottomright")

        local lockRow1Y = (22 + rowGap) / 2
        lockTLBtn:SetPoint("LEFT", lockContainer, "LEFT", 180, lockRow1Y)
        lockTCBtn:SetPoint("LEFT", lockTLBtn, "RIGHT", btnGap, 0)
        lockTRBtn:SetPoint("LEFT", lockTCBtn, "RIGHT", btnGap, 0)
        local lockRow2Y = -lockRow1Y
        lockBLBtn:SetPoint("LEFT", lockContainer, "LEFT", 180, lockRow2Y)
        lockBCBtn:SetPoint("LEFT", lockBLBtn, "RIGHT", btnGap, 0)
        lockBRBtn:SetPoint("LEFT", lockBCBtn, "RIGHT", btnGap, 0)

        local function UpdateLockButtonWidths()
            local containerWidth = lockContainer:GetWidth()
            if containerWidth and containerWidth > 0 then
                local availableWidth = containerWidth - 180
                local totalGaps = 2 * btnGap
                local lockBtnWidth = (availableWidth - totalGaps) / 3
                if lockBtnWidth > 20 then
                    lockTLBtn:SetWidth(lockBtnWidth)
                    lockTCBtn:SetWidth(lockBtnWidth)
                    lockTRBtn:SetWidth(lockBtnWidth)
                    lockBLBtn:SetWidth(lockBtnWidth)
                    lockBCBtn:SetWidth(lockBtnWidth)
                    lockBRBtn:SetWidth(lockBtnWidth)
                end
            end
        end
        lockContainer:HookScript("OnSizeChanged", function() UpdateLockButtonWidths() end)
        C_Timer.After(0, function() UpdateLockButtonWidths() UpdateLockButtonStates() end)

        y = y - (FORM_ROW + 22 + rowGap + 4)

        -- Lock to Target Frame section
        local targetLockContainer = CreateFrame("Frame", nil, lowerContainer)
        targetLockContainer:SetHeight(FORM_ROW + 22 + rowGap)
        targetLockContainer:SetPoint("TOPLEFT", 0, y)
        targetLockContainer:SetPoint("RIGHT", lowerContainer, "RIGHT", -PAD, 0)

        local targetLockLabel = targetLockContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        targetLockLabel:SetPoint("LEFT", 0, 0)
        targetLockLabel:SetText("Lock to Target Frame")
        targetLockLabel:SetTextColor(C.text[1], C.text[2], C.text[3], 1)

        local targetLockButtons = {}

        UpdateTargetLockButtonStates = function()
            local currentPos = barConfig.lockedToTarget and barConfig.targetLockPosition or nil
            for pos, btn in pairs(targetLockButtons) do
                if pos == currentPos then
                    btn:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 1)
                    btn.textObj:SetText("Unlock " .. btn.label)
                else
                    btn:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], 1)
                    btn.textObj:SetText(btn.label)
                end
            end
        end

        local function LockToTarget(corner)
            if barConfig.lockedToTarget and barConfig.targetLockPosition == corner then
                local bar = LUICore and LUICore.CustomTrackers and LUICore.CustomTrackers.activeBars and LUICore.CustomTrackers.activeBars[barConfig.id]
                if bar then
                    local scX, scY = UIParent:GetCenter()
                    local bX, bY = bar:GetCenter()
                    if bX and bY and scX and scY then
                        barConfig.offsetX = math.floor(bX - scX + 0.5)
                        barConfig.offsetY = math.floor(bY - scY + 0.5)
                    end
                end
                barConfig.lockedToTarget = false
                barConfig.targetLockPosition = nil
                if xOffsetSlider and xOffsetSlider.SetValue then xOffsetSlider.SetValue(barConfig.offsetX, true) end
                if yOffsetSlider and yOffsetSlider.SetValue then yOffsetSlider.SetValue(barConfig.offsetY, true) end
            else
                local targetFrame = _G["LUI_Target"]
                if not targetFrame then
                    print("|cffff6666[QUI]|r Target frame not found")
                    return
                end
                if barConfig.lockedToPlayer then
                    barConfig.lockedToPlayer = false
                    barConfig.lockPosition = nil
                    UpdateLockButtonStates()
                end
                barConfig.lockedToTarget = true
                barConfig.targetLockPosition = corner
                barConfig.offsetX = 0
                barConfig.offsetY = 0
                if xOffsetSlider and xOffsetSlider.SetValue then xOffsetSlider.SetValue(0, true) end
                if yOffsetSlider and yOffsetSlider.SetValue then yOffsetSlider.SetValue(0, true) end
            end
            RefreshPosition()
            UpdateTargetLockButtonStates()
        end

        local function CreateTargetLockButton(parent, label, corner)
            local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
            btn:SetSize(75, 22)
            btn:SetBackdrop({
                bgFile = "Interface\\Buttons\\WHITE8x8",
                edgeFile = "Interface\\Buttons\\WHITE8x8",
                edgeSize = 1,
            })
            btn:SetBackdropColor(0.15, 0.15, 0.15, 1)
            btn:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], 1)
            local text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            text:SetPoint("CENTER")
            text:SetText(label)
            text:SetTextColor(C.text[1], C.text[2], C.text[3], 1)
            btn.label = label
            btn.textObj = text
            btn:SetScript("OnClick", function() LockToTarget(corner) end)
            btn:SetScript("OnEnter", function(self) self:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 1) end)
            btn:SetScript("OnLeave", function(self)
                if not (barConfig.lockedToTarget and barConfig.targetLockPosition == corner) then
                    self:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], 1)
                end
            end)
            targetLockButtons[corner] = btn
            return btn
        end

        local targetLockTLBtn = CreateTargetLockButton(targetLockContainer, "Top Left", "topleft")
        local targetLockTCBtn = CreateTargetLockButton(targetLockContainer, "Top Center", "topcenter")
        local targetLockTRBtn = CreateTargetLockButton(targetLockContainer, "Top Right", "topright")
        local targetLockBLBtn = CreateTargetLockButton(targetLockContainer, "Btm Left", "bottomleft")
        local targetLockBCBtn = CreateTargetLockButton(targetLockContainer, "Btm Center", "bottomcenter")
        local targetLockBRBtn = CreateTargetLockButton(targetLockContainer, "Btm Right", "bottomright")

        local targetLockRow1Y = (22 + rowGap) / 2
        targetLockTLBtn:SetPoint("LEFT", targetLockContainer, "LEFT", 180, targetLockRow1Y)
        targetLockTCBtn:SetPoint("LEFT", targetLockTLBtn, "RIGHT", btnGap, 0)
        targetLockTRBtn:SetPoint("LEFT", targetLockTCBtn, "RIGHT", btnGap, 0)
        local targetLockRow2Y = -targetLockRow1Y
        targetLockBLBtn:SetPoint("LEFT", targetLockContainer, "LEFT", 180, targetLockRow2Y)
        targetLockBCBtn:SetPoint("LEFT", targetLockBLBtn, "RIGHT", btnGap, 0)
        targetLockBRBtn:SetPoint("LEFT", targetLockBCBtn, "RIGHT", btnGap, 0)

        local function UpdateTargetLockButtonWidths()
            local containerWidth = targetLockContainer:GetWidth()
            if containerWidth and containerWidth > 0 then
                local availableWidth = containerWidth - 180
                local totalGaps = 2 * btnGap
                local btnWidth = (availableWidth - totalGaps) / 3
                if btnWidth > 20 then
                    targetLockTLBtn:SetWidth(btnWidth)
                    targetLockTCBtn:SetWidth(btnWidth)
                    targetLockTRBtn:SetWidth(btnWidth)
                    targetLockBLBtn:SetWidth(btnWidth)
                    targetLockBCBtn:SetWidth(btnWidth)
                    targetLockBRBtn:SetWidth(btnWidth)
                end
            end
        end
        targetLockContainer:HookScript("OnSizeChanged", function() UpdateTargetLockButtonWidths() end)
        C_Timer.After(0, function() UpdateTargetLockButtonWidths() UpdateTargetLockButtonStates() end)

        y = y - (FORM_ROW + 22 + rowGap + 8)

        -- X/Y Offset sliders
        xOffsetSlider = GUI:CreateFormSlider(lowerContainer, "X Offset", -2000, 2000, 1, "offsetX", barConfig, RefreshPosition)
        xOffsetSlider:SetPoint("TOPLEFT", 0, y)
        xOffsetSlider:SetPoint("RIGHT", lowerContainer, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        yOffsetSlider = GUI:CreateFormSlider(lowerContainer, "Y Offset", -2000, 2000, 1, "offsetY", barConfig, RefreshPosition)
        yOffsetSlider:SetPoint("TOPLEFT", 0, y)
        yOffsetSlider:SetPoint("RIGHT", lowerContainer, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        UpdateLockState()

        -- Prevent Mouse Dragging checkbox
        local lockCheck = GUI:CreateFormCheckbox(lowerContainer, "Prevent Mouse Dragging", "locked", barConfig)
        lockCheck:SetPoint("TOPLEFT", 0, y)
        lockCheck:SetPoint("RIGHT", lowerContainer, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        -----------------------------------------------------------------------
        -- LAYOUT SECTION
        -----------------------------------------------------------------------
        local layoutHeader = GUI:CreateSectionHeader(lowerContainer, "Layout")
        layoutHeader:SetPoint("TOPLEFT", 0, y)
        y = y - layoutHeader.gap

        -- Grow Direction dropdown
        local growOptions = {
            {value = "RIGHT", text = "Right"},
            {value = "LEFT", text = "Left"},
            {value = "UP", text = "Up"},
            {value = "DOWN", text = "Down"},
            {value = "CENTER", text = "Center (Horizontal)"},
            {value = "CENTER_VERTICAL", text = "Center (Vertical)"},
        }
        local growDropdown = GUI:CreateFormDropdown(lowerContainer, "Grow Direction", growOptions, "growDirection", barConfig, RefreshThisBar)
        growDropdown:SetPoint("TOPLEFT", 0, y)
        growDropdown:SetPoint("RIGHT", lowerContainer, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local dynamicLayoutCheck = GUI:CreateFormCheckbox(lowerContainer, "Dynamic Layout (Collapsing)", "dynamicLayout", barConfig, RefreshThisBar)
        dynamicLayoutCheck:SetPoint("TOPLEFT", 0, y)
        dynamicLayoutCheck:SetPoint("RIGHT", lowerContainer, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local dynamicLayoutDesc = GUI:CreateLabel(lowerContainer, "When enabled, icons that are hidden by visibility rules (e.g. 'Show Only On Cooldown' or 'Show Only When Active') are removed from the layout, so the bar collapses/expands dynamically.", 11, C.textMuted)
        dynamicLayoutDesc:SetPoint("TOPLEFT", 0, y)
        dynamicLayoutDesc:SetPoint("RIGHT", lowerContainer, "RIGHT", -PAD, 0)
        dynamicLayoutDesc:SetJustifyH("LEFT")
        dynamicLayoutDesc:SetWordWrap(true)
        dynamicLayoutDesc:SetHeight(40)
        y = y - 50

        -- Icon Shape slider
        local shapeSlider = GUI:CreateFormSlider(lowerContainer, "Icon Shape", 1.0, 2.0, 0.01, "aspectRatioCrop", barConfig, RefreshThisBar)
        shapeSlider:SetPoint("TOPLEFT", 0, y)
        shapeSlider:SetPoint("RIGHT", lowerContainer, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local shapeTip = GUI:CreateLabel(lowerContainer, "Higher values imply flatter icons.", 11, C.textMuted)
        shapeTip:SetPoint("TOPLEFT", 0, y)
        shapeTip:SetPoint("RIGHT", lowerContainer, "RIGHT", -PAD, 0)
        shapeTip:SetJustifyH("LEFT")
        y = y - 20

        -- Icon Size slider
        local sizeSlider = GUI:CreateFormSlider(lowerContainer, "Icon Size", 16, 64, 1, "iconSize", barConfig, RefreshThisBar)
        sizeSlider:SetPoint("TOPLEFT", 0, y)
        sizeSlider:SetPoint("RIGHT", lowerContainer, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        -- Spacing slider
        local spacingSlider = GUI:CreateFormSlider(lowerContainer, "Spacing", 0, 20, 1, "spacing", barConfig, RefreshThisBar)
        spacingSlider:SetPoint("TOPLEFT", 0, y)
        spacingSlider:SetPoint("RIGHT", lowerContainer, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        -----------------------------------------------------------------------
        -- ICON STYLE SECTION
        -----------------------------------------------------------------------
        local styleHeader = GUI:CreateSectionHeader(lowerContainer, "Icon Style")
        styleHeader:SetPoint("TOPLEFT", 0, y)
        y = y - styleHeader.gap

        -- Border Size slider
        local borderSlider = GUI:CreateFormSlider(lowerContainer, "Border Size", 0, 8, 1, "borderSize", barConfig, RefreshThisBar)
        borderSlider:SetPoint("TOPLEFT", 0, y)
        borderSlider:SetPoint("RIGHT", lowerContainer, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        -- Zoom slider
        local zoomSlider = GUI:CreateFormSlider(lowerContainer, "Zoom", 0, 0.2, 0.01, "zoom", barConfig, RefreshThisBar)
        zoomSlider:SetPoint("TOPLEFT", 0, y)
        zoomSlider:SetPoint("RIGHT", lowerContainer, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        -----------------------------------------------------------------------
        -- DURATION TEXT SECTION
        -----------------------------------------------------------------------
        local durHeader = GUI:CreateSectionHeader(lowerContainer, "Duration Text")
        durHeader:SetPoint("TOPLEFT", 0, y)
        y = y - durHeader.gap

        local hideDurCheck = GUI:CreateFormCheckbox(lowerContainer, "Hide Text", "hideDurationText", barConfig, RefreshThisBar)
        hideDurCheck:SetPoint("TOPLEFT", 0, y)
        hideDurCheck:SetPoint("RIGHT", lowerContainer, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local durSizeSlider = GUI:CreateFormSlider(lowerContainer, "Size", 8, 24, 1, "durationSize", barConfig, RefreshThisBar)
        durSizeSlider:SetPoint("TOPLEFT", 0, y)
        durSizeSlider:SetPoint("RIGHT", lowerContainer, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local durColorPicker = GUI:CreateFormColorPicker(lowerContainer, "Text Color", "durationColor", barConfig, RefreshThisBar)
        durColorPicker:SetPoint("TOPLEFT", 0, y)
        durColorPicker:SetPoint("RIGHT", lowerContainer, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local durXSlider = GUI:CreateFormSlider(lowerContainer, "X Offset", -20, 20, 1, "durationOffsetX", barConfig, RefreshThisBar)
        durXSlider:SetPoint("TOPLEFT", 0, y)
        durXSlider:SetPoint("RIGHT", lowerContainer, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local durYSlider = GUI:CreateFormSlider(lowerContainer, "Y Offset", -20, 20, 1, "durationOffsetY", barConfig, RefreshThisBar)
        durYSlider:SetPoint("TOPLEFT", 0, y)
        durYSlider:SetPoint("RIGHT", lowerContainer, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        -----------------------------------------------------------------------
        -- STACK TEXT SECTION
        -----------------------------------------------------------------------
        local stackHeader = GUI:CreateSectionHeader(lowerContainer, "Stack Text")
        stackHeader:SetPoint("TOPLEFT", 0, y)
        y = y - stackHeader.gap

        local showChargesCheck  -- Forward declare for callback reference

        local hideStackCheck = GUI:CreateFormCheckbox(lowerContainer, "Hide Text", "hideStackText", barConfig, function(val)
            RefreshThisBar()
            -- Disable "Show Item Charges" when text is hidden (it has no effect)
            if showChargesCheck and showChargesCheck.SetEnabled then
                showChargesCheck:SetEnabled(not val)
            end
        end)
        hideStackCheck:SetPoint("TOPLEFT", 0, y)
        hideStackCheck:SetPoint("RIGHT", lowerContainer, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        showChargesCheck = GUI:CreateFormCheckbox(lowerContainer, "Show Item Charges", "showItemCharges", barConfig, RefreshThisBar)
        showChargesCheck:SetPoint("TOPLEFT", 0, y)
        showChargesCheck:SetPoint("RIGHT", lowerContainer, "RIGHT", -PAD, 0)
        -- Initial state: disabled if text is hidden
        if showChargesCheck.SetEnabled then
            showChargesCheck:SetEnabled(not barConfig.hideStackText)
        end
        y = y - FORM_ROW

        local stackSizeSlider = GUI:CreateFormSlider(lowerContainer, "Size", 8, 24, 1, "stackSize", barConfig, RefreshThisBar)
        stackSizeSlider:SetPoint("TOPLEFT", 0, y)
        stackSizeSlider:SetPoint("RIGHT", lowerContainer, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local stackColorPicker = GUI:CreateFormColorPicker(lowerContainer, "Text Color", "stackColor", barConfig, RefreshThisBar)
        stackColorPicker:SetPoint("TOPLEFT", 0, y)
        stackColorPicker:SetPoint("RIGHT", lowerContainer, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local stackXSlider = GUI:CreateFormSlider(lowerContainer, "X Offset", -20, 20, 1, "stackOffsetX", barConfig, RefreshThisBar)
        stackXSlider:SetPoint("TOPLEFT", 0, y)
        stackXSlider:SetPoint("RIGHT", lowerContainer, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local stackYSlider = GUI:CreateFormSlider(lowerContainer, "Y Offset", -20, 20, 1, "stackOffsetY", barConfig, RefreshThisBar)
        stackYSlider:SetPoint("TOPLEFT", 0, y)
        stackYSlider:SetPoint("RIGHT", lowerContainer, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        -----------------------------------------------------------------------
        -- BUFF ACTIVE SETTINGS SECTION
        -----------------------------------------------------------------------
        local buffActiveHeader = GUI:CreateSectionHeader(lowerContainer, "Buff Active Settings")
        buffActiveHeader:SetPoint("TOPLEFT", 0, y)
        y = y - buffActiveHeader.gap

        local glowEnabledCheck = GUI:CreateFormCheckbox(lowerContainer, "Enable Glow", "activeGlowEnabled", barConfig, RefreshThisBar)
        glowEnabledCheck:SetPoint("TOPLEFT", 0, y)
        glowEnabledCheck:SetPoint("RIGHT", lowerContainer, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local glowTypeOptions = {
            {value = "Pixel Glow", text = "Pixel Glow"},
            {value = "Autocast Shine", text = "Autocast Shine"},
            {value = "Proc Glow", text = "Proc Glow"},
        }
        local glowTypeDropdown = GUI:CreateFormDropdown(lowerContainer, "Glow Type", glowTypeOptions, "activeGlowType", barConfig, RefreshThisBar)
        glowTypeDropdown:SetPoint("TOPLEFT", 0, y)
        glowTypeDropdown:SetPoint("RIGHT", lowerContainer, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local glowColorPicker = GUI:CreateFormColorPicker(lowerContainer, "Glow Color", "activeGlowColor", barConfig, RefreshThisBar)
        glowColorPicker:SetPoint("TOPLEFT", 0, y)
        glowColorPicker:SetPoint("RIGHT", lowerContainer, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local glowLinesSlider = GUI:CreateFormSlider(lowerContainer, "Glow Lines", 4, 16, 1, "activeGlowLines", barConfig, RefreshThisBar)
        glowLinesSlider:SetPoint("TOPLEFT", 0, y)
        glowLinesSlider:SetPoint("RIGHT", lowerContainer, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local glowSpeedSlider = GUI:CreateFormSlider(lowerContainer, "Glow Speed", 0.1, 1.0, 0.05, "activeGlowFrequency", barConfig, RefreshThisBar)
        glowSpeedSlider:SetPoint("TOPLEFT", 0, y)
        glowSpeedSlider:SetPoint("RIGHT", lowerContainer, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local glowThicknessSlider = GUI:CreateFormSlider(lowerContainer, "Glow Thickness", 1, 5, 1, "activeGlowThickness", barConfig, RefreshThisBar)
        glowThicknessSlider:SetPoint("TOPLEFT", 0, y)
        glowThicknessSlider:SetPoint("RIGHT", lowerContainer, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local glowScaleSlider = GUI:CreateFormSlider(lowerContainer, "Glow Scale", 0.5, 2.0, 0.1, "activeGlowScale", barConfig, RefreshThisBar)
        glowScaleSlider:SetPoint("TOPLEFT", 0, y)
        glowScaleSlider:SetPoint("RIGHT", lowerContainer, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        -----------------------------------------------------------------------
        -- ICON VISIBILITY SECTION (moved after Buff Active per plan)
        -----------------------------------------------------------------------
        local cooldownOnlyHeader = GUI:CreateSectionHeader(lowerContainer, "Icon Visibility")
        cooldownOnlyHeader:SetPoint("TOPLEFT", 0, y)
        y = y - cooldownOnlyHeader.gap + 10

        local cooldownOnlyDesc = GUI:CreateLabel(lowerContainer, "Control when icons are visible. The first three options are mutually exclusive. 'Show Only In Combat' can be combined with any other option.", 11, C.textMuted)
        cooldownOnlyDesc:SetPoint("TOPLEFT", 0, y)
        cooldownOnlyDesc:SetPoint("RIGHT", lowerContainer, "RIGHT", -PAD, 0)
        cooldownOnlyDesc:SetJustifyH("LEFT")
        cooldownOnlyDesc:SetWordWrap(true)
        cooldownOnlyDesc:SetHeight(30)
        y = y - 38

        local showOnlyInCombatCheck = GUI:CreateFormCheckbox(lowerContainer, "Show Only In Combat", "showOnlyInCombat", barConfig, nil)
        showOnlyInCombatCheck:SetPoint("TOPLEFT", 0, y)
        showOnlyInCombatCheck:SetPoint("RIGHT", lowerContainer, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local showOnlyOnCooldownCheck = GUI:CreateFormCheckbox(lowerContainer, "Show Only On Cooldown", "showOnlyOnCooldown", barConfig, nil)
        showOnlyOnCooldownCheck:SetPoint("TOPLEFT", 0, y)
        showOnlyOnCooldownCheck:SetPoint("RIGHT", lowerContainer, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local showOnlyWhenActiveCheck = GUI:CreateFormCheckbox(lowerContainer, "Show Only When Active", "showOnlyWhenActive", barConfig, nil)
        showOnlyWhenActiveCheck:SetPoint("TOPLEFT", 0, y)
        showOnlyWhenActiveCheck:SetPoint("RIGHT", lowerContainer, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local showOnlyWhenOffCooldownCheck = GUI:CreateFormCheckbox(lowerContainer, "Show Only When Off Cooldown", "showOnlyWhenOffCooldown", barConfig, nil)
        showOnlyWhenOffCooldownCheck:SetPoint("TOPLEFT", 0, y)
        showOnlyWhenOffCooldownCheck:SetPoint("RIGHT", lowerContainer, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        -- Mutual exclusion handlers for cooldown/active visibility checkboxes
        -- showOnlyOnCooldown, showOnlyWhenActive, showOnlyWhenOffCooldown are mutually exclusive
        -- showOnlyInCombat can be combined with any of them
        if showOnlyOnCooldownCheck.track then
            showOnlyOnCooldownCheck.track:SetScript("OnClick", function()
                local newVal = not showOnlyOnCooldownCheck.GetValue()
                showOnlyOnCooldownCheck.SetValue(newVal, true)
                if newVal then
                    showOnlyWhenActiveCheck.SetValue(false, true)
                    showOnlyWhenOffCooldownCheck.SetValue(false, true)
                end
                RefreshThisBar()
            end)
        end
        if showOnlyWhenActiveCheck.track then
            showOnlyWhenActiveCheck.track:SetScript("OnClick", function()
                local newVal = not showOnlyWhenActiveCheck.GetValue()
                showOnlyWhenActiveCheck.SetValue(newVal, true)
                if newVal then
                    showOnlyOnCooldownCheck.SetValue(false, true)
                    showOnlyWhenOffCooldownCheck.SetValue(false, true)
                end
                RefreshThisBar()
            end)
        end
        if showOnlyWhenOffCooldownCheck.track then
            showOnlyWhenOffCooldownCheck.track:SetScript("OnClick", function()
                local newVal = not showOnlyWhenOffCooldownCheck.GetValue()
                showOnlyWhenOffCooldownCheck.SetValue(newVal, true)
                if newVal then
                    showOnlyOnCooldownCheck.SetValue(false, true)
                    showOnlyWhenActiveCheck.SetValue(false, true)
                end
                RefreshThisBar()
            end)
        end
        if showOnlyInCombatCheck.track then
            showOnlyInCombatCheck.track:SetScript("OnClick", function()
                local newVal = not showOnlyInCombatCheck.GetValue()
                showOnlyInCombatCheck.SetValue(newVal, true)
                RefreshThisBar()
            end)
        end

        -----------------------------------------------------------------------
        -- ADVANCED SETTINGS SECTION
        -----------------------------------------------------------------------
        local advancedHeader = GUI:CreateSectionHeader(lowerContainer, "Advanced Settings")
        advancedHeader:SetPoint("TOPLEFT", 0, y)
        y = y - advancedHeader.gap

        -- Show Recharge Swipe checkbox
        local showRechargeSwipe = GUI:CreateFormCheckbox(lowerContainer, "Show Recharge Swipe", "showRechargeSwipe", barConfig, RefreshThisBar)
        showRechargeSwipe:SetPoint("TOPLEFT", 0, y)
        showRechargeSwipe:SetPoint("RIGHT", lowerContainer, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        -- Recharge swipe description (below toggle)
        local rechargeSwipeDesc = GUI:CreateLabel(lowerContainer, "DO NOT turn on unless you know what you're doing. Shows GCD and radial swipe animations when spells are recharging.", 10, C.textMuted)
        rechargeSwipeDesc:SetPoint("TOPLEFT", 0, y + 4)
        y = y - 18

        -- Enable Spec-Specific Spells checkbox
        local specEnableCheck = GUI:CreateFormCheckbox(lowerContainer, "Enable Spec-Specific Spells", "specSpecificSpells", barConfig, function()
            if barConfig.specSpecificSpells then
                local specKey = getCurrentSpecKey()
                if specKey and trackerModule then
                    trackerModule:CopyEntriesToSpec(barConfig, specKey)
                end
            end
            refreshForSpec()
            if copyFromDropdown then
                if barConfig.specSpecificSpells then
                    copyFromDropdown:Show()
                else
                    copyFromDropdown:Hide()
                end
            end
        end)
        specEnableCheck:SetPoint("TOPLEFT", 0, y)
        specEnableCheck:SetPoint("RIGHT", lowerContainer, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        -- Spec-specific description (below toggle)
        local specHint = GUI:CreateLabel(lowerContainer, "When enabled, the spell list for this bar is saved separately for each spec. The bar's layout settings remain shared.", 10, C.textMuted)
        specHint:SetPoint("TOPLEFT", 0, y + 4)
        specHint:SetPoint("RIGHT", lowerContainer, "RIGHT", -PAD, 0)
        specHint:SetJustifyH("LEFT")
        specHint:SetWordWrap(true)
        specHint:SetHeight(26)
        y = y - 34

        -- Build specs list for copy dropdown
        local allSpecs = {}
        if trackerModule and trackerModule.GetAllClassSpecs then
            allSpecs = trackerModule.GetAllClassSpecs()
        else
            local _, className = UnitClass("player")
            local numSpecs = GetNumSpecializations()
            for i = 1, numSpecs do
                local specID, specName = GetSpecializationInfo(i)
                if specID and specName then
                    table.insert(allSpecs, {
                        key = className .. "-" .. specID,
                        name = className:sub(1, 1):upper() .. className:sub(2):lower() .. " - " .. specName,
                    })
                end
            end
        end

        -- Info label (shows currently editing spec)
        specInfoLabel = GUI:CreateLabel(lowerContainer, "", 11, C.accent)
        specInfoLabel:SetPoint("TOPLEFT", 0, y)
        specInfoLabel:SetPoint("RIGHT", lowerContainer, "RIGHT", -PAD, 0)
        specInfoLabel:SetJustifyH("LEFT")
        updateSpecInfoLabel()
        y = y - 18

        -- Copy From dropdown container
        local copyContainer = CreateFrame("Frame", nil, lowerContainer)
        copyContainer:SetHeight(FORM_ROW)
        copyContainer:SetPoint("TOPLEFT", 0, y)
        copyContainer:SetPoint("RIGHT", lowerContainer, "RIGHT", -PAD, 0)

        local copyLabel = copyContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        copyLabel:SetPoint("LEFT", 0, 0)
        copyLabel:SetText("Copy spells from")
        copyLabel:SetTextColor(C.textMuted[1], C.textMuted[2], C.textMuted[3], 1)

        local copyOptions = {}
        local targetSpec = getCurrentSpecKey()
        for _, spec in ipairs(allSpecs) do
            if spec.key ~= targetSpec then
                local entryCount = 0
                if trackerModule then
                    local specEntries = trackerModule:GetSpecEntries(barConfig, spec.key)
                    entryCount = specEntries and #specEntries or 0
                end
                local suffix = entryCount > 0 and (" (" .. entryCount .. " spells)") or " (empty)"
                table.insert(copyOptions, { value = spec.key, text = spec.name .. suffix })
            end
        end

        local copyDropdownWidget = GUI:CreateFormDropdown(copyContainer, "", copyOptions, nil, nil, function(selectedValue)
            if selectedValue and trackerModule then
                local sourceEntries = trackerModule:GetSpecEntries(barConfig, selectedValue)
                if sourceEntries and #sourceEntries > 0 then
                    local destSpec = getCurrentSpecKey()
                    local copiedEntries = {}
                    for _, entry in ipairs(sourceEntries) do
                        table.insert(copiedEntries, {
                            type = entry.type,
                            id = entry.id,
                            customName = entry.customName,
                        })
                    end
                    trackerModule:SetSpecEntries(barConfig, destSpec, copiedEntries)
                    refreshForSpec()
                end
            end
        end)
        copyDropdownWidget:SetPoint("LEFT", copyLabel, "RIGHT", 10, 0)
        copyDropdownWidget:SetPoint("RIGHT", copyContainer, "RIGHT", 0, 0)

        if not barConfig.specSpecificSpells then
            copyContainer:Hide()
        end
        copyFromDropdown = copyContainer
        y = y - FORM_ROW

        -- Set lowerContainer height based on content (increased for new sections)
        lowerContainer:SetHeight(math.abs(y) + 40)

        -- tabContent height needs to accommodate more content now
        tabContent:SetHeight(1200)
    end

    ---------------------------------------------------------------------------
    -- Build sub-tabs dynamically from bars
    ---------------------------------------------------------------------------
    -- Reference to be populated after subTabs creation (for live tab text updates)
    local subTabsRef = {}

    local tabDefs = {}

    ---------------------------------------------------------------------------
    -- SPELL SCANNER TAB (always first)
    ---------------------------------------------------------------------------
    table.insert(tabDefs, {
        name = "Setup Custom Buff Tracking",
        builder = function(tabContent)
            GUI:SetSearchContext({tabIndex = 9, tabName = "Custom Items/Spells/Buffs", subTabIndex = 1, subTabName = "Spell Scanner"})
            local y = -10
            local scanner = QUI.SpellScanner
            local scannedListFrame  -- Forward declaration for refresh

            -- Header
            local header = GUI:CreateSectionHeader(tabContent, "Spell Scanner")
            header:SetPoint("TOPLEFT", PAD, y)
            y = y - header.gap

            -- "How It Works" mini-header
            local howItWorks = GUI:CreateLabel(tabContent, "How It Works", 11, C.accentLight)
            howItWorks:SetPoint("TOPLEFT", PAD, y)
            y = y - 16

            -- Step 1
            local step1 = GUI:CreateLabel(tabContent, "1. Enable Scan Mode and cast spells or items out of combat to record their buff durations", 11, C.text)
            step1:SetPoint("TOPLEFT", PAD, y)
            step1:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            step1:SetJustifyH("LEFT")
            step1:SetWordWrap(true)
            step1:SetHeight(28)
            y = y - 32

            -- Step 2
            local step2 = GUI:CreateLabel(tabContent, "2. Add those spells/items to a Custom Tracker bar", 11, C.text)
            step2:SetPoint("TOPLEFT", PAD, y)
            step2:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            step2:SetJustifyH("LEFT")
            y = y - 20

            -- Step 3
            local step3 = GUI:CreateLabel(tabContent, "3. The icons on your Custom Bars will now show accurate custom buff timers in combat", 11, C.text)
            step3:SetPoint("TOPLEFT", PAD, y)
            step3:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            step3:SetJustifyH("LEFT")
            y = y - 26

            -- Scan Mode Toggle
            local scanModeContainer = CreateFrame("Frame", nil, tabContent)
            scanModeContainer:SetHeight(FORM_ROW)
            scanModeContainer:SetPoint("TOPLEFT", PAD, y)
            scanModeContainer:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)

            local scanLabel = scanModeContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            scanLabel:SetPoint("LEFT", 0, 0)
            scanLabel:SetText("Scan Mode")
            scanLabel:SetTextColor(C.text[1], C.text[2], C.text[3], 1)

            local scanBtn = GUI:CreateButton(scanModeContainer, "Enable", 100, 24, function(self)
                if scanner then
                    local enabled = scanner.ToggleScanMode()
                    if enabled then
                        self.text:SetText("Disable")
                        self:SetBackdropColor(0.2, 0.6, 0.2, 1)
                    else
                        self.text:SetText("Enable")
                        self:SetBackdropColor(C.bg[1], C.bg[2], C.bg[3], 1)
                    end
                end
            end)
            scanBtn:SetPoint("LEFT", 180, 0)
            -- Set initial state
            if scanner and scanner.scanMode then
                scanBtn.text:SetText("Disable")
                scanBtn:SetBackdropColor(0.2, 0.6, 0.2, 1)
            end

            y = y - FORM_ROW

            -- Auto-Scan Toggle (persistent setting) - using proper switch toggle
            -- Ensure spellScanner db exists with proper defaults
            if not QUI.db.global.spellScanner then
                QUI.db.global.spellScanner = { spells = {}, items = {}, autoScan = false }
            end
            -- Ensure autoScan key exists (could be nil from older version)
            if QUI.db.global.spellScanner.autoScan == nil then
                QUI.db.global.spellScanner.autoScan = false
            end

            local autoScanToggle = GUI:CreateFormToggle(tabContent, "Auto-Scan (silent)", "autoScan", QUI.db.global.spellScanner, function(val)
                if scanner then
                    scanner.autoScan = val  -- Keep runtime state in sync
                end
            end)
            autoScanToggle:SetPoint("TOPLEFT", PAD, y)
            autoScanToggle:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)

            y = y - FORM_ROW - 10

            -- Scanned Spells Header
            local scannedHeader = GUI:CreateSectionHeader(tabContent, "Scanned Spells & Items")
            scannedHeader:SetPoint("TOPLEFT", PAD, y)
            y = y - scannedHeader.gap

            -- Refresh function for the list (matches Tracked Items pattern)
            local function RefreshScannedList()
                if not scannedListFrame then return end

                -- Clear existing child frames
                for _, child in ipairs({scannedListFrame:GetChildren()}) do
                    child:Hide()
                    child:SetParent(nil)
                end

                local scannerDB = QUI.db and QUI.db.global and QUI.db.global.spellScanner
                local listY = 0
                local rowHeight = 30

                -- Helper to create a row (matches Tracked Items style)
                local function CreateScannedRow(id, data, isItem)
                    local entryFrame = CreateFrame("Frame", nil, scannedListFrame)
                    entryFrame:SetSize(320, 28)
                    entryFrame:SetPoint("TOPLEFT", 0, listY)

                    -- Icon (24x24)
                    local iconTex = entryFrame:CreateTexture(nil, "ARTWORK")
                    iconTex:SetSize(24, 24)
                    iconTex:SetPoint("LEFT", 0, 0)
                    iconTex:SetTexture(data.icon or 134400)
                    iconTex:SetTexCoord(0.08, 0.92, 0.08, 0.92)

                    -- Name display (input-box style background)
                    local nameBg = CreateFrame("Frame", nil, entryFrame, "BackdropTemplate")
                    nameBg:SetPoint("LEFT", iconTex, "RIGHT", 6, 0)
                    nameBg:SetSize(200, 22)
                    nameBg:SetBackdrop({
                        bgFile = "Interface\\Buttons\\WHITE8x8",
                        edgeFile = "Interface\\Buttons\\WHITE8x8",
                        edgeSize = 1,
                    })
                    nameBg:SetBackdropColor(0.05, 0.05, 0.05, 0.4)
                    nameBg:SetBackdropBorderColor(0.25, 0.25, 0.25, 0.6)

                    local nameText = nameBg:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                    nameText:SetPoint("LEFT", 6, 0)
                    nameText:SetPoint("RIGHT", -6, 0)
                    nameText:SetJustifyH("LEFT")
                    local displayName = data.name or (isItem and "Item " .. id or "Spell " .. id)
                    local durationStr = string.format("%.1fs", data.duration or 0)
                    nameText:SetText(displayName .. "  |cff888888" .. durationStr .. "|r")
                    nameText:SetTextColor(C.text[1], C.text[2], C.text[3], 1)

                    -- Delete button (X) - matches Tracked Items style
                    local removeBtn = CreateFrame("Button", nil, entryFrame, "BackdropTemplate")
                    removeBtn:SetSize(22, 22)
                    removeBtn:SetPoint("LEFT", nameBg, "RIGHT", 6, 0)
                    removeBtn:SetBackdrop({
                        bgFile = "Interface\\Buttons\\WHITE8x8",
                        edgeFile = "Interface\\Buttons\\WHITE8x8",
                        edgeSize = 1,
                    })
                    removeBtn:SetBackdropColor(0.15, 0.15, 0.15, 1)
                    removeBtn:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)

                    local removeText = removeBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                    removeText:SetPoint("CENTER", 0, 0)
                    removeText:SetText("X")
                    removeText:SetTextColor(C.accent[1], C.accent[2], C.accent[3], 1)

                    removeBtn:SetScript("OnClick", function()
                        if scannerDB then
                            if isItem then
                                scannerDB.items[id] = nil
                            else
                                scannerDB.spells[id] = nil
                            end
                            RefreshScannedList()
                        end
                    end)
                    removeBtn:SetScript("OnEnter", function(self)
                        self:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 1)
                    end)
                    removeBtn:SetScript("OnLeave", function(self)
                        self:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
                    end)

                    listY = listY - rowHeight
                end

                -- List spells
                for spellID, data in pairs((scannerDB and scannerDB.spells) or {}) do
                    CreateScannedRow(spellID, data, false)
                end

                -- List items
                for itemID, data in pairs((scannerDB and scannerDB.items) or {}) do
                    CreateScannedRow(itemID, data, true)
                end

                -- Update list frame height
                local listHeight = math.max(20, math.abs(listY))
                scannedListFrame:SetHeight(listHeight)
            end

            -- Scanned list container (no backdrop, matches Tracked Items style)
            scannedListFrame = CreateFrame("Frame", nil, tabContent)
            scannedListFrame:SetPoint("TOPLEFT", PAD, y)
            scannedListFrame:SetSize(400, 20)

            -- Register callback for real-time updates when spells are scanned
            if scanner then
                scanner.onScanCallback = RefreshScannedList
            end

            -- Populate the list
            RefreshScannedList()

            -- Lower container anchored to list (shifts down when list grows)
            local lowerContainer = CreateFrame("Frame", nil, tabContent)
            lowerContainer:SetPoint("TOPLEFT", scannedListFrame, "BOTTOMLEFT", 0, -15)
            lowerContainer:SetPoint("RIGHT", tabContent, "RIGHT", 0, 0)
            lowerContainer:SetHeight(100)
            lowerContainer:EnableMouse(false)

            -- Clear all button (in lower container)
            local clearBtn = GUI:CreateButton(lowerContainer, "Clear All Scanned", 140, 24, function()
                GUI:ShowConfirmation({
                    title = "Clear All Scanned Spells?",
                    message = "This will remove all scanned spell and item durations. You will need to cast them again to re-scan.",
                    acceptText = "Clear All",
                    cancelText = "Cancel",
                    onAccept = function()
                        local scannerDB = QUI.db and QUI.db.global and QUI.db.global.spellScanner
                        if scannerDB then
                            scannerDB.spells = {}
                            scannerDB.items = {}
                            RefreshScannedList()
                        end
                    end,
                })
            end)
            clearBtn:SetPoint("TOPLEFT", 0, 0)

            tabContent:SetHeight(500)
        end,
    })

    -- Add a tab for each existing bar
    for i, barConfig in ipairs(bars) do
        local tabName = barConfig.name or ("Tracker " .. i)
        -- Truncate long names for tab display
        if #tabName > 20 then
            tabName = tabName:sub(1, 17) .. "..."
        end
        table.insert(tabDefs, {
            name = tabName,
            builder = function(tabContent)
                -- Pass i+1 for subTabIndex since Spell Scanner is tab 1
                BuildTrackerBarTab(tabContent, barConfig, i + 1, subTabsRef)
            end,
        })
    end

    -- If no bars exist (only Spell Scanner tab), show empty state
    if #tabDefs == 1 then
        local emptyHeader = GUI:CreateSectionHeader(content, "Custom Tracker Bars")
        emptyHeader:SetPoint("TOPLEFT", PAD, -15)

        local emptyLabel = GUI:CreateLabel(content, "No tracker bars created yet. A default bar will be created on next /reload.", 12, C.textMuted)
        emptyLabel:SetPoint("TOPLEFT", PAD, -60)
        emptyLabel:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
        emptyLabel:SetJustifyH("LEFT")

        -- Add bar button
        local addBtn = GUI:CreateButton(content, "+ Add Tracker Bar", 160, 28, function()
            local newID = "tracker" .. (time() % 100000)
            -- Calculate position relative to player frame
            local newOffsetX, newOffsetY = CalculatePlayerRelativeOffset(-20, -50)
            local newBar = {
                id = newID,
                name = "Tracker " .. (#bars + 1),
                enabled = false,
                locked = false,
                offsetX = newOffsetX,
                offsetY = newOffsetY,
                growDirection = "RIGHT",
                iconSize = 28,
                spacing = 4,
                borderSize = 2,
                shape = "square",
                zoom = 0,
                durationSize = 13,
                durationColor = {1, 1, 1, 1},
                durationOffsetX = 0,
                durationOffsetY = 0,
                stackSize = 9,
                stackColor = {1, 1, 1, 1},
                stackOffsetX = 3,
                stackOffsetY = -1,
                bgOpacity = 0,
                hideGCD = true,
                showRechargeSwipe = false,
                entries = {},
            }
            table.insert(db.customTrackers.bars, newBar)
            if LUICore and LUICore.CustomTrackers then
                LUICore.CustomTrackers:RefreshAll()
            end
            GUI:ShowConfirmation({
                title = "Reload UI?",
                message = "Tracker bar created. Reload UI to configure it?",
                acceptText = "Reload",
                cancelText = "Later",
                onAccept = function() LuheyUI:SafeReload() end,
            })
        end)
        addBtn:SetPoint("TOPLEFT", PAD, -100)
        content:SetHeight(200)
    else
        -- Add a "+" tab to create new bars
        table.insert(tabDefs, {
            name = "+ Add Bar",
            builder = function(tabContent)
                local y = -10
                local header = GUI:CreateSectionHeader(tabContent, "Add New Tracker Bar")
                header:SetPoint("TOPLEFT", PAD, y)
                y = y - header.gap

                local desc = GUI:CreateLabel(tabContent, "Create a new tracker bar to monitor consumables, trinkets, or ability cooldowns.", 11, C.textMuted)
                desc:SetPoint("TOPLEFT", PAD, y)
                desc:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
                desc:SetJustifyH("LEFT")
                y = y - 30

                local addBtn = GUI:CreateButton(tabContent, "Create New Tracker Bar", 180, 28, function()
                    local newID = "tracker" .. (time() % 100000)
                    -- Calculate position relative to player frame (stagger by bar count)
                    local staggerY = #bars * 40  -- Each new bar 40px lower
                    local newOffsetX, newOffsetY = CalculatePlayerRelativeOffset(-20, -50 - staggerY)
                    local newBar = {
                        id = newID,
                        name = "Tracker " .. (#bars + 1),
                        enabled = false,
                        locked = false,
                        offsetX = newOffsetX,
                        offsetY = newOffsetY,
                        growDirection = "RIGHT",
                        iconSize = 28,
                        spacing = 4,
                        borderSize = 2,
                        shape = "square",
                        zoom = 0,
                        durationSize = 13,
                        durationColor = {1, 1, 1, 1},
                        durationOffsetX = 0,
                        durationOffsetY = 0,
                        stackSize = 9,
                        stackColor = {1, 1, 1, 1},
                        stackOffsetX = 3,
                        stackOffsetY = -1,
                        bgOpacity = 0,
                        hideGCD = true,
                        showRechargeSwipe = false,
                        entries = {},
                    }
                    table.insert(db.customTrackers.bars, newBar)
                    if LUICore and LUICore.CustomTrackers then
                        LUICore.CustomTrackers:RefreshAll()
                    end
                    GUI:ShowConfirmation({
                        title = "Reload UI?",
                        message = "Tracker bar created. Reload UI to configure it?",
                        acceptText = "Reload",
                        cancelText = "Later",
                        onAccept = function() LuheyUI:SafeReload() end,
                    })
                end)
                addBtn:SetPoint("TOPLEFT", PAD, y)
                tabContent:SetHeight(150)
            end,
        })

        -- Create sub-tabs
        local subTabs = GUI:CreateSubTabs(content, tabDefs)
        subTabsRef.tabButtons = subTabs.tabButtons  -- Populate reference for live tab text updates
        subTabs:SetPoint("TOPLEFT", 5, -5)
        subTabs:SetPoint("TOPRIGHT", -5, -5)
        subTabs:SetHeight(750)

        content:SetHeight(800)
    end
end

---------------------------------------------------------------------------
-- PAGE: UnitFrames (New Implementation with quiUnitFrames database)
---------------------------------------------------------------------------
local function CreateUnitFramesPage(parent)
    local scroll, content = CreateScrollableContent(parent)
    local db = GetDB()
    
    -- Get the new unit frames database
    local function GetUFDB()
        return db and db.quiUnitFrames
    end
    
    -- Refresh function for new unit frames
    local function RefreshNewUF()
        if _G.LuheyUI_RefreshUnitFrames then
            _G.LuheyUI_RefreshUnitFrames()
        end
    end
    
    -- Build the General tab content
    local function BuildGeneralTab(tabContent)
        local y = -10
        local PAD = 10
        local FORM_ROW = 32
        local ufdb = GetUFDB()

        -- Set search context for auto-registration
        GUI:SetSearchContext({tabIndex = 2, tabName = "Single Frames & Castbars", subTabIndex = 1, subTabName = "General"})

        if not ufdb then
            local info = GUI:CreateLabel(tabContent, "Unit frame settings not available - database not loaded", 12, C.textMuted)
            info:SetPoint("TOPLEFT", PAD, y)
            tabContent:SetHeight(100)
            return
        end

        -- Use the main profile general settings (not ufdb.general)
        local general = db.general
        if not general then
            db.general = {}
            general = db.general
        end

        -- Enable checkbox
        local enableCheck = GUI:CreateFormCheckbox(tabContent, "Enable Unitframes (Req. Reload)", "enabled", ufdb, RefreshNewUF)
        enableCheck:SetPoint("TOPLEFT", PAD, y)
        enableCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        -- EDIT MODE section
        local editHeader = GUI:CreateSectionHeader(tabContent, "Positioning")
        editHeader:SetPoint("TOPLEFT", PAD, y)
        y = y - editHeader.gap

        local editDesc = GUI:CreateLabel(tabContent, "Toggle Edit Mode to drag and reposition unit frames. Or use /lui editmode", 11, C.textMuted)
        editDesc:SetPoint("TOPLEFT", PAD, y)
        editDesc:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        editDesc:SetJustifyH("LEFT")
        y = y - 24

        -- Edit Mode button (form style)
        local editContainer = CreateFrame("Frame", nil, tabContent)
        editContainer:SetHeight(FORM_ROW)
        editContainer:SetPoint("TOPLEFT", PAD, y)
        editContainer:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)

        local editLabel = editContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        editLabel:SetPoint("LEFT", 0, 0)
        editLabel:SetText("Edit Mode")
        editLabel:SetTextColor(C.text[1], C.text[2], C.text[3], 1)

        local editModeBtn = CreateFrame("Button", nil, editContainer, "BackdropTemplate")
        editModeBtn:SetSize(120, 24)
        editModeBtn:SetPoint("LEFT", editContainer, "LEFT", 180, 0)
        editModeBtn:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        editModeBtn:SetBackdropColor(0.15, 0.15, 0.15, 1)
        editModeBtn:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], 1)

        local editBtnText = editModeBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        editBtnText:SetPoint("CENTER")
        editBtnText:SetText("Toggle")
        editBtnText:SetTextColor(C.text[1], C.text[2], C.text[3], 1)

        editModeBtn:SetScript("OnEnter", function(self)
            self:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 1)
        end)
        editModeBtn:SetScript("OnLeave", function(self)
            self:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], 1)
        end)
        editModeBtn:SetScript("OnClick", function()
            if _G.LuheyUI_ToggleUnitFrameEditMode then
                _G.LuheyUI_ToggleUnitFrameEditMode()
            end
        end)
        y = y - FORM_ROW - 10

        -- Store widget refs for BOTH sections (bidirectional conditional disable)
        local defaultWidgets = {}
        local darkModeWidgets = {}

        -- Helper to update enable states based on dark mode toggle
        local function UpdateDarkModeWidgetStates()
            local darkModeOn = general.darkMode
            -- Default widgets: enabled when dark mode OFF
            if defaultWidgets.healthColor then defaultWidgets.healthColor:SetEnabled(not darkModeOn) end
            if defaultWidgets.bgColor then defaultWidgets.bgColor:SetEnabled(not darkModeOn) end
            if defaultWidgets.opacity then defaultWidgets.opacity:SetEnabled(not darkModeOn) end
            -- Darkmode widgets: enabled when dark mode ON
            if darkModeWidgets.healthColor then darkModeWidgets.healthColor:SetEnabled(darkModeOn) end
            if darkModeWidgets.bgColor then darkModeWidgets.bgColor:SetEnabled(darkModeOn) end
            if darkModeWidgets.opacity then darkModeWidgets.opacity:SetEnabled(darkModeOn) end
        end

        -- DEFAULT UNITFRAME COLORS section
        local defaultHeader = GUI:CreateSectionHeader(tabContent, "Default Unitframe Colors")
        defaultHeader:SetPoint("TOPLEFT", PAD, y)
        y = y - defaultHeader.gap

        local defaultDesc = GUI:CreateLabel(tabContent, "Colors and opacity applied to unit frames when Dark Mode is disabled.", 11, C.textMuted)
        defaultDesc:SetPoint("TOPLEFT", PAD, y)
        defaultDesc:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        defaultDesc:SetJustifyH("LEFT")
        y = y - 24

        -- Use Class Colors toggle (greys out Default Health Color when ON)
        local defUseClassColor = GUI:CreateFormCheckbox(tabContent, "Use Class Colors", "defaultUseClassColor", general, function()
            RefreshNewUF()
            -- Grey out health color picker when class colors is enabled
            if defaultWidgets.healthColor then
                defaultWidgets.healthColor:SetEnabled(not general.defaultUseClassColor)
            end
        end)
        defUseClassColor:SetPoint("TOPLEFT", PAD, y)
        defUseClassColor:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        defaultWidgets.useClassColor = defUseClassColor
        y = y - FORM_ROW

        -- Default Health Color (greyed out when Use Class Colors is ON)
        local defHealthColor = GUI:CreateFormColorPicker(tabContent, "Default Health Color", "defaultHealthColor", general, RefreshNewUF, { noAlpha = true })
        defHealthColor:SetPoint("TOPLEFT", PAD, y)
        defHealthColor:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        defaultWidgets.healthColor = defHealthColor
        defHealthColor:SetEnabled(not general.defaultUseClassColor)  -- Initial state
        y = y - FORM_ROW

        -- Default Background Color
        local defBgColor = GUI:CreateFormColorPicker(tabContent, "Default Background Color", "defaultBgColor", general, RefreshNewUF, { noAlpha = true })
        defBgColor:SetPoint("TOPLEFT", PAD, y)
        defBgColor:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        defaultWidgets.bgColor = defBgColor
        y = y - FORM_ROW

        -- Health Opacity slider
        local defHealthOpacity = GUI:CreateFormSlider(tabContent, "Health Opacity", 0.1, 1.0, 0.01, "defaultHealthOpacity", general, RefreshNewUF)
        defHealthOpacity:SetPoint("TOPLEFT", PAD, y)
        defHealthOpacity:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        defaultWidgets.healthOpacity = defHealthOpacity
        y = y - FORM_ROW

        -- Background Opacity slider
        local defBgOpacity = GUI:CreateFormSlider(tabContent, "Background Opacity", 0.1, 1.0, 0.01, "defaultBgOpacity", general, RefreshNewUF)
        defBgOpacity:SetPoint("TOPLEFT", PAD, y)
        defBgOpacity:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        defaultWidgets.bgOpacity = defBgOpacity
        y = y - FORM_ROW - 10

        -- DARK MODE section
        local darkHeader = GUI:CreateSectionHeader(tabContent, "Darkmode For Unitframes")
        darkHeader:SetPoint("TOPLEFT", PAD, y)
        y = y - darkHeader.gap

        local darkDesc = GUI:CreateLabel(tabContent, "Instantly applies dark flat colors to all unit frame health bars.", 11, C.textMuted)
        darkDesc:SetPoint("TOPLEFT", PAD, y)
        darkDesc:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        darkDesc:SetJustifyH("LEFT")
        y = y - 24

        local darkEnable = GUI:CreateFormCheckbox(tabContent, "Enable Dark Mode", "darkMode", general, function()
            RefreshNewUF()
            UpdateDarkModeWidgetStates()
        end)
        darkEnable:SetPoint("TOPLEFT", PAD, y)
        darkEnable:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        -- Darkmode Health Color (no alpha - pure RGB)
        local healthColor = GUI:CreateFormColorPicker(tabContent, "Darkmode Health Color", "darkModeHealthColor", general, RefreshNewUF, { noAlpha = true })
        healthColor:SetPoint("TOPLEFT", PAD, y)
        healthColor:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        darkModeWidgets.healthColor = healthColor
        y = y - FORM_ROW

        -- Darkmode Background Color (no alpha - pure RGB)
        local bgColor = GUI:CreateFormColorPicker(tabContent, "Darkmode Background Color", "darkModeBgColor", general, RefreshNewUF, { noAlpha = true })
        bgColor:SetPoint("TOPLEFT", PAD, y)
        bgColor:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        darkModeWidgets.bgColor = bgColor
        y = y - FORM_ROW

        -- Darkmode Health Opacity slider
        local dmHealthOpacity = GUI:CreateFormSlider(tabContent, "Darkmode Health Opacity", 0.1, 1.0, 0.01, "darkModeHealthOpacity", general, RefreshNewUF)
        dmHealthOpacity:SetPoint("TOPLEFT", PAD, y)
        dmHealthOpacity:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        darkModeWidgets.healthOpacity = dmHealthOpacity
        y = y - FORM_ROW

        -- Darkmode Background Opacity slider
        local dmBgOpacity = GUI:CreateFormSlider(tabContent, "Darkmode Background Opacity", 0.1, 1.0, 0.01, "darkModeBgOpacity", general, RefreshNewUF)
        dmBgOpacity:SetPoint("TOPLEFT", PAD, y)
        dmBgOpacity:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        darkModeWidgets.bgOpacity = dmBgOpacity
        y = y - FORM_ROW - 10

        -- Set initial enable/disable states for both sections
        UpdateDarkModeWidgetStates()

        -- MASTER TEXT COLOR OVERRIDES section
        local textHeader = GUI:CreateSectionHeader(tabContent, "Text Class Color/React Color Overrides (Recommended For Dark Mode)")
        textHeader:SetPoint("TOPLEFT", PAD, y)
        y = y - textHeader.gap

        local textDesc = GUI:CreateLabel(tabContent, "Apply class/reaction color to text across ALL unit frames. When enabled, master toggles override individual frame settings.", 11, C.textMuted)
        textDesc:SetPoint("TOPLEFT", PAD, y)
        textDesc:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        textDesc:SetJustifyH("LEFT")
        textDesc:SetWordWrap(true)
        textDesc:SetHeight(30)
        y = y - 40

        local masterNameText = GUI:CreateFormCheckbox(tabContent, "Color ALL Name Text", "masterColorNameText", general, RefreshNewUF)
        masterNameText:SetPoint("TOPLEFT", PAD, y)
        masterNameText:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local masterHealthText = GUI:CreateFormCheckbox(tabContent, "Color ALL Health Text", "masterColorHealthText", general, RefreshNewUF)
        masterHealthText:SetPoint("TOPLEFT", PAD, y)
        masterHealthText:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local masterPowerText = GUI:CreateFormCheckbox(tabContent, "Color ALL Power Text", "masterColorPowerText", general, RefreshNewUF)
        masterPowerText:SetPoint("TOPLEFT", PAD, y)
        masterPowerText:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local masterCastbarText = GUI:CreateFormCheckbox(tabContent, "Color ALL Castbar Text", "masterColorCastbarText", general, RefreshNewUF)
        masterCastbarText:SetPoint("TOPLEFT", PAD, y)
        masterCastbarText:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local masterToTText = GUI:CreateFormCheckbox(tabContent, "Color ALL ToT Text", "masterColorToTText", general, RefreshNewUF)
        masterToTText:SetPoint("TOPLEFT", PAD, y)
        masterToTText:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        -- TOOLTIPS SECTION
        y = y - 10

        local tooltipHeader = GUI:CreateSectionHeader(tabContent, "Tooltips on QUI Unitframes")
        tooltipHeader:SetPoint("TOPLEFT", PAD, y)
        y = y - tooltipHeader.gap

        local tooltipCheck = GUI:CreateFormCheckbox(tabContent, "Show Tooltip for Unitframes", "showTooltips", ufdb.general, RefreshNewUF)
        tooltipCheck:SetPoint("TOPLEFT", PAD, y)
        tooltipCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        -- Smoother Updates section
        local smoothHeader = GUI:CreateSectionHeader(tabContent, "Smoother Updates")
        smoothHeader:SetPoint("TOPLEFT", PAD, y)
        y = y - smoothHeader.gap

        local smoothDesc = GUI:CreateLabel(tabContent, "Target, Focus, and Boss castbars are throttled to 60 FPS for CPU efficiency. Enable this option if you prefer maximum smoothness and don't mind the extra CPU usage.", 11, C.textMuted)
        smoothDesc:SetPoint("TOPLEFT", PAD, y)
        smoothDesc:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        smoothDesc:SetJustifyH("LEFT")
        y = y - 24

        local smoothCheck = GUI:CreateFormCheckbox(tabContent, "Smoother Animation", "smootherAnimation", ufdb.general, RefreshNewUF)
        smoothCheck:SetPoint("TOPLEFT", PAD, y)
        smoothCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        -- Hostility Color Customization section
        local hostilityHeader = GUI:CreateSectionHeader(tabContent, "Hostility Color Customization")
        hostilityHeader:SetPoint("TOPLEFT", PAD, y)
        y = y - hostilityHeader.gap

        local hostilityDesc = GUI:CreateLabel(tabContent, "Customize the colors used for hostile, neutral, and friendly NPCs on unit frames that have 'Use Hostility Color' enabled.", 11, C.textMuted)
        hostilityDesc:SetPoint("TOPLEFT", PAD, y)
        hostilityDesc:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        hostilityDesc:SetJustifyH("LEFT")
        y = y - 24

        local hostileColor = GUI:CreateFormColorPicker(tabContent, "Hostile Color", "hostilityColorHostile", general, RefreshNewUF, { noAlpha = true })
        hostileColor:SetPoint("TOPLEFT", PAD, y)
        hostileColor:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local neutralColor = GUI:CreateFormColorPicker(tabContent, "Neutral Color", "hostilityColorNeutral", general, RefreshNewUF, { noAlpha = true })
        neutralColor:SetPoint("TOPLEFT", PAD, y)
        neutralColor:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local friendlyColor = GUI:CreateFormColorPicker(tabContent, "Friendly Color", "hostilityColorFriendly", general, RefreshNewUF, { noAlpha = true })
        friendlyColor:SetPoint("TOPLEFT", PAD, y)
        friendlyColor:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        tabContent:SetHeight(math.abs(y) + 20)
    end
    
    -- Build unit-specific tab content (Player, Target, etc.)
    local function BuildUnitTab(tabContent, unitKey)
        local y = -10
        local PAD = 10
        local FORM_ROW = 32
        local ufdb = GetUFDB()

        -- Set search context for widget auto-registration (dynamic based on unitKey)
        local unitSubTabs = {
            player = {index = 2, name = "Player"},
            target = {index = 3, name = "Target"},
            targettarget = {index = 4, name = "ToT"},
            pet = {index = 5, name = "Pet"},
            focus = {index = 6, name = "Focus"},
            boss = {index = 7, name = "Boss"},
        }
        local subTabInfo = unitSubTabs[unitKey] or {index = 2, name = unitKey}
        GUI:SetSearchContext({tabIndex = 2, tabName = "Single Frames & Castbars", subTabIndex = subTabInfo.index, subTabName = subTabInfo.name})

        if not ufdb or not ufdb[unitKey] then
            local info = GUI:CreateLabel(tabContent, "Unit frame settings not available for " .. unitKey, 12, C.textMuted)
            info:SetPoint("TOPLEFT", PAD, y)
            tabContent:SetHeight(100)
            return
        end

        local unitDB = ufdb[unitKey]

        -- Refresh function for this specific unit
        local function RefreshUnit()
            RefreshNewUF()
            -- Preview state is now in database, CreateCastbar will handle it
        end

        -- Refresh function specifically for aura settings
        local function RefreshAuras()
            RefreshNewUF()
            -- Refresh aura preview if active (re-render with new settings)
            local LUI_UF = ns.LUI_UnitFrames
            if LUI_UF and LUI_UF.auraPreviewMode then
                if LUI_UF.auraPreviewMode[unitKey .. "_debuff"] then
                    _G.LuheyUI_ShowAuraPreview(unitKey, "debuff")
                end
                if LUI_UF.auraPreviewMode[unitKey .. "_buff"] then
                    _G.LuheyUI_ShowAuraPreview(unitKey, "buff")
                end
            end
            -- Refresh real auras if not in preview mode
            if _G.LuheyUI_RefreshAuras then
                _G.LuheyUI_RefreshAuras(unitKey)
            end
        end

        -- Preview button row (form style)
        local previewContainer = CreateFrame("Frame", nil, tabContent)
        previewContainer:SetHeight(FORM_ROW)
        previewContainer:SetPoint("TOPLEFT", PAD, y)
        previewContainer:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)

        local previewLabel = previewContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        previewLabel:SetPoint("LEFT", 0, 0)
        previewLabel:SetText("Frame Preview")
        previewLabel:SetTextColor(C.text[1], C.text[2], C.text[3], 1)

        -- Toggle track (pill-shaped, matches CreateFormToggle)
        local previewTrack = CreateFrame("Button", nil, previewContainer, "BackdropTemplate")
        previewTrack:SetSize(40, 20)
        previewTrack:SetPoint("LEFT", previewContainer, "LEFT", 180, 0)
        previewTrack:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1})

        -- Thumb (sliding circle)
        local previewThumb = CreateFrame("Frame", nil, previewTrack, "BackdropTemplate")
        previewThumb:SetSize(16, 16)
        previewThumb:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1})
        previewThumb:SetBackdropColor(0.95, 0.95, 0.95, 1)
        previewThumb:SetBackdropBorderColor(0.85, 0.85, 0.85, 1)
        previewThumb:SetFrameLevel(previewTrack:GetFrameLevel() + 1)

        -- Initialize state (preview defaults to off when panel opens)
        local isPreviewOn = false
        local function UpdatePreviewToggle(on)
            if on then
                previewTrack:SetBackdropColor(C.accent[1], C.accent[2], C.accent[3], 1)
                previewTrack:SetBackdropBorderColor(C.accent[1]*0.8, C.accent[2]*0.8, C.accent[3]*0.8, 1)
                previewThumb:ClearAllPoints()
                previewThumb:SetPoint("RIGHT", previewTrack, "RIGHT", -2, 0)
            else
                previewTrack:SetBackdropColor(0.15, 0.18, 0.22, 1)
                previewTrack:SetBackdropBorderColor(0.12, 0.14, 0.18, 1)
                previewThumb:ClearAllPoints()
                previewThumb:SetPoint("LEFT", previewTrack, "LEFT", 2, 0)
            end
        end
        UpdatePreviewToggle(isPreviewOn)

        previewTrack:SetScript("OnClick", function()
            isPreviewOn = not isPreviewOn
            UpdatePreviewToggle(isPreviewOn)
            if isPreviewOn then
                if _G.LuheyUI_ShowUnitFramePreview then _G.LuheyUI_ShowUnitFramePreview(unitKey) end
            else
                if _G.LuheyUI_HideUnitFramePreview then _G.LuheyUI_HideUnitFramePreview(unitKey) end
            end
        end)
        y = y - FORM_ROW

        -- Enable checkbox (requires reload)
        local displayNames = {targettarget = "Target of Target"}
        local frameName = displayNames[unitKey] or unitKey:gsub("^%l", string.upper)
        local enableCheck = GUI:CreateFormCheckbox(tabContent, "Enable " .. frameName .. " Frame", "enabled", unitDB, function()
            GUI:ShowConfirmation({
                title = "Reload UI?",
                message = "Enabling or disabling unit frames requires a UI reload to take effect.",
                acceptText = "Reload",
                cancelText = "Later",
                onAccept = function() LuheyUI:SafeReload() end,
            })
        end)
        enableCheck:SetPoint("TOPLEFT", PAD, y)
        enableCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW
        
        -- FRAME SIZE section
        local sizeHeader = GUI:CreateSectionHeader(tabContent, "Frame Size & Position")
        sizeHeader:SetPoint("TOPLEFT", PAD, y)
        y = y - sizeHeader.gap

        -- Size sliders (form style)
        -- For player unit, wrap callback to also update locked castbar width
        local widthCallback = RefreshUnit
        if unitKey == "player" then
            widthCallback = function()
                RefreshUnit()
                if _G.LuheyUI_UpdateLockedCastbarToFrame then
                    _G.LuheyUI_UpdateLockedCastbarToFrame()
                end
            end
        end
        local widthSlider = GUI:CreateFormSlider(tabContent, "Width", 100, 500, 1, "width", unitDB, widthCallback)
        widthSlider:SetPoint("TOPLEFT", PAD, y)
        widthSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local heightSlider = GUI:CreateFormSlider(tabContent, "Height", 20, 100, 1, "height", unitDB, RefreshUnit)
        heightSlider:SetPoint("TOPLEFT", PAD, y)
        heightSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local borderSizeSlider = GUI:CreateFormSlider(tabContent, "Border Size", 0, 5, 1, "borderSize", unitDB, RefreshUnit)
        borderSizeSlider:SetPoint("TOPLEFT", PAD, y)
        borderSizeSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        -- Boss frames get spacing slider
        if unitKey == "boss" then
            local spacingSlider = GUI:CreateFormSlider(tabContent, "Spacing", 0, 100, 1, "spacing", unitDB, RefreshUnit)
            spacingSlider:SetPoint("TOPLEFT", PAD, y)
            spacingSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW
        end

        -- Position sliders
        local offsetXSlider = GUI:CreateFormSlider(tabContent, "X Offset", -3000, 3000, 1, "offsetX", unitDB, RefreshUnit)
        offsetXSlider:SetPoint("TOPLEFT", PAD, y)
        offsetXSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local offsetYSlider = GUI:CreateFormSlider(tabContent, "Y Offset", -3000, 3000, 1, "offsetY", unitDB, RefreshUnit)
        offsetYSlider:SetPoint("TOPLEFT", PAD, y)
        offsetYSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        -- Register sliders for real-time sync during Edit Mode
        if _G.LuheyUI_RegisterEditModeSliders then
            _G.LuheyUI_RegisterEditModeSliders(unitKey, offsetXSlider, offsetYSlider)
        end

        -- Frame Anchoring section (only for player and target)
        if unitKey == "player" or unitKey == "target" then
            local anchorHeader = GUI:CreateSectionHeader(tabContent, "Frame Anchoring")
            anchorHeader:SetPoint("TOPLEFT", PAD, y)
            y = y - anchorHeader.gap

            -- Initialize defaults if needed
            if unitDB.anchorTo == nil then unitDB.anchorTo = "disabled" end
            if unitDB.anchorGap == nil then unitDB.anchorGap = 10 end
            if unitDB.anchorYOffset == nil then unitDB.anchorYOffset = 0 end

            -- Description text
            local anchorDesc = GUI:CreateLabel(tabContent,
                unitKey == "player"
                    and "Anchors frame to the LEFT edge of selected target. As the anchor width changes, this frame will reposition automatically."
                    or "Anchors frame to the RIGHT edge of selected target. As the anchor width changes, this frame will reposition automatically.",
                11, C.textMuted)
            anchorDesc:SetPoint("TOPLEFT", PAD, y)
            anchorDesc:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            anchorDesc:SetJustifyH("LEFT")
            y = y - 36

            -- Forward declarations for sliders
            local anchorGapSlider, anchorYOffsetSlider

            -- Helper function to update slider enabled states
            local function UpdateAnchorSliderStates()
                local isAnchored = unitDB.anchorTo and unitDB.anchorTo ~= "disabled"
                if isAnchored then
                    anchorGapSlider:SetAlpha(1)
                    anchorGapSlider:EnableMouse(true)
                    anchorYOffsetSlider:SetAlpha(1)
                    anchorYOffsetSlider:EnableMouse(true)
                    offsetXSlider:SetAlpha(0.4)
                    offsetXSlider:EnableMouse(false)
                    offsetYSlider:SetAlpha(0.4)
                    offsetYSlider:EnableMouse(false)
                else
                    anchorGapSlider:SetAlpha(0.4)
                    anchorGapSlider:EnableMouse(false)
                    anchorYOffsetSlider:SetAlpha(0.4)
                    anchorYOffsetSlider:EnableMouse(false)
                    offsetXSlider:SetAlpha(1)
                    offsetXSlider:EnableMouse(true)
                    offsetYSlider:SetAlpha(1)
                    offsetYSlider:EnableMouse(true)
                end
            end

            -- Anchor dropdown with 5 options
            local anchorOptions = {
                {value = "disabled", text = "Disabled"},
                {value = "essential", text = "Essential CDM"},
                {value = "utility", text = "Utility CDM"},
                {value = "primary", text = "Primary Resource Bar"},
                {value = "secondary", text = "Secondary Resource Bar"},
            }
            local anchorDropdown = GUI:CreateFormDropdown(tabContent, "Anchor To", anchorOptions, "anchorTo", unitDB, function()
                RefreshUnit()
                if _G.LuheyUI_UpdateAnchoredUnitFrames then
                    _G.LuheyUI_UpdateAnchoredUnitFrames()
                end
                UpdateAnchorSliderStates()
            end)
            anchorDropdown:SetPoint("TOPLEFT", PAD, y)
            anchorDropdown:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            -- Horizontal gap slider
            anchorGapSlider = GUI:CreateFormSlider(tabContent, "Horizontal Gap", 0, 100, 1, "anchorGap", unitDB, function()
                if _G.LuheyUI_UpdateAnchoredUnitFrames then
                    _G.LuheyUI_UpdateAnchoredUnitFrames()
                end
            end)
            anchorGapSlider:SetPoint("TOPLEFT", PAD, y)
            anchorGapSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            -- Vertical offset slider
            anchorYOffsetSlider = GUI:CreateFormSlider(tabContent, "Vertical Offset", -200, 200, 1, "anchorYOffset", unitDB, function()
                if _G.LuheyUI_UpdateAnchoredUnitFrames then
                    _G.LuheyUI_UpdateAnchoredUnitFrames()
                end
            end)
            anchorYOffsetSlider:SetPoint("TOPLEFT", PAD, y)
            anchorYOffsetSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            -- Set initial enabled state
            UpdateAnchorSliderStates()
        end

        -- Texture dropdown
        local textureDropdown = GUI:CreateFormDropdown(tabContent, "Bar Texture", GetTextureList(), "texture", unitDB, RefreshUnit)
        textureDropdown:SetPoint("TOPLEFT", PAD, y)
        textureDropdown:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW
        
        -- COLORS section
        local colorHeader = GUI:CreateSectionHeader(tabContent, "Health Bar Colors")
        colorHeader:SetPoint("TOPLEFT", PAD, y)
        y = y - colorHeader.gap

        -- Helper text explaining color priority (only for frames with hostility option)
        if unitKey ~= "player" then
            local colorDesc = GUI:CreateLabel(tabContent, "Class color for players, hostility color for NPCs. Custom color is the fallback.", 11, C.textMuted)
            colorDesc:SetPoint("TOPLEFT", PAD, y)
            colorDesc:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            colorDesc:SetJustifyH("LEFT")
            y = y - 24
        end

        -- Store custom color reference for conditional disable
        local customColor = nil

        local classColorCheck = GUI:CreateFormCheckbox(tabContent, "Use Class Color", "useClassColor", unitDB, RefreshUnit)
        classColorCheck:SetPoint("TOPLEFT", PAD, y)
        classColorCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        -- Hostility Color checkbox (for frames that can show varied unit types)
        if unitKey == "target" or unitKey == "focus" or unitKey == "targettarget" or unitKey == "pet" or unitKey == "boss" then
            local hostilityColorCheck = GUI:CreateFormCheckbox(tabContent, "Use Hostility Color", "useHostilityColor", unitDB, function()
                RefreshUnit()
                -- Disable custom color when hostility is ON (covers all units)
                if customColor then
                    customColor:SetEnabled(not unitDB.useHostilityColor)
                end
            end)
            hostilityColorCheck:SetPoint("TOPLEFT", PAD, y)
            hostilityColorCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW
        end

        customColor = GUI:CreateFormColorPicker(tabContent, "Custom Color", "customHealthColor", unitDB, RefreshUnit)
        customColor:SetPoint("TOPLEFT", PAD, y)
        customColor:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        -- Set initial enabled state based on hostility setting
        if unitKey == "target" or unitKey == "focus" or unitKey == "targettarget" or unitKey == "pet" or unitKey == "boss" then
            customColor:SetEnabled(not unitDB.useHostilityColor)
        end
        y = y - FORM_ROW

        -- ABSORB INDICATOR section
        local absorbHeader = GUI:CreateSectionHeader(tabContent, "Absorb Indicator")
        absorbHeader:SetPoint("TOPLEFT", PAD, y)
        y = y - absorbHeader.gap

        if not unitDB.absorbs then
            unitDB.absorbs = {
                enabled = true,
                color = { 0.2, 0.8, 0.8 },
                opacity = 0.7,
                texture = "LUI Stripes",
            }
        end

        local absorbCheck = GUI:CreateFormCheckbox(tabContent, "Show Absorb Shields", "enabled", unitDB.absorbs, RefreshUnit)
        absorbCheck:SetPoint("TOPLEFT", PAD, y)
        absorbCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local absorbOpacity = GUI:CreateFormSlider(tabContent, "Opacity", 0, 1, 0.05, "opacity", unitDB.absorbs, RefreshUnit)
        absorbOpacity:SetPoint("TOPLEFT", PAD, y)
        absorbOpacity:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local absorbColor = GUI:CreateFormColorPicker(tabContent, "Absorb Color", "color", unitDB.absorbs, RefreshUnit)
        absorbColor:SetPoint("TOPLEFT", PAD, y)
        absorbColor:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local absorbTexture = GUI:CreateFormDropdown(tabContent, "Absorb Texture", GetTextureList(), "texture", unitDB.absorbs, RefreshUnit)
        absorbTexture:SetPoint("TOPLEFT", PAD, y)
        absorbTexture:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local absorbTextureDesc = GUI:CreateLabel(tabContent, "Supports SharedMedia textures. Install the SharedMedia addon to add your own.", 11, C.textMuted)
        absorbTextureDesc:SetPoint("TOPLEFT", PAD, y + 4)
        absorbTextureDesc:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        absorbTextureDesc:SetJustifyH("LEFT")
        y = y - 20

        -- NAME TEXT section
        local nameHeader = GUI:CreateSectionHeader(tabContent, "Name Text")
        nameHeader:SetPoint("TOPLEFT", PAD, y)
        y = y - nameHeader.gap

        local showNameCheck = GUI:CreateFormCheckbox(tabContent, "Show Name", "showName", unitDB, RefreshUnit)
        showNameCheck:SetPoint("TOPLEFT", PAD, y)
        showNameCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        -- Anchor options for text positioning
        local anchorOptions = {
            {value = "TOPLEFT", text = "Top Left"},
            {value = "TOP", text = "Top Center"},
            {value = "TOPRIGHT", text = "Top Right"},
            {value = "LEFT", text = "Center Left"},
            {value = "CENTER", text = "Center"},
            {value = "RIGHT", text = "Center Right"},
            {value = "BOTTOMLEFT", text = "Bottom Left"},
            {value = "BOTTOM", text = "Bottom Center"},
            {value = "BOTTOMRIGHT", text = "Bottom Right"},
        }

        local nameSizeSlider = GUI:CreateFormSlider(tabContent, "Font Size", 8, 24, 1, "nameFontSize", unitDB, RefreshUnit)
        nameSizeSlider:SetPoint("TOPLEFT", PAD, y)
        nameSizeSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local nameColorPicker = GUI:CreateFormColorPicker(tabContent, "Custom Name Text Color", "nameTextColor", unitDB, RefreshUnit)
        nameColorPicker:SetPoint("TOPLEFT", PAD, y)
        nameColorPicker:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local nameAnchorDropdown = GUI:CreateFormDropdown(tabContent, "Anchor", anchorOptions, "nameAnchor", unitDB, RefreshUnit)
        nameAnchorDropdown:SetPoint("TOPLEFT", PAD, y)
        nameAnchorDropdown:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local nameXSlider = GUI:CreateFormSlider(tabContent, "X Offset", -100, 100, 1, "nameOffsetX", unitDB, RefreshUnit)
        nameXSlider:SetPoint("TOPLEFT", PAD, y)
        nameXSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local nameYSlider = GUI:CreateFormSlider(tabContent, "Y Offset", -50, 50, 1, "nameOffsetY", unitDB, RefreshUnit)
        nameYSlider:SetPoint("TOPLEFT", PAD, y)
        nameYSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local nameTruncSlider = GUI:CreateFormSlider(tabContent, "Max Length (0=none)", 0, 30, 1, "maxNameLength", unitDB, RefreshUnit)
        nameTruncSlider:SetPoint("TOPLEFT", PAD, y)
        nameTruncSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        -- TARGET OF TARGET TEXT section (target only)
        if unitKey == "target" then
            local totHeader = GUI:CreateSectionHeader(tabContent, "Target Of Target Text")
            totHeader:SetPoint("TOPLEFT", PAD, y)
            y = y - totHeader.gap

            local totCheck = GUI:CreateFormCheckbox(tabContent, "Show Inline Target-of-Target", "showInlineToT", unitDB, RefreshUnit)
            totCheck:SetPoint("TOPLEFT", PAD, y)
            totCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            local totSepOptions = {
                {value = " >> ", text = ">>"},
                {value = " > ", text = ">"},
                {value = " - ", text = "-"},
                {value = " | ", text = "|"},
                {value = " -> ", text = "->"},
                {value = " —> ", text = "—>"},
                {value = " >>> ", text = ">>>"},
            }
            local totSepDropdown = GUI:CreateFormDropdown(tabContent, "ToT Separator", totSepOptions, "totSeparator", unitDB, RefreshUnit)
            totSepDropdown:SetPoint("TOPLEFT", PAD, y)
            totSepDropdown:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            -- Store reference for enable/disable logic
            local totDividerWidgets = {}

            -- Toggle: Color Divider By Class/React
            local totDividerClassCheck = GUI:CreateFormCheckbox(tabContent, "Color Divider By Class/React", "totDividerUseClassColor", unitDB, function()
                RefreshUnit()
                -- Disable custom color picker when class color is enabled
                if totDividerWidgets.customColor then
                    totDividerWidgets.customColor:SetEnabled(not unitDB.totDividerUseClassColor)
                end
            end)
            totDividerClassCheck:SetPoint("TOPLEFT", PAD, y)
            totDividerClassCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            -- Color Picker: Custom Divider Color (disabled when class color toggle is ON)
            local totDividerColor = GUI:CreateFormColorPicker(tabContent, "Custom Divider Color", "totDividerColor", unitDB, RefreshUnit)
            totDividerColor:SetPoint("TOPLEFT", PAD, y)
            totDividerColor:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            totDividerWidgets.customColor = totDividerColor
            totDividerColor:SetEnabled(not unitDB.totDividerUseClassColor)  -- Initial state
            y = y - FORM_ROW

            local totCharLimitSlider = GUI:CreateFormSlider(tabContent, "ToT Name Character Limit", 0, 100, 1, "totNameCharLimit", unitDB, RefreshUnit)
            totCharLimitSlider:SetPoint("TOPLEFT", PAD, y)
            totCharLimitSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW
        end

        -- HEALTH TEXT section
        local healthHeader = GUI:CreateSectionHeader(tabContent, "Health Text")
        healthHeader:SetPoint("TOPLEFT", PAD, y)
        y = y - healthHeader.gap

        local showHealthCheck = GUI:CreateFormCheckbox(tabContent, "Show Health", "showHealth", unitDB, RefreshUnit)
        showHealthCheck:SetPoint("TOPLEFT", PAD, y)
        showHealthCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local healthStyleOptions = {
            {value = "percent", text = "Percent Only (75%)"},
            {value = "absolute", text = "Value Only (45.2k)"},
            {value = "both", text = "Value | Percent"},
            {value = "both_reverse", text = "Percent | Value"},
            {value = "missing_percent", text = "Missing Percent (-25%)"},
            {value = "missing_value", text = "Missing Value (-12.5k)"},
        }
        local healthStyleDropdown = GUI:CreateFormDropdown(tabContent, "Display Style", healthStyleOptions, "healthDisplayStyle", unitDB, RefreshUnit)
        healthStyleDropdown:SetPoint("TOPLEFT", PAD, y)
        healthStyleDropdown:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local healthDividerOptions = {
            {value = " | ", text = "|  (pipe)"},
            {value = " - ", text = "-  (dash)"},
            {value = " / ", text = "/  (slash)"},
            {value = " • ", text = "•  (dot)"},
        }
        local healthDividerDropdown = GUI:CreateFormDropdown(tabContent, "Divider", healthDividerOptions, "healthDivider", unitDB, RefreshUnit)
        healthDividerDropdown:SetPoint("TOPLEFT", PAD, y)
        healthDividerDropdown:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local healthTextColorPicker = GUI:CreateFormColorPicker(tabContent, "Custom Health Text Color", "healthTextColor", unitDB, RefreshUnit)
        healthTextColorPicker:SetPoint("TOPLEFT", PAD, y)
        healthTextColorPicker:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local healthSizeSlider = GUI:CreateFormSlider(tabContent, "Font Size", 8, 24, 1, "healthFontSize", unitDB, RefreshUnit)
        healthSizeSlider:SetPoint("TOPLEFT", PAD, y)
        healthSizeSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local healthAnchorDropdown = GUI:CreateFormDropdown(tabContent, "Anchor", anchorOptions, "healthAnchor", unitDB, RefreshUnit)
        healthAnchorDropdown:SetPoint("TOPLEFT", PAD, y)
        healthAnchorDropdown:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local healthXSlider = GUI:CreateFormSlider(tabContent, "X Offset", -100, 100, 1, "healthOffsetX", unitDB, RefreshUnit)
        healthXSlider:SetPoint("TOPLEFT", PAD, y)
        healthXSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local healthYSlider = GUI:CreateFormSlider(tabContent, "Y Offset", -50, 50, 1, "healthOffsetY", unitDB, RefreshUnit)
        healthYSlider:SetPoint("TOPLEFT", PAD, y)
        healthYSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        -- POWER BAR section
        local powerHeader = GUI:CreateSectionHeader(tabContent, "Power Bar")
        powerHeader:SetPoint("TOPLEFT", PAD, y)
        y = y - powerHeader.gap

        local showPowerCheck = GUI:CreateFormCheckbox(tabContent, "Show Power Bar", "showPowerBar", unitDB, RefreshUnit)
        showPowerCheck:SetPoint("TOPLEFT", PAD, y)
        showPowerCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local powerHeightSlider = GUI:CreateFormSlider(tabContent, "Power Bar Height", 1, 20, 1, "powerBarHeight", unitDB, RefreshUnit)
        powerHeightSlider:SetPoint("TOPLEFT", PAD, y)
        powerHeightSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local powerBorderCheck = GUI:CreateFormCheckbox(tabContent, "Power Bar Border", "powerBarBorder", unitDB, RefreshUnit)
        powerBorderCheck:SetPoint("TOPLEFT", PAD, y)
        powerBorderCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local powerBarColorPicker  -- Forward declare for closure

        local powerBarUsePowerColor = GUI:CreateFormCheckbox(tabContent, "Use Power Type Color", "powerBarUsePowerColor", unitDB, function()
            RefreshUnit()
            -- Grey out color picker when power type color is enabled
            if powerBarColorPicker then
                powerBarColorPicker:SetEnabled(not unitDB.powerBarUsePowerColor)
            end
        end)
        powerBarUsePowerColor:SetPoint("TOPLEFT", PAD, y)
        powerBarUsePowerColor:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        powerBarColorPicker = GUI:CreateFormColorPicker(tabContent, "Custom Bar Color", "powerBarColor", unitDB, RefreshUnit)
        powerBarColorPicker:SetPoint("TOPLEFT", PAD, y)
        powerBarColorPicker:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        -- Set initial state (greyed out if power type color is enabled)
        powerBarColorPicker:SetEnabled(not unitDB.powerBarUsePowerColor)
        y = y - FORM_ROW

        -- POWER TEXT section
        local powerTextHeader = GUI:CreateSectionHeader(tabContent, "Power Text")
        powerTextHeader:SetPoint("TOPLEFT", PAD, y)
        y = y - powerTextHeader.gap

        local showPowerTextCheck = GUI:CreateFormCheckbox(tabContent, "Show Power Text", "showPowerText", unitDB, RefreshUnit)
        showPowerTextCheck:SetPoint("TOPLEFT", PAD, y)
        showPowerTextCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local powerTextFormatOptions = {
            {value = "percent", text = "Percent (75%)"},
            {value = "current", text = "Current (12.5k)"},
            {value = "both", text = "Both (12.5k | 75%)"},
        }
        local powerTextFormatDropdown = GUI:CreateFormDropdown(tabContent, "Display Format", powerTextFormatOptions, "powerTextFormat", unitDB, RefreshUnit)
        powerTextFormatDropdown:SetPoint("TOPLEFT", PAD, y)
        powerTextFormatDropdown:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local powerTextColorPicker  -- Forward declare for closure

        local powerTextUsePowerColor = GUI:CreateFormCheckbox(tabContent, "Use Power Type Color", "powerTextUsePowerColor", unitDB, function()
            RefreshUnit()
            if powerTextColorPicker then
                powerTextColorPicker:SetEnabled(not unitDB.powerTextUsePowerColor)
            end
        end)
        powerTextUsePowerColor:SetPoint("TOPLEFT", PAD, y)
        powerTextUsePowerColor:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        powerTextColorPicker = GUI:CreateFormColorPicker(tabContent, "Custom Power Text Color", "powerTextColor", unitDB, RefreshUnit)
        powerTextColorPicker:SetPoint("TOPLEFT", PAD, y)
        powerTextColorPicker:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        powerTextColorPicker:SetEnabled(not unitDB.powerTextUsePowerColor)
        y = y - FORM_ROW

        local powerTextSizeSlider = GUI:CreateFormSlider(tabContent, "Font Size", 8, 24, 1, "powerTextFontSize", unitDB, RefreshUnit)
        powerTextSizeSlider:SetPoint("TOPLEFT", PAD, y)
        powerTextSizeSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local powerTextAnchorDropdown = GUI:CreateFormDropdown(tabContent, "Anchor", anchorOptions, "powerTextAnchor", unitDB, RefreshUnit)
        powerTextAnchorDropdown:SetPoint("TOPLEFT", PAD, y)
        powerTextAnchorDropdown:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local powerTextXSlider = GUI:CreateFormSlider(tabContent, "X Offset", -100, 100, 1, "powerTextOffsetX", unitDB, RefreshUnit)
        powerTextXSlider:SetPoint("TOPLEFT", PAD, y)
        powerTextXSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local powerTextYSlider = GUI:CreateFormSlider(tabContent, "Y Offset", -50, 50, 1, "powerTextOffsetY", unitDB, RefreshUnit)
        powerTextYSlider:SetPoint("TOPLEFT", PAD, y)
        powerTextYSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        -- Helper to copy castbar settings from one unit to another
        local function CopyCastbarSettings(sourceDB, targetDB)
            if not sourceDB or not targetDB then return end
            local keys = {"width", "height", "offsetX", "offsetY", "fontSize", "borderSize", "maxLength", "texture", "showIcon", "enabled"}
            for _, key in ipairs(keys) do
                if sourceDB[key] ~= nil then
                    targetDB[key] = sourceDB[key]
                end
            end
            if sourceDB.color then
                targetDB.color = {sourceDB.color[1], sourceDB.color[2], sourceDB.color[3], sourceDB.color[4]}
            end
            if sourceDB.bgColor then
                targetDB.bgColor = {sourceDB.bgColor[1], sourceDB.bgColor[2], sourceDB.bgColor[3], sourceDB.bgColor[4]}
            end
        end

        -- CASTBAR section (for player, target, targettarget, focus, pet, boss)
        if unitKey == "player" or unitKey == "target" or unitKey == "targettarget" or unitKey == "focus" or unitKey == "pet" or unitKey == "boss" then
            -- Use dedicated castbar options module (it creates its own header)
            if ns.LUI_CastbarOptions and ns.LUI_CastbarOptions.BuildCastbarOptions then
                y = ns.LUI_CastbarOptions.BuildCastbarOptions(tabContent, unitKey, y, PAD, FORM_ROW, RefreshUnit, GetTextureList, NINE_POINT_ANCHOR_OPTIONS, GetUFDB, GetDB)
            end
        end

        -- Aura settings (all single unit frames)
        if unitKey == "player" or unitKey == "target" or unitKey == "focus"
           or unitKey == "pet" or unitKey == "targettarget" or unitKey == "boss" then
            if not unitDB.auras then unitDB.auras = {} end
            local auraDB = unitDB.auras
            if auraDB.showBuffs == nil then auraDB.showBuffs = false end
            if auraDB.showDebuffs == nil then auraDB.showDebuffs = false end
            if unitKey ~= "player" then
                if auraDB.onlyMyDebuffs == nil then auraDB.onlyMyDebuffs = true end
            end
            if auraDB.iconSize == nil then auraDB.iconSize = 22 end
            if auraDB.buffIconSize == nil then auraDB.buffIconSize = 22 end
            if auraDB.debuffAnchor == nil then auraDB.debuffAnchor = "TOPLEFT" end
            if auraDB.debuffGrow == nil then auraDB.debuffGrow = "RIGHT" end
            if auraDB.debuffOffsetX == nil then auraDB.debuffOffsetX = 0 end
            if auraDB.debuffOffsetY == nil then auraDB.debuffOffsetY = 2 end
            if auraDB.buffAnchor == nil then auraDB.buffAnchor = "BOTTOMLEFT" end
            if auraDB.buffGrow == nil then auraDB.buffGrow = "RIGHT" end
            if auraDB.buffOffsetX == nil then auraDB.buffOffsetX = 0 end
            if auraDB.buffOffsetY == nil then auraDB.buffOffsetY = -2 end
            if auraDB.debuffMaxIcons == nil then auraDB.debuffMaxIcons = 16 end
            if auraDB.buffMaxIcons == nil then auraDB.buffMaxIcons = 16 end

            local auraAnchorOptions = {
                {value = "TOPLEFT", text = "Top Left"},
                {value = "TOPRIGHT", text = "Top Right"},
                {value = "BOTTOMLEFT", text = "Bottom Left"},
                {value = "BOTTOMRIGHT", text = "Bottom Right"},
            }
            local growOptions = {
                {value = "LEFT", text = "Left"},
                {value = "RIGHT", text = "Right"},
                {value = "UP", text = "Up"},
                {value = "DOWN", text = "Down"},
            }
            local ninePointAnchorOptions = {
                {value = "TOPLEFT", text = "Top Left"},
                {value = "TOP", text = "Top"},
                {value = "TOPRIGHT", text = "Top Right"},
                {value = "LEFT", text = "Left"},
                {value = "CENTER", text = "Center"},
                {value = "RIGHT", text = "Right"},
                {value = "BOTTOMLEFT", text = "Bottom Left"},
                {value = "BOTTOM", text = "Bottom"},
                {value = "BOTTOMRIGHT", text = "Bottom Right"},
            }

            -- === DEBUFF ICONS SECTION ===
            local debuffHeader = GUI:CreateSectionHeader(tabContent, "Debuff Icons")
            debuffHeader:SetPoint("TOPLEFT", PAD, y)
            y = y - debuffHeader.gap

            local showDebuffsCheck = GUI:CreateFormCheckbox(tabContent, "Show Debuffs", "showDebuffs", auraDB, RefreshAuras)
            showDebuffsCheck:SetPoint("TOPLEFT", PAD, y)
            showDebuffsCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            local debuffHideSwipe = GUI:CreateFormCheckbox(tabContent, "Hide Duration Swipe", "debuffHideSwipe", auraDB, RefreshAuras)
            debuffHideSwipe:SetPoint("TOPLEFT", PAD, y)
            debuffHideSwipe:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            if unitKey ~= "player" then
                local onlyMyDebuffsCheck = GUI:CreateFormCheckbox(tabContent, "Only My Debuffs", "onlyMyDebuffs", auraDB, RefreshAuras)
                onlyMyDebuffsCheck:SetPoint("TOPLEFT", PAD, y)
                onlyMyDebuffsCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
                y = y - FORM_ROW
            end

            -- Debuff Preview toggle (pill-shaped, matches Castbar Preview style)
            local debuffPreviewContainer = CreateFrame("Frame", nil, tabContent)
            debuffPreviewContainer:SetHeight(FORM_ROW)
            debuffPreviewContainer:SetPoint("TOPLEFT", PAD, y)
            debuffPreviewContainer:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)

            local debuffPreviewLabel = debuffPreviewContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            debuffPreviewLabel:SetPoint("LEFT", 0, 0)
            debuffPreviewLabel:SetText("Debuff Preview")
            debuffPreviewLabel:SetTextColor(C.text[1], C.text[2], C.text[3], 1)

            local debuffPreviewTrack = CreateFrame("Button", nil, debuffPreviewContainer, "BackdropTemplate")
            debuffPreviewTrack:SetSize(40, 20)
            debuffPreviewTrack:SetPoint("LEFT", debuffPreviewContainer, "LEFT", 180, 0)
            debuffPreviewTrack:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1})

            local debuffPreviewThumb = CreateFrame("Frame", nil, debuffPreviewTrack, "BackdropTemplate")
            debuffPreviewThumb:SetSize(16, 16)
            debuffPreviewThumb:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1})
            debuffPreviewThumb:SetBackdropColor(0.95, 0.95, 0.95, 1)
            debuffPreviewThumb:SetBackdropBorderColor(0.85, 0.85, 0.85, 1)
            debuffPreviewThumb:SetFrameLevel(debuffPreviewTrack:GetFrameLevel() + 1)

            local isDebuffPreviewOn = false
            local function UpdateDebuffPreviewToggle(on)
                if on then
                    debuffPreviewTrack:SetBackdropColor(C.accent[1], C.accent[2], C.accent[3], 1)
                    debuffPreviewTrack:SetBackdropBorderColor(C.accent[1]*0.8, C.accent[2]*0.8, C.accent[3]*0.8, 1)
                    debuffPreviewThumb:ClearAllPoints()
                    debuffPreviewThumb:SetPoint("RIGHT", debuffPreviewTrack, "RIGHT", -2, 0)
                else
                    debuffPreviewTrack:SetBackdropColor(0.15, 0.18, 0.22, 1)
                    debuffPreviewTrack:SetBackdropBorderColor(0.12, 0.14, 0.18, 1)
                    debuffPreviewThumb:ClearAllPoints()
                    debuffPreviewThumb:SetPoint("LEFT", debuffPreviewTrack, "LEFT", 2, 0)
                end
            end
            UpdateDebuffPreviewToggle(isDebuffPreviewOn)

            debuffPreviewTrack:SetScript("OnClick", function()
                isDebuffPreviewOn = not isDebuffPreviewOn
                UpdateDebuffPreviewToggle(isDebuffPreviewOn)
                if isDebuffPreviewOn then
                    if _G.LuheyUI_ShowAuraPreview then
                        _G.LuheyUI_ShowAuraPreview(unitKey, "debuff")
                    end
                else
                    if _G.LuheyUI_HideAuraPreview then
                        _G.LuheyUI_HideAuraPreview(unitKey, "debuff")
                    end
                end
            end)
            y = y - FORM_ROW

            local auraIconSize = GUI:CreateFormSlider(tabContent, "Icon Size", 12, 50, 1, "iconSize", auraDB, RefreshAuras)
            auraIconSize:SetPoint("TOPLEFT", PAD, y)
            auraIconSize:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            local debuffAnchorDrop = GUI:CreateFormDropdown(tabContent, "Anchor", auraAnchorOptions, "debuffAnchor", auraDB, RefreshAuras)
            debuffAnchorDrop:SetPoint("TOPLEFT", PAD, y)
            debuffAnchorDrop:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            local debuffGrowDrop = GUI:CreateFormDropdown(tabContent, "Grow Direction", growOptions, "debuffGrow", auraDB, RefreshAuras)
            debuffGrowDrop:SetPoint("TOPLEFT", PAD, y)
            debuffGrowDrop:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            local debuffMaxSlider = GUI:CreateFormSlider(tabContent, "Max Icons", 1, 32, 1, "debuffMaxIcons", auraDB, RefreshAuras)
            debuffMaxSlider:SetPoint("TOPLEFT", PAD, y)
            debuffMaxSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            local debuffXSlider = GUI:CreateFormSlider(tabContent, "X Offset", -100, 100, 1, "debuffOffsetX", auraDB, RefreshAuras)
            debuffXSlider:SetPoint("TOPLEFT", PAD, y)
            debuffXSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            local debuffYSlider = GUI:CreateFormSlider(tabContent, "Y Offset", -100, 100, 1, "debuffOffsetY", auraDB, RefreshAuras)
            debuffYSlider:SetPoint("TOPLEFT", PAD, y)
            debuffYSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            -- Debuff-specific text customization (stack and duration)
            if unitKey == "target" or unitKey == "player" or unitKey == "focus" or unitKey == "targettarget" or unitKey == "boss" then
                -- Initialize debuff-specific defaults
                if auraDB.debuffSpacing == nil then auraDB.debuffSpacing = 2 end
                if auraDB.debuffShowStack == nil then auraDB.debuffShowStack = true end
                if auraDB.debuffStackSize == nil then auraDB.debuffStackSize = 10 end
                if auraDB.debuffStackAnchor == nil then auraDB.debuffStackAnchor = "BOTTOMRIGHT" end
                if auraDB.debuffStackOffsetX == nil then auraDB.debuffStackOffsetX = -1 end
                if auraDB.debuffStackOffsetY == nil then auraDB.debuffStackOffsetY = 1 end
                if auraDB.debuffStackColor == nil then auraDB.debuffStackColor = {1, 1, 1, 1} end
                -- Duration defaults
                if auraDB.debuffShowDuration == nil then auraDB.debuffShowDuration = true end
                if auraDB.debuffDurationSize == nil then auraDB.debuffDurationSize = 12 end
                if auraDB.debuffDurationAnchor == nil then auraDB.debuffDurationAnchor = "CENTER" end
                if auraDB.debuffDurationOffsetX == nil then auraDB.debuffDurationOffsetX = 0 end
                if auraDB.debuffDurationOffsetY == nil then auraDB.debuffDurationOffsetY = 0 end
                if auraDB.debuffDurationColor == nil then auraDB.debuffDurationColor = {1, 1, 1, 1} end

                local debuffSpacingSlider = GUI:CreateFormSlider(tabContent, "Spacing", 0, 10, 1, "debuffSpacing", auraDB, RefreshAuras)
                debuffSpacingSlider:SetPoint("TOPLEFT", PAD, y)
                debuffSpacingSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
                y = y - FORM_ROW

                local debuffShowStackCheck = GUI:CreateFormCheckbox(tabContent, "Stack Show", "debuffShowStack", auraDB, RefreshAuras)
                debuffShowStackCheck:SetPoint("TOPLEFT", PAD, y)
                debuffShowStackCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
                y = y - FORM_ROW

                local debuffStackSizeSlider = GUI:CreateFormSlider(tabContent, "Stack Size", 8, 40, 1, "debuffStackSize", auraDB, RefreshAuras)
                debuffStackSizeSlider:SetPoint("TOPLEFT", PAD, y)
                debuffStackSizeSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
                y = y - FORM_ROW

                local debuffStackAnchorDD = GUI:CreateFormDropdown(tabContent, "Stack Anchor", ninePointAnchorOptions, "debuffStackAnchor", auraDB, RefreshAuras)
                debuffStackAnchorDD:SetPoint("TOPLEFT", PAD, y)
                debuffStackAnchorDD:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
                y = y - FORM_ROW

                local debuffStackXSlider = GUI:CreateFormSlider(tabContent, "Stack X Offset", -20, 20, 1, "debuffStackOffsetX", auraDB, RefreshAuras)
                debuffStackXSlider:SetPoint("TOPLEFT", PAD, y)
                debuffStackXSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
                y = y - FORM_ROW

                local debuffStackYSlider = GUI:CreateFormSlider(tabContent, "Stack Y Offset", -20, 20, 1, "debuffStackOffsetY", auraDB, RefreshAuras)
                debuffStackYSlider:SetPoint("TOPLEFT", PAD, y)
                debuffStackYSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
                y = y - FORM_ROW

                local debuffStackColorPicker = GUI:CreateFormColorPicker(tabContent, "Stack Color", "debuffStackColor", auraDB, RefreshAuras)
                debuffStackColorPicker:SetPoint("TOPLEFT", PAD, y)
                debuffStackColorPicker:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
                y = y - FORM_ROW

                -- Duration text settings
                local debuffShowDurationCheck = GUI:CreateFormCheckbox(tabContent, "Duration Show", "debuffShowDuration", auraDB, RefreshAuras)
                debuffShowDurationCheck:SetPoint("TOPLEFT", PAD, y)
                debuffShowDurationCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
                y = y - FORM_ROW

                local debuffDurationSizeSlider = GUI:CreateFormSlider(tabContent, "Duration Size", 8, 40, 1, "debuffDurationSize", auraDB, RefreshAuras)
                debuffDurationSizeSlider:SetPoint("TOPLEFT", PAD, y)
                debuffDurationSizeSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
                y = y - FORM_ROW

                local debuffDurationAnchorDD = GUI:CreateFormDropdown(tabContent, "Duration Anchor", ninePointAnchorOptions, "debuffDurationAnchor", auraDB, RefreshAuras)
                debuffDurationAnchorDD:SetPoint("TOPLEFT", PAD, y)
                debuffDurationAnchorDD:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
                y = y - FORM_ROW

                local debuffDurationXSlider = GUI:CreateFormSlider(tabContent, "Duration X Offset", -20, 20, 1, "debuffDurationOffsetX", auraDB, RefreshAuras)
                debuffDurationXSlider:SetPoint("TOPLEFT", PAD, y)
                debuffDurationXSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
                y = y - FORM_ROW

                local debuffDurationYSlider = GUI:CreateFormSlider(tabContent, "Duration Y Offset", -20, 20, 1, "debuffDurationOffsetY", auraDB, RefreshAuras)
                debuffDurationYSlider:SetPoint("TOPLEFT", PAD, y)
                debuffDurationYSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
                y = y - FORM_ROW

                local debuffDurationColorPicker = GUI:CreateFormColorPicker(tabContent, "Duration Color", "debuffDurationColor", auraDB, RefreshAuras)
                debuffDurationColorPicker:SetPoint("TOPLEFT", PAD, y)
                debuffDurationColorPicker:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
                y = y - FORM_ROW
            end

            -- === BUFF ICONS SECTION ===
            local buffHeader = GUI:CreateSectionHeader(tabContent, "Buff Icons")
            buffHeader:SetPoint("TOPLEFT", PAD, y)
            y = y - buffHeader.gap

            local showBuffsCheck = GUI:CreateFormCheckbox(tabContent, "Show Buffs", "showBuffs", auraDB, RefreshAuras)
            showBuffsCheck:SetPoint("TOPLEFT", PAD, y)
            showBuffsCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            local buffHideSwipe = GUI:CreateFormCheckbox(tabContent, "Hide Duration Swipe", "buffHideSwipe", auraDB, RefreshAuras)
            buffHideSwipe:SetPoint("TOPLEFT", PAD, y)
            buffHideSwipe:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            -- Buff Preview toggle (pill-shaped, matches Castbar Preview style)
            local buffPreviewContainer = CreateFrame("Frame", nil, tabContent)
            buffPreviewContainer:SetHeight(FORM_ROW)
            buffPreviewContainer:SetPoint("TOPLEFT", PAD, y)
            buffPreviewContainer:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)

            local buffPreviewLabel = buffPreviewContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            buffPreviewLabel:SetPoint("LEFT", 0, 0)
            buffPreviewLabel:SetText("Buff Preview")
            buffPreviewLabel:SetTextColor(C.text[1], C.text[2], C.text[3], 1)

            local buffPreviewTrack = CreateFrame("Button", nil, buffPreviewContainer, "BackdropTemplate")
            buffPreviewTrack:SetSize(40, 20)
            buffPreviewTrack:SetPoint("LEFT", buffPreviewContainer, "LEFT", 180, 0)
            buffPreviewTrack:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1})

            local buffPreviewThumb = CreateFrame("Frame", nil, buffPreviewTrack, "BackdropTemplate")
            buffPreviewThumb:SetSize(16, 16)
            buffPreviewThumb:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1})
            buffPreviewThumb:SetBackdropColor(0.95, 0.95, 0.95, 1)
            buffPreviewThumb:SetBackdropBorderColor(0.85, 0.85, 0.85, 1)
            buffPreviewThumb:SetFrameLevel(buffPreviewTrack:GetFrameLevel() + 1)

            local isBuffPreviewOn = false
            local function UpdateBuffPreviewToggle(on)
                if on then
                    buffPreviewTrack:SetBackdropColor(C.accent[1], C.accent[2], C.accent[3], 1)
                    buffPreviewTrack:SetBackdropBorderColor(C.accent[1]*0.8, C.accent[2]*0.8, C.accent[3]*0.8, 1)
                    buffPreviewThumb:ClearAllPoints()
                    buffPreviewThumb:SetPoint("RIGHT", buffPreviewTrack, "RIGHT", -2, 0)
                else
                    buffPreviewTrack:SetBackdropColor(0.15, 0.18, 0.22, 1)
                    buffPreviewTrack:SetBackdropBorderColor(0.12, 0.14, 0.18, 1)
                    buffPreviewThumb:ClearAllPoints()
                    buffPreviewThumb:SetPoint("LEFT", buffPreviewTrack, "LEFT", 2, 0)
                end
            end
            UpdateBuffPreviewToggle(isBuffPreviewOn)

            buffPreviewTrack:SetScript("OnClick", function()
                isBuffPreviewOn = not isBuffPreviewOn
                UpdateBuffPreviewToggle(isBuffPreviewOn)
                if isBuffPreviewOn then
                    if _G.LuheyUI_ShowAuraPreview then
                        _G.LuheyUI_ShowAuraPreview(unitKey, "buff")
                    end
                else
                    if _G.LuheyUI_HideAuraPreview then
                        _G.LuheyUI_HideAuraPreview(unitKey, "buff")
                    end
                end
            end)
            y = y - FORM_ROW

            local buffIconSize = GUI:CreateFormSlider(tabContent, "Icon Size", 12, 50, 1, "buffIconSize", auraDB, RefreshAuras)
            buffIconSize:SetPoint("TOPLEFT", PAD, y)
            buffIconSize:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            local buffAnchorDrop = GUI:CreateFormDropdown(tabContent, "Anchor", auraAnchorOptions, "buffAnchor", auraDB, RefreshAuras)
            buffAnchorDrop:SetPoint("TOPLEFT", PAD, y)
            buffAnchorDrop:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            local buffGrowDrop = GUI:CreateFormDropdown(tabContent, "Grow Direction", growOptions, "buffGrow", auraDB, RefreshAuras)
            buffGrowDrop:SetPoint("TOPLEFT", PAD, y)
            buffGrowDrop:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            local buffMaxSlider = GUI:CreateFormSlider(tabContent, "Max Icons", 1, 32, 1, "buffMaxIcons", auraDB, RefreshAuras)
            buffMaxSlider:SetPoint("TOPLEFT", PAD, y)
            buffMaxSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            local buffXSlider = GUI:CreateFormSlider(tabContent, "X Offset", -100, 100, 1, "buffOffsetX", auraDB, RefreshAuras)
            buffXSlider:SetPoint("TOPLEFT", PAD, y)
            buffXSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            local buffYSlider = GUI:CreateFormSlider(tabContent, "Y Offset", -100, 100, 1, "buffOffsetY", auraDB, RefreshAuras)
            buffYSlider:SetPoint("TOPLEFT", PAD, y)
            buffYSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            -- Buff-specific text customization (stack and duration)
            if unitKey == "target" or unitKey == "player" or unitKey == "focus" or unitKey == "targettarget" or unitKey == "boss" then
                -- Initialize buff-specific defaults
                if auraDB.buffSpacing == nil then auraDB.buffSpacing = 2 end
                if auraDB.buffShowStack == nil then auraDB.buffShowStack = true end
                if auraDB.buffStackSize == nil then auraDB.buffStackSize = 10 end
                if auraDB.buffStackAnchor == nil then auraDB.buffStackAnchor = "BOTTOMRIGHT" end
                if auraDB.buffStackOffsetX == nil then auraDB.buffStackOffsetX = -1 end
                if auraDB.buffStackOffsetY == nil then auraDB.buffStackOffsetY = 1 end
                if auraDB.buffStackColor == nil then auraDB.buffStackColor = {1, 1, 1, 1} end
                -- Duration defaults
                if auraDB.buffShowDuration == nil then auraDB.buffShowDuration = true end
                if auraDB.buffDurationSize == nil then auraDB.buffDurationSize = 12 end
                if auraDB.buffDurationAnchor == nil then auraDB.buffDurationAnchor = "CENTER" end
                if auraDB.buffDurationOffsetX == nil then auraDB.buffDurationOffsetX = 0 end
                if auraDB.buffDurationOffsetY == nil then auraDB.buffDurationOffsetY = 0 end
                if auraDB.buffDurationColor == nil then auraDB.buffDurationColor = {1, 1, 1, 1} end

                local buffSpacingSlider = GUI:CreateFormSlider(tabContent, "Spacing", 0, 10, 1, "buffSpacing", auraDB, RefreshAuras)
                buffSpacingSlider:SetPoint("TOPLEFT", PAD, y)
                buffSpacingSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
                y = y - FORM_ROW

                local buffShowStackCheck = GUI:CreateFormCheckbox(tabContent, "Stack Show", "buffShowStack", auraDB, RefreshAuras)
                buffShowStackCheck:SetPoint("TOPLEFT", PAD, y)
                buffShowStackCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
                y = y - FORM_ROW

                local buffStackSizeSlider = GUI:CreateFormSlider(tabContent, "Stack Size", 8, 40, 1, "buffStackSize", auraDB, RefreshAuras)
                buffStackSizeSlider:SetPoint("TOPLEFT", PAD, y)
                buffStackSizeSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
                y = y - FORM_ROW

                local buffStackAnchorDD = GUI:CreateFormDropdown(tabContent, "Stack Anchor", ninePointAnchorOptions, "buffStackAnchor", auraDB, RefreshAuras)
                buffStackAnchorDD:SetPoint("TOPLEFT", PAD, y)
                buffStackAnchorDD:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
                y = y - FORM_ROW

                local buffStackXSlider = GUI:CreateFormSlider(tabContent, "Stack X Offset", -20, 20, 1, "buffStackOffsetX", auraDB, RefreshAuras)
                buffStackXSlider:SetPoint("TOPLEFT", PAD, y)
                buffStackXSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
                y = y - FORM_ROW

                local buffStackYSlider = GUI:CreateFormSlider(tabContent, "Stack Y Offset", -20, 20, 1, "buffStackOffsetY", auraDB, RefreshAuras)
                buffStackYSlider:SetPoint("TOPLEFT", PAD, y)
                buffStackYSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
                y = y - FORM_ROW

                local buffStackColorPicker = GUI:CreateFormColorPicker(tabContent, "Stack Color", "buffStackColor", auraDB, RefreshAuras)
                buffStackColorPicker:SetPoint("TOPLEFT", PAD, y)
                buffStackColorPicker:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
                y = y - FORM_ROW

                -- Duration text settings
                local buffShowDurationCheck = GUI:CreateFormCheckbox(tabContent, "Duration Show", "buffShowDuration", auraDB, RefreshAuras)
                buffShowDurationCheck:SetPoint("TOPLEFT", PAD, y)
                buffShowDurationCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
                y = y - FORM_ROW

                local buffDurationSizeSlider = GUI:CreateFormSlider(tabContent, "Duration Size", 8, 40, 1, "buffDurationSize", auraDB, RefreshAuras)
                buffDurationSizeSlider:SetPoint("TOPLEFT", PAD, y)
                buffDurationSizeSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
                y = y - FORM_ROW

                local buffDurationAnchorDD = GUI:CreateFormDropdown(tabContent, "Duration Anchor", ninePointAnchorOptions, "buffDurationAnchor", auraDB, RefreshAuras)
                buffDurationAnchorDD:SetPoint("TOPLEFT", PAD, y)
                buffDurationAnchorDD:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
                y = y - FORM_ROW

                local buffDurationXSlider = GUI:CreateFormSlider(tabContent, "Duration X Offset", -20, 20, 1, "buffDurationOffsetX", auraDB, RefreshAuras)
                buffDurationXSlider:SetPoint("TOPLEFT", PAD, y)
                buffDurationXSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
                y = y - FORM_ROW

                local buffDurationYSlider = GUI:CreateFormSlider(tabContent, "Duration Y Offset", -20, 20, 1, "buffDurationOffsetY", auraDB, RefreshAuras)
                buffDurationYSlider:SetPoint("TOPLEFT", PAD, y)
                buffDurationYSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
                y = y - FORM_ROW

                local buffDurationColorPicker = GUI:CreateFormColorPicker(tabContent, "Duration Color", "buffDurationColor", auraDB, RefreshAuras)
                buffDurationColorPicker:SetPoint("TOPLEFT", PAD, y)
                buffDurationColorPicker:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
                y = y - FORM_ROW
            end
        end

        -- STATUS INDICATORS section (player only)
        if unitKey == "player" then
            local indicatorsHeader = GUI:CreateSectionHeader(tabContent, "Status Indicators")
            indicatorsHeader:SetPoint("TOPLEFT", PAD, y)
            y = y - indicatorsHeader.gap

            -- Ensure indicators table exists
            if not unitDB.indicators then
                unitDB.indicators = {
                    rested = { enabled = true, size = 16, anchor = "TOPLEFT", offsetX = -2, offsetY = 2 },
                    combat = { enabled = false, size = 16, anchor = "TOPLEFT", offsetX = -2, offsetY = 2 },
                }
            end

            -- Rested indicator
            local restedDesc = GUI:CreateLabel(tabContent, "Rested: Shows when in a rested area (disabled by default).", 11, C.textMuted)
            restedDesc:SetPoint("TOPLEFT", PAD, y)
            restedDesc:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            restedDesc:SetJustifyH("LEFT")
            y = y - 20

            local restedCheck = GUI:CreateFormCheckbox(tabContent, "Enable Rested Indicator", "enabled", unitDB.indicators.rested, RefreshUnit)
            restedCheck:SetPoint("TOPLEFT", PAD, y)
            restedCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            local restedSizeSlider = GUI:CreateFormSlider(tabContent, "Rested Icon Size", 8, 32, 1, "size", unitDB.indicators.rested, RefreshUnit)
            restedSizeSlider:SetPoint("TOPLEFT", PAD, y)
            restedSizeSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            local restedAnchorDrop = GUI:CreateFormDropdown(tabContent, "Rested Anchor", anchorOptions, "anchor", unitDB.indicators.rested, RefreshUnit)
            restedAnchorDrop:SetPoint("TOPLEFT", PAD, y)
            restedAnchorDrop:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            local restedXSlider = GUI:CreateFormSlider(tabContent, "Rested X Offset", -50, 50, 1, "offsetX", unitDB.indicators.rested, RefreshUnit)
            restedXSlider:SetPoint("TOPLEFT", PAD, y)
            restedXSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            local restedYSlider = GUI:CreateFormSlider(tabContent, "Rested Y Offset", -50, 50, 1, "offsetY", unitDB.indicators.rested, RefreshUnit)
            restedYSlider:SetPoint("TOPLEFT", PAD, y)
            restedYSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            -- Combat indicator
            local combatDesc = GUI:CreateLabel(tabContent, "Combat: Shows during combat (disabled by default).", 11, C.textMuted)
            combatDesc:SetPoint("TOPLEFT", PAD, y)
            combatDesc:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            combatDesc:SetJustifyH("LEFT")
            y = y - 20

            local combatCheck = GUI:CreateFormCheckbox(tabContent, "Enable Combat Indicator", "enabled", unitDB.indicators.combat, RefreshUnit)
            combatCheck:SetPoint("TOPLEFT", PAD, y)
            combatCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            local combatSizeSlider = GUI:CreateFormSlider(tabContent, "Combat Icon Size", 8, 32, 1, "size", unitDB.indicators.combat, RefreshUnit)
            combatSizeSlider:SetPoint("TOPLEFT", PAD, y)
            combatSizeSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            local combatAnchorDrop = GUI:CreateFormDropdown(tabContent, "Combat Anchor", anchorOptions, "anchor", unitDB.indicators.combat, RefreshUnit)
            combatAnchorDrop:SetPoint("TOPLEFT", PAD, y)
            combatAnchorDrop:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            local combatXSlider = GUI:CreateFormSlider(tabContent, "Combat X Offset", -50, 50, 1, "offsetX", unitDB.indicators.combat, RefreshUnit)
            combatXSlider:SetPoint("TOPLEFT", PAD, y)
            combatXSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            local combatYSlider = GUI:CreateFormSlider(tabContent, "Combat Y Offset", -50, 50, 1, "offsetY", unitDB.indicators.combat, RefreshUnit)
            combatYSlider:SetPoint("TOPLEFT", PAD, y)
            combatYSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            -- ═══════════════════════════════════════════════════════════════
            -- STANCE/FORM TEXT SECTION (player only)
            -- ═══════════════════════════════════════════════════════════════
            local stanceHeader = GUI:CreateSectionHeader(tabContent, "Stance / Form Text")
            stanceHeader:SetPoint("TOPLEFT", PAD, y)
            y = y - stanceHeader.gap

            -- Ensure stance table exists
            if not unitDB.indicators.stance then
                unitDB.indicators.stance = {
                    enabled = false,
                    fontSize = 12,
                    anchor = "BOTTOM",
                    offsetX = 0,
                    offsetY = -2,
                    useClassColor = true,
                    customColor = { 1, 1, 1, 1 },
                    showIcon = false,
                    iconSize = 14,
                    iconOffsetX = -2,
                }
            end

            local stanceDesc = GUI:CreateLabel(tabContent, "Displays current stance, form, or aura (e.g. Bear Form, Battle Stance, Devotion Aura).", 11, C.textMuted)
            stanceDesc:SetPoint("TOPLEFT", PAD, y)
            stanceDesc:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            stanceDesc:SetJustifyH("LEFT")
            y = y - 20

            local stanceCheck = GUI:CreateFormCheckbox(tabContent, "Show Stance/Form Text", "enabled", unitDB.indicators.stance, RefreshUnit)
            stanceCheck:SetPoint("TOPLEFT", PAD, y)
            stanceCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            local stanceFontSize = GUI:CreateFormSlider(tabContent, "Font Size", 8, 24, 1, "fontSize", unitDB.indicators.stance, RefreshUnit)
            stanceFontSize:SetPoint("TOPLEFT", PAD, y)
            stanceFontSize:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            local stanceAnchorDrop = GUI:CreateFormDropdown(tabContent, "Anchor", anchorOptions, "anchor", unitDB.indicators.stance, RefreshUnit)
            stanceAnchorDrop:SetPoint("TOPLEFT", PAD, y)
            stanceAnchorDrop:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            local stanceXSlider = GUI:CreateFormSlider(tabContent, "X Offset", -100, 100, 1, "offsetX", unitDB.indicators.stance, RefreshUnit)
            stanceXSlider:SetPoint("TOPLEFT", PAD, y)
            stanceXSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            local stanceYSlider = GUI:CreateFormSlider(tabContent, "Y Offset", -100, 100, 1, "offsetY", unitDB.indicators.stance, RefreshUnit)
            stanceYSlider:SetPoint("TOPLEFT", PAD, y)
            stanceYSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            local stanceClassColor = GUI:CreateFormCheckbox(tabContent, "Use Class Color", "useClassColor", unitDB.indicators.stance, RefreshUnit)
            stanceClassColor:SetPoint("TOPLEFT", PAD, y)
            stanceClassColor:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            local stanceCustomColor = GUI:CreateFormColorPicker(tabContent, "Custom Color", "customColor", unitDB.indicators.stance, RefreshUnit)
            stanceCustomColor:SetPoint("TOPLEFT", PAD, y)
            stanceCustomColor:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            local stanceShowIcon = GUI:CreateFormCheckbox(tabContent, "Show Icon", "showIcon", unitDB.indicators.stance, RefreshUnit)
            stanceShowIcon:SetPoint("TOPLEFT", PAD, y)
            stanceShowIcon:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            local stanceIconSize = GUI:CreateFormSlider(tabContent, "Icon Size", 8, 32, 1, "iconSize", unitDB.indicators.stance, RefreshUnit)
            stanceIconSize:SetPoint("TOPLEFT", PAD, y)
            stanceIconSize:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            local stanceIconOffsetX = GUI:CreateFormSlider(tabContent, "Icon X Offset", -20, 20, 1, "iconOffsetX", unitDB.indicators.stance, RefreshUnit)
            stanceIconOffsetX:SetPoint("TOPLEFT", PAD, y)
            stanceIconOffsetX:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW
        end

        -- TARGET MARKER section (all unit frames)
        local markerHeader = GUI:CreateSectionHeader(tabContent, "Target Marker")
        markerHeader:SetPoint("TOPLEFT", PAD, y)
        y = y - markerHeader.gap

        -- Ensure targetMarker table exists
        if not unitDB.targetMarker then
            unitDB.targetMarker = { enabled = false, size = 20, anchor = "TOP", xOffset = 0, yOffset = 8 }
        end

        local markerDesc = GUI:CreateLabel(tabContent, "Shows raid target markers (skull, cross, diamond, etc.) on the unit frame.", 11, C.textMuted)
        markerDesc:SetPoint("TOPLEFT", PAD, y)
        markerDesc:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        markerDesc:SetJustifyH("LEFT")
        y = y - 20

        local markerCheck = GUI:CreateFormCheckbox(tabContent, "Show Target Marker", "enabled", unitDB.targetMarker, RefreshUnit)
        markerCheck:SetPoint("TOPLEFT", PAD, y)
        markerCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local markerSizeSlider = GUI:CreateFormSlider(tabContent, "Marker Size", 8, 48, 1, "size", unitDB.targetMarker, RefreshUnit)
        markerSizeSlider:SetPoint("TOPLEFT", PAD, y)
        markerSizeSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local markerAnchorDrop = GUI:CreateFormDropdown(tabContent, "Anchor To", anchorOptions, "anchor", unitDB.targetMarker, RefreshUnit)
        markerAnchorDrop:SetPoint("TOPLEFT", PAD, y)
        markerAnchorDrop:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local markerXSlider = GUI:CreateFormSlider(tabContent, "X Offset", -100, 100, 1, "xOffset", unitDB.targetMarker, RefreshUnit)
        markerXSlider:SetPoint("TOPLEFT", PAD, y)
        markerXSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local markerYSlider = GUI:CreateFormSlider(tabContent, "Y Offset", -100, 100, 1, "yOffset", unitDB.targetMarker, RefreshUnit)
        markerYSlider:SetPoint("TOPLEFT", PAD, y)
        markerYSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        -- LEADER ICON section (player, target, focus only)
        if unitKey == "player" or unitKey == "target" or unitKey == "focus" then
            local leaderHeader = GUI:CreateSectionHeader(tabContent, "Leader/Assistant Icon")
            leaderHeader:SetPoint("TOPLEFT", PAD, y)
            y = y - leaderHeader.gap

            -- Ensure leaderIcon table exists
            if not unitDB.leaderIcon then
                unitDB.leaderIcon = { enabled = false, size = 16, anchor = "TOPLEFT", xOffset = -8, yOffset = 8 }
            end

            local leaderDesc = GUI:CreateLabel(tabContent, "Shows crown icon for party/raid leader, flag icon for raid assistants.", 11, C.textMuted)
            leaderDesc:SetPoint("TOPLEFT", PAD, y)
            leaderDesc:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            leaderDesc:SetJustifyH("LEFT")
            y = y - 20

            local leaderCheck = GUI:CreateFormCheckbox(tabContent, "Show Leader/Assistant Icon", "enabled", unitDB.leaderIcon, RefreshUnit)
            leaderCheck:SetPoint("TOPLEFT", PAD, y)
            leaderCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            local leaderSizeSlider = GUI:CreateFormSlider(tabContent, "Icon Size", 8, 32, 1, "size", unitDB.leaderIcon, RefreshUnit)
            leaderSizeSlider:SetPoint("TOPLEFT", PAD, y)
            leaderSizeSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            local leaderAnchorDrop = GUI:CreateFormDropdown(tabContent, "Anchor To", anchorOptions, "anchor", unitDB.leaderIcon, RefreshUnit)
            leaderAnchorDrop:SetPoint("TOPLEFT", PAD, y)
            leaderAnchorDrop:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            local leaderXSlider = GUI:CreateFormSlider(tabContent, "X Offset", -100, 100, 1, "xOffset", unitDB.leaderIcon, RefreshUnit)
            leaderXSlider:SetPoint("TOPLEFT", PAD, y)
            leaderXSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            local leaderYSlider = GUI:CreateFormSlider(tabContent, "Y Offset", -100, 100, 1, "yOffset", unitDB.leaderIcon, RefreshUnit)
            leaderYSlider:SetPoint("TOPLEFT", PAD, y)
            leaderYSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW
        end

        -- Portrait section (player, target, focus only)
        if unitKey == "player" or unitKey == "target" or unitKey == "focus" then
            local portraitHeader = GUI:CreateSectionHeader(tabContent, "Portrait")
            portraitHeader:SetPoint("TOPLEFT", PAD, y)
            y = y - portraitHeader.gap

            -- Initialize defaults
            if unitDB.showPortrait == nil then unitDB.showPortrait = false end
            if unitDB.portraitSide == nil then
                unitDB.portraitSide = (unitKey == "player") and "LEFT" or "RIGHT"
            end
            -- Migrate from portraitScale to portraitSize (pixels)
            if unitDB.portraitSize == nil then
                if unitDB.portraitScale then
                    local frameHeight = unitDB.height or 40
                    unitDB.portraitSize = math.floor(frameHeight * unitDB.portraitScale)
                else
                    unitDB.portraitSize = 40
                end
            end
            if unitDB.portraitBorderSize == nil then unitDB.portraitBorderSize = 1 end

            -- Show Portrait checkbox
            local showPortraitCheck = GUI:CreateFormCheckbox(tabContent, "Show Portrait", "showPortrait", unitDB, RefreshUnit)
            showPortraitCheck:SetPoint("TOPLEFT", PAD, y)
            showPortraitCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            -- Portrait Side dropdown
            local sideOptions = {
                {value = "LEFT", text = "Left"},
                {value = "RIGHT", text = "Right"},
            }
            local sideDropdown = GUI:CreateFormDropdown(tabContent, "Portrait Side", sideOptions, "portraitSide", unitDB, RefreshUnit)
            sideDropdown:SetPoint("TOPLEFT", PAD, y)
            sideDropdown:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            -- Portrait Size slider (pixels)
            local sizeSlider = GUI:CreateFormSlider(tabContent, "Portrait Size (Pixels)", 20, 150, 1, "portraitSize", unitDB, RefreshUnit)
            sizeSlider:SetPoint("TOPLEFT", PAD, y)
            sizeSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            -- Portrait Border Size slider
            local borderSlider = GUI:CreateFormSlider(tabContent, "Portrait Border", 0, 5, 1, "portraitBorderSize", unitDB, RefreshUnit)
            borderSlider:SetPoint("TOPLEFT", PAD, y)
            borderSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            -- Portrait Gap slider
            if unitDB.portraitGap == nil then unitDB.portraitGap = 0 end
            local gapSlider = GUI:CreateFormSlider(tabContent, "Portrait Gap", 0, 10, 1, "portraitGap", unitDB, RefreshUnit)
            gapSlider:SetPoint("TOPLEFT", PAD, y)
            gapSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            -- Portrait Offset X slider
            if unitDB.portraitOffsetX == nil then unitDB.portraitOffsetX = 0 end
            local offsetXSlider = GUI:CreateFormSlider(tabContent, "Portrait Offset X", -500, 500, 1, "portraitOffsetX", unitDB, RefreshUnit)
            offsetXSlider:SetPoint("TOPLEFT", PAD, y)
            offsetXSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            -- Portrait Offset Y slider
            if unitDB.portraitOffsetY == nil then unitDB.portraitOffsetY = 0 end
            local offsetYSlider = GUI:CreateFormSlider(tabContent, "Portrait Offset Y", -500, 500, 1, "portraitOffsetY", unitDB, RefreshUnit)
            offsetYSlider:SetPoint("TOPLEFT", PAD, y)
            offsetYSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            -- Initialize border color defaults
            if unitDB.portraitBorderUseClassColor == nil then unitDB.portraitBorderUseClassColor = false end
            if unitDB.portraitBorderColor == nil then unitDB.portraitBorderColor = { 0, 0, 0, 1 } end

            -- Forward declare color picker for conditional enable/disable
            local borderColorPicker

            -- Use Class Color for Border checkbox
            local useClassColorCheck = GUI:CreateFormCheckbox(tabContent, "Use Class Color for Border", "portraitBorderUseClassColor", unitDB, function(val)
                RefreshUnit()
                -- Enable/disable color picker based on toggle
                if borderColorPicker and borderColorPicker.SetEnabled then
                    borderColorPicker:SetEnabled(not val)
                end
            end)
            useClassColorCheck:SetPoint("TOPLEFT", PAD, y)
            useClassColorCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            -- Custom Border Color picker
            borderColorPicker = GUI:CreateFormColorPicker(tabContent, "Border Color", "portraitBorderColor", unitDB, RefreshUnit)
            borderColorPicker:SetPoint("TOPLEFT", PAD, y)
            borderColorPicker:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            -- Initial state based on class color toggle
            if borderColorPicker.SetEnabled then
                borderColorPicker:SetEnabled(not unitDB.portraitBorderUseClassColor)
            end
            y = y - FORM_ROW
        end

        tabContent:SetHeight(math.abs(y) + 30)
    end

    -- Create sub-tabs
    local subTabs = GUI:CreateSubTabs(content, {
        {name = "General", builder = BuildGeneralTab},
        {name = "Player", builder = function(c) BuildUnitTab(c, "player") end},
        {name = "Target", builder = function(c) BuildUnitTab(c, "target") end},
        {name = "ToT", builder = function(c) BuildUnitTab(c, "targettarget") end},
        {name = "Pet", builder = function(c) BuildUnitTab(c, "pet") end},
        {name = "Focus", builder = function(c) BuildUnitTab(c, "focus") end},
        {name = "Boss", builder = function(c) BuildUnitTab(c, "boss") end},
    })
    subTabs:SetPoint("TOPLEFT", 5, -5)
    subTabs:SetPoint("TOPRIGHT", -5, -5)
    subTabs:SetHeight(600)
    
    content:SetHeight(650)
end

---------------------------------------------------------------------------
-- PAGE: Castbars
---------------------------------------------------------------------------
local function CreateCastbarsPage(parent)
    local scroll, content = CreateScrollableContent(parent)
    local y = -15
    
    local info = GUI:CreateLabel(content, "Castbar customization - use Edit Mode for positioning", 12, C.textMuted)
    info:SetPoint("TOPLEFT", PADDING, y)
    y = y - ROW_GAP
    
    content:SetHeight(100)
end

---------------------------------------------------------------------------
-- PAGE: Action Bars
---------------------------------------------------------------------------
local function CreateActionBarsPage(parent)
    local scroll, content = CreateScrollableContent(parent)
    local db = GetDB()

    -- Safety check
    if not db or not db.actionBars then
        local errorLabel = GUI:CreateLabel(content, "Action Bars settings not available. Please reload UI.", 12, C.text)
        errorLabel:SetPoint("TOPLEFT", PADDING, -15)
        content:SetHeight(100)
        return scroll, content
    end

    local actionBars = db.actionBars
    local global = actionBars.global
    local fade = actionBars.fade
    local bars = actionBars.bars

    -- Refresh callback
    local function RefreshActionBars()
        if _G.LuheyUI_RefreshActionBars then
            _G.LuheyUI_RefreshActionBars()
        end
    end

    ---------------------------------------------------------
    -- SUB-TAB: Mouseover Hide
    ---------------------------------------------------------
    local function BuildMouseoverHideTab(tabContent)
        local y = -15
        local PAD = PADDING
        local FORM_ROW = 32

        -- Set search context for widget auto-registration
        GUI:SetSearchContext({tabIndex = 4, tabName = "Action Bars", subTabIndex = 2, subTabName = "Mouseover Hide"})

        ---------------------------------------------------------
        -- Warning: Enable Blizzard Action Bars
        ---------------------------------------------------------
        local warningText = GUI:CreateLabel(tabContent,
            "Important: Enable all 8 action bars in Game Menu > Options > Gameplay > Action Bars for mouseover hide to work correctly. To remove the default dragon texture, open Edit Mode, select Action Bar 1, check 'Hide Bar Art', then reload.",
            11, C.warning)
        warningText:SetPoint("TOPLEFT", PAD, y)
        warningText:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        warningText:SetJustifyH("LEFT")
        warningText:SetWordWrap(true)
        warningText:SetHeight(45)
        y = y - 55

        local openSettingsBtn = GUI:CreateButton(tabContent, "Open Game Settings", 160, 26, function()
            if SettingsPanel then
                SettingsPanel:Open()
            end
        end)
        openSettingsBtn:SetPoint("TOPLEFT", PAD, y)
        openSettingsBtn:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - 46  -- Extra spacing before main content

        ---------------------------------------------------------
        -- Section: Mouseover Hide
        ---------------------------------------------------------
        local fadeHeader = GUI:CreateSectionHeader(tabContent, "Mouseover Hide")
        fadeHeader:SetPoint("TOPLEFT", PAD, y)
        y = y - fadeHeader.gap

        local fadeCheck = GUI:CreateFormCheckbox(tabContent, "Enable Mouseover Hide",
            "enabled", fade, RefreshActionBars)
        fadeCheck:SetPoint("TOPLEFT", PAD, y)
        fadeCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local fadeTip = GUI:CreateLabel(tabContent,
            "Bars hide when mouse is not over them. Hover to reveal.",
            11, C.textMuted)
        fadeTip:SetPoint("TOPLEFT", PAD, y)
        fadeTip:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        fadeTip:SetJustifyH("LEFT")
        y = y - 24

        local fadeInSlider = GUI:CreateFormSlider(tabContent, "Fade In Speed (sec)",
            0.1, 1.0, 0.05, "fadeInDuration", fade, RefreshActionBars)
        fadeInSlider:SetPoint("TOPLEFT", PAD, y)
        fadeInSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local fadeOutSlider = GUI:CreateFormSlider(tabContent, "Fade Out Speed (sec)",
            0.1, 1.0, 0.05, "fadeOutDuration", fade, RefreshActionBars)
        fadeOutSlider:SetPoint("TOPLEFT", PAD, y)
        fadeOutSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local fadeAlphaSlider = GUI:CreateFormSlider(tabContent, "Faded Opacity",
            0, 1, 0.05, "fadeOutAlpha", fade, RefreshActionBars)
        fadeAlphaSlider:SetPoint("TOPLEFT", PAD, y)
        fadeAlphaSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local fadeDelaySlider = GUI:CreateFormSlider(tabContent, "Fade Out Delay (sec)",
            0, 2.0, 0.1, "fadeOutDelay", fade, RefreshActionBars)
        fadeDelaySlider:SetPoint("TOPLEFT", PAD, y)
        fadeDelaySlider:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local combatCheck = GUI:CreateFormCheckbox(tabContent, "Do Not Hide In Combat",
            "alwaysShowInCombat", fade, RefreshActionBars)
        combatCheck:SetPoint("TOPLEFT", PAD, y)
        combatCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local linkBarsCheck = GUI:CreateFormCheckbox(tabContent, "Link Action Bars 1-8 on Mouseover",
            "linkBars1to8", fade, RefreshActionBars)
        linkBarsCheck:SetPoint("TOPLEFT", PAD, y)
        linkBarsCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local linkBarsDesc = GUI:CreateLabel(tabContent,
            "When enabled, hovering any action bar (1-8) reveals all bars 1-8 together.",
            11, C.textMuted)
        linkBarsDesc:SetPoint("TOPLEFT", PAD, y)
        linkBarsDesc:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        linkBarsDesc:SetJustifyH("LEFT")
        y = y - 24

        -- Always Show toggles (bars that ignore mouseover hide)
        local alwaysShowTip = GUI:CreateLabel(tabContent,
            "Bars checked below will always remain visible, ignoring mouseover hide.",
            11, C.textMuted)
        alwaysShowTip:SetPoint("TOPLEFT", PAD, y)
        alwaysShowTip:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        alwaysShowTip:SetJustifyH("LEFT")
        y = y - 24

        local alwaysShowBars = {
            { key = "bar1", label = "Always Show Bar 1" },
            { key = "bar2", label = "Always Show Bar 2" },
            { key = "bar3", label = "Always Show Bar 3" },
            { key = "bar4", label = "Always Show Bar 4" },
            { key = "bar5", label = "Always Show Bar 5" },
            { key = "bar6", label = "Always Show Bar 6" },
            { key = "bar7", label = "Always Show Bar 7" },
            { key = "bar8", label = "Always Show Bar 8" },
            { key = "microbar", label = "Always Show Microbar" },
            { key = "bags", label = "Always Show Bags" },
            { key = "pet", label = "Always Show Pet Bar" },
            { key = "stance", label = "Always Show Stance Bar" },
            { key = "extraActionButton", label = "Always Show Extra Action" },
            { key = "zoneAbility", label = "Always Show Zone Ability" },
        }

        for _, barInfo in ipairs(alwaysShowBars) do
            local barDB = bars[barInfo.key]
            if barDB then
                local check = GUI:CreateFormCheckbox(tabContent, barInfo.label,
                    "alwaysShow", barDB, RefreshActionBars)
                check:SetPoint("TOPLEFT", PAD, y)
                check:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
                y = y - FORM_ROW
            end
        end

        tabContent:SetHeight(math.abs(y) + 50)
    end  -- End BuildMouseoverHideTab

    ---------------------------------------------------------
    -- SUB-TAB: Master Visual Settings (existing global settings)
    ---------------------------------------------------------
    local function BuildMasterSettingsTab(tabContent)
        local y = -15
        local PAD = PADDING
        local FORM_ROW = 32

        -- Set search context for auto-registration
        GUI:SetSearchContext({tabIndex = 4, tabName = "Action Bars", subTabIndex = 1, subTabName = "Master Settings"})

        -- 9-point anchor options for text positioning
        local anchorOptions = {
            {value = "TOPLEFT", text = "Top Left"},
            {value = "TOP", text = "Top"},
            {value = "TOPRIGHT", text = "Top Right"},
            {value = "LEFT", text = "Left"},
            {value = "CENTER", text = "Center"},
            {value = "RIGHT", text = "Right"},
            {value = "BOTTOMLEFT", text = "Bottom Left"},
            {value = "BOTTOM", text = "Bottom"},
            {value = "BOTTOMRIGHT", text = "Bottom Right"},
        }

        ---------------------------------------------------------
        -- Quick Keybind Mode (prominent tool at top)
        ---------------------------------------------------------
        local keybindModeBtn = GUI:CreateButton(tabContent, "Quick Keybind Mode", 180, 28, function()
            local LibKeyBound = LibStub("LibKeyBound-1.0", true)
            if LibKeyBound then
                LibKeyBound:Toggle()
            elseif QuickKeybindFrame then
                ShowUIPanel(QuickKeybindFrame)
            end
        end)
        keybindModeBtn:SetPoint("TOPLEFT", PAD, y)
        y = y - 38

        local keybindTip = GUI:CreateLabel(tabContent,
            "Hover over action buttons and press a key to bind. Type /kb anytime.",
            11, C.textMuted)
        keybindTip:SetPoint("TOPLEFT", PAD, y)
        keybindTip:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        keybindTip:SetJustifyH("LEFT")
        keybindTip:SetWordWrap(true)
        keybindTip:SetHeight(15)
        y = y - 30

        ---------------------------------------------------------
        -- Section: General
        ---------------------------------------------------------
        local generalHeader = GUI:CreateSectionHeader(tabContent, "General")
        generalHeader:SetPoint("TOPLEFT", PAD, y)
        y = y - generalHeader.gap

        local enableCheck = GUI:CreateFormCheckbox(tabContent, "Enable QUI Action Bars",
            "enabled", actionBars, function(val)
                GUI:ShowConfirmation({
                    title = "Reload Required",
                    message = "Action Bar styling requires a UI reload to take effect.",
                    acceptText = "Reload Now",
                    cancelText = "Later",
                    isDestructive = false,
                    onAccept = function()
                        LuheyUI:SafeReload()
                    end,
                })
            end)
        enableCheck:SetPoint("TOPLEFT", PAD, y)
        enableCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local tipText = GUI:CreateLabel(tabContent,
            "LUI hooks into Blizzard action bars to skin them. Position and resize bars via Edit Mode (Blizzard minimum padding: 2px). If you need actionbar paging (stance/form swapping), want to use action bars as your CDM, or prefer more control - disable LUI Action Bars and use a dedicated addon (e.g., Bartender4, Dominos).",
            11, C.warning)
        tipText:SetPoint("TOPLEFT", PAD, y)
        tipText:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        tipText:SetJustifyH("LEFT")
        tipText:SetWordWrap(true)
        tipText:SetHeight(45)
        y = y - 55

        ---------------------------------------------------------
        -- Section: Button Appearance
        ---------------------------------------------------------
        local appearanceHeader = GUI:CreateSectionHeader(tabContent, "Button Appearance")
        appearanceHeader:SetPoint("TOPLEFT", PAD, y)
        y = y - appearanceHeader.gap

        local zoomSlider = GUI:CreateFormSlider(tabContent, "Icon Crop Amount",
            0.05, 0.15, 0.01, "iconZoom", global, RefreshActionBars)
        zoomSlider:SetPoint("TOPLEFT", PAD, y)
        zoomSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local backdropCheck = GUI:CreateFormCheckbox(tabContent, "Show Backdrop",
            "showBackdrop", global, RefreshActionBars)
        backdropCheck:SetPoint("TOPLEFT", PAD, y)
        backdropCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local backdropAlphaSlider = GUI:CreateFormSlider(tabContent, "Backdrop Opacity",
            0, 1, 0.05, "backdropAlpha", global, RefreshActionBars)
        backdropAlphaSlider:SetPoint("TOPLEFT", PAD, y)
        backdropAlphaSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local glossCheck = GUI:CreateFormCheckbox(tabContent, "Show Gloss Effect",
            "showGloss", global, RefreshActionBars)
        glossCheck:SetPoint("TOPLEFT", PAD, y)
        glossCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local glossAlphaSlider = GUI:CreateFormSlider(tabContent, "Gloss Opacity",
            0, 1, 0.05, "glossAlpha", global, RefreshActionBars)
        glossAlphaSlider:SetPoint("TOPLEFT", PAD, y)
        glossAlphaSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local bordersCheck = GUI:CreateFormCheckbox(tabContent, "Show Button Borders",
            "showBorders", global, RefreshActionBars)
        bordersCheck:SetPoint("TOPLEFT", PAD, y)
        bordersCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        ---------------------------------------------------------
        -- Section: Bar Layout
        ---------------------------------------------------------
        local layoutHeader = GUI:CreateSectionHeader(tabContent, "Bar Layout")
        layoutHeader:SetPoint("TOPLEFT", PAD, y)
        y = y - layoutHeader.gap

        local scaleWarning = GUI:CreateLabel(tabContent, "To scale Action Bars, use Edit Mode: select each bar and adjust the 'Icon Size' slider. Enable 'Snap To Element' for easy alignment.", 11, C.warning)
        scaleWarning:SetPoint("TOPLEFT", PAD, y)
        scaleWarning:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        scaleWarning:SetJustifyH("LEFT")
        scaleWarning:SetWordWrap(true)
        scaleWarning:SetHeight(30)
        y = y - 32

        local hideEmptySlotsCheck = GUI:CreateFormCheckbox(tabContent, "Hide Empty Slots",
            "hideEmptySlots", global, RefreshActionBars)
        hideEmptySlotsCheck:SetPoint("TOPLEFT", PAD, y)
        hideEmptySlotsCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        -- Action Button Lock - combined lock + override key in one clear dropdown
        local lockOptions = {
            {value = "unlocked", text = "Unlocked"},
            {value = "shift", text = "Locked - Shift to drag"},
            {value = "alt", text = "Locked - Alt to drag"},
            {value = "ctrl", text = "Locked - Ctrl to drag"},
            {value = "none", text = "Fully Locked"},
        }
        -- Proxy that reads/writes to Blizzard's CVars
        local lockProxy = setmetatable({}, {
            __index = function(t, k)
                if k == "buttonLock" then
                    local isLocked = GetCVar("lockActionBars") == "1"
                    if not isLocked then return "unlocked" end
                    local modifier = GetModifiedClick("PICKUPACTION") or "SHIFT"
                    if modifier == "NONE" then return "none" end
                    return modifier:lower()
                end
            end,
            __newindex = function(t, k, v)
                if k == "buttonLock" and type(v) == "string" then
                    if v == "unlocked" then
                        SetCVar("lockActionBars", "0")
                    else
                        SetCVar("lockActionBars", "1")
                        local modifier = (v == "none") and "NONE" or v:upper()
                        SetModifiedClick("PICKUPACTION", modifier)
                        SaveBindings(GetCurrentBindingSet())
                    end
                end
            end
        })
        local lockDropdown = GUI:CreateFormDropdown(tabContent, "Action Button Lock", lockOptions,
            "buttonLock", lockProxy, RefreshActionBars)
        lockDropdown:SetPoint("TOPLEFT", PAD, y)
        lockDropdown:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        -- Refresh from Blizzard settings on show
        lockDropdown:HookScript("OnShow", function(self)
            self.SetValue(lockProxy.buttonLock, true)
        end)
        y = y - FORM_ROW

        local rangeCheck = GUI:CreateFormCheckbox(tabContent, "Out of Range Indicator",
            "rangeIndicator", global, RefreshActionBars)
        rangeCheck:SetPoint("TOPLEFT", PAD, y)
        rangeCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local rangeColorPicker = GUI:CreateFormColorPicker(tabContent, "Out of Range Color",
            "rangeColor", global, RefreshActionBars)
        rangeColorPicker:SetPoint("TOPLEFT", PAD, y)
        rangeColorPicker:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local usabilityCheck = GUI:CreateFormCheckbox(tabContent, "Dim Unusable Buttons",
            "usabilityIndicator", global, RefreshActionBars)
        usabilityCheck:SetPoint("TOPLEFT", PAD, y)
        usabilityCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local desaturateCheck = GUI:CreateFormCheckbox(tabContent, "Desaturate Unusable",
            "usabilityDesaturate", global, RefreshActionBars)
        desaturateCheck:SetPoint("TOPLEFT", PAD, y)
        desaturateCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local manaColorPicker = GUI:CreateFormColorPicker(tabContent, "Out of Mana Color",
            "manaColor", global, RefreshActionBars)
        manaColorPicker:SetPoint("TOPLEFT", PAD, y)
        manaColorPicker:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local fastUpdates = GUI:CreateFormCheckbox(tabContent, "Unthrottled CPU Usage",
            "fastUsabilityUpdates", global, RefreshActionBars)
        fastUpdates:SetPoint("TOPLEFT", PAD, y)
        fastUpdates:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local fastDesc = GUI:CreateLabel(tabContent, "Updates range/mana/unusable states 5x faster. Only enable if using action bars as your primary rotation display. Enabling while bars are hidden wastes CPU.", 11, {1, 0.6, 0})
        fastDesc:SetPoint("TOPLEFT", PAD, y + 4)
        y = y - 18

        local layoutTipText = GUI:CreateLabel(tabContent, "Enable 'Out of Range', 'Unusable' and 'Out of Mana' ONLY if you use Action Bars to replace CDM. They eat CPU resources.", 11, {1, 0.6, 0})
        layoutTipText:SetPoint("TOPLEFT", PAD, y)
        layoutTipText:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        layoutTipText:SetJustifyH("LEFT")
        layoutTipText:SetWordWrap(true)
        y = y - 40

        ---------------------------------------------------------
        -- Section: Text Display
        ---------------------------------------------------------
        local textHeader = GUI:CreateSectionHeader(tabContent, "Text Display")
        textHeader:SetPoint("TOPLEFT", PAD, y)
        y = y - textHeader.gap

        local keybindCheck = GUI:CreateFormCheckbox(tabContent, "Show Keybind Text",
            "showKeybinds", global, RefreshActionBars)
        keybindCheck:SetPoint("TOPLEFT", PAD, y)
        keybindCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local hideEmptyCheck = GUI:CreateFormCheckbox(tabContent, "Hide Empty Keybinds",
            "hideEmptyKeybinds", global, RefreshActionBars)
        hideEmptyCheck:SetPoint("TOPLEFT", PAD, y)
        hideEmptyCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local keybindSizeSlider = GUI:CreateFormSlider(tabContent, "Keybind Text Size",
            8, 50, 1, "keybindFontSize", global, RefreshActionBars)
        keybindSizeSlider:SetPoint("TOPLEFT", PAD, y)
        keybindSizeSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local keybindAnchorDD = GUI:CreateFormDropdown(tabContent, "Keybind Text Anchor",
            anchorOptions, "keybindAnchor", global, RefreshActionBars)
        keybindAnchorDD:SetPoint("TOPLEFT", PAD, y)
        keybindAnchorDD:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local keybindXOffsetSlider = GUI:CreateFormSlider(tabContent, "Keybind Text X-Offset",
            -20, 20, 1, "keybindOffsetX", global, RefreshActionBars)
        keybindXOffsetSlider:SetPoint("TOPLEFT", PAD, y)
        keybindXOffsetSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local keybindYOffsetSlider = GUI:CreateFormSlider(tabContent, "Keybind Text Y-Offset",
            -20, 20, 1, "keybindOffsetY", global, RefreshActionBars)
        keybindYOffsetSlider:SetPoint("TOPLEFT", PAD, y)
        keybindYOffsetSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local keybindColorPicker = GUI:CreateFormColorPicker(tabContent, "Keybind Text Color",
            "keybindColor", global, RefreshActionBars)
        keybindColorPicker:SetPoint("TOPLEFT", PAD, y)
        keybindColorPicker:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local macroCheck = GUI:CreateFormCheckbox(tabContent, "Show Macro Names",
            "showMacroNames", global, RefreshActionBars)
        macroCheck:SetPoint("TOPLEFT", PAD, y)
        macroCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local macroSizeSlider = GUI:CreateFormSlider(tabContent, "Macro Name Text Size",
            8, 50, 1, "macroNameFontSize", global, RefreshActionBars)
        macroSizeSlider:SetPoint("TOPLEFT", PAD, y)
        macroSizeSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local macroAnchorDD = GUI:CreateFormDropdown(tabContent, "Macro Name Anchor",
            anchorOptions, "macroNameAnchor", global, RefreshActionBars)
        macroAnchorDD:SetPoint("TOPLEFT", PAD, y)
        macroAnchorDD:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local macroXOffsetSlider = GUI:CreateFormSlider(tabContent, "Macro Name X-Offset",
            -20, 20, 1, "macroNameOffsetX", global, RefreshActionBars)
        macroXOffsetSlider:SetPoint("TOPLEFT", PAD, y)
        macroXOffsetSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local macroYOffsetSlider = GUI:CreateFormSlider(tabContent, "Macro Name Y-Offset",
            -20, 20, 1, "macroNameOffsetY", global, RefreshActionBars)
        macroYOffsetSlider:SetPoint("TOPLEFT", PAD, y)
        macroYOffsetSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local macroColorPicker = GUI:CreateFormColorPicker(tabContent, "Macro Name Color",
            "macroNameColor", global, RefreshActionBars)
        macroColorPicker:SetPoint("TOPLEFT", PAD, y)
        macroColorPicker:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local countCheck = GUI:CreateFormCheckbox(tabContent, "Show Stack Counts",
            "showCounts", global, RefreshActionBars)
        countCheck:SetPoint("TOPLEFT", PAD, y)
        countCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local countSizeSlider = GUI:CreateFormSlider(tabContent, "Stack Text Size",
            8, 50, 1, "countFontSize", global, RefreshActionBars)
        countSizeSlider:SetPoint("TOPLEFT", PAD, y)
        countSizeSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local countAnchorDD = GUI:CreateFormDropdown(tabContent, "Stack Text Anchor",
            anchorOptions, "countAnchor", global, RefreshActionBars)
        countAnchorDD:SetPoint("TOPLEFT", PAD, y)
        countAnchorDD:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local countXOffsetSlider = GUI:CreateFormSlider(tabContent, "Stack Text X-Offset",
            -20, 20, 1, "countOffsetX", global, RefreshActionBars)
        countXOffsetSlider:SetPoint("TOPLEFT", PAD, y)
        countXOffsetSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local countYOffsetSlider = GUI:CreateFormSlider(tabContent, "Stack Text Y-Offset",
            -20, 20, 1, "countOffsetY", global, RefreshActionBars)
        countYOffsetSlider:SetPoint("TOPLEFT", PAD, y)
        countYOffsetSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local countColorPicker = GUI:CreateFormColorPicker(tabContent, "Stack Count Color",
            "countColor", global, RefreshActionBars)
        countColorPicker:SetPoint("TOPLEFT", PAD, y)
        countColorPicker:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        tabContent:SetHeight(math.abs(y) + 50)
    end  -- End BuildMasterSettingsTab

    ---------------------------------------------------------
    -- SUB-TAB: Per-Bar Overrides (Accordion Style)
    ---------------------------------------------------------
    local function BuildPerBarOverridesTab(tabContent)
        -- Set search context for widget auto-registration
        GUI:SetSearchContext({tabIndex = 4, tabName = "Action Bars", subTabIndex = 3, subTabName = "Per-Bar Overrides"})

        -- Use tabContent directly - parent Action Bars page already has scroll
        local content = tabContent
        local PAD = PADDING
        local FORM_ROW = 32
        local SECTION_GAP = 4

        -- 9-point anchor options for text positioning
        local anchorOptions = {
            {value = "TOPLEFT", text = "Top Left"},
            {value = "TOP", text = "Top"},
            {value = "TOPRIGHT", text = "Top Right"},
            {value = "LEFT", text = "Left"},
            {value = "CENTER", text = "Center"},
            {value = "RIGHT", text = "Right"},
            {value = "BOTTOMLEFT", text = "Bottom Left"},
            {value = "BOTTOM", text = "Bottom"},
            {value = "BOTTOMRIGHT", text = "Bottom Right"},
        }

        -- Bar info for accordion sections
        local barInfo = {
            {key = "bar1", label = "Action Bar 1"},
            {key = "bar2", label = "Action Bar 2"},
            {key = "bar3", label = "Action Bar 3"},
            {key = "bar4", label = "Action Bar 4"},
            {key = "bar5", label = "Action Bar 5"},
            {key = "bar6", label = "Action Bar 6"},
            {key = "bar7", label = "Action Bar 7"},
            {key = "bar8", label = "Action Bar 8"},
        }

        -- Track sections for accordion behavior
        local sections = {}

        -- Keys to copy when using Copy From
        local copyKeys = {
            "iconZoom", "showBackdrop", "backdropAlpha", "showGloss", "glossAlpha",
            "showKeybinds", "hideEmptyKeybinds", "keybindFontSize", "keybindColor",
            "keybindAnchor", "keybindOffsetX", "keybindOffsetY",
            "showMacroNames", "macroNameFontSize", "macroNameColor",
            "macroNameAnchor", "macroNameOffsetX", "macroNameOffsetY",
            "showCounts", "countFontSize", "countColor",
            "countAnchor", "countOffsetX", "countOffsetY",
        }

        -- Helper to update scroll content height
        local function UpdateScrollHeight()
            local totalHeight = 15
            for _, section in ipairs(sections) do
                totalHeight = totalHeight + section:GetHeight() + SECTION_GAP
            end
            content:SetHeight(totalHeight + 15)
        end

        -- Function to build settings into a container
        local function BuildBarSettingsIntoContainer(barKey, container, onOverrideChanged)
            local barDB = bars[barKey]
            if not barDB then return end

            local sy = -8  -- Start with small padding inside content area
            local widgetRefs = {}

            -- Hide Page Arrow toggle (bar1 only)
            if barKey == "bar1" then
                local pageArrowToggle = GUI:CreateFormCheckbox(container,
                    "Hide Default Paging Arrow", "hidePageArrow", barDB,
                    function(val)
                        if _G.LuheyUI_ApplyPageArrowVisibility then
                            _G.LuheyUI_ApplyPageArrowVisibility(val)
                        end
                    end)
                pageArrowToggle:SetPoint("TOPLEFT", 0, sy)
                pageArrowToggle:SetPoint("RIGHT", container, "RIGHT", 0, 0)
                sy = sy - FORM_ROW
            end

            -- Row 1: Override Master Settings toggle
            local overrideToggle = GUI:CreateFormCheckbox(container,
                "Override Master Settings", "overrideEnabled", barDB,
                function(val)
                    for _, widget in pairs(widgetRefs) do
                        widget:SetEnabled(val)
                    end
                    if onOverrideChanged then
                        onOverrideChanged()
                    end
                    RefreshActionBars()
                end)
            overrideToggle:SetPoint("TOPLEFT", 0, sy)
            overrideToggle:SetPoint("RIGHT", container, "RIGHT", 0, 0)
            sy = sy - FORM_ROW

            -- Row 2: Copy From dropdown
            local copyOptions = {
                {value = "master", text = "Master Settings"},
                {value = "bar1", text = "Bar 1"},
                {value = "bar2", text = "Bar 2"},
                {value = "bar3", text = "Bar 3"},
                {value = "bar4", text = "Bar 4"},
                {value = "bar5", text = "Bar 5"},
                {value = "bar6", text = "Bar 6"},
                {value = "bar7", text = "Bar 7"},
                {value = "bar8", text = "Bar 8"},
            }

            local copyDropdown = GUI:CreateFormDropdown(container, "Copy from", copyOptions, nil, nil,
                function(sourceKey)
                    if sourceKey == barKey then return end

                    local sourceDB
                    if sourceKey == "master" then
                        sourceDB = global
                    else
                        sourceDB = bars[sourceKey]
                    end

                    if not sourceDB then return end

                    for _, key in ipairs(copyKeys) do
                        if sourceDB[key] ~= nil then
                            barDB[key] = sourceDB[key]
                        end
                    end

                    barDB.overrideEnabled = true

                    -- Rebuild this section's content
                    for _, child in pairs({container:GetChildren()}) do
                        child:Hide()
                        child:SetParent(nil)
                    end
                    BuildBarSettingsIntoContainer(barKey, container, onOverrideChanged)

                    if onOverrideChanged then
                        onOverrideChanged()
                    end
                    RefreshActionBars()
                end)
            copyDropdown:SetPoint("TOPLEFT", 0, sy)
            copyDropdown:SetPoint("RIGHT", container, "RIGHT", 0, 0)
            sy = sy - FORM_ROW

            -- Appearance Section
            local appHeader = GUI:CreateSectionHeader(container, "Appearance")
            appHeader:SetPoint("TOPLEFT", 0, sy)
            sy = sy - appHeader.gap

            local zoomSlider = GUI:CreateFormSlider(container, "Icon Crop",
                0.05, 0.15, 0.01, "iconZoom", barDB, RefreshActionBars)
            zoomSlider:SetPoint("TOPLEFT", 0, sy)
            zoomSlider:SetPoint("RIGHT", container, "RIGHT", 0, 0)
            table.insert(widgetRefs, zoomSlider)
            sy = sy - FORM_ROW

            local backdropCheck = GUI:CreateFormCheckbox(container, "Show Backdrop",
                "showBackdrop", barDB, RefreshActionBars)
            backdropCheck:SetPoint("TOPLEFT", 0, sy)
            backdropCheck:SetPoint("RIGHT", container, "RIGHT", 0, 0)
            table.insert(widgetRefs, backdropCheck)
            sy = sy - FORM_ROW

            local backdropAlphaSlider = GUI:CreateFormSlider(container, "Backdrop Opacity",
                0, 1, 0.05, "backdropAlpha", barDB, RefreshActionBars)
            backdropAlphaSlider:SetPoint("TOPLEFT", 0, sy)
            backdropAlphaSlider:SetPoint("RIGHT", container, "RIGHT", 0, 0)
            table.insert(widgetRefs, backdropAlphaSlider)
            sy = sy - FORM_ROW

            local glossCheck = GUI:CreateFormCheckbox(container, "Show Gloss",
                "showGloss", barDB, RefreshActionBars)
            glossCheck:SetPoint("TOPLEFT", 0, sy)
            glossCheck:SetPoint("RIGHT", container, "RIGHT", 0, 0)
            table.insert(widgetRefs, glossCheck)
            sy = sy - FORM_ROW

            local glossAlphaSlider = GUI:CreateFormSlider(container, "Gloss Opacity",
                0, 1, 0.05, "glossAlpha", barDB, RefreshActionBars)
            glossAlphaSlider:SetPoint("TOPLEFT", 0, sy)
            glossAlphaSlider:SetPoint("RIGHT", container, "RIGHT", 0, 0)
            table.insert(widgetRefs, glossAlphaSlider)
            sy = sy - FORM_ROW

            local bordersCheck = GUI:CreateFormCheckbox(container, "Show Borders",
                "showBorders", barDB, RefreshActionBars)
            bordersCheck:SetPoint("TOPLEFT", 0, sy)
            bordersCheck:SetPoint("RIGHT", container, "RIGHT", 0, 0)
            table.insert(widgetRefs, bordersCheck)
            sy = sy - FORM_ROW

            -- Keybind Section
            local keyHeader = GUI:CreateSectionHeader(container, "Keybind Text")
            keyHeader:SetPoint("TOPLEFT", 0, sy)
            sy = sy - keyHeader.gap

            local keybindCheck = GUI:CreateFormCheckbox(container, "Show Keybinds",
                "showKeybinds", barDB, RefreshActionBars)
            keybindCheck:SetPoint("TOPLEFT", 0, sy)
            keybindCheck:SetPoint("RIGHT", container, "RIGHT", 0, 0)
            table.insert(widgetRefs, keybindCheck)
            sy = sy - FORM_ROW

            local hideEmptyCheck = GUI:CreateFormCheckbox(container, "Hide Empty Keybinds",
                "hideEmptyKeybinds", barDB, RefreshActionBars)
            hideEmptyCheck:SetPoint("TOPLEFT", 0, sy)
            hideEmptyCheck:SetPoint("RIGHT", container, "RIGHT", 0, 0)
            table.insert(widgetRefs, hideEmptyCheck)
            sy = sy - FORM_ROW

            local keybindSizeSlider = GUI:CreateFormSlider(container, "Font Size",
                8, 18, 1, "keybindFontSize", barDB, RefreshActionBars)
            keybindSizeSlider:SetPoint("TOPLEFT", 0, sy)
            keybindSizeSlider:SetPoint("RIGHT", container, "RIGHT", 0, 0)
            table.insert(widgetRefs, keybindSizeSlider)
            sy = sy - FORM_ROW

            local keybindAnchorDD = GUI:CreateFormDropdown(container, "Anchor",
                anchorOptions, "keybindAnchor", barDB, RefreshActionBars)
            keybindAnchorDD:SetPoint("TOPLEFT", 0, sy)
            keybindAnchorDD:SetPoint("RIGHT", container, "RIGHT", 0, 0)
            table.insert(widgetRefs, keybindAnchorDD)
            sy = sy - FORM_ROW

            local keybindXOffsetSlider = GUI:CreateFormSlider(container, "X-Offset",
                -20, 20, 1, "keybindOffsetX", barDB, RefreshActionBars)
            keybindXOffsetSlider:SetPoint("TOPLEFT", 0, sy)
            keybindXOffsetSlider:SetPoint("RIGHT", container, "RIGHT", 0, 0)
            table.insert(widgetRefs, keybindXOffsetSlider)
            sy = sy - FORM_ROW

            local keybindYOffsetSlider = GUI:CreateFormSlider(container, "Y-Offset",
                -20, 20, 1, "keybindOffsetY", barDB, RefreshActionBars)
            keybindYOffsetSlider:SetPoint("TOPLEFT", 0, sy)
            keybindYOffsetSlider:SetPoint("RIGHT", container, "RIGHT", 0, 0)
            table.insert(widgetRefs, keybindYOffsetSlider)
            sy = sy - FORM_ROW

            local keybindColorPicker = GUI:CreateFormColorPicker(container, "Color",
                "keybindColor", barDB, RefreshActionBars)
            keybindColorPicker:SetPoint("TOPLEFT", 0, sy)
            keybindColorPicker:SetPoint("RIGHT", container, "RIGHT", 0, 0)
            table.insert(widgetRefs, keybindColorPicker)
            sy = sy - FORM_ROW

            -- Macro Section
            local macroHeader = GUI:CreateSectionHeader(container, "Macro Text")
            macroHeader:SetPoint("TOPLEFT", 0, sy)
            sy = sy - macroHeader.gap

            local macroCheck = GUI:CreateFormCheckbox(container, "Show Macro Names",
                "showMacroNames", barDB, RefreshActionBars)
            macroCheck:SetPoint("TOPLEFT", 0, sy)
            macroCheck:SetPoint("RIGHT", container, "RIGHT", 0, 0)
            table.insert(widgetRefs, macroCheck)
            sy = sy - FORM_ROW

            local macroSizeSlider = GUI:CreateFormSlider(container, "Font Size",
                8, 18, 1, "macroNameFontSize", barDB, RefreshActionBars)
            macroSizeSlider:SetPoint("TOPLEFT", 0, sy)
            macroSizeSlider:SetPoint("RIGHT", container, "RIGHT", 0, 0)
            table.insert(widgetRefs, macroSizeSlider)
            sy = sy - FORM_ROW

            local macroAnchorDD = GUI:CreateFormDropdown(container, "Anchor",
                anchorOptions, "macroNameAnchor", barDB, RefreshActionBars)
            macroAnchorDD:SetPoint("TOPLEFT", 0, sy)
            macroAnchorDD:SetPoint("RIGHT", container, "RIGHT", 0, 0)
            table.insert(widgetRefs, macroAnchorDD)
            sy = sy - FORM_ROW

            local macroXOffsetSlider = GUI:CreateFormSlider(container, "X-Offset",
                -20, 20, 1, "macroNameOffsetX", barDB, RefreshActionBars)
            macroXOffsetSlider:SetPoint("TOPLEFT", 0, sy)
            macroXOffsetSlider:SetPoint("RIGHT", container, "RIGHT", 0, 0)
            table.insert(widgetRefs, macroXOffsetSlider)
            sy = sy - FORM_ROW

            local macroYOffsetSlider = GUI:CreateFormSlider(container, "Y-Offset",
                -20, 20, 1, "macroNameOffsetY", barDB, RefreshActionBars)
            macroYOffsetSlider:SetPoint("TOPLEFT", 0, sy)
            macroYOffsetSlider:SetPoint("RIGHT", container, "RIGHT", 0, 0)
            table.insert(widgetRefs, macroYOffsetSlider)
            sy = sy - FORM_ROW

            local macroColorPicker = GUI:CreateFormColorPicker(container, "Color",
                "macroNameColor", barDB, RefreshActionBars)
            macroColorPicker:SetPoint("TOPLEFT", 0, sy)
            macroColorPicker:SetPoint("RIGHT", container, "RIGHT", 0, 0)
            table.insert(widgetRefs, macroColorPicker)
            sy = sy - FORM_ROW

            -- Count Section
            local countHeader = GUI:CreateSectionHeader(container, "Stack Count")
            countHeader:SetPoint("TOPLEFT", 0, sy)
            sy = sy - countHeader.gap

            local countCheck = GUI:CreateFormCheckbox(container, "Show Counts",
                "showCounts", barDB, RefreshActionBars)
            countCheck:SetPoint("TOPLEFT", 0, sy)
            countCheck:SetPoint("RIGHT", container, "RIGHT", 0, 0)
            table.insert(widgetRefs, countCheck)
            sy = sy - FORM_ROW

            local countSizeSlider = GUI:CreateFormSlider(container, "Font Size",
                8, 20, 1, "countFontSize", barDB, RefreshActionBars)
            countSizeSlider:SetPoint("TOPLEFT", 0, sy)
            countSizeSlider:SetPoint("RIGHT", container, "RIGHT", 0, 0)
            table.insert(widgetRefs, countSizeSlider)
            sy = sy - FORM_ROW

            local countAnchorDD = GUI:CreateFormDropdown(container, "Anchor",
                anchorOptions, "countAnchor", barDB, RefreshActionBars)
            countAnchorDD:SetPoint("TOPLEFT", 0, sy)
            countAnchorDD:SetPoint("RIGHT", container, "RIGHT", 0, 0)
            table.insert(widgetRefs, countAnchorDD)
            sy = sy - FORM_ROW

            local countXOffsetSlider = GUI:CreateFormSlider(container, "X-Offset",
                -20, 20, 1, "countOffsetX", barDB, RefreshActionBars)
            countXOffsetSlider:SetPoint("TOPLEFT", 0, sy)
            countXOffsetSlider:SetPoint("RIGHT", container, "RIGHT", 0, 0)
            table.insert(widgetRefs, countXOffsetSlider)
            sy = sy - FORM_ROW

            local countYOffsetSlider = GUI:CreateFormSlider(container, "Y-Offset",
                -20, 20, 1, "countOffsetY", barDB, RefreshActionBars)
            countYOffsetSlider:SetPoint("TOPLEFT", 0, sy)
            countYOffsetSlider:SetPoint("RIGHT", container, "RIGHT", 0, 0)
            table.insert(widgetRefs, countYOffsetSlider)
            sy = sy - FORM_ROW

            local countColorPicker = GUI:CreateFormColorPicker(container, "Color",
                "countColor", barDB, RefreshActionBars)
            countColorPicker:SetPoint("TOPLEFT", 0, sy)
            countColorPicker:SetPoint("RIGHT", container, "RIGHT", 0, 0)
            table.insert(widgetRefs, countColorPicker)
            sy = sy - FORM_ROW

            -- Initialize enabled state
            for _, widget in pairs(widgetRefs) do
                widget:SetEnabled(barDB.overrideEnabled or false)
            end

            -- Set content height and update parent section
            container:SetHeight(math.abs(sy) + 8)

            -- Update parent section height
            local section = container:GetParent()
            if section and section.UpdateHeight then
                section:UpdateHeight()
            end
        end

        -- Edit Mode tip
        local warningText = GUI:CreateLabel(content, "To modify the number of icons, growth direction, or scale of each Action Bar, use Edit Mode and click on the bar you want to configure.", 11, C.warning)
        warningText:SetPoint("TOPLEFT", PAD, -15)
        warningText:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
        warningText:SetJustifyH("LEFT")
        warningText:SetWordWrap(true)
        warningText:SetHeight(30)

        -- Create 8 accordion sections with relative anchoring
        -- Each section anchors to the previous section's bottom for dynamic repositioning
        local prevSection = nil
        for i, info in ipairs(barInfo) do
            local section = GUI:CreateCollapsibleSection(
                content,
                info.label,
                i == 1,  -- First section expanded by default
                {
                    text = "Override",
                    showFunc = function()
                        return bars[info.key] and bars[info.key].overrideEnabled
                    end
                }
            )

            -- Relative anchoring: each section anchors to the previous one's bottom
            if i == 1 then
                section:SetPoint("TOPLEFT", warningText, "BOTTOMLEFT", 0, -12)
            else
                section:SetPoint("TOPLEFT", prevSection, "BOTTOMLEFT", 0, -SECTION_GAP)
            end
            section:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)

            -- Build settings into this section's content
            BuildBarSettingsIntoContainer(info.key, section.content, function()
                section:UpdateBadge()
                section:UpdateHeight()
                UpdateScrollHeight()
            end)

            -- Accordion behavior: collapse others when this expands
            section.OnExpandChanged = function(isExpanded)
                if isExpanded then
                    for _, other in ipairs(sections) do
                        if other ~= section and other:GetExpanded() then
                            other:SetExpanded(false)
                        end
                    end
                end
                UpdateScrollHeight()
            end

            table.insert(sections, section)
            prevSection = section
        end

        -- Initial height calculation (delayed to ensure layout is complete)
        C_Timer.After(0.1, UpdateScrollHeight)
    end  -- End BuildPerBarOverridesTab

    ---------------------------------------------------------
    -- SUB-TAB: Extra Buttons (Extra Action Button & Zone Ability)
    ---------------------------------------------------------
    local function BuildExtraButtonsTab(tabContent)
        local y = -15
        local PAD = PADDING
        local FORM_ROW = 32

        -- Set search context
        GUI:SetSearchContext({tabIndex = 4, tabName = "Action Bars", subTabIndex = 4, subTabName = "Extra Buttons"})

        -- Refresh callback
        local function RefreshExtraButtons()
            if _G.LuheyUI_RefreshExtraButtons then
                _G.LuheyUI_RefreshExtraButtons()
            end
        end

        -- Description
        local descLabel = GUI:CreateLabel(tabContent,
            "Customize the Extra Action Button (boss encounters, quests) and Zone Ability Button (garrison, covenant, zone abilities) separately.",
            11, C.textMuted)
        descLabel:SetPoint("TOPLEFT", PAD, y)
        descLabel:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        descLabel:SetJustifyH("LEFT")
        descLabel:SetWordWrap(true)
        descLabel:SetHeight(30)
        y = y - 40

        -- Toggle Movers Button
        local moverBtn = GUI:CreateButton(tabContent, "Toggle Position Movers", 200, 28, function()
            if _G.LuheyUI_ToggleExtraButtonMovers then
                _G.LuheyUI_ToggleExtraButtonMovers()
            end
        end)
        moverBtn:SetPoint("TOPLEFT", PAD, y)
        y = y - 35

        local moverTip = GUI:CreateLabel(tabContent,
            "Click to show draggable movers. Drag to position, use sliders for fine-tuning.",
            10, C.textMuted)
        moverTip:SetPoint("TOPLEFT", PAD, y)
        moverTip:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
        moverTip:SetJustifyH("LEFT")
        y = y - 25

        ---------------------------------------------------------
        -- SECTION: Extra Action Button
        ---------------------------------------------------------
        local extraHeader = GUI:CreateSectionHeader(tabContent, "Extra Action Button")
        extraHeader:SetPoint("TOPLEFT", PAD, y)
        y = y - extraHeader.gap

        local extraDB = bars.extraActionButton
        if extraDB then
            local enableCheck = GUI:CreateFormCheckbox(tabContent, "Enable Customization",
                "enabled", extraDB, RefreshExtraButtons)
            enableCheck:SetPoint("TOPLEFT", PAD, y)
            enableCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            local scaleSlider = GUI:CreateFormSlider(tabContent, "Scale",
                0.5, 2.0, 0.05, "scale", extraDB, RefreshExtraButtons)
            scaleSlider:SetPoint("TOPLEFT", PAD, y)
            scaleSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            local xOffsetSlider = GUI:CreateFormSlider(tabContent, "X Offset",
                -200, 200, 1, "offsetX", extraDB, RefreshExtraButtons)
            xOffsetSlider:SetPoint("TOPLEFT", PAD, y)
            xOffsetSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            local yOffsetSlider = GUI:CreateFormSlider(tabContent, "Y Offset",
                -200, 200, 1, "offsetY", extraDB, RefreshExtraButtons)
            yOffsetSlider:SetPoint("TOPLEFT", PAD, y)
            yOffsetSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            local hideArtCheck = GUI:CreateFormCheckbox(tabContent, "Hide Button Artwork",
                "hideArtwork", extraDB, RefreshExtraButtons)
            hideArtCheck:SetPoint("TOPLEFT", PAD, y)
            hideArtCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            local fadeCheck = GUI:CreateFormCheckbox(tabContent, "Enable Mouseover Fade",
                "fadeEnabled", extraDB, function()
                    RefreshExtraButtons()
                    if extraDB.fadeEnabled then
                        GUI:ShowConfirmation({
                            title = "Reload UI?",
                            message = "Mouseover fade requires a reload to take effect.",
                            acceptText = "Reload",
                            cancelText = "Later",
                            onAccept = function() LuheyUI:SafeReload() end,
                        })
                    end
                end)
            fadeCheck:SetPoint("TOPLEFT", PAD, y)
            fadeCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW
        end
        y = y - 15

        ---------------------------------------------------------
        -- SECTION: Zone Ability Button
        ---------------------------------------------------------
        local zoneHeader = GUI:CreateSectionHeader(tabContent, "Zone Ability Button")
        zoneHeader:SetPoint("TOPLEFT", PAD, y)
        y = y - zoneHeader.gap

        local zoneDB = bars.zoneAbility
        if zoneDB then
            local enableCheck = GUI:CreateFormCheckbox(tabContent, "Enable Customization",
                "enabled", zoneDB, RefreshExtraButtons)
            enableCheck:SetPoint("TOPLEFT", PAD, y)
            enableCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            local scaleSlider = GUI:CreateFormSlider(tabContent, "Scale",
                0.5, 2.0, 0.05, "scale", zoneDB, RefreshExtraButtons)
            scaleSlider:SetPoint("TOPLEFT", PAD, y)
            scaleSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            local xOffsetSlider = GUI:CreateFormSlider(tabContent, "X Offset",
                -200, 200, 1, "offsetX", zoneDB, RefreshExtraButtons)
            xOffsetSlider:SetPoint("TOPLEFT", PAD, y)
            xOffsetSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            local yOffsetSlider = GUI:CreateFormSlider(tabContent, "Y Offset",
                -200, 200, 1, "offsetY", zoneDB, RefreshExtraButtons)
            yOffsetSlider:SetPoint("TOPLEFT", PAD, y)
            yOffsetSlider:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            local hideArtCheck = GUI:CreateFormCheckbox(tabContent, "Hide Button Artwork",
                "hideArtwork", zoneDB, RefreshExtraButtons)
            hideArtCheck:SetPoint("TOPLEFT", PAD, y)
            hideArtCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW

            local fadeCheck = GUI:CreateFormCheckbox(tabContent, "Enable Mouseover Fade",
                "fadeEnabled", zoneDB, function()
                    RefreshExtraButtons()
                    if zoneDB.fadeEnabled then
                        GUI:ShowConfirmation({
                            title = "Reload UI?",
                            message = "Mouseover fade requires a reload to take effect.",
                            acceptText = "Reload",
                            cancelText = "Later",
                            onAccept = function() LuheyUI:SafeReload() end,
                        })
                    end
                end)
            fadeCheck:SetPoint("TOPLEFT", PAD, y)
            fadeCheck:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
            y = y - FORM_ROW
        end

        tabContent:SetHeight(math.abs(y) + 50)
    end  -- End BuildExtraButtonsTab

    ---------------------------------------------------------
    -- Create Sub-Tabs
    ---------------------------------------------------------
    local subTabs = GUI:CreateSubTabs(content, {
        {name = "Master Settings", builder = BuildMasterSettingsTab},
        {name = "Mouseover Hide", builder = BuildMouseoverHideTab},
        {name = "Per-Bar Overrides", builder = BuildPerBarOverridesTab},
        {name = "Extra Buttons", builder = BuildExtraButtonsTab},
    })
    subTabs:SetPoint("TOPLEFT", 5, -5)
    subTabs:SetPoint("TOPRIGHT", -5, -5)
    subTabs:SetHeight(700)

    content:SetHeight(750)
    return scroll, content
end

---------------------------------------------------------------------------
-- HELPER: Scrollable text box for import strings
---------------------------------------------------------------------------
local function CreateScrollableTextBox(parent, height, text)
    local container = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    container:SetHeight(height)
    container:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    container:SetBackdropColor(0.1, 0.1, 0.1, 1)
    container:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)

    -- ScrollFrame to contain the EditBox
    local scrollFrame = CreateFrame("ScrollFrame", nil, container, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 6, -6)
    scrollFrame:SetPoint("BOTTOMRIGHT", -26, 6)

    -- Style the scroll bar
    local scrollBar = scrollFrame.ScrollBar or _G[scrollFrame:GetName().."ScrollBar"]
    if scrollBar then
        scrollBar:ClearAllPoints()
        scrollBar:SetPoint("TOPRIGHT", container, "TOPRIGHT", -4, -18)
        scrollBar:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", -4, 18)
    end

    -- EditBox inside ScrollFrame
    local editBox = CreateFrame("EditBox", nil, scrollFrame)
    editBox:SetMultiLine(true)
    editBox:SetAutoFocus(false)
    editBox:SetFontObject(GameFontHighlightSmall)
    editBox:SetWidth(scrollFrame:GetWidth() or 400)
    editBox:SetText(text or "")
    editBox:SetCursorPosition(0)
    editBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

    -- Update width when container is sized
    container:SetScript("OnSizeChanged", function(self)
        editBox:SetWidth(self:GetWidth() - 36)
    end)

    scrollFrame:SetScrollChild(editBox)

    container.editBox = editBox
    container.scrollFrame = scrollFrame
    return container
end

---------------------------------------------------------------------------
-- SUB-TAB BUILDER: Import/Export (user profile import/export)
---------------------------------------------------------------------------
local function BuildImportExportTab(tabContent)
    local y = -10
    local PAD = 10

    GUI:SetSearchContext({tabIndex = 13, tabName = "LUI Import/Export", subTabIndex = 1, subTabName = "Import/Export"})

    local info = GUI:CreateLabel(tabContent, "Import and export LuheyUI profiles", 11, C.textMuted)
    info:SetPoint("TOPLEFT", PAD, y)
    info:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
    info:SetJustifyH("LEFT")
    y = y - 28

    -- Export Section Header
    local exportHeader = GUI:CreateSectionHeader(tabContent, "Export Current Profile")
    exportHeader:SetPoint("TOPLEFT", PAD, y)
    y = y - exportHeader.gap

    -- Create a scroll frame for the export box
    local exportScroll = CreateFrame("ScrollFrame", nil, tabContent, "UIPanelScrollFrameTemplate")
    exportScroll:SetPoint("TOPLEFT", PAD, y)
    exportScroll:SetPoint("TOPRIGHT", -PAD - 20, y)
    exportScroll:SetHeight(100)

    local exportEditBox = CreateFrame("EditBox", nil, exportScroll)
    exportEditBox:SetMultiLine(true)
    exportEditBox:SetAutoFocus(false)
    exportEditBox:SetFont(GUI.FONT_PATH, 11, "")
    exportEditBox:SetTextColor(0.8, 0.85, 0.9, 1)
    exportEditBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    exportEditBox:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
    exportScroll:SetScrollChild(exportEditBox)

    -- Set width dynamically when scroll frame is sized
    exportScroll:SetScript("OnSizeChanged", function(self)
        exportEditBox:SetWidth(self:GetWidth() - 10)
    end)

    -- Background for export box
    local exportBg = tabContent:CreateTexture(nil, "BACKGROUND")
    exportBg:SetPoint("TOPLEFT", exportScroll, -5, 5)
    exportBg:SetPoint("BOTTOMRIGHT", exportScroll, 25, -5)
    exportBg:SetColorTexture(0.05, 0.07, 0.1, 0.9)

    -- Border for export box
    local exportBorder = CreateFrame("Frame", nil, tabContent, "BackdropTemplate")
    exportBorder:SetPoint("TOPLEFT", exportScroll, -6, 6)
    exportBorder:SetPoint("BOTTOMRIGHT", exportScroll, 26, -6)
    exportBorder:SetBackdrop({
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    exportBorder:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], 1)

    -- Populate export string
    local function RefreshExportString()
        local LUICore = _G.LuheyUI and _G.LuheyUI.LUICore
        if LUICore and LUICore.ExportProfileToString then
            local str = LUICore:ExportProfileToString()
            exportEditBox:SetText(str or "Error generating export string")
        else
            exportEditBox:SetText("LUICore not available")
        end
    end
    RefreshExportString()

    y = y - 115

    -- SELECT ALL button (themed)
    local selectBtn = GUI:CreateButton(tabContent, "SELECT ALL", 120, 28, function()
        RefreshExportString()
        exportEditBox:SetFocus()
        exportEditBox:HighlightText()
    end)
    selectBtn:SetPoint("TOPLEFT", PAD, y)

    -- Hint text
    local copyHint = GUI:CreateLabel(tabContent, "then press Ctrl+C to copy", 11, C.textMuted)
    copyHint:SetPoint("LEFT", selectBtn, "RIGHT", 12, 0)

    y = y - 50

    -- Import Section Header
    local importHeader = GUI:CreateSectionHeader(tabContent, "Import Profile String")
    importHeader:SetPoint("TOPLEFT", PAD, y)

    -- Paste hint next to header
    local pasteHint = GUI:CreateLabel(tabContent, "press Ctrl+V to paste", 11, C.textMuted)
    pasteHint:SetPoint("LEFT", importHeader, "RIGHT", 12, 0)

    y = y - importHeader.gap

    -- Import EditBox (user pastes string here)
    local importScroll = CreateFrame("ScrollFrame", nil, tabContent, "UIPanelScrollFrameTemplate")
    importScroll:SetPoint("TOPLEFT", PAD, y)
    importScroll:SetPoint("TOPRIGHT", -PAD - 20, y)
    importScroll:SetHeight(100)

    local importEditBox = CreateFrame("EditBox", nil, importScroll)
    importEditBox:SetMultiLine(true)
    importEditBox:SetAutoFocus(false)
    importEditBox:SetFont(GUI.FONT_PATH, 11, "")
    importEditBox:SetTextColor(0.8, 0.85, 0.9, 1)
    importEditBox:SetHeight(100)
    importEditBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    importScroll:SetScrollChild(importEditBox)

    -- Set width dynamically when scroll frame is sized
    importScroll:SetScript("OnSizeChanged", function(self)
        importEditBox:SetWidth(self:GetWidth() - 10)
    end)

    -- Background for import box - make it clickable to focus the editbox
    local importBg = CreateFrame("Button", nil, tabContent)
    importBg:SetPoint("TOPLEFT", importScroll, -5, 5)
    importBg:SetPoint("BOTTOMRIGHT", importScroll, 25, -5)
    importBg:SetScript("OnClick", function() importEditBox:SetFocus() end)

    local importBgTex = importBg:CreateTexture(nil, "BACKGROUND")
    importBgTex:SetAllPoints()
    importBgTex:SetColorTexture(0.05, 0.07, 0.1, 0.9)

    -- Border for import box
    local importBorder = CreateFrame("Frame", nil, tabContent, "BackdropTemplate")
    importBorder:SetPoint("TOPLEFT", importScroll, -6, 6)
    importBorder:SetPoint("BOTTOMRIGHT", importScroll, 26, -6)
    importBorder:SetBackdrop({
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    importBorder:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], 1)

    y = y - 115

    -- IMPORT AND RELOAD button (themed)
    local importBtn = GUI:CreateButton(tabContent, "IMPORT AND RELOAD", 200, 28, function()
        local str = importEditBox:GetText()
        if not str or str == "" then
            print("|cffff0000LuheyUI: No import string provided.|r")
            return
        end
        local LUICore = _G.LuheyUI and _G.LuheyUI.LUICore
        if LUICore and LUICore.ImportProfileFromString then
            local ok, err = LUICore:ImportProfileFromString(str)
            if ok then
                print("|cff34D399LuheyUI:|r Profile imported successfully!")
                print("|cff34D399LuheyUI:|r Please type |cFFFFD700/reload|r to apply changes.")
            else
                print("|cffff0000LuheyUI: Import failed: " .. (err or "Unknown error") .. "|r")
            end
        else
            print("|cffff0000LuheyUI: LUICore not available for import.|r")
        end
    end)
    importBtn:SetPoint("TOPLEFT", PAD, y)
    y = y - 40

    tabContent:SetHeight(math.abs(y) + 20)
end

---------------------------------------------------------------------------
-- SUB-TAB BUILDER: Quazii's Strings (preset import strings)
---------------------------------------------------------------------------
local function BuildLuheyStringsTab(tabContent)
    local y = -10
    local PAD = 10
    local BOX_HEIGHT = 70

    GUI:SetSearchContext({tabIndex = 13, tabName = "LUI Import/Export", subTabIndex = 2, subTabName = "Luhey's Strings"})

    local info = GUI:CreateLabel(tabContent, "Luhey's personal import strings - select all and copy", 11, C.textMuted)
    info:SetPoint("TOPLEFT", PAD, y)
    info:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
    info:SetJustifyH("LEFT")
    y = y - 28

    -- Store all text boxes for clearing selections
    local allTextBoxes = {}

    -- Helper to clear all selections except the target
    local function selectOnly(targetEditBox)
        for _, editBox in ipairs(allTextBoxes) do
            if editBox ~= targetEditBox then
                editBox:ClearFocus()
                editBox:HighlightText(0, 0)
            end
        end
        targetEditBox:SetFocus()
        targetEditBox:HighlightText()
    end

    -- =====================================================
    -- EDIT MODE STRING
    -- =====================================================
    local editModeHeader = GUI:CreateSectionHeader(tabContent, "Luhey Edit Mode String")
    editModeHeader:SetPoint("TOPLEFT", PAD, y)
    y = y - editModeHeader.gap

    local editModeString = ""
    if _G.LuheyUI and _G.LuheyUI.imports and _G.LuheyUI.imports.EditMode then
        editModeString = _G.LuheyUI.imports.EditMode.data or ""
    end

    local editModeContainer = CreateScrollableTextBox(tabContent, BOX_HEIGHT, editModeString)
    editModeContainer:SetPoint("TOPLEFT", PAD, y)
    editModeContainer:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
    table.insert(allTextBoxes, editModeContainer.editBox)

    y = y - BOX_HEIGHT - 8

    local editModeBtn = GUI:CreateButton(tabContent, "SELECT ALL", 120, 24, function()
        selectOnly(editModeContainer.editBox)
    end)
    editModeBtn:SetPoint("TOPLEFT", PAD, y)

    local editModeTip = GUI:CreateLabel(tabContent, "then press Ctrl+C to copy", 11, C.textMuted)
    editModeTip:SetPoint("LEFT", editModeBtn, "RIGHT", 10, 0)
    y = y - 40

    -- =====================================================
    -- QUI IMPORT/EXPORT STRING - DEFAULT PROFILE
    -- =====================================================
    local luiHeader = GUI:CreateSectionHeader(tabContent, "LUI Import/Export String - Default Profile")
    luiHeader:SetPoint("TOPLEFT", PAD, y)
    y = y - luiHeader.gap

    local quiString = ""
    if _G.LuheyUI and _G.LuheyUI.imports and _G.LuheyUI.imports.LUIProfile then
        quiString = _G.LuheyUI.imports.LUIProfile.data or ""
    end

    local quiContainer = CreateScrollableTextBox(tabContent, BOX_HEIGHT, quiString)
    quiContainer:SetPoint("TOPLEFT", PAD, y)
    quiContainer:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
    table.insert(allTextBoxes, quiContainer.editBox)

    y = y - BOX_HEIGHT - 8

    local quiBtn = GUI:CreateButton(tabContent, "SELECT ALL", 120, 24, function()
        selectOnly(quiContainer.editBox)
    end)
    quiBtn:SetPoint("TOPLEFT", PAD, y)

    local quiTip = GUI:CreateLabel(tabContent, "then press Ctrl+C to copy", 11, C.textMuted)
    quiTip:SetPoint("LEFT", quiBtn, "RIGHT", 10, 0)
    y = y - 40

    -- =====================================================
    -- QUI IMPORT/EXPORT STRING - DARK MODE
    -- =====================================================
    local luiDarkHeader = GUI:CreateSectionHeader(tabContent, "LUI Import/Export String - Dark Mode")
    luiDarkHeader:SetPoint("TOPLEFT", PAD, y)
    y = y - luiDarkHeader.gap

    local quiDarkString = ""
    if _G.LuheyUI and _G.LuheyUI.imports and _G.LuheyUI.imports.LUIProfileDarkMode then
        quiDarkString = _G.LuheyUI.imports.LUIProfileDarkMode.data or ""
    end

    local quiDarkContainer = CreateScrollableTextBox(tabContent, BOX_HEIGHT, quiDarkString)
    quiDarkContainer:SetPoint("TOPLEFT", PAD, y)
    quiDarkContainer:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
    table.insert(allTextBoxes, quiDarkContainer.editBox)

    y = y - BOX_HEIGHT - 8

    local quiDarkBtn = GUI:CreateButton(tabContent, "SELECT ALL", 120, 24, function()
        selectOnly(quiDarkContainer.editBox)
    end)
    quiDarkBtn:SetPoint("TOPLEFT", PAD, y)

    local quiDarkTip = GUI:CreateLabel(tabContent, "then press Ctrl+C to copy", 11, C.textMuted)
    quiDarkTip:SetPoint("LEFT", quiDarkBtn, "RIGHT", 10, 0)
    y = y - 40

    -- =====================================================
    -- PLATYNATOR STRING
    -- =====================================================
    local platHeader = GUI:CreateSectionHeader(tabContent, "Platynator String")
    platHeader:SetPoint("TOPLEFT", PAD, y)
    y = y - platHeader.gap

    local platString = ""
    if _G.LuheyUI and _G.LuheyUI.imports and _G.LuheyUI.imports.Platynator then
        platString = _G.LuheyUI.imports.Platynator.data or ""
    end

    local platContainer = CreateScrollableTextBox(tabContent, BOX_HEIGHT, platString)
    platContainer:SetPoint("TOPLEFT", PAD, y)
    platContainer:SetPoint("RIGHT", tabContent, "RIGHT", -PAD, 0)
    table.insert(allTextBoxes, platContainer.editBox)

    y = y - BOX_HEIGHT - 8

    local platBtn = GUI:CreateButton(tabContent, "SELECT ALL", 120, 24, function()
        selectOnly(platContainer.editBox)
    end)
    platBtn:SetPoint("TOPLEFT", PAD, y)

    local platTip = GUI:CreateLabel(tabContent, "then press Ctrl+C to copy", 11, C.textMuted)
    platTip:SetPoint("LEFT", platBtn, "RIGHT", 10, 0)
    y = y - 30

    tabContent:SetHeight(math.abs(y) + 20)
end

---------------------------------------------------------------------------
-- PAGE: QUI Import/Export (with sub-tabs)
---------------------------------------------------------------------------
local function CreateImportExportPage(parent)
    local scroll, content = CreateScrollableContent(parent)

    local subTabs = GUI:CreateSubTabs(content, {
        {name = "Import/Export", builder = BuildImportExportTab},
        {name = "Luhey's Strings", builder = BuildLuheyStringsTab},
    })
    subTabs:SetPoint("TOPLEFT", 5, -5)
    subTabs:SetPoint("TOPRIGHT", -5, -5)
    subTabs:SetHeight(550)

    content:SetHeight(600)
end

---------------------------------------------------------------------------
-- PAGE: Spec Profiles (Autoswap)
---------------------------------------------------------------------------
local function CreateSpecProfilesPage(parent)
    local scroll, content = CreateScrollableContent(parent)
    local y = -15
    local PAD = PADDING
    local FORM_ROW = 32

    local LUICore = _G.LuheyUI and _G.LuheyUI.LUICore
    local db = LUICore and LUICore.db

    local info = GUI:CreateLabel(content, "Manage profiles and auto-switch based on specialization", 11, C.textMuted)
    info:SetPoint("TOPLEFT", PAD, y)
    info:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    info:SetJustifyH("LEFT")
    y = y - 28
    
    -- =====================================================
    -- CURRENT PROFILE SECTION
    -- =====================================================
    local currentHeader = GUI:CreateSectionHeader(content, "Current Profile")
    currentHeader:SetPoint("TOPLEFT", PAD, y)
    y = y - currentHeader.gap

    -- Forward declare profileDropdown so refresh function can reference it
    local profileDropdown

    -- Current profile display (form style row)
    local activeContainer = CreateFrame("Frame", nil, content)
    activeContainer:SetHeight(FORM_ROW)
    activeContainer:SetPoint("TOPLEFT", PAD, y)
    activeContainer:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)

    local currentProfileLabel = activeContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    currentProfileLabel:SetPoint("LEFT", 0, 0)
    currentProfileLabel:SetText("Active Profile")
    currentProfileLabel:SetTextColor(C.text[1], C.text[2], C.text[3], 1)

    local currentProfileName = activeContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    currentProfileName:SetPoint("LEFT", activeContainer, "LEFT", 180, 0)
    currentProfileName:SetText("Loading...")
    currentProfileName:SetTextColor(C.accent[1], C.accent[2], C.accent[3], 1)
    
    -- Function to refresh profile display - called on show and via timer
    -- Note: This gets replaced later after profileDropdown is created
    local function RefreshProfileDisplay()
        local LUICore = _G.LuheyUI and _G.LuheyUI.LUICore
        local freshDB = LUICore and LUICore.db
        if freshDB then
            local currentName = freshDB:GetCurrentProfile()
            currentProfileName:SetText(currentName or "Unknown")
        end
    end
    
    -- Update on show
    content:SetScript("OnShow", RefreshProfileDisplay)
    
    -- Also update on scroll parent show (in case content is already visible)
    scroll:SetScript("OnShow", RefreshProfileDisplay)
    
    -- Also use a short timer to catch any race conditions
    C_Timer.After(0.1, RefreshProfileDisplay)

    y = y - FORM_ROW

    -- Reset Profile button (form style row)
    local resetContainer = CreateFrame("Frame", nil, content)
    resetContainer:SetHeight(FORM_ROW)
    resetContainer:SetPoint("TOPLEFT", PAD, y)
    resetContainer:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)

    local resetLabel = resetContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    resetLabel:SetPoint("LEFT", 0, 0)
    resetLabel:SetText("Reset Profile")
    resetLabel:SetTextColor(C.text[1], C.text[2], C.text[3], 1)

    local resetBtn = CreateFrame("Button", nil, resetContainer, "BackdropTemplate")
    resetBtn:SetSize(120, 24)
    resetBtn:SetPoint("LEFT", resetContainer, "LEFT", 180, 0)
    resetBtn:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1})
    resetBtn:SetBackdropColor(0.15, 0.15, 0.15, 1)
    resetBtn:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], 1)
    local resetBtnText = resetBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    resetBtnText:SetPoint("CENTER")
    resetBtnText:SetText("Reset to Defaults")
    resetBtnText:SetTextColor(C.text[1], C.text[2], C.text[3], 1)
    resetBtn:SetScript("OnEnter", function(self) self:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 1) end)
    resetBtn:SetScript("OnLeave", function(self) self:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], 1) end)
    resetBtn:SetScript("OnClick", function()
        if db then
            GUI:ShowConfirmation({
                title = "Reset Profile?",
                message = "Reset current profile to defaults?",
                warningText = "This cannot be undone.",
                acceptText = "Reset",
                cancelText = "Cancel",
                isDestructive = true,
                onAccept = function()
                    local LUICore = _G.LuheyUI and _G.LuheyUI.LUICore
                    local dbRef = LUICore and LUICore.db
                    if dbRef then
                        dbRef:ResetProfile()
                        print("|cff34D399LuheyUI:|r Profile reset to defaults.")
                        print("|cff34D399LuheyUI:|r Please type |cFFFFD700/reload|r to apply changes.")
                    end
                end,
            })
        end
    end)
    y = y - FORM_ROW - 10

    -- =====================================================
    -- PROFILE SELECTION SECTION
    -- =====================================================
    local selectHeader = GUI:CreateSectionHeader(content, "Switch Profile")
    selectHeader:SetPoint("TOPLEFT", PAD, y)
    y = y - selectHeader.gap
    
    -- Get existing profiles
    local function GetProfileList()
        local profiles = {}
        if db then
            local profileList = db:GetProfiles()
            for _, name in ipairs(profileList) do
                table.insert(profiles, {value = name, text = name})
            end
        end
        return profiles
    end
    
    -- Profile dropdown - custom styled (matches our form dropdowns)
    local profileDropdownContainer = CreateFrame("Frame", nil, content)
    profileDropdownContainer:SetHeight(FORM_ROW)
    profileDropdownContainer:SetPoint("TOPLEFT", PAD, y)
    profileDropdownContainer:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)

    local profileDropdownLabel = profileDropdownContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    profileDropdownLabel:SetPoint("LEFT", 0, 0)
    profileDropdownLabel:SetText("Select Profile")
    profileDropdownLabel:SetTextColor(C.text[1], C.text[2], C.text[3], 1)

    -- Custom dropdown button (styled to match our form dropdowns)
    local CHEVRON_ZONE_WIDTH = 28
    local CHEVRON_BG_ALPHA = 0.15
    local CHEVRON_BG_ALPHA_HOVER = 0.25
    local CHEVRON_TEXT_ALPHA = 0.8

    profileDropdown = CreateFrame("Button", nil, profileDropdownContainer, "BackdropTemplate")
    profileDropdown:SetHeight(24)
    profileDropdown:SetPoint("LEFT", profileDropdownContainer, "LEFT", 180, 0)
    profileDropdown:SetPoint("RIGHT", profileDropdownContainer, "RIGHT", 0, 0)
    profileDropdown:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    profileDropdown:SetBackdropColor(0.08, 0.08, 0.08, 1)
    profileDropdown:SetBackdropBorderColor(0.35, 0.35, 0.35, 1)

    -- Chevron zone (right side with accent tint)
    local chevronZone = CreateFrame("Frame", nil, profileDropdown, "BackdropTemplate")
    chevronZone:SetWidth(CHEVRON_ZONE_WIDTH)
    chevronZone:SetPoint("TOPRIGHT", profileDropdown, "TOPRIGHT", -1, -1)
    chevronZone:SetPoint("BOTTOMRIGHT", profileDropdown, "BOTTOMRIGHT", -1, 1)
    chevronZone:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
    })
    chevronZone:SetBackdropColor(C.accent[1], C.accent[2], C.accent[3], CHEVRON_BG_ALPHA)

    -- Separator line (left edge of chevron zone)
    local separator = chevronZone:CreateTexture(nil, "ARTWORK")
    separator:SetWidth(1)
    separator:SetPoint("TOPLEFT", chevronZone, "TOPLEFT", 0, 0)
    separator:SetPoint("BOTTOMLEFT", chevronZone, "BOTTOMLEFT", 0, 0)
    separator:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 0.3)

    -- Line chevron (two angled lines forming a V pointing DOWN)
    local chevronLeft = chevronZone:CreateTexture(nil, "OVERLAY")
    chevronLeft:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], CHEVRON_TEXT_ALPHA)
    chevronLeft:SetSize(7, 2)
    chevronLeft:SetPoint("CENTER", chevronZone, "CENTER", -2, -1)
    chevronLeft:SetRotation(math.rad(-45))

    local chevronRight = chevronZone:CreateTexture(nil, "OVERLAY")
    chevronRight:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], CHEVRON_TEXT_ALPHA)
    chevronRight:SetSize(7, 2)
    chevronRight:SetPoint("CENTER", chevronZone, "CENTER", 2, -1)
    chevronRight:SetRotation(math.rad(45))

    local profileDropdownText = profileDropdown:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    profileDropdownText:SetFont(GUI.FONT_PATH, 11, "")
    profileDropdownText:SetPoint("LEFT", 8, 0)
    profileDropdownText:SetPoint("RIGHT", chevronZone, "LEFT", -5, 0)
    profileDropdownText:SetJustifyH("LEFT")
    profileDropdownText:SetTextColor(C.text[1], C.text[2], C.text[3], 1)

    profileDropdown:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 1)
        chevronZone:SetBackdropColor(C.accent[1], C.accent[2], C.accent[3], CHEVRON_BG_ALPHA_HOVER)
        separator:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 0.5)
        chevronLeft:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 1)
        chevronRight:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 1)
    end)
    profileDropdown:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(0.35, 0.35, 0.35, 1)
        chevronZone:SetBackdropColor(C.accent[1], C.accent[2], C.accent[3], CHEVRON_BG_ALPHA)
        separator:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 0.3)
        chevronLeft:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], CHEVRON_TEXT_ALPHA)
        chevronRight:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], CHEVRON_TEXT_ALPHA)
    end)

    -- Menu frame for profile options
    local profileMenu = CreateFrame("Frame", nil, profileDropdown, "BackdropTemplate")
    profileMenu:SetPoint("TOPLEFT", profileDropdown, "BOTTOMLEFT", 0, -2)
    profileMenu:SetPoint("TOPRIGHT", profileDropdown, "BOTTOMRIGHT", 0, -2)
    profileMenu:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    profileMenu:SetBackdropColor(0.1, 0.1, 0.1, 0.98)
    profileMenu:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
    profileMenu:SetFrameStrata("TOOLTIP")
    profileMenu:Hide()

    local function BuildProfileMenu()
        -- Clear existing items
        for _, child in ipairs({profileMenu:GetChildren()}) do
            child:Hide()
            child:SetParent(nil)
        end

        local LUICore = _G.LuheyUI and _G.LuheyUI.LUICore
        local freshDB = LUICore and LUICore.db
        if not freshDB then return end

        local profiles = freshDB:GetProfiles()
        local currentProfile = freshDB:GetCurrentProfile()
        local itemHeight = 20
        local menuHeight = #profiles * itemHeight + 4

        profileMenu:SetHeight(menuHeight)

        for i, profileName in ipairs(profiles) do
            local item = CreateFrame("Button", nil, profileMenu, "BackdropTemplate")
            item:SetHeight(itemHeight)
            item:SetPoint("TOPLEFT", 2, -2 - (i-1) * itemHeight)
            item:SetPoint("TOPRIGHT", -2, -2 - (i-1) * itemHeight)

            local itemText = item:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            itemText:SetFont(GUI.FONT_PATH, 11, "")
            itemText:SetPoint("LEFT", 6, 0)
            itemText:SetText(profileName)

            if profileName == currentProfile then
                itemText:SetTextColor(C.accent[1], C.accent[2], C.accent[3], 1)
            else
                itemText:SetTextColor(C.text[1], C.text[2], C.text[3], 1)
            end

            item:SetScript("OnEnter", function(self)
                self:SetBackdropColor(C.accent[1] * 0.3, C.accent[2] * 0.3, C.accent[3] * 0.3, 1)
            end)
            item:SetScript("OnLeave", function(self)
                self:SetBackdropColor(0, 0, 0, 0)
            end)
            item:SetScript("OnClick", function()
                if profileName ~= currentProfile then
                    freshDB:SetProfile(profileName)
                    profileDropdownText:SetText(profileName)
                    currentProfileName:SetText(profileName)
                    print("|cff34D399LuheyUI:|r Switched to profile: " .. profileName)
                end
                profileMenu:Hide()
            end)
        end
    end

    profileDropdown:SetScript("OnClick", function()
        if profileMenu:IsShown() then
            profileMenu:Hide()
        else
            BuildProfileMenu()
            profileMenu:Show()
        end
    end)

    -- Set initial text
    local initCore = _G.LuheyUI and _G.LuheyUI.LUICore
    local initDB = initCore and initCore.db
    local initProfile = initDB and initDB:GetCurrentProfile() or "Default"
    profileDropdownText:SetText(initProfile)

    -- Update RefreshProfileDisplay to use our custom dropdown
    local oldRefresh = RefreshProfileDisplay
    RefreshProfileDisplay = function()
        local LUICore = _G.LuheyUI and _G.LuheyUI.LUICore
        local freshDB = LUICore and LUICore.db
        if freshDB then
            local currentName = freshDB:GetCurrentProfile()
            currentProfileName:SetText(currentName or "Unknown")
            profileDropdownText:SetText(currentName or "Default")
        end
    end

    -- Re-register OnShow scripts with updated function (they were set before replacement)
    content:SetScript("OnShow", RefreshProfileDisplay)
    scroll:SetScript("OnShow", RefreshProfileDisplay)

    -- Refresh display after a short delay to ensure everything is loaded
    C_Timer.After(0.2, RefreshProfileDisplay)
    C_Timer.After(0.5, RefreshProfileDisplay)

    -- Expose refresh function for profile change callbacks
    _G.LuheyUI_RefreshSpecProfilesTab = RefreshProfileDisplay

    y = y - FORM_ROW - 10

    -- =====================================================
    -- CREATE NEW PROFILE SECTION
    -- =====================================================
    local newHeader = GUI:CreateSectionHeader(content, "Create New Profile")
    newHeader:SetPoint("TOPLEFT", PAD, y)
    y = y - newHeader.gap

    -- New profile name input (form style row)
    local newProfileContainer = CreateFrame("Frame", nil, content)
    newProfileContainer:SetHeight(FORM_ROW)
    newProfileContainer:SetPoint("TOPLEFT", PAD, y)
    newProfileContainer:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)

    local newProfileLabel = newProfileContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    newProfileLabel:SetPoint("LEFT", 0, 0)
    newProfileLabel:SetText("Profile Name")
    newProfileLabel:SetTextColor(C.text[1], C.text[2], C.text[3], 1)

    -- Custom styled editbox (matches dropdown styling)
    local newProfileBoxBg = CreateFrame("Frame", nil, newProfileContainer, "BackdropTemplate")
    newProfileBoxBg:SetPoint("LEFT", newProfileContainer, "LEFT", 180, 0)
    newProfileBoxBg:SetSize(200, 24)
    newProfileBoxBg:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    newProfileBoxBg:SetBackdropColor(0.08, 0.08, 0.08, 1)
    newProfileBoxBg:SetBackdropBorderColor(0.35, 0.35, 0.35, 1)

    local newProfileBox = CreateFrame("EditBox", nil, newProfileBoxBg)
    newProfileBox:SetPoint("LEFT", 8, 0)
    newProfileBox:SetPoint("RIGHT", -8, 0)
    newProfileBox:SetHeight(22)
    newProfileBox:SetAutoFocus(false)
    newProfileBox:SetFont(GUI.FONT_PATH, 11, "")
    newProfileBox:SetTextColor(C.text[1], C.text[2], C.text[3], 1)
    newProfileBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    newProfileBox:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    newProfileBox:SetScript("OnEditFocusGained", function()
        newProfileBoxBg:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 1)
    end)
    newProfileBox:SetScript("OnEditFocusLost", function()
        newProfileBoxBg:SetBackdropBorderColor(0.35, 0.35, 0.35, 1)
    end)

    -- Create button
    local createBtn = CreateFrame("Button", nil, newProfileContainer, "BackdropTemplate")
    createBtn:SetSize(80, 24)
    createBtn:SetPoint("LEFT", newProfileBoxBg, "RIGHT", 10, 0)
    createBtn:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1})
    createBtn:SetBackdropColor(0.15, 0.15, 0.15, 1)
    createBtn:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], 1)
    local createBtnText = createBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    createBtnText:SetPoint("CENTER")
    createBtnText:SetText("Create")
    createBtnText:SetTextColor(C.text[1], C.text[2], C.text[3], 1)
    createBtn:SetScript("OnEnter", function(self) self:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 1) end)
    createBtn:SetScript("OnLeave", function(self) self:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], 1) end)
    createBtn:SetScript("OnClick", function()
        local newName = newProfileBox:GetText()
        if newName and newName ~= "" and db then
            db:SetProfile(newName)
            currentProfileName:SetText(newName)
            profileDropdownText:SetText(newName)
            newProfileBox:SetText("")
            print("|cff34D399LuheyUI:|r Created new profile: " .. newName)
        end
    end)
    y = y - FORM_ROW - 10
    
    -- =====================================================
    -- COPY FROM PROFILE SECTION
    -- =====================================================
    local copyHeader = GUI:CreateSectionHeader(content, "Copy From Profile")
    copyHeader:SetPoint("TOPLEFT", PAD, y)
    y = y - copyHeader.gap

    local copyInfo = GUI:CreateLabel(content, "Copy settings from another profile into current", 11, C.textMuted)
    copyInfo:SetPoint("TOPLEFT", PAD, y)
    copyInfo:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    copyInfo:SetJustifyH("LEFT")
    y = y - 24

    -- Copy from dropdown (form style)
    local copyWrapper = { selected = "" }
    local copyDropdown = GUI:CreateFormDropdown(content, "Copy From", GetProfileList(), "selected", copyWrapper, function(value)
        if db and value and value ~= "" then
            db:CopyProfile(value)
            print("|cff34D399LuheyUI:|r Copied settings from: " .. value)
            copyWrapper.selected = ""
        end
    end)
    copyDropdown:SetPoint("TOPLEFT", PAD, y)
    copyDropdown:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - FORM_ROW - 10

    -- =====================================================
    -- DELETE PROFILE SECTION
    -- =====================================================
    local deleteHeader = GUI:CreateSectionHeader(content, "Delete Profile")
    deleteHeader:SetPoint("TOPLEFT", PAD, y)
    y = y - deleteHeader.gap

    local deleteInfo = GUI:CreateLabel(content, "Remove unused profiles to save space", 11, C.textMuted)
    deleteInfo:SetPoint("TOPLEFT", PAD, y)
    deleteInfo:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    deleteInfo:SetJustifyH("LEFT")
    y = y - 24

    -- Delete dropdown (form style)
    local deleteWrapper = { selected = "" }
    local deleteDropdown = GUI:CreateFormDropdown(content, "Delete Profile", GetProfileList(), "selected", deleteWrapper, function(value)
        if db and value and value ~= "" then
            local current = db:GetCurrentProfile()
            if value == current then
                print("|cffff0000LuheyUI:|r Cannot delete the active profile!")
                deleteWrapper.selected = ""
            else
                -- Show confirmation dialog
                local profileToDelete = value
                GUI:ShowConfirmation({
                    title = "Delete Profile?",
                    message = string.format("Delete profile '%s'?", profileToDelete),
                    warningText = "This cannot be undone.",
                    acceptText = "Delete",
                    cancelText = "Cancel",
                    isDestructive = true,
                    onAccept = function()
                        db:DeleteProfile(profileToDelete, true)
                        print("|cff34D399LuheyUI:|r Deleted profile: " .. profileToDelete)
                        deleteWrapper.selected = ""
                    end,
                })
            end
        end
    end)
    deleteDropdown:SetPoint("TOPLEFT", PAD, y)
    deleteDropdown:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - FORM_ROW - 10

    -- =====================================================
    -- SPEC AUTO-SWITCH SECTION
    -- =====================================================
    local specHeader = GUI:CreateSectionHeader(content, "Spec Auto-Switch")
    specHeader:SetPoint("TOPLEFT", PAD, y)
    y = y - specHeader.gap

    -- Check if LibDualSpec methods are available on db (added by EnhanceDatabase)
    if db and db.IsDualSpecEnabled and db.SetDualSpecEnabled and db.GetDualSpecProfile and db.SetDualSpecProfile then
        -- Enable checkbox (form style)
        local enableWrapper = { enabled = db:IsDualSpecEnabled() }
        local enableCheckbox = GUI:CreateFormCheckbox(content, "Enable Spec Profiles", "enabled", enableWrapper,
            function()
                db:SetDualSpecEnabled(enableWrapper.enabled)
                print("|cff34D399LuheyUI:|r Spec auto-switch " .. (enableWrapper.enabled and "enabled" or "disabled"))
            end)
        enableCheckbox:SetPoint("TOPLEFT", PAD, y)
        enableCheckbox:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local specInfo = GUI:CreateLabel(content, "When enabled, your profile will switch when you change specialization", 11, C.textMuted)
        specInfo:SetPoint("TOPLEFT", PAD, y)
        specInfo:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
        specInfo:SetJustifyH("LEFT")
        y = y - 28

        -- Get spec names for current class
        local numSpecs = GetNumSpecializations()
        local currentSpec = GetSpecialization()

        for i = 1, numSpecs do
            local specID, specName = GetSpecializationInfo(i)
            if specName then
                -- Mark active spec
                local displayName = specName
                if i == currentSpec then
                    displayName = specName .. " (Active)"
                end

                -- Get current profile for this spec using LibDualSpec method
                local currentSpecProfile = db:GetDualSpecProfile(i) or ""
                local specWrapper = { selected = currentSpecProfile }

                -- Dropdown for this spec (form style)
                local specDropdown = GUI:CreateFormDropdown(content, displayName, GetProfileList(), "selected", specWrapper, function(value)
                    if value and value ~= "" then
                        db:SetDualSpecProfile(value, i)
                        print("|cff34D399LuheyUI:|r " .. specName .. " will use profile: " .. value)
                    end
                end)
                specDropdown:SetPoint("TOPLEFT", PAD, y)
                specDropdown:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
                
                y = y - FORM_ROW
            end
        end
    else
        local noSpec = GUI:CreateLabel(content, "LibDualSpec not available. Make sure another addon provides it.", 11, C.textMuted)
        noSpec:SetPoint("TOPLEFT", PAD, y)
        noSpec:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
        noSpec:SetJustifyH("LEFT")
        y = y - 24

        local noSpec2 = GUI:CreateLabel(content, "Common addons with LibDualSpec: Masque and other action bar addons", 11, C.textMuted)
        noSpec2:SetPoint("TOPLEFT", PAD, y)
        noSpec2:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
        noSpec2:SetJustifyH("LEFT")
        y = y - 24
    end

    y = y - 20

    content:SetHeight(math.abs(y) + 20)
end

---------------------------------------------------------------------------
-- SEARCH TAB - Search settings across all tabs
---------------------------------------------------------------------------
local function CreateSearchPage(tabContent)
    local PAD = 15
    local y = -10

    -- Search input at top
    local searchBox = GUI:CreateSearchBox(tabContent)
    searchBox:SetSize(tabContent:GetWidth() - (PAD * 2), 28)
    searchBox:SetPoint("TOPLEFT", PAD, y)
    y = y - 40

    -- Results scroll area below
    local scrollFrame = CreateFrame("ScrollFrame", nil, tabContent, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", PAD, y)
    scrollFrame:SetPoint("BOTTOMRIGHT", -30, 10)

    local resultsContent = CreateFrame("Frame", nil, scrollFrame)
    resultsContent:SetWidth(scrollFrame:GetWidth() - 10)
    scrollFrame:SetScrollChild(resultsContent)

    -- Scroll bar styling
    local scrollBar = scrollFrame.ScrollBar
    if scrollBar then
        scrollBar:SetPoint("TOPLEFT", scrollFrame, "TOPRIGHT", 4, -16)
        scrollBar:SetPoint("BOTTOMLEFT", scrollFrame, "BOTTOMRIGHT", 4, 16)
    end

    -- Initial empty state
    GUI:RenderSearchResults(resultsContent, nil, nil)

    -- Wire up search callbacks
    searchBox.onSearch = function(text)
        local results = GUI:ExecuteSearch(text)
        GUI:RenderSearchResults(resultsContent, results, text)
    end

    searchBox.onClear = function()
        GUI:RenderSearchResults(resultsContent, nil, nil)
    end

    tabContent.searchBox = searchBox
    tabContent.resultsContent = resultsContent
end

---------------------------------------------------------------------------
-- HUD LAYERING PAGE
---------------------------------------------------------------------------
local function CreateHUDLayeringPage(parent)
    local scroll, content = CreateScrollableContent(parent)
    local y = -15
    local PAD = PADDING
    local FORM_ROW = 32

    local LUICore = _G.LuheyUI and _G.LuheyUI.LUICore
    local db = LUICore and LUICore.db and LUICore.db.profile

    -- Helper to get hudLayering table (with fallback initialization)
    local function GetLayeringDB()
        if not db then return nil end
        if not db.hudLayering then
            db.hudLayering = {
                essential = 5, utility = 5, buffIcon = 5,
                primaryPowerBar = 7, secondaryPowerBar = 6,
                playerFrame = 4, targetFrame = 4, totFrame = 3, petFrame = 3, focusFrame = 4, bossFrames = 4,
                playerCastbar = 5, targetCastbar = 5,
                playerIndicators = 6,  -- Player frame indicator icons (rested, combat, stance)
                customBars = 5,
                skyridingHUD = 5,
            }
        end
        return db.hudLayering
    end

    -- Refresh functions for each component type
    local function RefreshCDM()
        if NCDM and NCDM.ApplySettings then
            NCDM:ApplySettings("essential")
            NCDM:ApplySettings("utility")
        end
        if _G.LuheyUI_RefreshBuffBar then
            _G.LuheyUI_RefreshBuffBar()
        end
    end

    local function RefreshPowerBars()
        if LUICore and LUICore.UpdatePowerBar then
            LUICore:UpdatePowerBar()
        end
        if LUICore and LUICore.UpdateSecondaryPowerBar then
            LUICore:UpdateSecondaryPowerBar()
        end
    end

    local function RefreshUnitFrames()
        if _G.LuheyUI_RefreshUnitFrames then
            _G.LuheyUI_RefreshUnitFrames()
        end
    end

    local function RefreshCastbars()
        if _G.LuheyUI_RefreshCastbars then
            _G.LuheyUI_RefreshCastbars()
        end
    end

    local function RefreshCustomTrackers()
        if _G.LuheyUI_RefreshCustomTrackers then
            _G.LuheyUI_RefreshCustomTrackers()
        end
    end

    local function RefreshSkyriding()
        if _G.LuheyUI_RefreshSkyriding then
            _G.LuheyUI_RefreshSkyriding()
        end
    end

    -- Header description
    local info = GUI:CreateLabel(content, "Control which HUD elements appear above others. Higher values render on top of lower values.", 11, C.textMuted)
    info:SetPoint("TOPLEFT", PAD, y)
    info:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    info:SetJustifyH("LEFT")
    y = y - 28

    local layeringDB = GetLayeringDB()
    if not layeringDB then
        local errorLabel = GUI:CreateLabel(content, "Database not loaded. Please reload UI.", 12, {1, 0.3, 0.3, 1})
        errorLabel:SetPoint("TOPLEFT", PAD, y)
        return scroll
    end

    -- =====================================================
    -- COOLDOWN DISPLAY MANAGER SECTION
    -- =====================================================
    local cdmHeader = GUI:CreateSectionHeader(content, "Cooldown Display Manager")
    cdmHeader:SetPoint("TOPLEFT", PAD, y)
    y = y - cdmHeader.gap

    local essentialSlider = GUI:CreateFormSlider(content, "Essential Viewer", 0, 10, 1, "essential", layeringDB, RefreshCDM)
    essentialSlider:SetPoint("TOPLEFT", PAD, y)
    essentialSlider:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - FORM_ROW

    local utilitySlider = GUI:CreateFormSlider(content, "Utility Viewer", 0, 10, 1, "utility", layeringDB, RefreshCDM)
    utilitySlider:SetPoint("TOPLEFT", PAD, y)
    utilitySlider:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - FORM_ROW

    local buffIconSlider = GUI:CreateFormSlider(content, "Buff Icon Viewer", 0, 10, 1, "buffIcon", layeringDB, RefreshCDM)
    buffIconSlider:SetPoint("TOPLEFT", PAD, y)
    buffIconSlider:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - FORM_ROW

    local buffBarSlider = GUI:CreateFormSlider(content, "Buff Bar Viewer", 0, 10, 1, "buffBar", layeringDB, RefreshCDM)
    buffBarSlider:SetPoint("TOPLEFT", PAD, y)
    buffBarSlider:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - FORM_ROW

    y = y - 10  -- Section spacing

    -- =====================================================
    -- POWER BARS SECTION
    -- =====================================================
    local powerHeader = GUI:CreateSectionHeader(content, "Power Bars")
    powerHeader:SetPoint("TOPLEFT", PAD, y)
    y = y - powerHeader.gap

    local primaryPowerSlider = GUI:CreateFormSlider(content, "Primary Power Bar", 0, 10, 1, "primaryPowerBar", layeringDB, RefreshPowerBars)
    primaryPowerSlider:SetPoint("TOPLEFT", PAD, y)
    primaryPowerSlider:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - FORM_ROW

    local secondaryPowerSlider = GUI:CreateFormSlider(content, "Secondary Power Bar", 0, 10, 1, "secondaryPowerBar", layeringDB, RefreshPowerBars)
    secondaryPowerSlider:SetPoint("TOPLEFT", PAD, y)
    secondaryPowerSlider:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - FORM_ROW

    y = y - 10  -- Section spacing

    -- =====================================================
    -- UNIT FRAMES SECTION
    -- =====================================================
    local ufHeader = GUI:CreateSectionHeader(content, "Unit Frames")
    ufHeader:SetPoint("TOPLEFT", PAD, y)
    y = y - ufHeader.gap

    local playerFrameSlider = GUI:CreateFormSlider(content, "Player Frame", 0, 10, 1, "playerFrame", layeringDB, RefreshUnitFrames)
    playerFrameSlider:SetPoint("TOPLEFT", PAD, y)
    playerFrameSlider:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - FORM_ROW

    local playerIndicatorsSlider = GUI:CreateFormSlider(content, "Player Status Indicators", 0, 10, 1, "playerIndicators", layeringDB, RefreshUnitFrames)
    playerIndicatorsSlider:SetPoint("TOPLEFT", PAD, y)
    playerIndicatorsSlider:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - FORM_ROW

    local targetFrameSlider = GUI:CreateFormSlider(content, "Target Frame", 0, 10, 1, "targetFrame", layeringDB, RefreshUnitFrames)
    targetFrameSlider:SetPoint("TOPLEFT", PAD, y)
    targetFrameSlider:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - FORM_ROW

    local totFrameSlider = GUI:CreateFormSlider(content, "Target of Target", 0, 10, 1, "totFrame", layeringDB, RefreshUnitFrames)
    totFrameSlider:SetPoint("TOPLEFT", PAD, y)
    totFrameSlider:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - FORM_ROW

    local petFrameSlider = GUI:CreateFormSlider(content, "Pet Frame", 0, 10, 1, "petFrame", layeringDB, RefreshUnitFrames)
    petFrameSlider:SetPoint("TOPLEFT", PAD, y)
    petFrameSlider:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - FORM_ROW

    local focusFrameSlider = GUI:CreateFormSlider(content, "Focus Frame", 0, 10, 1, "focusFrame", layeringDB, RefreshUnitFrames)
    focusFrameSlider:SetPoint("TOPLEFT", PAD, y)
    focusFrameSlider:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - FORM_ROW

    local bossFramesSlider = GUI:CreateFormSlider(content, "Boss Frames", 0, 10, 1, "bossFrames", layeringDB, RefreshUnitFrames)
    bossFramesSlider:SetPoint("TOPLEFT", PAD, y)
    bossFramesSlider:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - FORM_ROW

    y = y - 10  -- Section spacing

    -- =====================================================
    -- CASTBARS SECTION
    -- =====================================================
    local castbarHeader = GUI:CreateSectionHeader(content, "Castbars")
    castbarHeader:SetPoint("TOPLEFT", PAD, y)
    y = y - castbarHeader.gap

    local playerCastbarSlider = GUI:CreateFormSlider(content, "Player Castbar", 0, 10, 1, "playerCastbar", layeringDB, RefreshCastbars)
    playerCastbarSlider:SetPoint("TOPLEFT", PAD, y)
    playerCastbarSlider:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - FORM_ROW

    local targetCastbarSlider = GUI:CreateFormSlider(content, "Target Castbar", 0, 10, 1, "targetCastbar", layeringDB, RefreshCastbars)
    targetCastbarSlider:SetPoint("TOPLEFT", PAD, y)
    targetCastbarSlider:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - FORM_ROW

    y = y - 10  -- Section spacing

    -- =====================================================
    -- CUSTOM TRACKERS SECTION
    -- =====================================================
    local customHeader = GUI:CreateSectionHeader(content, "Custom Trackers")
    customHeader:SetPoint("TOPLEFT", PAD, y)
    y = y - customHeader.gap

    local customBarsSlider = GUI:CreateFormSlider(content, "Custom Item/Spell Bars", 0, 10, 1, "customBars", layeringDB, RefreshCustomTrackers)
    customBarsSlider:SetPoint("TOPLEFT", PAD, y)
    customBarsSlider:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - FORM_ROW

    y = y - 10  -- Section spacing

    -- =====================================================
    -- SKYRIDING SECTION
    -- =====================================================
    local skyridingHeader = GUI:CreateSectionHeader(content, "Skyriding")
    skyridingHeader:SetPoint("TOPLEFT", PAD, y)
    y = y - skyridingHeader.gap

    local skyridingSlider = GUI:CreateFormSlider(content, "Skyriding HUD", 0, 10, 1, "skyridingHUD", layeringDB, RefreshSkyriding)
    skyridingSlider:SetPoint("TOPLEFT", PAD, y)
    skyridingSlider:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)
    y = y - FORM_ROW

    -- Set content height
    content:SetHeight(math.abs(y) + 20)

    return scroll
end

---------------------------------------------------------------------------
-- INITIALIZE OPTIONS - Main tabs
---------------------------------------------------------------------------
function GUI:InitializeOptions()
    local frame = self:CreateMainFrame()

    -- Row 1: Core UI Elements
    GUI:AddTab(frame, "General & QoL", CreateGeneralQoLPage)
    GUI:AddTab(frame, "Single Frames & Castbars", CreateUnitFramesPage)
    GUI:AddTab(frame, "Minimap & Datatext", CreateMinimapPage)
    GUI:AddTab(frame, "Action Bars", CreateActionBarsPage)
    GUI:AddTab(frame, "Autohide & Skinning", CreateAutohidesPage)

    -- Row 2: Cooldown System (CDM cluster)
    GUI:AddTab(frame, "CDM Setup & Class Bars", CreateCDMSetupPage)
    GUI:AddTab(frame, "CDM GCD & Effects", CreateCDEffectsPage)
    GUI:AddTab(frame, "CDM Keybind & Rotation", CreateCDKeybindsPage)
    GUI:AddTab(frame, "Custom Items/Spells/Buffs", CreateCustomTrackersPage)

    -- Row 3: Utilities + Action Buttons
    GUI:AddTab(frame, "HUD Layering", CreateHUDLayeringPage)
    GUI:AddTab(frame, "Spec Profiles", CreateSpecProfilesPage)
    GUI:AddTab(frame, "LUI Import/Export", CreateImportExportPage)
    GUI:AddTab(frame, "Search", CreateSearchPage)
    GUI._searchTabIndex = #frame.tabs  -- Store Search tab index for ForceLoadAllTabs trigger

    GUI:AddActionButton(frame, "Cooldown Settings", function()
        if CooldownViewerSettings then
            CooldownViewerSettings:SetShown(not CooldownViewerSettings:IsShown())
        else
            print("|cFF56D1FFLuheyUI:|r Cooldown Settings not available. Enable Cooldown Manager in Options > Gameplay Enhancement.")
        end
    end)

    GUI:AddActionButton(frame, "Edit Mode", function()
        if EditModeManagerFrame then
            ShowUIPanel(EditModeManagerFrame)
        end
    end)

    -- Mark that all tabs have been added (for search indexing)
    GUI._allTabsAdded = true

    return frame
end
