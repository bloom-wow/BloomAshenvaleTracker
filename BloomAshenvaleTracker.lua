local BloomAshenvaleTracker = ...

BloomAshenvaleTrackerSettings = BloomAshenvaleTrackerSettings or {}

if BloomAshenvaleTrackerSettings.accountForLayers == nil then
    BloomAshenvaleTrackerSettings.accountForLayers = false
end

if BloomAshenvaleTrackerSettings.shareInGuild == nil then
    BloomAshenvaleTrackerSettings.shareInGuild = true
end

if BloomAshenvaleTrackerSettings.shareInParty == nil then
    BloomAshenvaleTrackerSettings.shareInParty = true
end

if BloomAshenvaleTrackerSettings.shareInRaid == nil then
    BloomAshenvaleTrackerSettings.shareInRaid = true
end

local settings = BloomAshenvaleTrackerSettings

_G.BloomAshenvaleTrackerSettings = settings

BloomAshenvaleTrackerLayerInfo = {}
local lastUpdateTime = 0
local UPDATE_INTERVAL = 5
local ASHENVALE_MAP_ID = 1440
local ALLIANCE_WIDGET_ID = 5360
local HORDE_WIDGET_ID = 5361

-- Create main frame for display
local mainFrame = CreateFrame("Frame", "BloomAshenvaleTrackerMainFrame", UIParent, "BackdropTemplate")
local contentText

-- Create a clear button
local clearButton = CreateFrame("Button", "BloomAshenvaleTrackerClearButton", mainFrame, "UIPanelButtonTemplate")
clearButton:SetSize(80, 22)                                -- Width, Height
clearButton:SetPoint("BOTTOM", mainFrame, "BOTTOM", 0, 10) -- Position it at the bottom of the mainFrame
clearButton:SetText("Clear")
clearButton:Hide()                                         -- Initially hide the button

-- Function to update the visibility of the clear button
UpdateClearButtonVisibility = function()
    if settings.accountForLayers and next(BloomAshenvaleTrackerLayerInfo) ~= nil then
        clearButton:Show()
    else
        clearButton:Hide()
    end
end

local function ClearEntries()
    wipe(BloomAshenvaleTrackerLayerInfo) -- Clears the BloomAshenvaleTrackerLayerInfo table
    UpdateFrame()                        -- Update the frame to reflect the cleared data
    UpdateClearButtonVisibility()        -- Update the visibility of the clear button
end

clearButton:SetScript("OnClick", ClearEntries)

-- Local Function Definitions
local function SetupMainFrame(frame)
    frame:SetWidth(360)
    frame:SetPoint("CENTER")
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 8, right = 8, top = 8, bottom = 8 }
    })
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

    local titleText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    titleText:SetPoint("CENTER", frame, "TOP", 0, -20)
    titleText:SetText("Bloom Ashenvale Tracker")

    contentText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    contentText:SetPoint("CENTER", frame, "CENTER", 0, 0)
    contentText:SetWidth(350)
    contentText:SetJustifyH("CENTER")
    contentText:SetJustifyV("CENTER")
    contentText:SetText("")
end

function UpdateFrame()
    local displayText, frameHeight = "", 60
    local info = settings.accountForLayers and BloomAshenvaleTrackerLayerInfo or
    { default = BloomAshenvaleTrackerLayerInfo["default"] }

    for layer, layerData in pairs(info) do
        local timeString = date("%H:%M", layerData.lastUpdated)

        if settings.accountForLayers then
            displayText = displayText ..
                string.format("Layer %s: Alliance: %s, Horde: %s (Updated: %s)\n",
                    tostring(layer), layerData.allianceProgress, layerData.hordeProgress, timeString)
        else
            displayText = string.format("Alliance: %s, Horde: %s (Updated: %s)\n",
                layerData.allianceProgress, layerData.hordeProgress, timeString)
            break -- Break after the first iteration as we only need one entry
        end

        frameHeight = frameHeight + 20
    end

    mainFrame:SetHeight(frameHeight)
    contentText:SetText(displayText)
end

local function UpdateTimeDisplay()
    if time() - lastUpdateTime >= UPDATE_INTERVAL then
        lastUpdateTime = time()
        UpdateFrame()
    end
end

local function GetEventProgress()
    local allianceProgress = C_UIWidgetManager.GetIconAndTextWidgetVisualizationInfo(ALLIANCE_WIDGET_ID).text
    local hordeProgress = C_UIWidgetManager.GetIconAndTextWidgetVisualizationInfo(HORDE_WIDGET_ID).text
    local layer = settings.accountForLayers and (_G["NWB_CurrentLayer"] or 0) or 0
    return allianceProgress, hordeProgress, layer
