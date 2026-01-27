local addonName, ns = ...
local LUICore = ns.Addon

---------------------------------------------------------------------------
-- BAG FRAME SKINNING
-- Skins ContainerFrames and BankFrame to match LuheyUI dark theme
---------------------------------------------------------------------------

-- Module reference
local BagSkinning = {}
LUICore.BagSkinning = BagSkinning

-- Configuration constants
local CONFIG = {
    MAX_CONTAINER_FRAMES = 13,
    BANK_ADDON = "Blizzard_BankUI",
    BAGANATOR_ADDON = "Baganator",
}

-- Module state - track skinned frames by name
local skinnedFrames = {}

-- Track whether Baganator is handling bags
local baganatorActive = false

---------------------------------------------------------------------------
-- Helper: Get skin colors from LuheyUI system
---------------------------------------------------------------------------
local function GetSkinColors()
    local LUI = _G.LuheyUI
    local sr, sg, sb, sa = 0.2, 1.0, 0.6, 1      -- Fallback mint
    local bgr, bgg, bgb, bga = 0.05, 0.05, 0.05, 0.95  -- Fallback dark

    if LUI and LUI.GetSkinColor then
        sr, sg, sb, sa = LUI:GetSkinColor()
    end
    if LUI and LUI.GetSkinBgColor then
        bgr, bgg, bgb, bga = LUI:GetSkinBgColor()
    end

    return sr, sg, sb, sa, bgr, bgg, bgb, bga
end

---------------------------------------------------------------------------
-- Helper: Check if skinning is enabled
---------------------------------------------------------------------------
local function IsSkinningEnabled()
    local coreRef = _G.LuheyUI and _G.LuheyUI.LUICore
    local settings = coreRef and coreRef.db and coreRef.db.profile and coreRef.db.profile.general
    -- Default to true if not explicitly set
    if settings and settings.skinBagFrames == nil then
        return true
    end
    return settings and settings.skinBagFrames
end

---------------------------------------------------------------------------
-- Helper: Check if Baganator is loaded and has Skins API
---------------------------------------------------------------------------
local function IsBaganatorLoaded()
    return Baganator and Baganator.API and Baganator.API.Skins
end

---------------------------------------------------------------------------
-- Hide Blizzard decorative elements on a container frame
---------------------------------------------------------------------------
local function HideContainerDecorations(frame)
    if not frame then return end

    -- Hide NineSlice border (modern frames)
    if frame.NineSlice then frame.NineSlice:Hide() end

    -- Hide background elements
    if frame.Bg then frame.Bg:Hide() end
    if frame.Background then frame.Background:Hide() end

    -- Hide portrait container (if exists)
    if frame.PortraitContainer then frame.PortraitContainer:Hide() end

    -- Hide title bar decorations
    if frame.TitleContainer then
        if frame.TitleContainer.TitleBg then
            frame.TitleContainer.TitleBg:Hide()
        end
    end
    if frame.TopTileStreaks then frame.TopTileStreaks:Hide() end

    -- Hide inset backgrounds
    if frame.Inset then
        if frame.Inset.Bg then frame.Inset.Bg:Hide() end
        if frame.Inset.NineSlice then frame.Inset.NineSlice:Hide() end
    end

    -- Hide money frame background if present
    if frame.MoneyFrame then
        if frame.MoneyFrame.Border then frame.MoneyFrame.Border:Hide() end
        if frame.MoneyFrame.Background then frame.MoneyFrame.Background:Hide() end
    end
end

---------------------------------------------------------------------------
-- Create/update custom background for a container frame
-- Optional padding parameter adds space around the border
---------------------------------------------------------------------------
local function CreateOrUpdateContainerBackground(frame, padding)
    if not frame then return nil end

    local frameName = frame:GetName()
    local sr, sg, sb, sa, bgr, bgg, bgb, bga = GetSkinColors()
    padding = padding or 0

    local customBg = skinnedFrames[frameName]

    if not customBg then
        customBg = CreateFrame("Frame", "LUI_" .. (frameName or "Container") .. "Bg_Skin", frame, "BackdropTemplate")
        customBg:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
            insets = { left = 1, right = 1, top = 1, bottom = 1 }
        })
        customBg:SetFrameStrata("BACKGROUND")
        customBg:SetFrameLevel(0)
        customBg:EnableMouse(false)  -- Don't steal clicks

        if padding > 0 then
            customBg:SetPoint("TOPLEFT", frame, "TOPLEFT", -padding, padding)
            customBg:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", padding, -padding)
        else
            customBg:SetAllPoints(frame)
        end

        skinnedFrames[frameName] = customBg
    end

    customBg:SetBackdropColor(bgr, bgg, bgb, bga)
    customBg:SetBackdropBorderColor(sr, sg, sb, sa)

    return customBg
end

---------------------------------------------------------------------------
-- Skin a single container frame
---------------------------------------------------------------------------
-- Padding for bag frames (pixels around the border)
local BAG_PADDING = 5

local function SkinContainerFrame(frame)
    if not IsSkinningEnabled() then return end
    if not frame then return end

    local frameName = frame:GetName()
    if not frameName then return end

    -- Create/update background with padding
    local customBg = CreateOrUpdateContainerBackground(frame, BAG_PADDING)
    if customBg then
        customBg:Show()
    end

    -- Hide Blizzard decorations
    HideContainerDecorations(frame)
end

---------------------------------------------------------------------------
-- BAGANATOR INTEGRATION
---------------------------------------------------------------------------

