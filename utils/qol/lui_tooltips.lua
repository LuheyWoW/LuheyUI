---------------------------------------------------------------------------
-- LuheyUI Tooltip Module
-- Cursor-following tooltips with per-context visibility controls
---------------------------------------------------------------------------
local ADDON_NAME, ns = ...
local QUI = ns.QUI or {}
ns.QUI = QUI

-- Locals for performance
local GameTooltip = GameTooltip
local UIParent = UIParent
local IsShiftKeyDown = IsShiftKeyDown
local IsControlKeyDown = IsControlKeyDown
local IsAltKeyDown = IsAltKeyDown
local InCombatLockdown = InCombatLockdown
local strfind = string.find
local strmatch = string.match
local GetMouseFoci = GetMouseFoci
local WorldFrame = WorldFrame

---------------------------------------------------------------------------
-- Mouse Focus Detection
-- Gets topmost frame under mouse cursor (API compatibility wrapper)
-- PERFORMANCE: Cached to prevent repeated GetMouseFoci() calls with @mouseover macros
---------------------------------------------------------------------------
local cachedMouseFrame = nil
local cachedMouseFrameTime = 0
local MOUSE_FRAME_CACHE_TTL = 0.2  -- 200ms cache (was 100ms)

local function GetTopMouseFrame()
    local now = GetTime()
    -- Return cached result if still valid
    if cachedMouseFrame ~= nil and (now - cachedMouseFrameTime) < MOUSE_FRAME_CACHE_TTL then
        return cachedMouseFrame
    end

    -- Expensive API call - cache the result
    if GetMouseFoci then
        local frames = GetMouseFoci()
        cachedMouseFrame = frames and frames[1]
    else
        cachedMouseFrame = GetMouseFocus and GetMouseFocus()
    end
    cachedMouseFrameTime = now
    return cachedMouseFrame
end

-- Check if a UI frame is blocking mouse from the 3D world
local function IsFrameBlockingMouse()
    local focus = GetTopMouseFrame()
    if not focus then return false end

    -- WorldFrame means mouse is over the 3D world, not a UI panel
    if focus == WorldFrame then return false end

    -- If there's any other visible frame under the mouse, it's blocking
    return focus:IsVisible()
end

-- State
local cachedSettings = nil
local originalSetDefaultAnchor = nil

-- PERFORMANCE: Pending state for debouncing (prevents spam with @mouseover macros)
local pendingSetUnit = nil


-- Frames below this alpha are considered "faded out" and tooltips will be suppressed
local FADED_ALPHA_THRESHOLD = 0.5

---------------------------------------------------------------------------
-- Get settings from database (cached for performance)
---------------------------------------------------------------------------
local function GetSettings()
    if cachedSettings then return cachedSettings end
    local LUICore = _G.LuheyUI and _G.LuheyUI.LUICore
    if LUICore and LUICore.db and LUICore.db.profile and LUICore.db.profile.tooltip then
        cachedSettings = LUICore.db.profile.tooltip
        return cachedSettings
    end
    return nil
end

-- Cache invalidation (called on profile change or settings update)
local function InvalidateCache()
    cachedSettings = nil
end

