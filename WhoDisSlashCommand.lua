-- Handles /whodis command
-- @author Abracadaniel22

local addonName, addon = ...
local WhoDis = LibStub("AceAddon-3.0"):GetAddon(WHODIS_ADDON_ID)

local SlashCommand = {}
WhoDis.SlashCommand = SlashCommand

local API = WhoDis.API
local uiInstance = nil

function SlashCommand.HandleSlashCommand(msg)
    local command, faction, race = msg:match("^(%S+)%s*(%S*)%s*(.*)")
    
    if not command or command == "" then
        uiInstance:ShowUI()
        return
    end

    local showhelp = function()
        print("Usage: /whodis <command> [faction] [race]")
        print("Commands: addrace, removerace, reset, help, ?")
        print("Factions: alliance, horde")
    end
    
    command = command:lower()
    faction = faction and faction:lower()
    race = race or ""
    if command == "help" or command == "?" then
        showhelp()
        return
    elseif command == "addrace" then
        if faction ~= "alliance" and faction ~= "horde" or race == "" then
            API.PrintAddonMessage("Usage: /whodis addrace <alliance|horde> <race>")
            return
        end
        local raceTable = faction == "alliance" and API.GetDB().allianceCustomRaces or API.GetDB().hordeCustomRaces
        for _, v in ipairs(raceTable) do
            if v == race then
                API.PrintAddonMessage(race .. " is already in " .. faction .. " custom races.")
                return
            end
        end
        table.insert(raceTable, race)
        if faction == "alliance" then
            API.SetAllianceCustomRaces(raceTable)
        else
            API.SetHordeCustomRaces(raceTable)
        end
        API.PrintAddonMessage(race .. " added to " .. faction .. " custom races.")
    elseif command == "removerace" then
        if faction ~= "alliance" and faction ~= "horde" or race == "" then
            API.PrintAddonMessage("Usage: /whodis removerace <alliance|horde> <race>")
            return
        end
        local raceTable = faction == "alliance" and API.GetDB().allianceCustomRaces or API.GetDB().hordeCustomRaces
        for i, v in ipairs(raceTable) do
            if v:lower() == race:lower() then
                table.remove(raceTable, i)
                prAPI.PrintAddonMessageint(race .. " removed from " .. faction .. " custom races.")
                return
            end
        end
        if faction == "alliance" then
            API.SetAllianceCustomRaces(raceTable)
        else
            API.SetHordeCustomRaces(raceTable)
        end
        API.PrintAddonMessage(race .. " not found in " .. faction .. " custom races.")
    elseif command == "reset" then
        API.SetAllianceCustomRaces({})
        API.SetHordeCustomRaces({})
        API.PrintAddonMessage("Custom races list reset.")
    else
        showhelp()
        return
    end
end

function SlashCommand.Initialize()
    uiInstance = WhoDis.uiInstance
    SLASH_WHODIS1 = "/whodis"
    SlashCmdList["WHODIS"] = SlashCommand.HandleSlashCommand
end
