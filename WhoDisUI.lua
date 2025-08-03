-- Shows main addon UI with form
-- @author Abracadaniel22

local addonName, addon = ...
local AceGUI = LibStub("AceGUI-3.0")

local WhoDis = LibStub("AceAddon-3.0"):GetAddon(WHODIS_ADDON_ID)
local API = WhoDis.API
local UIUtils = UIUtils

local UI = {}
UI.__index = UI
WhoDis.UI = UI

-- Constructor

function UI:New()
    local instance = {
        _formState = {
            minLevel = "",
            maxLevel = "",
            classes = {},
            races = {},
            zone = "",
            name = "",
            guild = "",
        },
        _dialogFrame = nil
    }
    setmetatable(instance, self)
    return instance
end

local function _loadPersistedFormData(self)
    local db = API.GetDB()
    if db.formData ~= nil and db.formData ~= {} then
        self._formState = db.formData
    end
end

-- Private methods

local function _savePersistedFormData(self)
    local db = API.GetDB()
    db.formData = self._formState
end

local function _updateStatusBarText(self)
    local parts = { "/who" }
    if self._formState.name ~= "" then
        table.insert(parts, string.format('n-"%s"', self._formState.name))
    end
    if self._formState.guild ~= "" then
        table.insert(parts, string.format('g-"%s"', self._formState.guild))
    end
    local region = self._formState.zone ~= "" and self._formState.zone
    if region and region ~= "" then
        table.insert(parts, string.format('z-"%s"', region))
    end
    for _, c in ipairs(self._formState.classes) do
        table.insert(parts, string.format('c-"%s"', c))
    end
    for _, r in ipairs(self._formState.races) do
        table.insert(parts, string.format('r-"%s"', r))
    end
    local min = tonumber(self._formState.minLevel)
    local max = tonumber(self._formState.maxLevel)
    if self._formState.minLevel ~= "" or self._formState.maxLevel ~= "" then
        if self._formState.minLevel == "" and self._formState.maxLevel ~= "" then min = nil end
        if self._formState.maxLevel == "" and self._formState.minLevel ~= "" then max = nil end
        if min and max and min ~= max then
            table.insert(parts, string.format("%d-%d", min, max))
        elseif min and max and min == max then
            table.insert(parts, tostring(min))
        elseif min then
            table.insert(parts, tostring(min))
        elseif max then
            table.insert(parts, tostring(max))
        end
    end
    self._dialogFrame:SetStatusText(table.concat(parts, " "))
end

