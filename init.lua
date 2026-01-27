-- Keybinding display name (must be global before Bindings.xml loads)
BINDING_NAME_LUHEYUI_TOGGLE_OPTIONS = "Open LuheyUI Options"

---@type table|AceAddon
LuheyUI = LibStub("AceAddon-3.0"):NewAddon("LuheyUI", "AceConsole-3.0", "AceEvent-3.0")
---@type table<string, string>
LuheyUI.L = LibStub("AceLocale-3.0"):GetLocale("LuheyUI")

local L = LuheyUI.L

---@type table
LuheyUI.DF = _G["DetailsFramework"]
LuheyUI.DEBUG_MODE = false

-- Version info
LuheyUI.versionString = C_AddOns.GetAddOnMetadata("LuheyUI", "Version") or "2.0"

---@type table
LuheyUI.defaults = {
    global = {},
    char = {
        ---@type table
        debug = {
            ---@type boolean
            reload = false
        }
    }
}

function LuheyUI:OnInitialize()
    -- Migration from QuaziiUI to LuheyUI
    if QuaziiUI_DB and not LuheyUI_DB then
        LuheyUI_DB = CopyTable(QuaziiUI_DB)
        print("|cFF30D1FFLuhey UI|r: Settings migrated from QuaziiUI.")
    end

    ---@type AceDBObject-3.0
    self.db = LibStub("AceDB-3.0"):New("LuheyUI_DB", self.defaults, "Default")

    -- Register slash commands (keeping /qui for backwards compatible)
    self:RegisterChatCommand("lui", "SlashCommandOpen")
    self:RegisterChatCommand("luheyui", "SlashCommandOpen")
    self:RegisterChatCommand("qui", "SlashCommandOpen")
    self:RegisterChatCommand("rl", "SlashCommandReload")

    -- Register our media files with LibSharedMedia
    self:CheckMediaRegistration()
end

-- Quick Keybind Mode shortcut (/kb)
SLASH_LUIKB1 = "/kb"
SlashCmdList["LUIKB"] = function()
    local LibKeyBound = LibStub("LibKeyBound-1.0", true)
    if LibKeyBound then
        LibKeyBound:Toggle()
    elseif QuickKeybindFrame then
        -- Fallback to Blizzard's Quick Keybind Mode (no mousewheel support)
        ShowUIPanel(QuickKeybindFrame)
    else
        print("|cff34D399LuheyUI:|r Quick Keybind Mode not available.")
    end
end

-- Cooldown Settings shortcut (/cdm)
SLASH_LUHEYUI_CDM1 = "/cdm"
SLASH_LUHEYUI_CDM2 = "/wa"
SlashCmdList["LUHEYUI_CDM"] = function()
    if CooldownViewerSettings then
        CooldownViewerSettings:SetShown(not CooldownViewerSettings:IsShown())
    else
        print("|cff34D399LuheyUI:|r Cooldown Settings not available. Enable CDM first.")
    end
end

function LuheyUI:SlashCommandOpen(input)
    if input and input == "debug" then
        self.db.char.debug.reload = true
        LuheyUI:SafeReload()
    elseif input and input == "editmode" then
        -- Toggle Unit Frames Edit Mode
        if _G.LuheyUI_ToggleUnitFrameEditMode then
            _G.LuheyUI_ToggleUnitFrameEditMode()
        else
            print("|cFF56D1FFLuheyUI:|r Unit Frames module not loaded.")
        end
        return
    end

    -- Default: Open custom GUI
    if self.GUI then
        self.GUI:Toggle()
    else
        print("|cFF56D1FFLuheyUI:|r GUI not loaded yet. Try again in a moment.")
    end
end

function LuheyUI:SlashCommandReload()
    LuheyUI:SafeReload()
end

function LuheyUI:OnEnable()
    self:RegisterEvent("PLAYER_ENTERING_WORLD")

    -- Initialize LUICore (AceDB-based integration)
    if self.LUICore then
        -- Show intro message if enabled (defaults to true)
        if self.db.profile.chat.showIntroMessage ~= false then
            print("|cFF30D1FFLuhey UI|r loaded. |cFFFFFF00/lui|r to setup.")
        end
    end
end

function LuheyUI:PLAYER_ENTERING_WORLD(_, isInitialLogin, isReloadingUi)
    LuheyUI:BackwardsCompat()

    -- Ensure debug table exists
    if not self.db.char.debug then
        self.db.char.debug = { reload = false }
    end

    if not self.DEBUG_MODE then
        if self.db.char.debug.reload then
            self.DEBUG_MODE = true
            self.db.char.debug.reload = false
            self:DebugPrint("Debug Mode Enabled")
        end
    else
        self:DebugPrint("Debug Mode Enabled")
    end
end

function LuheyUI:DebugPrint(...)
    if self.DEBUG_MODE then
        self:Print(...)
    end
end

-- ADDON COMPARTMENT FUNCTIONS --
function LuheyUI_CompartmentClick()
    -- Open the new GUI
    if LuheyUI.GUI then
        LuheyUI.GUI:Toggle()
    end
end

local GameTooltip = GameTooltip
function LuheyUI_CompartmentOnEnter(self, button)
    GameTooltip:ClearLines()
    GameTooltip:SetOwner(type(self) ~= "string" and self or button, "ANCHOR_LEFT")
    GameTooltip:AddLine(L["AddonName"] .. " v" .. LuheyUI.versionString)
    GameTooltip:AddLine(L["LeftClickOpen"])
    GameTooltip:Show()
end

function LuheyUI_CompartmentOnLeave()
    GameTooltip:Hide()
end
