--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--     F I N A L    C U T    P R O    I M P O R T    P R E F E R E N C E S    --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- EXTENSIONS:
--------------------------------------------------------------------------------
local fcp			= require("cp.finalcutpro")

--------------------------------------------------------------------------------
-- CONSTANTS:
--------------------------------------------------------------------------------
local PRIORITY 		= 1000

--------------------------------------------------------------------------------
-- THE MODULE:
--------------------------------------------------------------------------------
local mod = {}

	--------------------------------------------------------------------------------
	-- TOGGLE CREATE OPTIMIZED MEDIA:
	--------------------------------------------------------------------------------
	function mod.toggleCreateOptimizedMedia(optionalValue)

		--------------------------------------------------------------------------------
		-- Make sure it's active:
		--------------------------------------------------------------------------------
		fcp:launch()

		--------------------------------------------------------------------------------
		-- If we're setting rather than toggling...
		--------------------------------------------------------------------------------
		if optionalValue ~= nil and optionalValue == fcp:getPreference("FFImportCreateOptimizeMedia", false) then
			return
		end

		local prefs = fcp:preferencesWindow()

		--------------------------------------------------------------------------------
		-- Toggle the checkbox:
		--------------------------------------------------------------------------------
		if not prefs:importPanel():toggleCreateOptimizedMedia() then
			dialog.displayErrorMessage("Failed to toggle 'Create Optimized Media'.\n\nError occurred in toggleCreateOptimizedMedia().")
			return "Failed"
		end

		--------------------------------------------------------------------------------
		-- Close the Preferences window:
		--------------------------------------------------------------------------------
		prefs:hide()
	end

	--------------------------------------------------------------------------------
	-- TOGGLE CREATE MULTI-CAM OPTIMISED MEDIA:
	--------------------------------------------------------------------------------
	function mod.toggleCreateMulticamOptimizedMedia(optionalValue)

		--------------------------------------------------------------------------------
		-- Make sure it's active:
		--------------------------------------------------------------------------------
		fcp:launch()

		--------------------------------------------------------------------------------
		-- If we're setting rather than toggling...
		--------------------------------------------------------------------------------
		if optionalValue ~= nil and optionalValue == fcp:getPreference("FFCreateOptimizedMediaForMulticamClips", true) then
			return
		end

		--------------------------------------------------------------------------------
		-- Define FCPX:
		--------------------------------------------------------------------------------
		local prefs = fcp:preferencesWindow()

		--------------------------------------------------------------------------------
		-- Toggle the checkbox:
		--------------------------------------------------------------------------------
		if not prefs:playbackPanel():toggleCreateOptimizedMediaForMulticamClips() then
			dialog.displayErrorMessage("Failed to toggle 'Create Optimized Media for Multicam Clips'.\n\nError occurred in toggleCreateMulticamOptimizedMedia().")
			return "Failed"
		end

		--------------------------------------------------------------------------------
		-- Close the Preferences window:
		--------------------------------------------------------------------------------
		prefs:hide()
	end

	--------------------------------------------------------------------------------
	-- TOGGLE CREATE PROXY MEDIA:
	--------------------------------------------------------------------------------
	function mod.toggleCreateProxyMedia(optionalValue)

		--------------------------------------------------------------------------------
		-- Make sure it's active:
		--------------------------------------------------------------------------------
		fcp:launch()

		--------------------------------------------------------------------------------
		-- If we're setting rather than toggling...
		--------------------------------------------------------------------------------
		if optionalValue ~= nil and optionalValue == fcp:getPreference("FFImportCreateProxyMedia", false) then
			return
		end

		--------------------------------------------------------------------------------
		-- Define FCPX:
		--------------------------------------------------------------------------------
		local prefs = fcp:preferencesWindow()

		--------------------------------------------------------------------------------
		-- Toggle the checkbox:
		--------------------------------------------------------------------------------
		if not prefs:importPanel():toggleCreateProxyMedia() then
			dialog.displayErrorMessage("Failed to toggle 'Create Proxy Media'.\n\nError occurred in toggleCreateProxyMedia().")
			return "Failed"
		end

		--------------------------------------------------------------------------------
		-- Close the Preferences window:
		--------------------------------------------------------------------------------
		prefs:hide()
	end

	--------------------------------------------------------------------------------
	-- TOGGLE LEAVE IN PLACE ON IMPORT:
	--------------------------------------------------------------------------------
	function mod.toggleLeaveInPlace(optionalValue)

		--------------------------------------------------------------------------------
		-- Make sure it's active:
		--------------------------------------------------------------------------------
		fcp:launch()

		--------------------------------------------------------------------------------
		-- If we're setting rather than toggling...
		--------------------------------------------------------------------------------
		if optionalValue ~= nil and optionalValue == fcp:getPreference("FFImportCopyToMediaFolder", true) then
			return
		end

		--------------------------------------------------------------------------------
		-- Define FCPX:
		--------------------------------------------------------------------------------
		local prefs = fcp:preferencesWindow()

		--------------------------------------------------------------------------------
		-- Toggle the checkbox:
		--------------------------------------------------------------------------------
		if not prefs:importPanel():toggleCopyToMediaFolder() then
			dialog.displayErrorMessage("Failed to toggle 'Copy To Media Folder'.\n\nError occurred in toggleLeaveInPlace().")
			return "Failed"
		end

		--------------------------------------------------------------------------------
		-- Close the Preferences window:
		--------------------------------------------------------------------------------
		prefs:hide()

	end

