---------------------------------------------------------------------------
-- LuheyUI Inspect iLvL Display
-- Item level display for the Blizzard inspect frame
-- Shows per-slot ilvl (colored by rarity) and overall average ilvl
---------------------------------------------------------------------------
local ADDON_NAME, ns = ...
local QUI = ns.QUI or {}
ns.QUI = QUI

---------------------------------------------------------------------------
-- Module State
---------------------------------------------------------------------------
local liteInitialized = false
local slotTexts = {}  -- Stores FontStrings for per-slot ilvl
local overallDisplay = nil  -- FontString for overall ilvl
local currentInspectGUID = nil
local updateRetryCount = 0
local MAX_RETRIES = 5

---------------------------------------------------------------------------
-- Slot Configuration (matches inspect slot names)
-- Excludes shirt/tabard as they are cosmetic items
---------------------------------------------------------------------------
local INSPECT_SLOT_NAMES = {
    "InspectHeadSlot", "InspectNeckSlot", "InspectShoulderSlot",
    "InspectBackSlot", "InspectChestSlot",
    "InspectWristSlot", "InspectHandsSlot",
    "InspectWaistSlot", "InspectLegsSlot", "InspectFeetSlot",
    "InspectFinger0Slot", "InspectFinger1Slot",
    "InspectTrinket0Slot", "InspectTrinket1Slot",
    "InspectMainHandSlot", "InspectSecondaryHandSlot",
}

-- Slot ID mapping from slot name
local SLOT_NAME_TO_ID = {
    InspectHeadSlot = INVSLOT_HEAD,
    InspectNeckSlot = INVSLOT_NECK,
    InspectShoulderSlot = INVSLOT_SHOULDER,
    InspectBackSlot = INVSLOT_BACK,
    InspectChestSlot = INVSLOT_CHEST,
    InspectShirtSlot = INVSLOT_BODY,
    InspectTabardSlot = INVSLOT_TABARD,
    InspectWristSlot = INVSLOT_WRIST,
    InspectHandsSlot = INVSLOT_HAND,
    InspectWaistSlot = INVSLOT_WAIST,
    InspectLegsSlot = INVSLOT_LEGS,
    InspectFeetSlot = INVSLOT_FEET,
    InspectFinger0Slot = INVSLOT_FINGER1,
    InspectFinger1Slot = INVSLOT_FINGER2,
    InspectTrinket0Slot = INVSLOT_TRINKET1,
    InspectTrinket1Slot = INVSLOT_TRINKET2,
    InspectMainHandSlot = INVSLOT_MAINHAND,
    InspectSecondaryHandSlot = INVSLOT_OFFHAND,
}

-- Slots that count toward average ilvl (exclude shirt/tabard)
local COUNTED_SLOTS = {
    [INVSLOT_HEAD] = true,
    [INVSLOT_NECK] = true,
    [INVSLOT_SHOULDER] = true,
    [INVSLOT_BACK] = true,
    [INVSLOT_CHEST] = true,
    [INVSLOT_WRIST] = true,
    [INVSLOT_HAND] = true,
    [INVSLOT_WAIST] = true,
    [INVSLOT_LEGS] = true,
    [INVSLOT_FEET] = true,
    [INVSLOT_FINGER1] = true,
    [INVSLOT_FINGER2] = true,
    [INVSLOT_TRINKET1] = true,
    [INVSLOT_TRINKET2] = true,
    [INVSLOT_MAINHAND] = true,
    [INVSLOT_OFFHAND] = true,
}

---------------------------------------------------------------------------
-- Get settings from database
---------------------------------------------------------------------------
local function GetSettings()
    local LUICore = _G.LuheyUI and _G.LuheyUI.LUICore
    if LUICore and LUICore.db and LUICore.db.profile and LUICore.db.profile.character then
        return LUICore.db.profile.character
    end
    -- Fallback defaults
    return {
        inspectLiteEnabled = true,
        inspectLiteShowOverall = true,
        inspectLiteShowPerSlot = true,
        inspectLiteSlotFontSize = 15,
        inspectLiteFont = "Friz Quadrata TT",
        inspectLiteOutline = "OUTLINE",
        inspectLiteOverallFont = "Friz Quadrata TT",
        inspectLiteOverallOutline = "OUTLINE",
        inspectLiteOverallFontSize = 11,
        inspectLiteOverallOffsetX = 0,
        inspectLiteOverallOffsetY = -8,
    }
