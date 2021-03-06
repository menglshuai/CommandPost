--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   C O L O R    B O A R D    P L U G I N                    --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- EXTENSIONS:
--------------------------------------------------------------------------------
local timer								= require("hs.timer")
local eventtap							= require("hs.eventtap")

local fcp								= require("cp.finalcutpro")
local tools								= require("cp.tools")
local dialog							= require("cp.dialog")

local log								= require("hs.logger").new("colorboard")

--------------------------------------------------------------------------------
-- THE MODULE:
--------------------------------------------------------------------------------
local mod = {}

	--------------------------------------------------------------------------------
	-- COLOR BOARD - PUCK SELECTION:
	--------------------------------------------------------------------------------
	function mod.selectPuck(aspect, property, whichDirection)

		--------------------------------------------------------------------------------
		-- Show the Color Board with the correct panel
		--------------------------------------------------------------------------------
		local colorBoard = fcp:colorBoard()

		--------------------------------------------------------------------------------
		-- Show the Color Board if it's hidden:
		--------------------------------------------------------------------------------
		if not colorBoard:isShowing() then colorBoard:show() end

		if not colorBoard:isActive() then
			dialog.displayNotification(i18n("pleaseSelectSingleClipInTimeline"))
			return "Failed"
		end

		--------------------------------------------------------------------------------
		-- If a Direction is specified:
		--------------------------------------------------------------------------------
		if whichDirection ~= nil then

			--------------------------------------------------------------------------------
			-- Get shortcut key from plist, press and hold if required:
			--------------------------------------------------------------------------------
			mod.releaseColorBoardDown = false
			timer.doUntil(function() return mod.releaseColorBoardDown end, function()
				if whichDirection == "up" then
					colorBoard:shiftPercentage(aspect, property, 1)
				elseif whichDirection == "down" then
					colorBoard:shiftPercentage(aspect, property, -1)
				elseif whichDirection == "left" then
					colorBoard:shiftAngle(aspect, property, -1)
				elseif whichDirection == "right" then
					colorBoard:shiftAngle(aspect, property, 1)
				end
			end, eventtap.keyRepeatInterval())
		else -- just select the puck
			colorBoard:selectPuck(aspect, property)
		end
	end

	--------------------------------------------------------------------------------
	-- COLOR BOARD - RELEASE KEYPRESS:
	--------------------------------------------------------------------------------
	local function colorBoardSelectPuckRelease()
		mod.releaseColorBoardDown = true
	end

	--------------------------------------------------------------------------------
	-- COLOR BOARD - PUCK CONTROL VIA MOUSE:
	--------------------------------------------------------------------------------
	function mod.mousePuck(aspect, property)
		--------------------------------------------------------------------------------
		-- Stop Existing Color Pucker:
		--------------------------------------------------------------------------------
		if mod.colorPucker then
			mod.colorPucker:stop()
		end

		--------------------------------------------------------------------------------
		-- Delete any pre-existing highlights:
		--------------------------------------------------------------------------------
		plugins("cp.plugins.browser.playhead").deleteHighlight()

		colorBoard = fcp:colorBoard()

		--------------------------------------------------------------------------------
		-- Show the Color Board if it's hidden:
		--------------------------------------------------------------------------------
		if not colorBoard:isShowing() then colorBoard:show() end

		if not colorBoard:isActive() then
			dialog.displayNotification(i18n("pleaseSelectSingleClipInTimeline"))
			return "Failed"
		end

		mod.colorPucker = colorBoard:startPucker(aspect, property)
	end

	--------------------------------------------------------------------------------
	-- COLOR BOARD - RELEASE MOUSE KEYPRESS:
	--------------------------------------------------------------------------------
	local function colorBoardMousePuckRelease()
		if mod.colorPucker then
			mod.colorPucker:stop()
			mod.colorPicker = nil
		end
	end

