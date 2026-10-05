-- HiddenMicroMenuBagBar: MicroMenu and BagsBar (the micro-menu buttons and
-- bag slot buttons, confirmed real global names on this client) aren't part
-- of Edit Mode's hideable systems. Each has its own mode - visible/mouseover/
-- hidden. SetAlpha keeps them mouse-interactive even at 0 (unlike Hide()),
-- so mouseover mode still reads real cursor position. Edit Mode is exempted
-- from all three modes, via EditModeManagerFrame:IsEditModeActive(), so both
-- bars stay visible while repositioning things even if set to Hidden.
--
-- Neither frame has mouse interaction enabled on itself (confirmed against
-- their real XML - only their child buttons do, and MicroMenu's template is
-- a layout-only GridLayoutFrame), so OnEnter/OnLeave never fire on them.
-- IsMouseOver() is polled on a timer instead of waiting for those events.

local ADDON_NAME = "HiddenMicroMenuBagBar"

HiddenMicroMenuBagBar = {}
local Addon = HiddenMicroMenuBagBar
Addon.name = ADDON_NAME

local DEFAULTS = {
	bagBarMode = "mouseover", -- "visible" | "mouseover" | "hidden"
	microMenuMode = "mouseover",
}
Addon.DEFAULTS = DEFAULTS

local function ApplyDefaults(db, defaults)
	for key, value in pairs(defaults) do
		if db[key] == nil then
			db[key] = value
		end
	end
end

local db -- HiddenMicroMenuBagBarDB, set on ADDON_LOADED

local function ComputeAlpha(mode, frameObj)
	if EditModeManagerFrame and EditModeManagerFrame:IsEditModeActive() then
		return 1
	elseif mode == "visible" then
		return 1
	elseif mode == "hidden" then
		return 0
	else -- "mouseover"
		return (frameObj and frameObj:IsMouseOver()) and 1 or 0
	end
end

local function UpdateVisibility()
	if not db then
		return
	end
	if MicroMenu then
		MicroMenu:SetAlpha(ComputeAlpha(db.microMenuMode, MicroMenu))
	end
	if BagsBar then
		BagsBar:SetAlpha(ComputeAlpha(db.bagBarMode, BagsBar))
	end
end
Addon.UpdateVisibility = UpdateVisibility

local POLL_INTERVAL = 0.1
local elapsed = 0

local driver = CreateFrame("Frame")
driver:SetScript("OnUpdate", function(_, delta)
	elapsed = elapsed + delta
	if elapsed < POLL_INTERVAL then
		return
	end
	elapsed = 0
	UpdateVisibility()
end)

local initialized = false

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:SetScript("OnEvent", function(_, event, arg1)
	if event == "ADDON_LOADED" then
		if arg1 == ADDON_NAME then
			HiddenMicroMenuBagBarDB = HiddenMicroMenuBagBarDB or {}
			ApplyDefaults(HiddenMicroMenuBagBarDB, DEFAULTS)
			db = HiddenMicroMenuBagBarDB
			Addon.db = db
			if Addon.Options then
				Addon.Options:Init()
			end
		end
		return
	end

	-- PLAYER_ENTERING_WORLD
	if not initialized then
		initialized = true
		if EditModeManagerFrame then
			hooksecurefunc(EditModeManagerFrame, "EnterEditMode", UpdateVisibility)
			hooksecurefunc(EditModeManagerFrame, "ExitEditMode", UpdateVisibility)
		end
	end

	UpdateVisibility()
end)