---------------------------------------------------------------------------
-- Context Detection
-- Determines what triggered the tooltip based on owner frame
---------------------------------------------------------------------------
local function GetTooltipContext(owner)
    if not owner then return "npcs" end

    -- CDM: Check for skinned CDM icons (Essential, Utility, Buff views)
    if owner.__cdmSkinned then
        return "cdm"
    end

    -- Check parent for CDM (tooltip owner might be child of CDM icon)
    local parent = owner:GetParent()
    if parent then
        if parent.__cdmSkinned then
            return "cdm"
        end
        -- Check if parent is a CDM viewer frame
        local parentName = parent:GetName() or ""
        if parentName == "EssentialCooldownViewer" or
           parentName == "UtilityCooldownViewer" or
           parentName == "BuffIconCooldownViewer" or
           parentName == "BuffBarCooldownViewer" then
            return "cdm"
        end
    end

    -- Custom Trackers: Check for custom tracker icons
    if owner.__customTrackerIcon then
        return "customTrackers"
    end

    local name = owner:GetName() or ""

    -- Abilities: Check for action button patterns
    if strmatch(name, "ActionButton") or
       strmatch(name, "MultiBar") or
       strmatch(name, "PetActionButton") or
       strmatch(name, "StanceButton") or
       strmatch(name, "OverrideActionBar") or
       strmatch(name, "ExtraActionButton") or
       strmatch(name, "BT4Button") or           -- Bartender4
       strmatch(name, "DominosActionButton") or -- Dominos
       strmatch(name, "ElvUI_Bar") then         -- ElvUI

        -- Check if this action button contains an item (trinket, equipment, etc)
        local actionSlot = owner:GetAttribute("action")
        if actionSlot then
            local actionType, actionID = GetActionInfo(actionSlot)
            if actionType == "item" then
                return "items"
            end
        end

        return "abilities"
    end

    -- Items: Check for container/bag frame patterns
    if strmatch(name, "ContainerFrame") or
       strmatch(name, "BagSlot") or
       strmatch(name, "BankFrame") or
       strmatch(name, "ReagentBank") or
       strmatch(name, "BagItem") or
       strmatch(name, "Baganator") then         -- Baganator addon
        return "items"
    end

    -- Check parent for bag items (nested frames)
    -- Note: parent already defined earlier for CDM check
    if parent then
        local parentNameItems = parent:GetName() or ""
        if strmatch(parentNameItems, "ContainerFrame") or
           strmatch(parentNameItems, "BankFrame") or
           strmatch(parentNameItems, "Baganator") then
            return "items"
        end
    end

    -- Frames: Check for unit frame patterns
    if owner.unit or                            -- Standard unit attribute
       strmatch(name, "UnitFrame") or
       strmatch(name, "PlayerFrame") or
       strmatch(name, "TargetFrame") or
       strmatch(name, "FocusFrame") or
       strmatch(name, "PartyMemberFrame") or
       strmatch(name, "CompactRaidFrame") or
       strmatch(name, "CompactPartyFrame") or
       strmatch(name, "NamePlate") or
       strmatch(name, "Quazii.*Frame") then     -- LuheyUI unit frames
        return "frames"
    end

    -- Default: NPCs, players, objects in the game world
    return "npcs"
end

---------------------------------------------------------------------------
-- Modifier Key Check
---------------------------------------------------------------------------
local function IsModifierActive(modKey)
    if modKey == "SHIFT" then return IsShiftKeyDown() end
    if modKey == "CTRL" then return IsControlKeyDown() end
    if modKey == "ALT" then return IsAltKeyDown() end
    return false
end

---------------------------------------------------------------------------
-- Visibility Logic
-- Determines if tooltip should be shown based on context and settings
---------------------------------------------------------------------------
local function ShouldShowTooltip(context)
    local settings = GetSettings()
    if not settings or not settings.enabled then
        return true  -- Module disabled = default behavior
    end

    -- Combat check - if hideInCombat is enabled and we're in combat
    if settings.hideInCombat and InCombatLockdown() then
        -- Check if combat key is set and pressed
        if settings.combatKey and settings.combatKey ~= "NONE" then
            if IsModifierActive(settings.combatKey) then
                return true  -- Force show in combat with modifier
            end
        end
        return false  -- Hide in combat (no key pressed)
    end

    local visibility = settings.visibility and settings.visibility[context]
    if not visibility then
        return true  -- Unknown context = show by default
    end

    -- Context visibility check
    if visibility == "SHOW" then
        return true
    elseif visibility == "HIDE" then
        return false
    else
        -- Modifier-based visibility (SHIFT/CTRL/ALT)
        return IsModifierActive(visibility)
    end
end

