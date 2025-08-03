-- Main addon file
-- @author Abracadaniel22

local addonName, addon = ...
WHODIS_ADDON_ID = "WhoDis"
WHODIS_ADDON_TITLE = "Who dis?"

local AceAddon = LibStub("AceAddon-3.0")
local LDB = LibStub("LibDataBroker-1.1")
local LDBIcon = LibStub("LibDBIcon-1.0")

local WhoDis = AceAddon:NewAddon(WHODIS_ADDON_ID, "AceEvent-3.0")

local AceEvent = LibStub("AceEvent-3.0")
AceEvent:Embed(WhoDis)
local AceTimer = LibStub("AceTimer-3.0")
AceTimer:Embed(WhoDis)

function WhoDis:OnInitialize()
    local minimapIconData = LDB:NewDataObject(WHODIS_ADDON_ID, {
        type = "launcher",
        text = WHODIS_ADDON_ID,
        icon = "Interface\\ICONS\\inv_misc_grouplooking" ,
        OnClick = function(clickedframe, button)
            WhoDis.uiInstance:ShowUI()
        end,
        OnTooltipShow = function(tooltip)
            tooltip:AddLine(WHODIS_ADDON_TITLE)
            tooltip:AddLine("Click to open")
        end,
    })
    LDBIcon:Register(WHODIS_ADDON_ID, minimapIconData, { hide = false })
    WhoDis.API.Initialize()
    WhoDis.uiInstance = WhoDis.UI:New()
    WhoDis.SlashCommand.Initialize()
    WhoDis.API.PrintAddonMessage("Loaded. Type '/whodis' to open, or '/whodis help' for instructions")
end
