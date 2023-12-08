local BloomAshenvaleTracker = ...

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
    for layer, info in pairs(layerInfo) do
        if layer and layer ~= 0 then
            local timeDiff = time() - info.lastUpdated
            local timeString = timeDiff < 60 and string.format("%d sec ago", timeDiff) or string.format("%d min ago", math.floor(timeDiff / 60))
            displayText = displayText .. string.format("Layer %s: Alliance: %s, Horde: %s (%s)\n", layer, info.allianceProgress, info.hordeProgress, timeString)
            frameHeight = frameHeight + 20
        end
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
    local layer = _G["NWB_CurrentLayer"] or 0
    return allianceProgress, hordeProgress, layer
end

local function SendProgress()
    if C_Map.GetBestMapForUnit("player") == ASHENVALE_MAP_ID then
        local allianceProgress, hordeProgress, layer = GetEventProgress()
        if layer and layer ~= 0 then
            local message = string.format("%s|%s|%s", allianceProgress, hordeProgress, layer)
            C_ChatInfo.SendAddonMessage("BAT", message, "GUILD")
        end
    end
    UpdateFrame()
end

local function HandleAddonMessage(self, event, ...)
    if event == "CHAT_MSG_ADDON" then
        local prefix, message, sender = ...
        if prefix == "BAT" then
            local allianceProgress, hordeProgress, layer = strsplit("|", message)
            if tonumber(layer) and layer ~= 0 then
                layerInfo[layer] = { allianceProgress = allianceProgress, hordeProgress = hordeProgress, lastUpdated = time() }
                UpdateFrame()
            end
        end
    end
end

local function ToggleFrameAndUpdate(msg)
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
print(addonRegisteredSuccessfully and "BloomAshenvaleTracker started successfully!" or "BloomAshenvaleTracker failed to start successfully!")

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