end

---------------------------------------------------------------------------
-- Check if inspect iLvL display should be active
---------------------------------------------------------------------------
local function ShouldBeActive()
    local settings = GetSettings()
    return settings.inspectLiteEnabled
end

---------------------------------------------------------------------------
-- Get font path from settings (via LibSharedMedia)
---------------------------------------------------------------------------
local function GetFont()
    local settings = GetSettings()
    local fontName = settings.inspectLiteFont or "Friz Quadrata TT"
    local LSM = LibStub("LibSharedMedia-3.0", true)
    if LSM then
        local fontPath = LSM:Fetch("font", fontName)
        if fontPath then
            return fontPath
        end
    end
    return "Fonts\\FRIZQT__.TTF"
end

---------------------------------------------------------------------------
-- Get font outline from settings
---------------------------------------------------------------------------
local function GetOutline()
    local settings = GetSettings()
    return settings.inspectLiteOutline or "OUTLINE"
end

---------------------------------------------------------------------------
-- Get overall iLvL font path from settings (via LibSharedMedia)
---------------------------------------------------------------------------
local function GetOverallFont()
    local settings = GetSettings()
    local fontName = settings.inspectLiteOverallFont or "Friz Quadrata TT"
    local LSM = LibStub("LibSharedMedia-3.0", true)
    if LSM then
        local fontPath = LSM:Fetch("font", fontName)
        if fontPath then
            return fontPath
        end
    end
    return "Fonts\\FRIZQT__.TTF"
end

---------------------------------------------------------------------------
-- Get overall iLvL font outline from settings
---------------------------------------------------------------------------
local function GetOverallOutline()
    local settings = GetSettings()
    return settings.inspectLiteOverallOutline or "OUTLINE"
end

---------------------------------------------------------------------------
-- Get item level for a slot
-- Uses C_TooltipInfo.GetInventoryItem for reliable ilvl extraction
-- This works correctly for both player and inspected units
---------------------------------------------------------------------------
local function GetSlotItemLevel(unit, slotId)
    if not unit or not slotId then return nil end

    -- Use C_TooltipInfo for reliable ilvl extraction (works for inspect)
    if C_TooltipInfo and C_TooltipInfo.GetInventoryItem then
        local info = C_TooltipInfo.GetInventoryItem(unit, slotId)
        if info and info.lines then
            for _, line in ipairs(info.lines) do
                local text = line.leftText
                if text then
                    -- Strip color codes and textures
                    text = text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
                    text = text:gsub("|T.-|t", "")  -- Strip texture escapes
                    -- Match "Item Level X" pattern using the localized ITEM_LEVEL global
                    local pattern = ITEM_LEVEL:gsub("%%d", "(%%d+)")
                    local ilvl = text:match(pattern)
                    if ilvl then
                        return tonumber(ilvl)
                    end
                end
            end
        end
    end

    return nil
end

---------------------------------------------------------------------------
-- Check if mainhand is a 2H weapon
---------------------------------------------------------------------------
local function IsMainHand2H(unit)
    local itemLink = GetInventoryItemLink(unit, INVSLOT_MAINHAND)
    if not itemLink then return false end

    local _, _, _, _, _, _, _, _, equipSlot = C_Item.GetItemInfo(itemLink)
    return equipSlot == "INVTYPE_2HWEAPON"
end

---------------------------------------------------------------------------
-- Validate that the unit is inspectable and data is ready
---------------------------------------------------------------------------
local function IsInspectDataReady(unit)
    if not unit then return false end
    if not UnitExists(unit) then return false end
    if not CanInspect(unit) then return false end
    -- Check if we have any item data at all
    local hasAnyItem = false
    for slotId = 1, 17 do
        if GetInventoryItemLink(unit, slotId) then
            hasAnyItem = true
            break
        end
    end
    return hasAnyItem
end

---------------------------------------------------------------------------
-- Get item quality for a slot
---------------------------------------------------------------------------
local function GetSlotItemQuality(unit, slotId)
    local itemLink = GetInventoryItemLink(unit, slotId)
    if not itemLink then return nil end

    local ok, quality = pcall(C_Item.GetItemQualityByID, itemLink)
    if ok and quality then
        return quality
    end
    return nil