--------------------------------------------------------------------------------
-- THE PLUGIN:
--------------------------------------------------------------------------------
local plugin = {}

	--------------------------------------------------------------------------------
	-- DEPENDENCIES:
	--------------------------------------------------------------------------------
	plugin.dependencies = {
		["cp.plugins.finalcutpro.commands.fcpx"]	= "fcpxCmds",
	}

	--------------------------------------------------------------------------------
	-- INITIALISE PLUGIN:
	--------------------------------------------------------------------------------
	function plugin.init(deps)

		local colorFunction = {
			[1] = "global",
			[2] = "shadows",
			[3] = "midtones",
			[4] = "highlights",
		}

		local selectColorBoardPuckDefaultShortcuts = {
			[1] = "m",
			[2] = ",",
			[3] = ".",
			[4] = "/",
		}

		local colorBoardPanel = {"Color", "Saturation", "Exposure"}

		for i=1, 4 do
			deps.fcpxCmds:add("cpSelectColorBoardPuck" .. tools.numberToWord(i))
				:titled(i18n("cpSelectColorBoardPuck_customTitle", {count = i}))
				:groupedBy("colorboard")
				:activatedBy():ctrl():option():cmd(selectColorBoardPuckDefaultShortcuts[i])
				:whenActivated(function() mod.selectPuck("*", colorFunction[i]) end)

			deps.fcpxCmds:add("cpPuck" .. tools.numberToWord(i) .. "Mouse")
				:titled(i18n("cpPuckMouse_customTitle", {count = i}))
				:groupedBy("colorboard")
				:whenActivated(function() mod.mousePuck("*", colorFunction[i]) end)

			for _, whichPanel in ipairs(colorBoardPanel) do
				deps.fcpxCmds:add("cp" .. whichPanel .. "Puck" .. tools.numberToWord(i))
					:titled(i18n("cpPuck_customTitle", {count = i, panel = whichPanel}))
					:groupedBy("colorboard")
					:whenActivated(function() mod.selectPuck(string.lower(whichPanel), colorFunction[i]) end)

				deps.fcpxCmds:add("cp" .. whichPanel .. "Puck" .. tools.numberToWord(i) .. "Up")
					:titled(i18n("cpPuckDirection_customTitle", {count = i, panel = whichPanel, direction = "Up"}))
					:groupedBy("colorboard")
					:whenActivated(function() mod.selectPuck(string.lower(whichPanel), colorFunction[i], "up") end)
					:whenReleased(function() colorBoardSelectPuckRelease() end)

				deps.fcpxCmds:add("cp" .. whichPanel .. "Puck" .. tools.numberToWord(i) .. "Down")
					:titled(i18n("cpPuckDirection_customTitle", {count = i, panel = whichPanel, direction = "Down"}))
					:groupedBy("colorboard")
					:whenActivated(function() mod.selectPuck(string.lower(whichPanel), colorFunction[i], "down") end)
					:whenReleased(function() colorBoardSelectPuckRelease() end)

				if whichPanel == "Color" then
					deps.fcpxCmds:add("cp" .. whichPanel .. "Puck" .. tools.numberToWord(i) .. "Left")
						:titled(i18n("cpPuckDirection_customTitle", {count = i, panel = whichPanel, direction = "Left"}))
						:groupedBy("colorboard")
						:whenActivated(function() mod.selectPuck(string.lower(whichPanel), colorFunction[i], "left") end)
						:whenReleased(function() colorBoardSelectPuckRelease() end)

					deps.fcpxCmds:add("cp" .. whichPanel .. "Puck" .. tools.numberToWord(i) .. "Right")
						:titled(i18n("cpPuckDirection_customTitle", {count = i, panel = whichPanel, direction = "Right"}))
						:groupedBy("colorboard")
						:whenActivated(function() mod.selectPuck(string.lower(whichPanel), colorFunction[i], "right") end)
						:whenReleased(function() colorBoardSelectPuckRelease() end)
				end

				deps.fcpxCmds:add("cp" .. whichPanel .. "Puck" .. tools.numberToWord(i) .. "Mouse")
					:titled(i18n("cpPuckMousePanel_customTitle", {count = i, panel = whichPanel}))
					:groupedBy("colorboard")
					:whenActivated(function() mod.mousePuck(string.lower(whichPanel), colorFunction[i]) end)
					:whenReleased(function() colorBoardMousePuckRelease() end)
			end
		end

		return mod

	end

return plugin