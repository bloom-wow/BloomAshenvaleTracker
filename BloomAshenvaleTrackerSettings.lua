local settings = BloomAshenvaleTrackerSettings

local function OnSettingChanged(_, setting, value)
    local variable = setting:GetVariable()
    settings[variable] = value
end

local category = Settings.RegisterVerticalLayoutCategory("Bloom Ashenvale Tracker")

do
    local variable = "accountForLayers"
    local name = "Account for Layers"
    local tooltip = "Enable or disable accounting for layers in event tracking."
    local defaultValue = settings.accountForLayers

    local setting = Settings.RegisterAddOnSetting(category, name, variable, type(defaultValue), defaultValue)
    Settings.CreateCheckBox(category, setting, tooltip)
    Settings.SetOnValueChangedCallback(variable, OnSettingChanged)
end


Settings.RegisterAddOnCategory(category)