-- Skin a Baganator frame via its Skins API
local function SkinBaganatorFrame(details)
    if not IsSkinningEnabled() then return end

    -- Only skin main window frames (ButtonFrame type)
    if details.regionType ~= "ButtonFrame" then return end

    local frame = details.region
    if not frame then return end

    -- Generate a unique name for tracking
    local frameName = frame:GetName() or ("BaganatorFrame_" .. tostring(frame))

    -- Create/update background with padding
    local customBg = CreateOrUpdateContainerBackground(frame, BAG_PADDING)
    if customBg then
        customBg:Show()
    end

    -- Hide Baganator's default decorations
    HideContainerDecorations(frame)
end

-- Set up Baganator skinning via its API
local function SetupBaganatorSkinning()
    if not IsBaganatorLoaded() then
        return false
    end

    -- Register listener for new frames as they're created
    Baganator.API.Skins.RegisterListener(SkinBaganatorFrame)

    -- Skin any existing frames (retroactive skinning)
    local existingFrames = Baganator.API.Skins.GetAllFrames()
    if existingFrames then
        for _, details in pairs(existingFrames) do
            SkinBaganatorFrame(details)
        end
    end

    baganatorActive = true
    return true
end

---------------------------------------------------------------------------
-- Skin all container frames (bags)
---------------------------------------------------------------------------
local function SkinAllContainerFrames()
    if not IsSkinningEnabled() then return end
    -- Skip if Baganator is handling bags
    if baganatorActive then return end

    -- Skin individual bag frames (ContainerFrame1 through ContainerFrame13)
    for i = 1, CONFIG.MAX_CONTAINER_FRAMES do
        local frame = _G["ContainerFrame" .. i]
        if frame then
            SkinContainerFrame(frame)
        end
    end

    -- Skin combined bags view if it exists
    if ContainerFrameCombinedBags then
        SkinContainerFrame(ContainerFrameCombinedBags)
    end
end

---------------------------------------------------------------------------
-- Skin the bank frame
---------------------------------------------------------------------------
local function SkinBankFrame()
    if not IsSkinningEnabled() then return end

    -- Main bank frame
    if BankFrame then
        SkinContainerFrame(BankFrame)

        -- Also skin bank panels/tabs if they have separate backgrounds
        if BankFrame.activeTabIndex then
            -- Modern bank with tabs
            for i = 1, 3 do  -- Bank typically has up to 3 tab panels
                local tabPanel = BankFrame["Tab" .. i]
                if tabPanel then
                    HideContainerDecorations(tabPanel)
                end
            end
        end
    end

    -- Account bank frame (if exists in Midnight)
    if AccountBankPanel then
        SkinContainerFrame(AccountBankPanel)
    end

    -- Reagent bank (if separate frame)
    if ReagentBankFrame then
        SkinContainerFrame(ReagentBankFrame)
    end
end

---------------------------------------------------------------------------
-- Refresh colors on all skinned frames (for live preview)
---------------------------------------------------------------------------
local function RefreshBagColors()
    if not IsSkinningEnabled() then return end

    local sr, sg, sb, sa, bgr, bgg, bgb, bga = GetSkinColors()

    for frameName, customBg in pairs(skinnedFrames) do
        if customBg and customBg.SetBackdropColor then
            customBg:SetBackdropColor(bgr, bgg, bgb, bga)
            customBg:SetBackdropBorderColor(sr, sg, sb, sa)
        end
    end
end

---------------------------------------------------------------------------
-- Hook container frame show events
---------------------------------------------------------------------------
local function SetupContainerHooks()
    -- Skip if Baganator is handling bags
    if baganatorActive then return end

    -- Hook individual bag frames
    for i = 1, CONFIG.MAX_CONTAINER_FRAMES do
        local frame = _G["ContainerFrame" .. i]
        if frame then
            frame:HookScript("OnShow", function(self)
                -- Don't skin if Baganator became active after hooks were set
                if baganatorActive then return end
                SkinContainerFrame(self)
            end)
        end
    end

    -- Hook combined bags view
    if ContainerFrameCombinedBags then
        ContainerFrameCombinedBags:HookScript("OnShow", function(self)
            if baganatorActive then return end
            SkinContainerFrame(self)
        end)
    end
end

---------------------------------------------------------------------------
-- CONSOLIDATED API TABLE
---------------------------------------------------------------------------
_G.LUI_BagFrameSkinning = {
    CONFIG = CONFIG,
    IsEnabled = IsSkinningEnabled,
    IsBaganatorActive = function() return baganatorActive end,
    Refresh = RefreshBagColors,
    SkinAll = SkinAllContainerFrames,
}

-- Global refresh function for options panel
_G.LuheyUI_RefreshBagColors = RefreshBagColors

---------------------------------------------------------------------------
-- INITIALIZATION
---------------------------------------------------------------------------
local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, addon)
    if event == "PLAYER_ENTERING_WORLD" then
        -- Check if Baganator is already loaded
        if IsBaganatorLoaded() then
            C_Timer.After(0.1, function()
                SetupBaganatorSkinning()
            end)
        else
            -- Set up hooks for default container frames
            C_Timer.After(0.1, function()
                SetupContainerHooks()
                -- Skin any already-open bags
                SkinAllContainerFrames()
            end)
        end
    elseif event == "ADDON_LOADED" then
        if addon == CONFIG.BAGANATOR_ADDON then
            -- Baganator just loaded, set up its skinning
            C_Timer.After(0.1, function()
                SetupBaganatorSkinning()
            end)
        elseif addon == CONFIG.BANK_ADDON then
            -- Skip bank skinning if Baganator is handling it
            if baganatorActive then return end

            C_Timer.After(0.1, function()
                SkinBankFrame()

                -- Hook bank frame show event
                if BankFrame then
                    BankFrame:HookScript("OnShow", function()
                        if baganatorActive then return end
                        SkinBankFrame()
                    end)
                end
            end)
        end
    end
end)
