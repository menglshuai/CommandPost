-- Includes
local touchbar 									= require("hs._asm.touchbar")
local settings									= require("hs.settings")
local eventtap									= require("hs.eventtap")
local fcp										= require("hs.finalcutpro")
local dialog									= require("hs.fcpxhacks.modules.dialog")
local log										= require("hs.logger").new("touchbar")

-- Constants

local PRIORITY			= 7000

local LOCATION_MOUSE	= "Mouse"
local LOCATION_TIMELINE	= "TimelineTopCentre"

-- The Module
local mod = {}

function mod.isSupported()
	return touchbar.supported()
end

function mod.getLastLocation()
	settings.get("fcpxHacks.lastTouchBarLocation")
end

function mod.setLastLocation(value)
	settings.set("fcpxHacks.lastTouchBarLocation", value)
end

function mod.getLocation()
	return settings.get("fcpxHacks.displayTouchBarLocation") or LOCATION_MOUSE
end

function mod.setLocation(value)
	settings.set("fcpxHacks.displayTouchBarLocation", value)
	mod.update()
end

--------------------------------------------------------------------------------
-- SET TOUCH BAR LOCATION:
--------------------------------------------------------------------------------
function mod.updateLocation()

	--------------------------------------------------------------------------------
	-- Get Settings:
	--------------------------------------------------------------------------------
	local displayTouchBarLocation = mod.getLocation()

	--------------------------------------------------------------------------------
	-- Show Touch Bar at Top Centre of Timeline:
	--------------------------------------------------------------------------------
	local timeline = fcp:timeline()
	if displayTouchBarLocation == LOCATION_TIMELINE and timeline:isShowing() then
		--------------------------------------------------------------------------------
		-- Position Touch Bar to Top Centre of Final Cut Pro Timeline:
		--------------------------------------------------------------------------------
		local viewFrame = timeline:contents():viewFrame()

		local topLeft = {x = viewFrame.x + viewFrame.w/2 - mod.touchBarWindow:getFrame().w/2, y = viewFrame.y + 20}
		mod.touchBarWindow:topLeft(topLeft)
	else
		--------------------------------------------------------------------------------
		-- Position Touch Bar to Mouse Pointer Location:
		--------------------------------------------------------------------------------
		mod.touchBarWindow:atMousePosition()

	end

	--------------------------------------------------------------------------------
	-- Save last Touch Bar Location to Settings:
	--------------------------------------------------------------------------------
	mod.setLastLocation(mod.touchBarWindow:topLeft())
end

function mod.isEnabled()
	return settings.get("fcpxHacks.displayTouchBar") or false
end

function mod.setEnabled(value)
	settings.set("fcpxHacks.displayTouchBar", value)
	mod.update()
end

--------------------------------------------------------------------------------
-- TOGGLE TOUCH BAR:
--------------------------------------------------------------------------------
function mod.toggleEnabled()

	--------------------------------------------------------------------------------
	-- Check for compatibility:
	--------------------------------------------------------------------------------
	if not mod.isSupported() then
		dialog.displayMessage(i18n("touchBarError"))
		return "Fail"
	end

	--------------------------------------------------------------------------------
	-- Get Settings:
	--------------------------------------------------------------------------------
	mod.setEnabled(not mod.isEnabled())

	--------------------------------------------------------------------------------
	-- Toggle Touch Bar:
	--------------------------------------------------------------------------------
	mod.update()
end

function mod.update()
	if mod.isEnabled() then
		mod.show()
	else
		mod.hide()
	end
end

--------------------------------------------------------------------------------
-- SHOW TOUCH BAR:
--------------------------------------------------------------------------------
function mod.show()
	--------------------------------------------------------------------------------
	-- Check if we need to show the Touch Bar:
	--------------------------------------------------------------------------------
	if fcp:isFrontmost() and mod.isSupported() and mod.isEnabled() then
		mod.updateLocation()
		mod.touchBarWindow:show()
	end
end

--------------------------------------------------------------------------------
-- HIDE TOUCH BAR:
--------------------------------------------------------------------------------
function mod.hide()
	if mod.isSupported() then mod.touchBarWindow:hide() end
end

