-- This file contains shared functionality used by other modules
-- @author Abracadaniel22

local addonName, addon = ...
local WhoDis = LibStub("AceAddon-3.0"):GetAddon(WHODIS_ADDON_ID)

local API = {}
WhoDis.API = API

WhoDisDB = WhoDisDB or {
    allianceCustomRaces = {},
    hordeCustomRaces = {},
    formData = {}
}

API.ZONES_CACHE = nil
API.DEFAULT_CLASSES = {
    "Death Knight",
    "Druid",
    "Hunter",
    "Mage",
    "Paladin",
    "Priest",
    "Rogue",
    "Shaman",
    "Warlock",
    "Warrior"
}
API.DEFAULT_RACES = {
    ["Alliance"] = {"Human", "Dwarf", "Night Elf", "Gnome", "Draenei"},
    ["Horde"] = {"Orc", "Undead", "Tauren", "Troll", "Blood Elf"}
}

function API.PrintAddonMessage(text)
    DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFFd0e75a%s|r", "[" .. WHODIS_ADDON_TITLE .. "]") .. " " .. text)
end

function API.GetAllZones()
    if API.ZONES_CACHE == nil then
        API.ZONES_CACHE = {}
        for ContinentIndex = 1, 4 do
            local zones = {GetMapZones(ContinentIndex)}
            for _, zone in ipairs(zones) do
                table.insert(API.ZONES_CACHE, zone)
            end
        end
        table.sort(API.ZONES_CACHE)
    end
    return API.ZONES_CACHE
end

function API.SplitList(arr)
    local n = #arr
    local mid = math.floor(n / 2)
    local firstHalf = {}
    local secondHalf = {}
    
    for i = 1, mid do
        firstHalf[i] = arr[i]
    end
    
    for i = mid + 1, n do
        secondHalf[i - mid] = arr[i]
    end
    
    return firstHalf, secondHalf
end

function API.GetAllRaces()
    local allRaces = {
        Alliance = {},
        Horde = {}
    }
    
    for _, race in ipairs(API.DEFAULT_RACES.Alliance) do
        table.insert(allRaces.Alliance, race)
    end
    
    for _, race in ipairs(API.DEFAULT_RACES.Horde) do
        table.insert(allRaces.Horde, race)
    end
    
    for _, race in ipairs(WhoDisDB.allianceCustomRaces) do
        table.insert(allRaces.Alliance, race)
    end
    
    for _, race in ipairs(WhoDisDB.hordeCustomRaces) do
        table.insert(allRaces.Horde, race)
    end
    
    return allRaces
end

function API.DetectPlayersCustomRace()
    local englishFaction, _ = UnitFactionGroup("player")
    local race, _ = UnitRace("player")
    
    englishFaction = englishFaction:lower()
    if not englishFaction or not race then
        return
    end

    local allRaces = API.GetAllRaces()
    local fullRaceTable = englishFaction == "alliance" and allRaces.Alliance or allRaces.Horde
    local customRaceTable = englishFaction == "alliance" and WhoDisDB.allianceCustomRaces or WhoDisDB.hordeCustomRaces

    for _, v in ipairs(fullRaceTable) do
        if v:lower() == race:lower() then
            return
        end
    end
    
    table.insert(customRaceTable, race)
    if englishFaction == "alliance" then
        WhoDisDB.allianceCustomRaces = customRaceTable
    else
        WhoDisDB.hordeCustomRaces = customRaceTable
    end
    API.PrintAddonMessage("Automatically added " .. race .. " to " .. englishFaction .. " custom races.")
end

function API.GetDB()
    return WhoDisDB
end

--TODO perhaps just let classes set db directly. This creates unnecessary encapsulation that overcomplicates things
function API.SetAllianceCustomRaces(raceTable)
    WhoDisDB.allianceCustomRaces = raceTable
end

function API.SetHordeCustomRaces(raceTable)
    WhoDisDB.hordeCustomRaces = raceTable
end

function API.Initialize()
    API.DetectPlayersCustomRace()
end