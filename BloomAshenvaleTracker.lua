local BloomAshenvaleTracker = ...

BloomAshenvaleTrackerSettings = BloomAshenvaleTrackerSettings or {}

if BloomAshenvaleTrackerSettings.accountForLayers == nil then
    BloomAshenvaleTrackerSettings.accountForLayers = false
end

local settings = BloomAshenvaleTrackerSettings

_G.BloomAshenvaleTrackerSettings = settings

local layerInfo = {}
local lastUpdateTime = 0
local UPDATE_INTERVAL = 5
local ASHENVALE_MAP_ID = 1440
local ALLIANCE_WIDGET_ID = 5360
local HORDE_WIDGET_ID = 5361

-- Create main frame for display
local mainFrame = CreateFrame("Frame", "BloomAshenvaleTrackerMainFrame", UIParent, "BackdropTemplate")
local contentText

-- Local Function Definitions
local function SetupMainFrame(frame)
    frame:SetWidth(330)
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
    contentText:SetWidth(330)
    contentText:SetJustifyH("CENTER")
    contentText:SetJustifyV("CENTER")
    contentText:SetText("")
end

local function UpdateFrame()
    local displayText, frameHeight = "", 60
    local info = settings.accountForLayers and layerInfo or {default = layerInfo["default"]}

    for layer, layerData in pairs(info) do
        local timeString = date("%H:%M", layerData.lastUpdated)

        if settings.accountForLayers then
            displayText = displayText ..
                string.format("Layer %s: Alliance: %s, Horde: %s (Updated: %s)\n",
                    tostring(layer), layerData.allianceProgress, layerData.hordeProgress, timeString)
        else
            displayText = string.format("Alliance: %s, Horde: %s (Updated: %s)\n",
                layerData.allianceProgress, layerData.hordeProgress, timeString)
            break  -- Break after the first iteration as we only need one entry
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
        -- Send layer info only if layers are accounted for
        local message = string.format("%s|%s|%s", allianceProgress, hordeProgress, layer)
        C_ChatInfo.SendAddonMessage("BAT", message, "GUILD")
    end
    UpdateFrame()
end

local function HandleAddonMessage(self, event, ...)
    if event == "CHAT_MSG_ADDON" then
        local prefix, message, sender = ...
        if prefix == "BAT" then
            local allianceProgress, hordeProgress, layer = strsplit("|", message)
            local layerKey = settings.accountForLayers and layer or "default"
            layerInfo[layerKey] = {
                allianceProgress = allianceProgress,
                hordeProgress = hordeProgress,
                lastUpdated = time()
            }
            UpdateFrame()
        end
    end
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
eventFrame:RegisterEvent("CHAT_MSG_ADDON")
eventFrame:SetScript("OnEvent", HandleAddonMessage)

-- Slash Command
SLASH_BLOOMASHENVALETRACKER1 = "/bat"
SlashCmdList["BLOOMASHENVALETRACKER"] = ToggleFrameAndUpdate

-- Timers
C_Timer.NewTicker(UPDATE_INTERVAL, UpdateTimeDisplay)
C_Timer.NewTicker(UPDATE_INTERVAL * 2, SendProgress)