end

local function SendProgress()
    if C_Map.GetBestMapForUnit("player") == ASHENVALE_MAP_ID then
        local allianceProgress, hordeProgress, layer = GetEventProgress()
        local message = string.format("%s|%s|%s", allianceProgress, hordeProgress, layer)

        if BloomAshenvaleTrackerSettings.shareInGuild and IsInGuild() then
            C_ChatInfo.SendAddonMessage("BAT", message, "GUILD")
        end

        if BloomAshenvaleTrackerSettings.shareInParty and IsInGroup(LE_PARTY_CATEGORY_HOME) and not IsInRaid(LE_PARTY_CATEGORY_HOME) then
            C_ChatInfo.SendAddonMessage("BAT", message, "PARTY")
        end

        if BloomAshenvaleTrackerSettings.shareInRaid and IsInRaid(LE_PARTY_CATEGORY_HOME) then
            C_ChatInfo.SendAddonMessage("BAT", message, "RAID")
        end

        UpdateFrame()
    end
end

local function HandleAddonMessage(self, event, ...)
    if event == "ADDON_LOADED" then
        local addonName = ...
        if addonName == "BloomAshenvaleTracker" then
            -- Initialize or update settings from SavedVariables
            BloomAshenvaleTrackerSettings = BloomAshenvaleTrackerSettings or {}
            settings = BloomAshenvaleTrackerSettings

            -- Initialize the settings UI
            InitializeSettingsUI()

            -- Update Clear Button visibility based on the loaded settings
            UpdateClearButtonVisibility()

            BloomAshenvaleTrackerLayerInfo = BloomAshenvaleTrackerLayerInfo or {}

            -- Unregister the ADDON_LOADED event
            self:UnregisterEvent("ADDON_LOADED")
        end
    elseif event == "CHAT_MSG_ADDON" then
        local prefix, message, sender = ...
        if prefix == "BAT" then
            local allianceProgress, hordeProgress, layer = strsplit("|", message)
            local layerKey = settings.accountForLayers and layer or "default"
            BloomAshenvaleTrackerLayerInfo[layerKey] = {
                allianceProgress = allianceProgress,
                hordeProgress = hordeProgress,
                lastUpdated = time()
            }
            UpdateFrame()
        end
    end
end

local function RemoveDuplicateZeroLayerEntries()
    local entriesToRemove = {}

    -- Iterate over all entries
    for layer, layerData in pairs(BloomAshenvaleTrackerLayerInfo) do
        -- Skip the 'default' layer
        if layer ~= "default" then
            -- Compare with other layers
            for otherLayer, otherLayerData in pairs(BloomAshenvaleTrackerLayerInfo) do
                -- Check if it's not the same layer and not the 'default' layer
                if layer ~= otherLayer and otherLayer ~= "default" then
                    -- Check if both layers have the same progress values
                    if layerData.allianceProgress == otherLayerData.allianceProgress and
                        layerData.hordeProgress == otherLayerData.hordeProgress then
                        -- Mark layer 0 for removal if it's one of the duplicates
                        if layer == "0" or otherLayer == "0" then
                            entriesToRemove[layer == "0" and layer or otherLayer] = true
                        end
                    end
                end
            end
        end
    end

    -- Remove marked entries
    for layer, _ in pairs(entriesToRemove) do
        BloomAshenvaleTrackerLayerInfo[layer] = nil
    end

    -- Update the UI if necessary
    UpdateFrame()
end

local function ToggleFrameAndUpdate()
    if mainFrame:IsShown() then
        mainFrame:Hide()
    else
        mainFrame:Show()
        UpdateFrame()
    end
end

-- Setup main frame
SetupMainFrame(mainFrame)

-- Register Addon
local addonRegisteredSuccessfully = C_ChatInfo.RegisterAddonMessagePrefix("BAT")
print(addonRegisteredSuccessfully and "BloomAshenvaleTracker started successfully!" or
    "BloomAshenvaleTracker failed to start successfully!")

-- Event Handling
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("CHAT_MSG_ADDON")
eventFrame:SetScript("OnEvent", HandleAddonMessage)

-- Slash Command
SLASH_BLOOMASHENVALETRACKER1 = "/bat"
SlashCmdList["BLOOMASHENVALETRACKER"] = ToggleFrameAndUpdate

-- Timers
C_Timer.NewTicker(UPDATE_INTERVAL, UpdateTimeDisplay)
C_Timer.NewTicker(UPDATE_INTERVAL * 2, SendProgress)
C_Timer.NewTicker(UPDATE_INTERVAL * 3, RemoveDuplicateZeroLayerEntries)
