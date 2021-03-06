--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                       A S S I G N   S H O R T C U T S                      --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- The AUTOMATION > 'Options' menu section

--------------------------------------------------------------------------------
-- CONSTANTS:
--------------------------------------------------------------------------------
local PRIORITY = 8888888

--------------------------------------------------------------------------------
-- THE PLUGIN:
--------------------------------------------------------------------------------
local plugin = {}

	--------------------------------------------------------------------------------
	-- DEPENDENCIES:
	--------------------------------------------------------------------------------
	plugin.dependencies = {
		["cp.plugins.finalcutpro.menu.timeline"] = "automation"
	}

	--------------------------------------------------------------------------------
	-- INITIALISE PLUGIN:
	--------------------------------------------------------------------------------
	function plugin.init(dependencies)
		return dependencies.automation:addMenu(PRIORITY, function() return i18n("assignShortcuts") end)
	end

return plugin