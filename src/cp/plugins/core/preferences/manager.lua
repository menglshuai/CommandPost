--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                     P R E F E R E N C E S   M A N A G E R                  --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.plugins.core.preferences.manager ===
---
--- Manager for the CommandPost Preferences Panel.

--------------------------------------------------------------------------------
-- EXTENSIONS:
--------------------------------------------------------------------------------
local log										= require("hs.logger").new("prefsManager")

local application								= require("hs.application")
local base64									= require("hs.base64")
local console									= require("hs.console")
local drawing									= require("hs.drawing")
local geometry									= require("hs.geometry")
local screen									= require("hs.screen")
local timer										= require("hs.timer")
local toolbar                  					= require("hs.webview.toolbar")
local urlevent									= require("hs.urlevent")
local webview									= require("hs.webview")

local dialog									= require("cp.dialog")
local fcp										= require("cp.finalcutpro")
local metadata									= require("cp.metadata")
local plugins									= require("cp.plugins")
local template									= require("cp.template")
local tools										= require("cp.tools")

--------------------------------------------------------------------------------
-- CONSTANTS:
--------------------------------------------------------------------------------

local PRIORITY 									= 8888889
local WEBVIEW_LABEL								= "preferences"
local TEMPLATE_PATH								= "/cp/plugins/core/preferences/html/template.htm"

