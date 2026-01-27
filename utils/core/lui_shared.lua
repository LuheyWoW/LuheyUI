--[[
    LuheyUI Shared Utilities
    Common helper functions used across all modules
]]

local ADDON_NAME, ns = ...

---------------------------------------------------------------------------
-- SHARED UTILITIES TABLE
---------------------------------------------------------------------------
ns.Shared = ns.Shared or {}

---------------------------------------------------------------------------
-- DATABASE ACCESS
---------------------------------------------------------------------------

--- Get the current profile database
-- @return table|nil The profile database or nil if not available
function ns.Shared.GetDB()
    local LUICore = _G.LuheyUI and _G.LuheyUI.LUICore
    if LUICore and LUICore.db and LUICore.db.profile then
        return LUICore.db.profile
    end
    return nil
end

--- Get settings for a specific feature with optional defaults
-- @param key string The settings key to retrieve
-- @param defaults table Optional default values if settings not found
-- @return table The settings table or defaults
function ns.Shared.GetSettings(key, defaults)
    local db = ns.Shared.GetDB()
    if db and db[key] then
        return db[key]
    end
    return defaults or {}
end

---------------------------------------------------------------------------
-- SKIN COLOR UTILITIES
---------------------------------------------------------------------------

--- Get the current skin colors (accent and background)
-- @return number, number, number, number, number, number, number, number
--         Accent RGBA followed by Background RGBA
function ns.Shared.GetSkinColors()
    local QUI = _G.LuheyUI
    if QUI and QUI.GetSkinColor and QUI.GetSkinBgColor then
        local sr, sg, sb, sa = QUI:GetSkinColor()
        local bgr, bgg, bgb, bga = QUI:GetSkinBgColor()
        return sr, sg, sb, sa, bgr, bgg, bgb, bga
    end
    -- Default fallback colors (mint accent, dark blue background)
    return 0.2, 0.8, 0.6, 1, 0.067, 0.094, 0.153, 0.95
end

--- Get only the accent skin color
-- @return number, number, number, number RGBA values
function ns.Shared.GetAccentColor()
    local QUI = _G.LuheyUI
    if QUI and QUI.GetSkinColor then
        return QUI:GetSkinColor()
    end
    return 0.2, 0.8, 0.6, 1
end

--- Get only the background skin color
-- @return number, number, number, number RGBA values
function ns.Shared.GetBgColor()
    local QUI = _G.LuheyUI
    if QUI and QUI.GetSkinBgColor then
        return QUI:GetSkinBgColor()
    end
    return 0.067, 0.094, 0.153, 0.95
end
