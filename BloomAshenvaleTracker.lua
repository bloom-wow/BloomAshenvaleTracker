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
    for layer, info in pairs(layerInfo) do
        local timeDiff = time() - info.lastUpdated
        local timeString = timeDiff < 60 and string.format("%d sec ago", timeDiff) or
            string.format("%d min ago", math.floor(timeDiff / 60))

        if settings.accountForLayers then
            -- Display layer information when layer accounting is enabled
            displayText = displayText ..
                string.format("Layer %s: Alliance: %s, Horde: %s (%s)\n",
                    tostring(layer), info.allianceProgress, info.hordeProgress, timeString)
        else
            -- Display only faction progress and update time when layer accounting is disabled
            displayText = displayText ..
                string.format("Alliance: %s, Horde: %s (%s)\n",
                    info.allianceProgress, info.hordeProgress, timeString)
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
            -- Process the message if layer accounting is disabled or if the layer is not 0
            if not settings.accountForLayers or (tonumber(layer) and layer ~= 0) then
                -- Use a default key (e.g., "default") when layer accounting is disabled
                local layerKey = settings.accountForLayers and layer or 0
                layerInfo[layerKey] = {
                    allianceProgress = allianceProgress,
                    hordeProgress = hordeProgress,
                    lastUpdated = time()
                }
                UpdateFrame()
            end
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
