--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                    P R E F E R E N C E S     M E N U                       --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- The 'Preferences' menu section

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
		["cp.plugins.core.menu.bottom"] = "bottom"
	}

	--------------------------------------------------------------------------------
	-- INITIALISE PLUGIN:
	--------------------------------------------------------------------------------
	function plugin.init(dependencies)
		--[[
		local section = dependencies.bottom:addSection(PRIORITY)
			:addMenu(0, function() return i18n("preferences") end)
		return section
		--]]
	end

return plugin