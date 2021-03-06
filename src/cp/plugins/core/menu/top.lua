--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                       T O P    M E N U   S E C T I O N                     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- The top menu section.

--------------------------------------------------------------------------------
-- CONSTANTS:
--------------------------------------------------------------------------------
local PRIORITY = 0

--------------------------------------------------------------------------------
-- THE PLUGIN:
--------------------------------------------------------------------------------
local plugin = {}

	--------------------------------------------------------------------------------
	-- DEPENDENCIES:
	--------------------------------------------------------------------------------
	plugin.dependencies = {
		["cp.plugins.core.menu.manager"] = "manager"
	}

	--------------------------------------------------------------------------------
	-- INITIALISE PLUGIN:
	--------------------------------------------------------------------------------
	function plugin.init(dependencies)
		return dependencies.manager.addSection(PRIORITY)
	end

return plugin