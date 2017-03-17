-- Imports
local chooser			= require("hs.chooser")
local screen			= require("hs.screen")
local drawing			= require("hs.drawing")
local timer				= require("hs.timer")
local inspect			= require("hs.inspect")

local choices			= require("cp.choices")
local fcp				= require("cp.finalcutpro")
local dialog			= require("cp.dialog")
local tools				= require("cp.tools")
local metadata			= require("cp.metadata")

local log				= require("hs.logger").new("transitions")

-- Constants
local MAX_SHORTCUTS = 5


-- Effects Action
local action = {}
local mod = {}

function action.init(actionmanager)
	action._manager = actionmanager
	action._manager.addAction(action)
end

function action.id()
	return "transition"
end

function action.setEnabled(value)
	metadata.set(action.id().."ActionEnabled", value)
	action._manager.refresh()
end

function action.isEnabled()
	return metadata.get(action.id().."ActionEnabled", true)
end

function action.toggleEnabled()
	action.setEnabled(not action.isEnabled())
end

function action.choices()
	if not action._choices then
		action._choices = choices.new(action.id())
		--------------------------------------------------------------------------------
		-- Transition List:
		--------------------------------------------------------------------------------

		local list = mod.getTransitions()
		if list ~= nil and next(list) ~= nil then
			for i,name in ipairs(list) do
				local params = { name = name }
				action._choices:add(name)
					:subText(i18n("transition_group"))
					:params(params)
					:id(action.getId(params))
			end
		end
	end
	return action._choices
end

function action.getId(params)
	return action.id() .. ":" .. params.name
end

function action.execute(params)
	if params and params.name then
		mod.apply(params.name)
		return true
	end
	return false
end

function action.reset()
	action._choices = nil
end

-- The Module

function mod.getShortcuts()
	return metadata.get(fcp:getCurrentLanguage() .. ".transitionsShortcuts", {})
end

function mod.setShortcut(number, value)
	assert(number >= 1 and number <= MAX_SHORTCUTS)
	local shortcuts = mod.getShortcuts()
	shortcuts[number] = value
	metadata.set(fcp:getCurrentLanguage() .. ".transitionsShortcuts", shortcuts)
end

function mod.getTransitions()
	return metadata.get(fcp:getCurrentLanguage() .. ".allTransitions")
end

--------------------------------------------------------------------------------
-- TRANSITIONS SHORTCUT PRESSED:
-- The shortcut may be a number from 1-5, in which case the 'assigned' shortcut is applied,
-- or it may be the name of the transition to apply in the current FCPX language.
--------------------------------------------------------------------------------
function mod.apply(shortcut)

	--------------------------------------------------------------------------------
	-- Get settings:
	--------------------------------------------------------------------------------
	local currentLanguage = fcp:getCurrentLanguage()

	if type(shortcut) == "number" then
		shortcut = mod.getShortcuts()[shortcut]
	end

	if shortcut == nil then
		dialog.displayMessage(i18n("noTransitionShortcut"))
		return "Fail"
	end

	--------------------------------------------------------------------------------
	-- Save the Effects Browser layout:
	--------------------------------------------------------------------------------
	local effects = fcp:effects()
	local effectsLayout = effects:saveLayout()

	--------------------------------------------------------------------------------
	-- Get Transitions Browser:
	--------------------------------------------------------------------------------
	local transitions = fcp:transitions()
	local transitionsShowing = transitions:isShowing()
	local transitionsLayout = transitions:saveLayout()

	--------------------------------------------------------------------------------
	-- Make sure panel is open:
	--------------------------------------------------------------------------------
	transitions:show()

	--------------------------------------------------------------------------------
	-- Make sure "Installed Transitions" is selected:
	--------------------------------------------------------------------------------
	transitions:showInstalledTransitions()

	--------------------------------------------------------------------------------
	-- Make sure there's nothing in the search box:
	--------------------------------------------------------------------------------
	transitions:search():clear()

	--------------------------------------------------------------------------------
	-- Click 'All':
	--------------------------------------------------------------------------------
	transitions:showAllTransitions()

	--------------------------------------------------------------------------------
	-- Perform Search:
	--------------------------------------------------------------------------------
	transitions:search():setValue(shortcut)

	--------------------------------------------------------------------------------
	-- Get the list of matching transitions
	--------------------------------------------------------------------------------
	local matches = transitions:currentItemsUI()
	if not matches or #matches == 0 then
		--------------------------------------------------------------------------------
		-- If Needed, Search Again Without Text Before First Dash:
		--------------------------------------------------------------------------------
		local index = string.find(shortcut, "-")
		if index ~= nil then
			local trimmedShortcut = string.sub(shortcut, index + 2)
			transitions:search():setValue(trimmedShortcut)

			matches = transitions:currentItemsUI()
			if not matches or #matches == 0 then
				dialog.displayErrorMessage("Unable to find a transition called '"..shortcut.."'.\n\nError occurred in transitionsShortcut().")
				return "Fail"
			end
		end
	end

	local transition = matches[1]

	--------------------------------------------------------------------------------
	-- Apply the selected Transition:
	--------------------------------------------------------------------------------
	mod.touchbar.hide()

	transitions:applyItem(transition)

	-- TODO: HACK: This timer exists to  work around a mouse bug in Hammerspoon Sierra
	timer.doAfter(0.1, function()
		mod.touchbar.show()

		transitions:loadLayout(transitionsLayout)
		if effectsLayout then effects:loadLayout(effectsLayout) end
		if not transitionsShowing then transitions:hide() end
	end)

