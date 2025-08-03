-- Static utility UI methods 
-- @author Abracadaniel22

UIUtils = {}
local AceGUI = LibStub("AceGUI-3.0")

local function StartsWith(str, substr)
   return string.sub(str, 1, string.len(substr))==substr
end

local function TableContains(array, valToSearch)
    for _, value in ipairs(array) do
        if value == valToSearch then
            return true
        end
    end
    return false
end

--[[
Creates an EditBox that shows suggestions
args:
    [label]: string - If set, renders a standard label
    items: table{any, string} - table of suggestions
    [onTextChangedCallback] - If set, invokes whenever text changes on the EditBox 
        (including when a suggestion is selected)
example:
    local editBox = CreateAutoCompleteEditBox{
        label = "Zone",
        items = { [0] = "Alterac", [1] = "Stormwind City", [2] = "Dalaran", [3] = "Whiterun" }, 
        onTextChangedCallback = function(widget, evt, val)
            print("Text changed to: "..val)
        end
    }
--]]
function UIUtils.CreateAutoCompleteEditBox(args)
    local label = args.label
    local items = args.items
    local initialText = args.text or ""
    local onTextChangedCallback = args.onTextChangedCallback
    local lowerCaseItems = {}
    for i, v in pairs(items) do
        table.insert(lowerCaseItems, v:lower())
    end
    local editBox = AceGUI:Create("EditBox")
    if label ~= nil then
        editBox:SetLabel(label)
    end
    editBox:DisableButton(true)
    editBox:SetText(initialText)

    local suggestionFrame = CreateFrame("Frame", nil, editBox.frame)
    suggestionFrame:SetWidth(200)
    suggestionFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 8, right = 8, top = 8, bottom = 8 }
    })
    suggestionFrame:Hide()

    local suggestionButtons = {}

    local function UpdateSuggestions(text)
        for _, btn in ipairs(suggestionButtons) do
            btn:ClearAllPoints()
            btn:SetParent(nil)
            btn:Hide()
        end
        wipe(suggestionButtons)
        suggestionFrame:Hide()

        if text == "" then return end
        local lowerCaseUserText = text:lower()

        local matches = {}
        for itemId, itemValue in pairs(lowerCaseItems) do
            if StartsWith(itemValue, lowerCaseUserText) then
                table.insert(matches, items[itemId])
            end
        end

        if #matches > 0 then
            -- TODO scrollbar needed if too many items (ok for zones)
            suggestionFrame:SetHeight(math.min(#matches * 20 + 20, 250))
            suggestionFrame:SetPoint("TOPLEFT", editBox.frame, "BOTTOMLEFT", 0, 0)
            for i, match in ipairs(matches) do
                if not suggestionButtons[i] then
                    suggestionButtons[i] = CreateFrame("Button", nil, suggestionFrame)
                    suggestionButtons[i]:SetHeight(20)
                    suggestionButtons[i]:SetWidth(180)
                    suggestionButtons[i]:SetPoint("TOPLEFT", suggestionFrame, "TOPLEFT", 10, -10 - (i-1) * 20)
                    suggestionButtons[i]:SetNormalFontObject("GameFontNormal")
                    suggestionButtons[i]:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
                    suggestionButtons[i]:SetScript("OnClick", function()
                        editBox:SetText(match)
                        if onTextChangedCallback ~= nil then
                            onTextChangedCallback(editBox, "OnTextChanged", match)
                        end
                        suggestionFrame:Hide()
                    end)
                end
                suggestionButtons[i]:SetText(match)
                suggestionButtons[i]:Show()
            end
            suggestionFrame:Show()
        end
    end

    editBox:SetCallback("OnTextChanged", function(widget, event, text)
        UpdateSuggestions(text)
        if onTextChangedCallback ~= nil then
            onTextChangedCallback(widget, event, text)
        end
    end)
    return editBox
end

function UIUtils.CreateLabel(text)
    local lbl = AceGUI:Create("Label")
    lbl:SetText(text)
    lbl:SetColor(1,.82,0)
    return lbl
end

--[[
Creates two column checkbox list
args:
    label[string]: checkbox list main label
    items[table]: table containing two arrays of items to be the checkboxes. 
        First array will be left side, second will be right side.
    valueTable[table{array}]: table to write the selected elements, updated whenever 
        something is checked/unchecked. It will also be read to pre-select items.
    [onItemChangedCallback] - If set, invokes whenever something is checked/unchecked
returns:
    uiFrame: the frame containing the checkboxes
    updateUIWithModel: method to force check/uncheck the checkboxes after the args.value is updated
example:
    -- creates list and pre-selects Left side item 1 and Right side item 3
    local selectedTextBoxes = {"Left side item 1", "Right side item 3"}
    local checkBoxesList, triggerUpdateCheckboxes = createTwoColumnCheckboxList{
        label = "Best classes",
        items = {
            {"Left side item 1", "Left side item 2", "Left side item 3", "Left side item 4"},
            {"Right side item 1", "Right side item 2", "Right side item 3", "Right side item 4"}
        }, 
        valueTable = selectedTextBoxes,
        onItemChangedCallback = function()
            print("Selected textboxes: " .. selectedTextBoxes)
        end
    }
    frame.add(checkBoxesList)
    -- later on, to check/uncheck the checkboxes
    table.insert(selectedTextBoxes, "Right side item 2")
    triggerUpdateCheckboxes()
--]]
-- update docs
function UIUtils.CreateTwoColumnCheckboxList(args)
    local label = args.label
    local items = args.items
    local valueTable = args.valueTable
    local onItemChangedCallback = args.onItemChangedCallback
    local checkBoxes = {}
    local createColumnGroup = function(groupItems)
        local columnGroup = AceGUI:Create("SimpleGroup")
        columnGroup:SetLayout("List")
        columnGroup:SetWidth(120)
        for _, labelValue in ipairs(groupItems) do
            local cb = AceGUI:Create("CheckBox")
            table.insert(checkBoxes, cb)
            cb:SetLabel(labelValue)
            cb:SetWidth(110)
            if TableContains(valueTable, labelValue) then
                cb:SetValue(true)
            end
            cb:SetCallback("OnValueChanged", function(widget, evt, val)
                if val then
                    table.insert(valueTable, labelValue)
                else
                    for i=#valueTable,1,-1 do if valueTable[i]==labelValue then table.remove(valueTable,i) end end
                end
                if onItemChangedCallback ~= nil then
                    onItemChangedCallback()
                end
            end)
            columnGroup:AddChild(cb)
        end
        return columnGroup
    end

    local mainGroup = AceGUI:Create("SimpleGroup")
    mainGroup:AddChild(UIUtils.CreateLabel(label))

    local checkboxGroup = AceGUI:Create("SimpleGroup")
    checkboxGroup:SetLayout("Flow")
    checkboxGroup:SetFullWidth(true)

    checkboxGroup:AddChild(createColumnGroup(items[1]))
    checkboxGroup:AddChild(createColumnGroup(items[2]))
    
    mainGroup:AddChild(checkboxGroup)
    local updateUIWithModel = function()
        for _, cb in ipairs(checkBoxes) do
            if TableContains(valueTable, cb.text:GetText()) then
                cb:SetValue(true)
            else
                cb:SetValue(false)
            end          
        end
    end

    return {["uiFrame"] = mainGroup, ["updateUIWithModel"] = updateUIWithModel}
end
