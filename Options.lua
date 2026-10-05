-- HiddenMicroMenuBagBar: settings panel. Only two dropdowns, no text entry,
-- so the native Settings.RegisterVerticalLayoutCategory API is enough here -
-- no need for a hand-built canvas panel like SwingTimerBuffTracking's
-- blocklist/allowlist required.

local Addon = HiddenMicroMenuBagBar

local Options = {}
Addon.Options = Options

local category

-- Dropdown contract on this client: the options argument passed to
-- Settings.CreateDropdown is called as optionsFunc() internally, so it must
-- be a function returning the entry list, never the list itself. Each entry
-- needs controlType = Settings.ControlType.Radio.
local function DropdownOptions(entries)
	local container = Settings.CreateControlTextContainer()
	for i = 1, #entries do
		container:Add(entries[i].value, entries[i].label, entries[i].tooltip, Settings.ControlType.Radio)
	end
	return container:GetData()
end

local MODE_ENTRIES = {
	{ value = "visible", label = "Visible", tooltip = "Always shown." },
	{ value = "mouseover", label = "On Mouseover", tooltip = "Hidden until you mouse over it." },
	{ value = "hidden", label = "Hidden", tooltip = "Always hidden. Still shown while Edit Mode is active, so you can reposition it." },
}

local function AddModeDropdown(db, dbKey, name, tooltip)
	local setting = Settings.RegisterProxySetting(category, dbKey, Settings.VarType.String, name, db[dbKey],
		function() return db[dbKey] end,
		function(value)
			db[dbKey] = value
			Addon.UpdateVisibility()
		end)
	local function GetOptions()
		return DropdownOptions(MODE_ENTRIES)
	end
	Settings.CreateDropdown(category, setting, GetOptions, tooltip)
end

function Options:Init()
	if category then
		return
	end
	local db = Addon.db

	category = Settings.RegisterVerticalLayoutCategory(Addon.name)
	Settings.RegisterAddOnCategory(category)

	AddModeDropdown(db, "bagBarMode", "Bag bar visibility", "Controls the Bags bar (bag slot buttons).")
	AddModeDropdown(db, "microMenuMode", "Micro menu visibility", "Controls the Micro Menu (Character/Spellbook/etc buttons).")
end

function Options:Open()
	if not category then
		return
	end
	-- OpenToCategory's argument has shifted between client builds; try the
	-- category object first and its numeric id as a fallback.
	if not pcall(Settings.OpenToCategory, category) then
		pcall(Settings.OpenToCategory, category.GetID and category:GetID() or nil)
	end
end