end

--------------------------------------------------------------------------------
-- ASSIGN TRANSITIONS SHORTCUT:
--------------------------------------------------------------------------------
function mod.assignTransitionsShortcut(whichShortcut)

	--------------------------------------------------------------------------------
	-- Was Final Cut Pro Open?
	--------------------------------------------------------------------------------
	local wasFinalCutProOpen = fcp:isFrontmost()

	--------------------------------------------------------------------------------
	-- Get settings:
	--------------------------------------------------------------------------------
	local currentLanguage 			= fcp:getCurrentLanguage()
	local transitionsListUpdated 	= mod.isTransitionsListUpdated()
	local allTransitions 			= mod.getTransitions()

	--------------------------------------------------------------------------------
	-- Error Checking:
	--------------------------------------------------------------------------------
	if not transitionsListUpdated
	   or allTransitions == nil
	   or next(allTransitions) == nil then
		dialog.displayMessage(i18n("assignTransitionsShortcutError"))
		return "Failed"
	end

	--------------------------------------------------------------------------------
	-- Transitions List:
	--------------------------------------------------------------------------------
	local choices = {}
	if allTransitions ~= nil and next(allTransitions) ~= nil then
		for i=1, #allTransitions do
			item = {
				["text"] = allTransitions[i],
				["subText"] = "Transition",
			}
			table.insert(choices, 1, item)
		end
	end

	--------------------------------------------------------------------------------
	-- Sort everything:
	--------------------------------------------------------------------------------
	table.sort(choices, function(a, b) return a.text < b.text end)

	--------------------------------------------------------------------------------
	-- Setup Chooser:
	--------------------------------------------------------------------------------
	local theChooser = nil
	theChooser = chooser.new(function(result)
		theChooser:hide()
		if result ~= nil then
			--------------------------------------------------------------------------------
			-- Save the selection:
			--------------------------------------------------------------------------------
			mod.setShortcut(whichShortcut, result.text)
		end

		--------------------------------------------------------------------------------
		-- Put focus back in Final Cut Pro:
		--------------------------------------------------------------------------------
		if wasFinalCutProOpen then fcp:launch() end
	end)

	theChooser:bgDark(true):choices(choices)

	--------------------------------------------------------------------------------
	-- Allow for Reduce Transparency:
	--------------------------------------------------------------------------------
	if screen.accessibilitySettings()["ReduceTransparency"] then
		theChooser:fgColor(nil)
		          :subTextColor(nil)
	else
		theChooser:fgColor(drawing.color.x11.snow)
 		          :subTextColor(drawing.color.x11.snow)
	end

	--------------------------------------------------------------------------------
	-- Show Chooser:
	--------------------------------------------------------------------------------
	theChooser:show()
end

