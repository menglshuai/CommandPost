--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                B A C K U P    I N T E R V A L    P L U G I N               --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- EXTENSIONS:
--------------------------------------------------------------------------------
local log				= require("hs.logger").new("movingmarkers")

local application		= require("hs.application")

local dialog			= require("cp.dialog")
local fcp				= require("cp.finalcutpro")
local metadata			= require("cp.metadata")
local plist				= require("cp.plist")
local tools				= require("cp.tools")

--------------------------------------------------------------------------------
-- CONSTANTS:
--------------------------------------------------------------------------------
local PRIORITY 			= 30
local DEFAULT_VALUE 	= "15"
local PREFERENCES_KEY	= "FFPeriodicBackupInterval"

--------------------------------------------------------------------------------
-- THE MODULE:
--------------------------------------------------------------------------------
local mod = {}

	function mod.getPeriodicBackupInterval()

		local FFPeriodicBackupInterval = DEFAULT_VALUE
		local preferences = fcp:getPreferences()
		if preferences and preferences[PREFERENCES_KEY] then
			FFPeriodicBackupInterval = preferences[PREFERENCES_KEY]
		end
		return FFPeriodicBackupInterval

	end

	function mod.changeBackupInterval()

		--------------------------------------------------------------------------------
		-- Get existing value:
		--------------------------------------------------------------------------------
		local FFPeriodicBackupInterval = mod.getPeriodicBackupInterval()

		--------------------------------------------------------------------------------
		-- If Final Cut Pro is running...
		--------------------------------------------------------------------------------
		local restartStatus = false
		if fcp:isRunning() then
			if dialog.displayYesNoQuestion(i18n("changeBackupIntervalMessage") .. "\n\n" .. i18n("doYouWantToContinue")) then
				restartStatus = true
			else
				return "Done"
			end
		end

		--------------------------------------------------------------------------------
		-- Ask user what to set the backup interval to:
		--------------------------------------------------------------------------------
		local userSelectedBackupInterval = dialog.displaySmallNumberTextBoxMessage(i18n("changeBackupIntervalTextbox"), i18n("changeBackupIntervalError"), FFPeriodicBackupInterval)
		if not userSelectedBackupInterval then
			return "Cancel"
		end

		--------------------------------------------------------------------------------
		-- Update plist:
		--------------------------------------------------------------------------------
		local result = fcp:setPreference(PREFERENCES_KEY, tostring(userSelectedBackupInterval))
		if result == nil then
			dialog.displayErrorMessage(i18n("backupIntervalFail"))
			return "Failed"
		end

		--------------------------------------------------------------------------------
		-- Restart Final Cut Pro:
		--------------------------------------------------------------------------------
		if restartStatus then
			if not fcp:restart() then
				--------------------------------------------------------------------------------
				-- Failed to restart Final Cut Pro:
				--------------------------------------------------------------------------------
				dialog.displayErrorMessage(i18n("failedToRestart"))
				return "Failed"
			end
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
		["cp.plugins.finalcutpro.menu.administrator.advancedfeatures"] = "advancedfeatures",
		["cp.plugins.finalcutpro.commands.fcpx"]		= "fcpxCmds",
	}

	--------------------------------------------------------------------------------
	-- INITIALISE PLUGIN:
	--------------------------------------------------------------------------------
	function plugin.init(deps)

		deps.advancedfeatures:addItem(PRIORITY, function()
			return { title = i18n("changeBackupInterval") .. " (" .. tostring(mod.getPeriodicBackupInterval()) .. " " .. i18n("mins") .. ")",	fn = mod.changeBackupInterval }
		end)

		-- Commands
		deps.fcpxCmds:add("cpChangeBackupInterval")
			:groupedBy("hacks")
			:activatedBy():ctrl():option():cmd("b")
			:whenActivated(mod.changeBackupInterval)

		return mod

	end

return plugin