end

---------------------------------------------------------------------------
-- Calculate average equipped item quality for overall iLvL coloring
-- Returns rounded average quality (1-7) based on equipped gear
---------------------------------------------------------------------------
local function CalculateAverageEquippedQuality(unit)
    local totalQuality = 0
    local itemCount = 0
    local is2H = IsMainHand2H(unit)

    for slotId, counted in pairs(COUNTED_SLOTS) do
        if counted then
            if slotId == INVSLOT_OFFHAND and is2H then
                -- 2H weapon counts twice - add mainhand quality again
                local mainQuality = GetSlotItemQuality(unit, INVSLOT_MAINHAND)
                if mainQuality and mainQuality >= 1 then
                    totalQuality = totalQuality + mainQuality
                    itemCount = itemCount + 1
                end
            else
                local quality = GetSlotItemQuality(unit, slotId)
                if quality and quality >= 1 then
                    totalQuality = totalQuality + quality
                    itemCount = itemCount + 1
                end
            end
        end
    end

    if itemCount > 0 then
        return math.floor((totalQuality / itemCount) + 0.5)  -- Round to nearest integer
    end
    return 1  -- Default to Common (white)
end

---------------------------------------------------------------------------
-- Create per-slot ilvl FontString
---------------------------------------------------------------------------
local function CreateSlotILvlText(slotFrame)
    if not slotFrame then return nil end

    local settings = GetSettings()
    local fontSize = settings.inspectLiteSlotFontSize or 11
    local font = GetFont()
    local outline = GetOutline()

    local text = slotFrame:CreateFontString(nil, "OVERLAY")
    text:SetFont(font, fontSize, outline)
    text:SetPoint("CENTER", slotFrame, "CENTER", 0, 0)
    text:SetJustifyH("CENTER")
    text:SetJustifyV("MIDDLE")
    text:Hide()

    return text
end

---------------------------------------------------------------------------
-- Update per-slot ilvl text
---------------------------------------------------------------------------
local function UpdateSlotILvlText(slotName, unit)
    local settings = GetSettings()
    if not settings.inspectLiteShowPerSlot then
        if slotTexts[slotName] then
            slotTexts[slotName]:Hide()
        end
        return
    end

    local slotFrame = _G[slotName]
    if not slotFrame then return end

    -- Create text if not exists
    if not slotTexts[slotName] then
        slotTexts[slotName] = CreateSlotILvlText(slotFrame)
    end

    local text = slotTexts[slotName]
    if not text then return end

    -- Update font settings in case they changed
    local fontSize = settings.inspectLiteSlotFontSize or 11
    text:SetFont(GetFont(), fontSize, GetOutline())

    local slotId = SLOT_NAME_TO_ID[slotName]
    if not slotId then
        text:Hide()
        return
    end

    local itemLevel = GetSlotItemLevel(unit, slotId)
    local quality = GetSlotItemQuality(unit, slotId)

    if itemLevel and itemLevel > 0 then
        text:SetText(tostring(math.floor(itemLevel)))

        -- Color by item rarity
        if quality and quality >= 1 then
            local r, g, b = C_Item.GetItemQualityColor(quality)
            text:SetTextColor(r, g, b, 1)
        else
            text:SetTextColor(1, 1, 1, 1)  -- White fallback
        end

        text:Show()
    else
        text:Hide()
    end
end

---------------------------------------------------------------------------
-- Calculate average item level for unit
-- WoW calculates average ilvl over 16 slots (2H weapons count twice)
---------------------------------------------------------------------------
local function CalculateAverageILvl(unit)
    local totalIlvl = 0
    local slotCount = 0
    local is2H = IsMainHand2H(unit)

    for slotId, counted in pairs(COUNTED_SLOTS) do
        if counted then
            -- Skip offhand slot if wielding a 2H weapon
            if slotId == INVSLOT_OFFHAND and is2H then
                -- 2H weapon counts twice - add mainhand ilvl again
                local mainIlvl = GetSlotItemLevel(unit, INVSLOT_MAINHAND)
                if mainIlvl and mainIlvl > 0 then
                    totalIlvl = totalIlvl + mainIlvl
                    slotCount = slotCount + 1
                end
            else
                local ilvl = GetSlotItemLevel(unit, slotId)
                if ilvl and ilvl > 0 then
                    totalIlvl = totalIlvl + ilvl
                    slotCount = slotCount + 1
                end
            end
        end
    end

    if slotCount > 0 then
        return totalIlvl / slotCount
    end
    return 0