--------------------------------------------------------------------------------
-- GET LIST OF TRANSITIONS:
--------------------------------------------------------------------------------
function mod.updateTransitionsList()

	--------------------------------------------------------------------------------
	-- Make sure Final Cut Pro is active:
	--------------------------------------------------------------------------------
	fcp:launch()

	--------------------------------------------------------------------------------
	-- Save the layout of the Effects panel, in case we switch away...
	--------------------------------------------------------------------------------
	local effects = fcp:effects()
	local effectsLayout = nil
	if effects:isShowing() then
		effectsLayout = effects:saveLayout()
	end

	--------------------------------------------------------------------------------
	-- Make sure Transitions panel is open:
	--------------------------------------------------------------------------------
	local transitions = fcp:transitions()
	local transitionsShowing = transitions:isShowing()
	if not transitions:show():isShowing() then
		dialog.displayErrorMessage("Unable to activate the Transitions panel.\n\nError occurred in updateTransitionsList().")
		return "Fail"
	end

	local transitionsLayout = transitions:saveLayout()

	--------------------------------------------------------------------------------
	-- Make sure "Installed Transitions" is selected:
	--------------------------------------------------------------------------------
	transitions:showInstalledTransitions()

	--------------------------------------------------------------------------------
	-- Make sure there's nothing in the search box:
	--------------------------------------------------------------------------------
	transitions:search():clear()

	--------------------------------------------------------------------------------
	-- Make sure the sidebar is visible:
	--------------------------------------------------------------------------------
	local sidebar = transitions:sidebar()

	transitions:showSidebar()

	if not sidebar:isShowing() then
		dialog.displayErrorMessage("Unable to activate the Transitions sidebar.\n\nError occurred in updateTransitionsList().")
		return "Fail"
	end

	--------------------------------------------------------------------------------
	-- Click 'All' in the sidebar:
	--------------------------------------------------------------------------------
	transitions:showAllTransitions()

	--------------------------------------------------------------------------------
	-- Get list of All Transitions:
	--------------------------------------------------------------------------------
	local allTransitions = transitions:getCurrentTitles()
	if allTransitions == nil then
		dialog.displayErrorMessage("Unable to get list of all transitions.\n\nError occurred in updateTransitionsList().")
		return "Fail"
	end

	--------------------------------------------------------------------------------
	-- Restore Effects and Transitions Panels:
	--------------------------------------------------------------------------------
	transitions:loadLayout(transitionsLayout)
	if effectsLayout then effects:loadLayout(effectsLayout) end
	if not transitionsShowing then transitions:hide() end

	--------------------------------------------------------------------------------
	-- Save Results to Settings:
	--------------------------------------------------------------------------------
	local currentLanguage = fcp:getCurrentLanguage()
	metadata.set(currentLanguage .. ".allTransitions", allTransitions)
	metadata.set(currentLanguage .. ".transitionsListUpdated", true)
	action.reset()
end

function mod.isTransitionsListUpdated()
	return metadata.get(fcp:getCurrentLanguage() .. ".transitionsListUpdated", false)
end

-- The Plugin
local PRIORITY = 2000

local plugin = {}

plugin.dependencies = {
	["cp.plugins.menu.timeline.assignshortcuts"]	= "automation",
	["cp.plugins.commands.fcpx"]					= "fcpxCmds",
	["cp.plugins.os.touchbar"]						= "touchbar",
	["cp.plugins.actions.actionmanager"]			= "actionmanager",
}

function plugin.init(deps)
	local fcpxRunning = fcp:isRunning()
	mod.touchbar = deps.touchbar

	-- Register the Action
	action.init(deps.actionmanager)

	-- The 'Assign Shortcuts' menu
	local menu = deps.automation:addMenu(PRIORITY, function() return i18n("assignTransitionsShortcuts") end)

	menu:addItems(1000, function()
		--------------------------------------------------------------------------------
		-- Shortcuts:
		--------------------------------------------------------------------------------
		local listUpdated 	= mod.isTransitionsListUpdated()
		local shortcuts		= mod.getShortcuts()

		local items = {}

		for i = 1, MAX_SHORTCUTS do
			local shortcutName = shortcuts[i] or i18n("unassignedTitle")
			items[i] = { title = i18n("transitionShortcutTitle", { number = i, title = shortcutName}), fn = function() mod.assignTransitionsShortcut(i) end,	disabled = not listUpdated }
		end

		return items
	end)

	-- Commands
	local fcpxCmds = deps.fcpxCmds
	for i = 1, MAX_SHORTCUTS do
		fcpxCmds:add("cpTransitions"..tools.numberToWord(i)):whenActivated(function() mod.apply(i) end)
	end

	return mod
end

return plugin