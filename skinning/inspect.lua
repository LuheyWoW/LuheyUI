local addonName, ns = ...
local LUICore = ns.Addon

---------------------------------------------------------------------------
-- INSPECT FRAME SKINNING
-- Skins InspectFrame to match CharacterFrame appearance
---------------------------------------------------------------------------

-- Module reference
local InspectSkinning = {}
LUICore.InspectSkinning = InspectSkinning

-- Configuration constants
local CONFIG = {
    PANEL_WIDTH_EXTENSION = 0,    -- No stats panel, no width extension needed
    PANEL_HEIGHT_EXTENSION = 50,  -- Height extension for tabs area at bottom
}

-- Module state
local customBg = nil

---------------------------------------------------------------------------
-- Helper: Get skin colors from QUI system
---------------------------------------------------------------------------
local function GetSkinColors()
    local QUI = _G.LuheyUI
    local sr, sg, sb, sa = 0.2, 1.0, 0.6, 1      -- Fallback mint
    local bgr, bgg, bgb, bga = 0.05, 0.05, 0.05, 0.95  -- Fallback dark

    if QUI and QUI.GetSkinColor then
        sr, sg, sb, sa = QUI:GetSkinColor()
    end
    if QUI and QUI.GetSkinBgColor then
        bgr, bgg, bgb, bga = QUI:GetSkinBgColor()
    end

    return sr, sg, sb, sa, bgr, bgg, bgb, bga
end

---------------------------------------------------------------------------
-- Helper: Check if skinning is enabled
-- Uses general.skinInspectFrame for visual skinning (background, borders)
---------------------------------------------------------------------------
local function IsSkinningEnabled()
    local coreRef = _G.LuheyUI and _G.LuheyUI.LUICore
    local settings = coreRef and coreRef.db and coreRef.db.profile and coreRef.db.profile.general
    -- Default to true if not explicitly set
    if settings and settings.skinInspectFrame == nil then
        return true
    end
    return settings and settings.skinInspectFrame
end

---------------------------------------------------------------------------
-- Create/update the custom background frame
---------------------------------------------------------------------------
local function CreateOrUpdateBackground()
    if not InspectFrame then return end

    local sr, sg, sb, sa, bgr, bgg, bgb, bga = GetSkinColors()

    if not customBg then
        customBg = CreateFrame("Frame", "LUI_InspectFrameBg_Skin", InspectFrame, "BackdropTemplate")
        customBg:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
            insets = { left = 1, right = 1, top = 1, bottom = 1 }
        })
        customBg:SetFrameStrata("BACKGROUND")
        customBg:SetFrameLevel(0)
        customBg:EnableMouse(false)  -- Don't steal clicks
    end

    customBg:SetBackdropColor(bgr, bgg, bgb, bga)
    customBg:SetBackdropBorderColor(sr, sg, sb, sa)

    return customBg
end