end

---------------------------------------------------------------------------
-- Get overall iLvL color based on average equipped item quality
-- Uses WoW's standard quality colors (Poor=gray, Common=white, Uncommon=green,
-- Rare=blue, Epic=purple, Legendary=orange)
---------------------------------------------------------------------------
local function GetOverallILvlColor(unit)
    local avgQuality = CalculateAverageEquippedQuality(unit)
    -- Clamp to valid quality range (1-7)
    avgQuality = math.max(1, math.min(avgQuality, 7))
    local r, g, b = C_Item.GetItemQualityColor(avgQuality)
    return r, g, b
end

---------------------------------------------------------------------------
-- Create overall ilvl display
-- Positioned below the wrist slot on the left side
---------------------------------------------------------------------------
local function CreateOverallILvlDisplay()
    if not InspectFrame then return nil end

    local settings = GetSettings()
    local font = GetOverallFont()
    local outline = GetOverallOutline()
    local fontSize = settings.inspectLiteOverallFontSize or 11
    local offsetX = settings.inspectLiteOverallOffsetX or 0
    local offsetY = settings.inspectLiteOverallOffsetY or -8

    -- If display already exists, update it instead of recreating
    if overallDisplay then
        overallDisplay:ClearAllPoints()
        local wristSlot = _G["InspectWristSlot"]
        if wristSlot then
            overallDisplay:SetPoint("TOP", wristSlot, "BOTTOM", offsetX, offsetY)
        else
            overallDisplay:SetPoint("TOPLEFT", InspectFrame, "TOPLEFT", 16 + offsetX, -280 + offsetY)
        end
        if overallDisplay.label then
            overallDisplay.label:SetFont(font, fontSize, outline)
        end
        if overallDisplay.value then
            overallDisplay.value:SetFont(font, fontSize, outline)
        end
        return overallDisplay
    end

    local frame = CreateFrame("Frame", nil, InspectFrame)
    frame:SetSize(80, 20)
    -- Position below the wrist slot (bracers) on the left side
    local wristSlot = _G["InspectWristSlot"]
    if wristSlot then
        frame:SetPoint("TOP", wristSlot, "BOTTOM", offsetX, offsetY)
    else
        -- Fallback position if slot not found
        frame:SetPoint("TOPLEFT", InspectFrame, "TOPLEFT", 16 + offsetX, -280 + offsetY)
    end
    frame:SetFrameLevel(InspectFrame:GetFrameLevel() + 10)

    local label = frame:CreateFontString(nil, "OVERLAY")
    label:SetFont(font, fontSize, outline)
    label:SetPoint("RIGHT", frame, "CENTER", -2, 0)
    label:SetText("iLvL:")
    label:SetTextColor(0.7, 0.7, 0.7, 1)

    local value = frame:CreateFontString(nil, "OVERLAY")
    value:SetFont(font, fontSize, outline)
    value:SetPoint("LEFT", frame, "CENTER", 0, 0)
    value:SetJustifyH("LEFT")

    frame.label = label
    frame.value = value
    frame:Hide()

    overallDisplay = frame
    return frame
end

---------------------------------------------------------------------------
-- Update overall ilvl display
---------------------------------------------------------------------------
local function UpdateOverallILvlDisplay(unit)
    local settings = GetSettings()

    if not settings.inspectLiteShowOverall then
        if overallDisplay then
            overallDisplay:Hide()
        end
        return
    end

    CreateOverallILvlDisplay()

    if not overallDisplay or not overallDisplay.value then return end

    local avgIlvl = CalculateAverageILvl(unit)

    if avgIlvl > 0 then
        local r, g, b = GetOverallILvlColor(unit)
        overallDisplay.value:SetText(string.format("%.1f", avgIlvl))
        overallDisplay.value:SetTextColor(r, g, b, 1)
        overallDisplay:Show()
    else
        overallDisplay:Hide()
    end
end