---------------------------------------------------------------------------
-- Tooltip Hook
-- Intercepts GameTooltip_SetDefaultAnchor to apply cursor anchoring
---------------------------------------------------------------------------
local function SetupTooltipHook()
    hooksecurefunc("GameTooltip_SetDefaultAnchor", function(tooltip, parent)
        local settings = GetSettings()
        if not settings or not settings.enabled then
            return  -- Module disabled, use default behavior
        end

        -- Get context from parent (owner)
        local context = GetTooltipContext(parent)

        -- Check visibility for this context (handles combat + modifier key logic)
        if not ShouldShowTooltip(context) then
            tooltip:Hide()
            tooltip:SetOwner(UIParent, "ANCHOR_NONE")
            tooltip:ClearLines()
            return
        end

        -- Cursor anchor logic
        if settings.anchorToCursor then
            -- Use WoW's built-in cursor anchor (handles positioning automatically)
            tooltip:SetOwner(parent, "ANCHOR_CURSOR")
        end
    end)

    -- Hook SetUnit to suppress tooltips when a UI frame blocks the mouse
    -- PERFORMANCE: Debounced to prevent spam with @mouseover macros (max 20 calls/sec)
    hooksecurefunc(GameTooltip, "SetUnit", function(tooltip, unit)
        local settings = GetSettings()
        if not settings or not settings.enabled then return end

        -- Debounce: Only process once per 100ms to prevent CPU spikes with @mouseover macros
        if pendingSetUnit then return end
        pendingSetUnit = C_Timer.After(0.1, function()
            pendingSetUnit = nil
            -- If owner is UIParent (world tooltip) and a UI frame is blocking the mouse
            if tooltip:GetOwner() == UIParent and IsFrameBlockingMouse() then
                tooltip:Hide()
            end
        end)
    end)

    -- Apply class color to player names in tooltips (WoW 10.0+)
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, function(tooltip)
        if tooltip ~= GameTooltip then return end

        local settings = GetSettings()
        if not settings or not settings.enabled or not settings.classColorName then return end

        local _, unit = tooltip:GetUnit()
        if not unit then return end

        -- Wrap UnitIsPlayer in pcall to handle protected "secret" unit values
        -- During instanced combat, unit can be a protected value that causes taint errors
        local okPlayer, isPlayer = pcall(UnitIsPlayer, unit)
        if not okPlayer or not isPlayer then return end

        local okClass, _, class = pcall(UnitClass, unit)
        if not okClass or not class then return end

        local classColor = class and RAID_CLASS_COLORS[class]
        if classColor then
            local nameLine = GameTooltipTextLeft1
            if nameLine and nameLine:GetText() then
                nameLine:SetTextColor(classColor.r, classColor.g, classColor.b)
            end
        end
    end)

    -- Hide tooltip health bar based on settings
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, function(tooltip)
        if tooltip ~= GameTooltip then return end

        local settings = GetSettings()
        if not settings or not settings.enabled then return end

        local hideBar = settings.hideHealthBar

        if GameTooltipStatusBar then
            GameTooltipStatusBar:SetShown(not hideBar)
            GameTooltipStatusBar:SetAlpha(hideBar and 0 or 1)
        end
    end)

    ---------------------------------------------------------------------------
    -- Visual Styling Hook
    -- Applies scale, background color, border color to tooltips
    ---------------------------------------------------------------------------
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, function(tooltip)
        if tooltip ~= GameTooltip then return end

        local settings = GetSettings()
        if not settings or not settings.enabled then return end

        -- Apply scale
        if settings.scale and settings.scale ~= 1.0 then
            tooltip:SetScale(settings.scale)
        else
            tooltip:SetScale(1.0)
        end

        -- Get unit for class/reaction coloring
        local _, unit = tooltip:GetUnit()

        -- Determine border color
        local bg = settings.backgroundColor or {0.05, 0.05, 0.05, 0.95}
        local border = settings.borderColor or {0.2, 1.0, 0.6, 1.0}

        -- Class-colored border (players only)
        if unit and settings.classColoredBorder then
            local okPlayer, isPlayer = pcall(UnitIsPlayer, unit)
            if okPlayer and isPlayer then
                local okClass, _, class = pcall(UnitClass, unit)
                if okClass and class and RAID_CLASS_COLORS[class] then
                    local c = RAID_CLASS_COLORS[class]
                    border = {c.r, c.g, c.b, 1}
                end
            end
        -- Reaction-colored border (NPCs/players)
        elseif unit and settings.reactionColoredBorder then
            local okReaction, reaction = pcall(UnitReaction, unit, "player")
            if okReaction and reaction then
                if reaction <= 2 then      -- Hostile
                    border = {0.8, 0.2, 0.2, 1}
                elseif reaction <= 4 then  -- Neutral
                    border = {0.9, 0.7, 0.2, 1}
                else                       -- Friendly
                    border = {0.2, 0.8, 0.2, 1}
                end
            end
        end

        -- Apply to NineSlice (modern tooltip system)
        if tooltip.NineSlice then
            tooltip.NineSlice:SetCenterColor(bg[1], bg[2], bg[3], bg[4])
            tooltip.NineSlice:SetBorderColor(border[1], border[2], border[3], border[4])
        end
    end)

    ---------------------------------------------------------------------------
    -- Information Display Hook
    -- Adds target, guild rank, realm, mount, and Raider.IO info to tooltips
    ---------------------------------------------------------------------------
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, function(tooltip)
        if tooltip ~= GameTooltip then return end

        local settings = GetSettings()
        if not settings or not settings.enabled then return end

        local _, unit = tooltip:GetUnit()
        if not unit then return end

        -- Modify realm display in tooltip name
        if settings.realmDisplay and settings.realmDisplay ~= "always" then
            local okName, name, realm = pcall(UnitName, unit)
            if okName and realm and realm ~= "" then
                local realmDisplay = settings.realmDisplay
                local nameLine = GameTooltipTextLeft1
                if nameLine then
                    local currentText = nameLine:GetText()
                    if currentText then
                        if realmDisplay == "never" then
                            -- Remove "-RealmName" pattern, preserve color codes
                            local cleanedText = currentText:gsub("%-" .. realm, "")
                            nameLine:SetText(cleanedText)
                        elseif realmDisplay == "crossrealm" then
                            local format = settings.realmFormat or "full"
                            if format == "asterisk" then
                                -- Replace "-RealmName" with " (*)"
                                local cleanedText = currentText:gsub("%-" .. realm, " (*)")
                                nameLine:SetText(cleanedText)
                            end
                        end
                    end
                end
            end
        end

        -- Show target display
        if settings.showTarget then
            local target = unit .. "target"
            local okExists, targetExists = pcall(UnitExists, target)
            if okExists and targetExists then
                local okTargetName, targetName = pcall(UnitName, target)
                if okTargetName and targetName then
                    local okIsUnit, isTargetingPlayer = pcall(UnitIsUnit, target, "player")
                    if okIsUnit and isTargetingPlayer then
                        targetName = settings.targetYouText or "<<YOU>>"
                    else
                        local okIsPlayer, isTargetPlayer = pcall(UnitIsPlayer, target)
                        if okIsPlayer and isTargetPlayer then
                            local okClass, _, class = pcall(UnitClass, target)
                            if okClass and class and RAID_CLASS_COLORS[class] then
                                local c = RAID_CLASS_COLORS[class]
                                targetName = string.format("|cff%02x%02x%02x%s|r",
                                    c.r * 255, c.g * 255, c.b * 255, targetName)
                            end
                        end
                    end
                    tooltip:AddLine("Target: " .. targetName, 0.7, 0.7, 0.7)
                end
            end
        end

        -- Mount display (only for players)
        if settings.showMount then
            local okIsPlayer, isPlayer = pcall(UnitIsPlayer, unit)
            if okIsPlayer and isPlayer then
                -- Iterate through auras to find mount buff (UnitIsMounted may not work for other players)
                for i = 1, 40 do
                    local auraData = C_UnitAuras.GetAuraDataByIndex(unit, i, "HELPFUL")
                    if not auraData then break end
                    if auraData.spellId then
                        local mountID = C_MountJournal.GetMountFromSpell(auraData.spellId)
                        if mountID then
                            local mountName = C_MountJournal.GetMountInfoByID(mountID)
                            if mountName then
                                tooltip:AddLine("Mount: " .. mountName, 0.6, 0.8, 1.0)
                                break
                            end
                        end
                    end
                end
            end
        end

        -- Raider.IO score (only if addon loaded and setting enabled)
        if settings.showRaiderIO and _G.RaiderIO then
            local RaiderIO = _G.RaiderIO
            if RaiderIO.GetProfile then
                local okProfile, profile = pcall(RaiderIO.GetProfile, unit)
                if okProfile and profile and profile.mythicKeystoneProfile then
                    local score = profile.mythicKeystoneProfile.currentScore
                    if score and score > 0 then
                        local color = {1, 1, 1}
                        if RaiderIO.GetScoreColor then
                            local okColor, scoreColor = pcall(RaiderIO.GetScoreColor, score)
                            if okColor and scoreColor then
                                color = {scoreColor.r, scoreColor.g, scoreColor.b}
                            end
                        end
                        tooltip:AddLine(string.format("M+ Score: %d", score),
                            color[1], color[2], color[3])
                    end
                end
            end
        end

        -- Refresh tooltip to show new lines
        tooltip:Show()
    end)

    -- Hook SetSpellByID to suppress CDM and Custom Tracker tooltips
    -- These icons use SetSpellByID which bypasses GameTooltip_SetDefaultAnchor
    hooksecurefunc(GameTooltip, "SetSpellByID", function(tooltip, spellID)
        local settings = GetSettings()
        if not settings or not settings.enabled then return end

        local owner = tooltip:GetOwner()

        -- Suppress tooltip if owner frame is faded out (e.g., CDM hidden when mounted)
        if owner and owner.GetEffectiveAlpha and owner:GetEffectiveAlpha() < FADED_ALPHA_THRESHOLD then
            tooltip:Hide()
            return
        end

        local context = GetTooltipContext(owner)

        -- Apply visibility rules to CDM and Custom Trackers contexts
        if context == "cdm" or context == "customTrackers" then
            if not ShouldShowTooltip(context) then
                tooltip:Hide()
            end
        end
    end)

    -- Hook SetItemByID to suppress Custom Tracker item tooltips
    hooksecurefunc(GameTooltip, "SetItemByID", function(tooltip, itemID)
        local settings = GetSettings()
        if not settings or not settings.enabled then return end

        local owner = tooltip:GetOwner()

        -- Suppress tooltip if owner frame is faded out (e.g., CDM hidden when mounted)
        if owner and owner.GetEffectiveAlpha and owner:GetEffectiveAlpha() < FADED_ALPHA_THRESHOLD then
            tooltip:Hide()
            return
        end

        local context = GetTooltipContext(owner)

        -- Apply visibility rules to Custom Trackers context
        if context == "customTrackers" then
            if not ShouldShowTooltip("customTrackers") then
                tooltip:Hide()
            end
        end
    end)

    -- Hook GameTooltip_Hide as safety net for combat tooltip issues
    -- Runs after original function - if tooltip still visible during combat, force hide
    hooksecurefunc("GameTooltip_Hide", function()
        if InCombatLockdown() and GameTooltip:IsVisible() then
            GameTooltip:Hide()
        end
    end)

    -- Tooltip sticking monitor - fixes Midnight 12.0+ combat tooltip issue
    -- PERFORMANCE: Only runs during combat (event-driven start/stop)
    -- Only active when hideInCombat is DISABLED (when ON, the hook handles it)
    local tooltipMonitor = CreateFrame("Frame")
    local monitorElapsed = 0

    local function TooltipMonitorOnUpdate(self, delta)
        monitorElapsed = monitorElapsed + delta
        if monitorElapsed < 0.25 then return end  -- 250ms throttle (4 FPS) - was 100ms
        monitorElapsed = 0

        local settings = GetSettings()
        if not settings or not settings.enabled then return end
        if settings.hideInCombat then return end  -- Hook handles this case

        if not GameTooltip:IsVisible() then return end

        local owner = GameTooltip:GetOwner()
        if not owner then return end

        local mouseFrame = GetTopMouseFrame()
        if not mouseFrame then return end

        -- Check if mouse is over owner or child of owner
        local isOverOwner = false
        local checkFrame = mouseFrame
        while checkFrame do
            if checkFrame == owner then
                isOverOwner = true
                break
            end
            checkFrame = checkFrame:GetParent()
        end

        -- If mouse moved away from owner, hide stuck tooltip
        if not isOverOwner then
            GameTooltip:Hide()
        end
    end

    -- Event-driven: Only run OnUpdate during combat
    tooltipMonitor:RegisterEvent("PLAYER_REGEN_DISABLED")
    tooltipMonitor:RegisterEvent("PLAYER_REGEN_ENABLED")
    tooltipMonitor:SetScript("OnEvent", function(self, event)
        if event == "PLAYER_REGEN_DISABLED" then
            -- Entering combat - start monitoring
            monitorElapsed = 0
            self:SetScript("OnUpdate", TooltipMonitorOnUpdate)
        else
            -- Leaving combat - stop monitoring (zero CPU outside combat)
            self:SetScript("OnUpdate", nil)
        end
    end)