--------------------------------------------------------------------------------
-- THE MODULE:
--------------------------------------------------------------------------------
local mod = {}

	--------------------------------------------------------------------------------
	-- SETTINGS:
	--------------------------------------------------------------------------------
	mod.defaultWidth 		= 365
	mod.defaultHeight 		= 438
	mod.defaultTitle 		= i18n("preferences")
	mod._panels				= {}

	function mod.getLabel()
		return WEBVIEW_LABEL
	end

	--------------------------------------------------------------------------------
	-- HIGHEST PRIORITY ID:
	--------------------------------------------------------------------------------
	local function highestPriorityID()

		local sortedPanels = mod._panels
		table.sort(sortedPanels, function(a, b) return a.priority < b.priority end)
		return mod._panels[1]["id"]

	end

	--------------------------------------------------------------------------------
	-- GENERATE HTML:
	--------------------------------------------------------------------------------
	local function generateHTML()

		local env = template.defaultEnv()

		env.i18n = i18n

		env.content = ""

		local highestPriorityID = highestPriorityID()
		for i, v in ipairs(mod._panels) do
			local display = "none"
			if v["id"] == highestPriorityID then display = "block" end
			env.content =  env.content .. [[
				<div id="]] .. v["id"] .. [[" style="display: ]] .. display .. [[;">
				]] .. v["contentFn"]() .. [[
				</div>
			]]

    	end

		return template.compileFile(metadata.scriptPath .. TEMPLATE_PATH, env)

	end

	--------------------------------------------------------------------------------
	-- NEW PREFERENCES PANEL:
	--------------------------------------------------------------------------------
	function mod.new()

		--------------------------------------------------------------------------------
		-- Centre on Screen:
		--------------------------------------------------------------------------------
		local screenFrame = screen.mainScreen():frame()
		local defaultRect = {x = (screenFrame['w']/2) - (mod.defaultWidth/2), y = (screenFrame['h']/2) - (mod.defaultHeight/2), w = mod.defaultWidth, h = mod.defaultHeight}

		--------------------------------------------------------------------------------
		-- Setup Web View Controller:
		--------------------------------------------------------------------------------
		mod.controller = webview.usercontent.new(WEBVIEW_LABEL)
			:setCallback(function(message)
				--------------------------------------------------------------------------------
				-- Trigger Callbacks:
				--------------------------------------------------------------------------------
				for i, v in ipairs(mod._panels) do
					if type(v["callbackFn"]) == "function" then
						v["callbackFn"](message)
					end
				end
			end)

		--------------------------------------------------------------------------------
		-- Setup Tool Bar:
		--------------------------------------------------------------------------------
		mod.toolbar = toolbar.new(WEBVIEW_LABEL, mod._panels)
			:canCustomize(true)
			:autosaves(true)

		--------------------------------------------------------------------------------
		-- Setup Web View:
		--------------------------------------------------------------------------------
		local developerExtrasEnabled = {}
		if metadata.get("debugMode") then developerExtrasEnabled = {developerExtrasEnabled = true} end
		mod.webview = webview.new(defaultRect, developerExtrasEnabled, mod.controller)
			--:navigationCallback(preferencesWebViewNavigationWatcher)
			:windowStyle({"titled", "closable", "nonactivating", "resizable"})
			:shadow(true)
			:allowNewWindows(false)
			:allowTextEntry(true)
			:windowTitle(mod.defaultTitle)
			:html(generateHTML())
			:toolbar(mod.toolbar)

		--------------------------------------------------------------------------------
		-- Setup URL Events:
		--------------------------------------------------------------------------------
		mod.urlEvent = urlevent.bind(WEBVIEW_LABEL, function(eventName, params)
			-- if params["action"] == "cancel" then
		end)

		--------------------------------------------------------------------------------
		-- Select Panel:
		--------------------------------------------------------------------------------
		mod.selectPanel(highestPriorityID())

	end

	--- cp.plugins.core.preferences.manager.showPreferences() -> boolean
	--- Function
	--- Shows the Preferences Window
	---
	--- Parameters:
	---  * None
	---
	--- Returns:
	---  * True if successful or nil if an error occurred
	---
	function mod.show()

		if mod.webview == nil then
			mod.new()
		end

		if next(mod._panels) == nil then
			dialog.displayMessage("There is no Preferences Panels to display.")
			return nil
		else
			mod.webview:show()
			timer.doAfter(0.1, function()
				log.df("Attempting to bring Preferences Panel to focus.")
				mod.webview:hswindow():raise():focus()
			end)
			return true
		end

	end

	--------------------------------------------------------------------------------
	-- SELECT PANEL:
	--------------------------------------------------------------------------------
	function mod.selectPanel(id)

		-- log.df("Selecting Panel with ID: %s", id)

		local javascriptToInject = ""

		for i, v in ipairs(mod._panels) do
			if v["id"] == id then
				javascriptToInject = javascriptToInject .. [[
					document.getElementById(']] .. v["id"] .. [[').style.display = 'block';
				]]
			else
				javascriptToInject = javascriptToInject .. [[
					document.getElementById(']] .. v["id"] .. [[').style.display = 'none';
				]]
			end
		end

		mod.webview:evaluateJavaScript(javascriptToInject)
		mod.toolbar:selectedItem(id)

	end

	--------------------------------------------------------------------------------
	-- ADD PANEL:
	--------------------------------------------------------------------------------
	function mod.addPanel(id, label, image, priority, tooltip, contentFn, callbackFn)

		--log.df("Adding Preferences Panel with ID: %s", id)

		mod._panels[#mod._panels + 1] = {
			id = id,
			label = label,
			image = image,
			priority = priority,
			tooltip = tooltip,
			fn = function() mod.selectPanel(id) end,
			selectable = true,
			contentFn = contentFn,
			callbackFn = callbackFn,
		}

	end

--------------------------------------------------------------------------------
-- THE PLUGIN:
--------------------------------------------------------------------------------
local plugin = {}

	--------------------------------------------------------------------------------
	-- DEPENDENCIES:
	--------------------------------------------------------------------------------
	plugin.dependencies = {
		["cp.plugins.core.menu.bottom"] = "bottom",
	}

	--------------------------------------------------------------------------------
	-- INITIALISE PLUGIN:
	--------------------------------------------------------------------------------
	function plugin.init(deps)

		deps.bottom:addItem(PRIORITY, function()
			return { title = i18n("preferences") .. "...", fn = mod.show }
		end)

		--:addSeparator(PRIORITY+1)

		return mod
	end

return plugin