local function _showMainDialog(self)
    self._dialogFrame = AceGUI:Create("Frame")
    self._dialogFrame:SetTitle(WHODIS_ADDON_TITLE)
    self._dialogFrame:SetStatusText("/who ")
    self._dialogFrame:SetLayout("Fill")
    self._dialogFrame:SetWidth(600)
    self._dialogFrame:SetHeight(600)
    self._dialogFrame:EnableResize(false)
    self._dialogFrame:SetCallback("OnClose", function(widget) self:CloseUI() end)
    _G["WhoDisMainFrame"] = self._dialogFrame.frame
    table.insert(UISpecialFrames, "WhoDisMainFrame")
    local frameGroup = AceGUI:Create("InlineGroup")
    frameGroup:SetLayout("List")
    self._dialogFrame:AddChild(frameGroup)

    -- Table layout for min/max level
    local levelTableGroup = AceGUI:Create("SimpleGroup")
    levelTableGroup:SetLayout("Table")
    levelTableGroup:SetUserData("table", { columns = { {width=0.5, weight=1}, {width=0.5, weight=1}, {width=0.3, weight=0.5} } })
    levelTableGroup:SetFullWidth(true)
    
    levelTableGroup:AddChild(UIUtils.CreateLabel("Min level"))

    levelTableGroup:AddChild(UIUtils.CreateLabel("Max level"))

    local useMyLevelBtn = AceGUI:Create("Button")
    useMyLevelBtn:SetText("Use my level")
    useMyLevelBtn:SetWidth(110)
    levelTableGroup:AddChild(useMyLevelBtn)

    local minEdit = AceGUI:Create("EditBox")
    minEdit:DisableButton(true)
    minEdit:SetText(self._formState.minLevel)
    minEdit:SetLabel("")
    minEdit:SetWidth(100)
    minEdit:SetCallback("OnTextChanged", function(widget, evt, val)
        self._formState.minLevel = val
        _updateStatusBarText(self)
    end)
    levelTableGroup:AddChild(minEdit)

    local maxEdit = AceGUI:Create("EditBox")
    maxEdit:DisableButton(true)
    maxEdit:SetText(self._formState.maxLevel)
    maxEdit:SetLabel("")
    maxEdit:SetWidth(100)
    maxEdit:SetCallback("OnTextChanged", function(widget, evt, val)
        self._formState.maxLevel = val
        _updateStatusBarText(self)
    end)
    levelTableGroup:AddChild(maxEdit)

    useMyLevelBtn:SetCallback("OnClick", function()
        local lvl = UnitLevel("player")
        self._formState.maxLevel = tostring(lvl)
        self._formState.minLevel = tostring(math.max(1, lvl - 2))
        minEdit:SetText(self._formState.minLevel)
        maxEdit:SetText(self._formState.maxLevel)
        _updateStatusBarText(self)
    end)

    -- Add an empty label to keep the table layout correct
    levelTableGroup:AddChild(UIUtils.CreateLabel(""))

    frameGroup:AddChild(levelTableGroup)

    -- Class
    local classCol1, classCol2 = API.SplitList(API.DEFAULT_CLASSES)
    local classesInput = UIUtils.CreateTwoColumnCheckboxList{
        frame = self._dialogFrame,
        label = "Class",
        items = {classCol1, classCol2}, 
        valueTable = self._formState.classes,
        onItemChangedCallback = function(...)
            _updateStatusBarText(self)
        end
    }
    frameGroup:AddChild(classesInput.uiFrame)

    -- Race
    local allRaces = API.GetAllRaces()
    local raceCol1 = allRaces["Alliance"]
    local raceCol2 = allRaces["Horde"]
    local racesInput = UIUtils.CreateTwoColumnCheckboxList{
        frame = self._dialogFrame,
        label = "Race",
        items = {raceCol1, raceCol2}, 
        valueTable = self._formState.races,
        onItemChangedCallback = function(...)
            _updateStatusBarText(self)
        end
    }
    frameGroup:AddChild(racesInput.uiFrame)

    -- Zone
    local zoneEdit = UIUtils.CreateAutoCompleteEditBox{
        label = "Zone",
        items = API.GetAllZones(),
        text = self._formState.zone,
        onTextChangedCallback = function(widget, evt, val)
            self._formState.zone = val
            _updateStatusBarText(self)
        end
    }
    zoneEdit:SetWidth(250)
    frameGroup:AddChild(zoneEdit)

    -- Name
    local nameEdit = AceGUI:Create("EditBox")
    nameEdit:DisableButton(true)
    nameEdit:SetLabel("Name")
    nameEdit:SetText(self._formState.name)
    nameEdit:SetWidth(250)
    nameEdit:SetCallback("OnTextChanged", function(widget, evt, val)
        self._formState.name = val
        _updateStatusBarText(self)
    end)
    frameGroup:AddChild(nameEdit)

    -- Guild
    local guildEdit = AceGUI:Create("EditBox")
    guildEdit:DisableButton(true)
    guildEdit:SetLabel("Guild name")
    guildEdit:SetText(self._formState.guild)
    guildEdit:SetWidth(250)
    guildEdit:SetCallback("OnTextChanged", function(widget, evt, val)
        self._formState.guild = val
        _updateStatusBarText(self)
    end)
    frameGroup:AddChild(guildEdit)

    -- Buttons
    local buttonsGroup = AceGUI:Create("SimpleGroup")
    buttonsGroup:SetLayout("Table")
    buttonsGroup:SetUserData("table", { columns = { {width=0.5, weight=1}, {width=0.5, weight=1}, {width=0.3, weight=0.5} } })
    buttonsGroup:SetFullWidth(true)
    
    local okBtn = AceGUI:Create("Button")
    okBtn:SetText("Run /who")
    okBtn:SetWidth(100)
    okBtn:SetCallback("OnClick", function()
        local fullStatusText = self._dialogFrame.statustext:GetText()
        local whoCommandArgs = string.sub(fullStatusText, 6, string.len(fullStatusText))
        API.PrintAddonMessage(fullStatusText)
        SendWho(whoCommandArgs)
    end)
    buttonsGroup:AddChild(okBtn)
    
    buttonsGroup:AddChild(UIUtils.CreateLabel(""))

    local resetBtn = AceGUI:Create("Button")
    resetBtn:SetText("Reset")
    resetBtn:SetWidth(110)
    resetBtn:SetCallback("OnClick", function()
        local empty = function(t)
            if t == nil then return end
            for k in pairs(t) do
                t[k] = nil
            end
        end
        -- Update the model
        self._formState.minLevel = ""
        self._formState.maxLevel = ""
        empty(self._formState.classes)
        empty(self._formState.races)
        self._formState.zone = ""
        self._formState.name = ""
        self._formState.guild = ""

        -- Update the UI visuals (this doesn't fire OnChanged)
        minEdit:SetText("")
        maxEdit:SetText("")
        zoneEdit:SetText("")
        nameEdit:SetText("")
        guildEdit:SetText("")
        classesInput.updateUIWithModel()
        racesInput.updateUIWithModel()

        _updateStatusBarText(self)
    end)
    buttonsGroup:AddChild(resetBtn)
    
    frameGroup:AddChild(buttonsGroup)

    _updateStatusBarText(self)
end

-- Public methods

function UI:ShowUI()
    if self._dialogFrame then return end
    _loadPersistedFormData(self)
    _showMainDialog(self)
end

function UI:CloseUI()
    if self._dialogFrame then
        _savePersistedFormData(self)
        self._dialogFrame:Release()
        self._dialogFrame = nil
    end
end
