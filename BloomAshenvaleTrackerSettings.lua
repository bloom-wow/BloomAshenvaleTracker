local function OnSettingChanged(_, setting, value)
    local variable = setting:GetVariable()
    BloomAshenvaleTrackerSettings[variable] = value
    HandleAccountForLayersSettingChange()
end

-- This function initializes the settings UI
function InitializeSettingsUI()
    local category = Settings.RegisterVerticalLayoutCategory("Bloom Ashenvale Tracker")

    do
        local variable = "accountForLayers"
        local name = "Account for Layers"
        local tooltip = "Enable or disable accounting for layers in event tracking."

        -- Retrieve the current value from BloomAshenvaleTrackerSettings
        local currentValue = BloomAshenvaleTrackerSettings[variable]

        local setting = Settings.RegisterAddOnSetting(category, name, variable, type(currentValue), currentValue)
        Settings.CreateCheckBox(category, setting, tooltip)
        Settings.SetOnValueChangedCallback(variable, OnSettingChanged)
    end

    Settings.RegisterAddOnCategory(category)
end

function HandleAccountForLayersSettingChange()
    if BloomAshenvaleTrackerSettings.accountForLayers then
        -- If enabling layer accounting and there's data in the "default" key, move it to "0"
        if BloomAshenvaleTrackerLayerInfo["default"] then
            BloomAshenvaleTrackerLayerInfo["0"] = BloomAshenvaleTrackerLayerInfo["default"]
            BloomAshenvaleTrackerLayerInfo["default"] = nil
        end
    else
        -- If disabling layer accounting, merge data from "0" into "default"
        if BloomAshenvaleTrackerLayerInfo["0"] then
            BloomAshenvaleTrackerLayerInfo["default"] = BloomAshenvaleTrackerLayerInfo["0"]
            BloomAshenvaleTrackerLayerInfo["0"] = nil
        end
    end
    UpdateFrame()
    UpdateClearButtonVisibility()
end