---------------------------------------------------------------------------
-- Update all lite displays
---------------------------------------------------------------------------
local function UpdateAllLiteDisplays(unit)
    if not ShouldBeActive() then
        -- Hide everything if not active
        for _, text in pairs(slotTexts) do
            if text then text:Hide() end
        end
        if overallDisplay then overallDisplay:Hide() end
        return
    end

    unit = unit or InspectFrame.unit or "target"

    -- Verify inspect data is ready
    if not IsInspectDataReady(unit) then
        -- Retry after a short delay if data isn't ready yet
        if updateRetryCount < MAX_RETRIES then
            updateRetryCount = updateRetryCount + 1
            C_Timer.After(0.2, function()
                if InspectFrame and InspectFrame:IsShown() then
                    UpdateAllLiteDisplays(unit)
                end
            end)
        end
        return
    end

    -- Reset retry counter on successful update
    updateRetryCount = 0

    -- Update per-slot ilvl texts
    for _, slotName in ipairs(INSPECT_SLOT_NAMES) do
        UpdateSlotILvlText(slotName, unit)
    end

    -- Update overall ilvl display
    UpdateOverallILvlDisplay(unit)
end

---------------------------------------------------------------------------
-- Show/hide all lite displays
---------------------------------------------------------------------------
local function ShowLiteDisplays()
    if not ShouldBeActive() then return end

    for _, text in pairs(slotTexts) do
        if text then text:Show() end
    end
    if overallDisplay then overallDisplay:Show() end
end

local function HideLiteDisplays()
    for _, text in pairs(slotTexts) do
        if text then text:Hide() end
    end
    if overallDisplay then overallDisplay:Hide() end
end

---------------------------------------------------------------------------
-- Initialize slot FontStrings
---------------------------------------------------------------------------
local function InitializeLiteDisplays()
    if liteInitialized then return end
    if not InspectFrame then return end

    -- Create overall ilvl display
    CreateOverallILvlDisplay()

    -- Create per-slot texts (will be created on demand during update)
    liteInitialized = true
end

---------------------------------------------------------------------------
-- Hook inspect frame
---------------------------------------------------------------------------
local function HookInspectFrame()
    if not InspectFrame then return end

    InspectFrame:HookScript("OnShow", function()
        -- Reset retry counter when frame opens
        updateRetryCount = 0

        if ShouldBeActive() then
            InitializeLiteDisplays()
            -- Delay to allow inspect data to load
            C_Timer.After(0.5, function()
                if InspectFrame and InspectFrame:IsShown() then
                    local unit = InspectFrame.unit or "target"
                    UpdateAllLiteDisplays(unit)
                end
            end)
        else
            HideLiteDisplays()
        end
    end)

    InspectFrame:HookScript("OnHide", function()
        HideLiteDisplays()
    end)
end

---------------------------------------------------------------------------
-- Event frame
---------------------------------------------------------------------------
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("INSPECT_READY")

eventFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 == "Blizzard_InspectUI" then
            C_Timer.After(0.1, function()
                HookInspectFrame()
            end)
        end
    elseif event == "INSPECT_READY" then
        currentInspectGUID = arg1
        if ShouldBeActive() and InspectFrame and InspectFrame:IsShown() then
            local unit = InspectFrame.unit or "target"
            -- Verify GUID matches to avoid stale updates
            if UnitGUID(unit) == currentInspectGUID then
                C_Timer.After(0.1, function()
                    UpdateAllLiteDisplays(unit)
                end)
            end
        end
    end
end)

---------------------------------------------------------------------------
-- Refresh function (called from options when settings change)
---------------------------------------------------------------------------
local function RefreshLiteDisplays()
    if InspectFrame and InspectFrame:IsShown() then
        local unit = InspectFrame.unit or "target"
        UpdateAllLiteDisplays(unit)
    end
end

-- Export refresh function globally for options panel
_G.LuheyUI_RefreshInspectLite = RefreshLiteDisplays

---------------------------------------------------------------------------
-- Module API
---------------------------------------------------------------------------
QUI.InspectLite = {
    UpdateAllLiteDisplays = UpdateAllLiteDisplays,
    RefreshLiteDisplays = RefreshLiteDisplays,
    ShouldBeActive = ShouldBeActive,
}

ns.InspectLite = QUI.InspectLite