--------------------------------------------------------------------------------
-- THE PLUGIN:
--------------------------------------------------------------------------------
local plugin = {}

	--------------------------------------------------------------------------------
	-- DEPENDENCIES:
	--------------------------------------------------------------------------------
	plugin.dependencies = {
		["cp.plugins.finalcutpro.menu.mediaimport"] = "shortcuts",
		["cp.plugins.finalcutpro.commands.fcpx"]	= "fcpxCmds",
	}

	--------------------------------------------------------------------------------
	-- INITIALISE PLUGIN:
	--------------------------------------------------------------------------------
	function plugin.init(deps)
		--------------------------------------------------------------------------------
		-- Menus:
		--------------------------------------------------------------------------------
		deps.shortcuts:addItems(PRIORITY, function()
			local fcpxRunning = fcp:isRunning()

			return {
				{ title = i18n("createOptimizedMedia"), 											fn = mod.toggleCreateOptimizedMedia, 				checked = fcp:getPreference("FFImportCreateOptimizeMedia", false),				disabled = not fcpxRunning },
				{ title = i18n("createMulticamOptimizedMedia"),										fn = mod.toggleCreateMulticamOptimizedMedia, 		checked = fcp:getPreference("FFCreateOptimizedMediaForMulticamClips", true), 	disabled = not fcpxRunning },
				{ title = i18n("createProxyMedia"), 												fn = mod.toggleCreateProxyMedia, 					checked = fcp:getPreference("FFImportCreateProxyMedia", false),					disabled = not fcpxRunning },
				{ title = i18n("leaveFilesInPlaceOnImport"), 										fn = mod.toggleLeaveInPlace, 						checked = not fcp:getPreference("FFImportCopyToMediaFolder", true),				disabled = not fcpxRunning },
			}
		end)

		--------------------------------------------------------------------------------
		-- Commands:
		--------------------------------------------------------------------------------
		local fcpxCmds = deps.fcpxCmds
		fcpxCmds:add("cpCreateOptimizedMediaOn")
			:groupedBy("mediaImport")
			:whenActivated(function() mod.toggleCreateOptimizedMedia(true) end)
		fcpxCmds:add("cpCreateOptimizedMediaOff")
			:groupedBy("mediaImport")
			:whenActivated(function() mod.toggleCreateOptimizedMedia(false) end)

		fcpxCmds:add("cpCreateMulticamOptimizedMediaOn")
			:groupedBy("mediaImport")
			:whenActivated(function() mod.toggleCreateMulticamOptimizedMedia(true) end)
		fcpxCmds:add("cpCreateMulticamOptimizedMediaOff")
			:groupedBy("mediaImport")
			:whenActivated(function() mod.toggleCreateMulticamOptimizedMedia(false) end)

		fcpxCmds:add("cpCreateProxyMediaOn")
			:groupedBy("mediaImport")
			:whenActivated(function() mod.toggleCreateProxyMedia(true) end)
		fcpxCmds:add("cpCreateProxyMediaOff")
			:groupedBy("mediaImport")
			:whenActivated(function() mod.toggleCreateProxyMedia(false) end)

		fcpxCmds:add("cpLeaveInPlaceOn")
			:groupedBy("mediaImport")
			:whenActivated(function() mod.toggleLeaveInPlace(true) end)
		fcpxCmds:add("cpLeaveInPlaceOff")
			:groupedBy("mediaImport")
			:whenActivated(function() mod.toggleLeaveInPlace(false) end)

		return mod
	end

return plugin