end

---------------------------------------------------------------------------
-- Modifier State Handler
-- Re-evaluates tooltip visibility when modifier keys change
---------------------------------------------------------------------------
local function OnModifierStateChanged()
    -- Only process if tooltip is currently shown
    if not GameTooltip:IsShown() then return end

    local settings = GetSettings()
    if not settings or not settings.enabled then return end

    local owner = GameTooltip:GetOwner()
    local context = GetTooltipContext(owner)

    -- If tooltip should now be hidden, hide it
    if not ShouldShowTooltip(context) then
        GameTooltip:Hide()
    end
end

---------------------------------------------------------------------------
-- Combat State Handler
-- Hides tooltips immediately when entering combat (if hideInCombat enabled)
---------------------------------------------------------------------------
local function OnCombatStateChanged(inCombat)
    local settings = GetSettings()
    if not settings or not settings.enabled or not settings.hideInCombat then return end

    if inCombat then
        -- Entering combat - hide tooltip immediately if no combat key override
        if not settings.combatKey or settings.combatKey == "NONE" or not IsModifierActive(settings.combatKey) then
            GameTooltip:Hide()
        end
    end
    -- Leaving combat - nothing special needed, tooltips will show normally
end

---------------------------------------------------------------------------
-- Event Frame
---------------------------------------------------------------------------
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("MODIFIER_STATE_CHANGED")
eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")

eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        -- Delay hook setup to ensure database is ready
        C_Timer.After(0.5, function()
            SetupTooltipHook()

            -- Wrap MoneyFrame functions in pcall to suppress Blizzard secret value bug
            if MoneyFrame_Update then
                local originalMoneyFrameUpdate = MoneyFrame_Update
                MoneyFrame_Update = function(...)
                    pcall(originalMoneyFrameUpdate, ...)
                end
            end
            if SetTooltipMoney then
                local originalSetTooltipMoney = SetTooltipMoney
                SetTooltipMoney = function(...)
                    pcall(originalSetTooltipMoney, ...)
                end
            end

            -- Wrap GameTooltip:SetSpellByID in pcall to suppress Blizzard PTRFeedback secret value bug
            if GameTooltip and GameTooltip.SetSpellByID then
                local originalSetSpellByID = GameTooltip.SetSpellByID
                GameTooltip.SetSpellByID = function(...)
                    pcall(originalSetSpellByID, ...)
                end
            end
        end)
    elseif event == "MODIFIER_STATE_CHANGED" then
        OnModifierStateChanged()
    elseif event == "PLAYER_REGEN_DISABLED" then
        -- Entering combat
        OnCombatStateChanged(true)
    elseif event == "PLAYER_REGEN_ENABLED" then
        -- Leaving combat
        OnCombatStateChanged(false)
    end
end)

---------------------------------------------------------------------------
-- Global Refresh Function (called from options panel)
---------------------------------------------------------------------------
_G.LuheyUI_RefreshTooltips = function()
    InvalidateCache()
    -- Settings will apply on next tooltip show
end