---------------------------------------------------------------------------
-- Hide Blizzard decorative elements on InspectFrame
---------------------------------------------------------------------------
local function HideBlizzardDecorations()
    if not InspectFrame then return end

    -- Hide portrait and portrait container (ButtonFrameTemplate)
    if InspectFramePortrait then InspectFramePortrait:Hide() end
    if InspectFrame.PortraitContainer then InspectFrame.PortraitContainer:Hide() end
    if InspectFrame.portrait then InspectFrame.portrait:Hide() end

    -- Hide NineSlice border (ButtonFrameTemplate)
    if InspectFrame.NineSlice then InspectFrame.NineSlice:Hide() end

    -- Hide background elements
    if InspectFrame.Bg then InspectFrame.Bg:Hide() end
    if InspectFrame.Background then InspectFrame.Background:Hide() end
    if InspectFrameBg then InspectFrameBg:Hide() end

    -- Hide title bar decorations (ButtonFrameTemplate)
    if InspectFrame.TitleContainer then
        -- Keep title text, hide decorations
        if InspectFrame.TitleContainer.TitleBg then
            InspectFrame.TitleContainer.TitleBg:Hide()
        end
    end
    if InspectFrame.TopTileStreaks then InspectFrame.TopTileStreaks:Hide() end

    -- Hide inset background
    if InspectFrame.Inset then
        if InspectFrame.Inset.Bg then InspectFrame.Inset.Bg:Hide() end
        if InspectFrame.Inset.NineSlice then InspectFrame.Inset.NineSlice:Hide() end
    end

    -- Hide model frame borders
    if InspectModelFrameBorderTopLeft then InspectModelFrameBorderTopLeft:Hide() end
    if InspectModelFrameBorderTopRight then InspectModelFrameBorderTopRight:Hide() end
    if InspectModelFrameBorderTop then InspectModelFrameBorderTop:Hide() end
    if InspectModelFrameBorderLeft then InspectModelFrameBorderLeft:Hide() end
    if InspectModelFrameBorderRight then InspectModelFrameBorderRight:Hide() end
    if InspectModelFrameBorderBottomLeft then InspectModelFrameBorderBottomLeft:Hide() end
    if InspectModelFrameBorderBottomRight then InspectModelFrameBorderBottomRight:Hide() end
    if InspectModelFrameBorderBottom then InspectModelFrameBorderBottom:Hide() end
    if InspectModelFrameBorderBottom2 then InspectModelFrameBorderBottom2:Hide() end

    -- Hide model frame background textures
    if InspectModelFrame then
        if InspectModelFrame.BackgroundOverlay then
            InspectModelFrame.BackgroundOverlay:SetAlpha(0)
        end
    end
    for _, corner in pairs({ "TopLeft", "TopRight", "BotLeft", "BotRight" }) do
        local bg = _G["InspectModelFrameBackground" .. corner]
        if bg then bg:Hide() end
    end
end

---------------------------------------------------------------------------
-- API: Set background extended mode (for stats panel)
---------------------------------------------------------------------------
local function SetInspectFrameBgExtended(extended)
    if not customBg then
        CreateOrUpdateBackground()
    end
    if not customBg then return end

    customBg:ClearAllPoints()

    if extended then
        customBg:SetPoint("TOPLEFT", InspectFrame, "TOPLEFT", 0, 0)
        customBg:SetPoint("BOTTOMRIGHT", InspectFrame, "BOTTOMRIGHT",
            CONFIG.PANEL_WIDTH_EXTENSION, -CONFIG.PANEL_HEIGHT_EXTENSION)
    else
        customBg:SetAllPoints(InspectFrame)
    end

    customBg:Show()
    HideBlizzardDecorations()
end

---------------------------------------------------------------------------
-- Main skinning setup
---------------------------------------------------------------------------
local function SetupInspectFrameSkinning()
    if not IsSkinningEnabled() then return end
    if not InspectFrame then return end

    -- Create initial background
    CreateOrUpdateBackground()

    -- Initial setup if already shown (rare edge case)
    if InspectFrame:IsShown() then
        SetInspectFrameBgExtended(false)
    end
end

---------------------------------------------------------------------------
-- Refresh colors on already-skinned elements (for live preview)
---------------------------------------------------------------------------
local function RefreshInspectFrameColors()
    if not IsSkinningEnabled() then return end

    local sr, sg, sb, sa, bgr, bgg, bgb, bga = GetSkinColors()

    -- Update main background
    if customBg then
        customBg:SetBackdropColor(bgr, bgg, bgb, bga)
        customBg:SetBackdropBorderColor(sr, sg, sb, sa)
    end
end

---------------------------------------------------------------------------
-- CONSOLIDATED API TABLE
---------------------------------------------------------------------------
_G.LUI_InspectFrameSkinning = {
    -- Configuration
    CONFIG = CONFIG,

    -- Core functions
    IsEnabled = IsSkinningEnabled,
    SetExtended = SetInspectFrameBgExtended,
    Refresh = RefreshInspectFrameColors,
}

-- Legacy compatibility alias
_G.LuheyUI_RefreshInspectColors = RefreshInspectFrameColors

---------------------------------------------------------------------------
-- INITIALIZATION
---------------------------------------------------------------------------
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, addon)
    if addon == "Blizzard_InspectUI" then
        C_Timer.After(0.1, function()
            SetupInspectFrameSkinning()
        end)
        self:UnregisterEvent("ADDON_LOADED")
    end
end)