--------------------------------------------------------------------------------
-- TOUCH BAR WATCHER:
--------------------------------------------------------------------------------
local function touchbarWatcher(obj, message)
	if message == "didEnter" then
        mod.mouseInsideTouchbar = true
    elseif message == "didExit" then
        mod.mouseInsideTouchbar = false

        --------------------------------------------------------------------------------
	    -- Just in case we got here before the eventtap returned the Touch Bar to normal:
	    --------------------------------------------------------------------------------
        mod.touchBarWindow:movable(false)
        mod.touchBarWindow:acceptsMouseEvents(true)
		mod.setLastLocation(mod.touchBarWindow:topLeft())
    end
end

function mod.init()
	if mod.isSupported() then
		--------------------------------------------------------------------------------
		-- New Touch Bar:
		--------------------------------------------------------------------------------
		mod.touchBarWindow = touchbar.new()

		--------------------------------------------------------------------------------
		-- Touch Bar Watcher:
		--------------------------------------------------------------------------------
		mod.touchBarWindow:setCallback(touchbarWatcher)

		--------------------------------------------------------------------------------
		-- Get last Touch Bar Location from Settings:
		--------------------------------------------------------------------------------
		local lastTouchBarLocation = mod.getLastLocation()
		if lastTouchBarLocation ~= nil then	mod.touchBarWindow:topLeft(lastTouchBarLocation) end

		--------------------------------------------------------------------------------
		-- Draggable Touch Bar:
		--------------------------------------------------------------------------------
		local events = eventtap.event.types
		touchbarKeyboardWatcher = eventtap.new({events.flagsChanged, events.keyDown, events.leftMouseDown}, function(ev)
			if mod.mouseInsideTouchbar then
				if ev:getType() == events.flagsChanged and ev:getRawEventData().CGEventData.flags == 524576 then
					mod.touchBarWindow:backgroundColor{ red = 1 }
								  	:movable(true)
								  	:acceptsMouseEvents(false)
				elseif ev:getType() ~= events.leftMouseDown then
					mod.touchBarWindow:backgroundColor{ white = 0 }
								  :movable(false)
								  :acceptsMouseEvents(true)
					mod.setLastLocation(mod.touchBarWindow:topLeft())
				end
			end
			return false
		end):start()

		mod.update()
	end
end

-- The Plugin
local plugin = {}

plugin.dependencies = {
	["hs.fcpxhacks.plugins.menu.preferences"]	= "prefs",
	["hs.fcpxhacks.plugins.commands.fcpx"]		= "fcpxCmds",
}

function plugin.init(deps)
	mod.init()

	-- Disable/Enable the touchbar when the Command Editor/etc is open
	fcp:commandEditor():watch({
		show		= function() mod.hide() end,
		hide		= function() mod.show() end,
	})
	fcp:mediaImport():watch({
		show		= function() mod.hide() end,
		hide		= function() mod.show() end,
	})
	fcp:watch({
		active		= function() mod.show() end,
		inactive	= function() mod.hide() end,
		move		= function() mod.update() end,
	})

	-- Menu items
	-- if mod.isSupported() then
		local section = deps.prefs:addSection(PRIORITY)
		section:addSeparator(1000)
		section:addMenu(2000, function() return i18n("touchBar") end)
			:addItems(1000, function()
				local location = mod.getLocation()
				return {
					{ title = i18n("enableTouchBar"), 		fn = mod.toggleEnabled, 								checked = mod.isEnabled(),					disabled = not mod.isSupported() },
					{ title = "-" },
					{ title = string.upper(i18n("touchBarLocation")),		disabled = true },
					{ title = i18n("mouseLocation"), 		fn = function() mod.setLocation(LOCATION_MOUSE) end,	checked = location == LOCATION_MOUSE, 		disabled = not mod.isSupported() },
					{ title = i18n("topCentreOfTimeline"), 	fn = function() mod.setLocation(LOCATION_TIMELINE) end,	checked = location == LOCATION_TIMELINE,	disabled = not mod.isSupported() },
					{ title = "-" },
					{ title = i18n("touchBarTipOne"), 		disabled = true },
					{ title = i18n("touchBarTipTwo"), 		disabled = true },
				}
			end)
		section:addSeparator(3000)
	-- end

	-- Commands
	deps.fcpxCmds:add("FCPXHackToggleTouchBar")
		:activatedBy():ctrl():option():cmd("z")
		:whenActivated(function() mod.toggleEnabled() end)

	return mod
end

return plugin