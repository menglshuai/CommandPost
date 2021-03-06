--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   X M L   S H A R I N G    P L U G I N                     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- EXTENSIONS:
--------------------------------------------------------------------------------
local log 										= require("hs.logger").new("sharingxml")

local fs										= require("hs.fs")
local host										= require("hs.host")
local image										= require("hs.image")
local notify									= require("hs.notify")
local pathwatcher								= require("hs.pathwatcher")

local fcp										= require("cp.finalcutpro")
local metadata									= require("cp.metadata")

local dialog									= require("cp.dialog")
local tools										= require("cp.tools")

--------------------------------------------------------------------------------
-- CONSTANTS:
--------------------------------------------------------------------------------
local PRIORITY 									= 4000

--------------------------------------------------------------------------------
-- THE MODULE:
--------------------------------------------------------------------------------
local mod = {}

	--------------------------------------------------------------------------------
	-- IS ENABLED:
	--------------------------------------------------------------------------------
	function mod.isEnabled()
		return metadata.get("enableXMLSharing", false)
	end

	--------------------------------------------------------------------------------
	-- SET ENABLED:
	--------------------------------------------------------------------------------
	function mod.setEnabled(value)
		metadata.set("enableXMLSharing", value)
		if value then
			mod:_notify('enable')
		else
			mod:_notify('disable')
		end
		mod.update()
	end

	--------------------------------------------------------------------------------
	-- TOGGLE ENABLED:
	--------------------------------------------------------------------------------
	function mod.toggleEnabled()
		mod.setEnabled(not mod.isEnabled())
	end

	--------------------------------------------------------------------------------
	-- GET SHARING PATH:
	--------------------------------------------------------------------------------
	function mod.getSharingPath()
		return metadata.get("xmlSharingPath")
	end

	--------------------------------------------------------------------------------
	-- SET SHARING PATH:
	--------------------------------------------------------------------------------
	function mod.setSharingPath(value)
		metadata.set("xmlSharingPath", value)
	end

	--------------------------------------------------------------------------------
	-- CLEAR SHARED XML FILES:
	--------------------------------------------------------------------------------
	function mod.clearSharedFiles()
		local xmlSharingPath = mod.getSharingPath()
		for folder in fs.dir(xmlSharingPath) do
			if tools.doesDirectoryExist(xmlSharingPath .. "/" .. folder) then
				for file in fs.dir(xmlSharingPath .. "/" .. folder) do
					if file:sub(-7) == ".fcpxml" then
						os.remove(xmlSharingPath .. folder .. "/" .. file)
					end
				end
			end
		end
	end

	--------------------------------------------------------------------------------
	-- LIST FILES MENU:
	--------------------------------------------------------------------------------
	function mod.listFilesMenu()
		if mod._filesMenuCache ~= nil then
			--log.df("Using XML Sharing Menu Cache")
			return mod._filesMenuCache
		else
			--log.df("NOT Using XML Sharing Menu Cache")
			--------------------------------------------------------------------------------
			-- Shared XML Menu:
			--------------------------------------------------------------------------------
			local menu = {}
			if mod.isEnabled() then

				--------------------------------------------------------------------------------
				-- Get list of files:
				--------------------------------------------------------------------------------
				local sharedXMLFiles = {}

				local emptySharedXMLFiles = true
				local xmlSharingPath = mod.getSharingPath()

				if not xmlSharingPath then
					return nil
				end

				local fcpxRunning = fcp:isRunning()

				for folder in fs.dir(xmlSharingPath) do

					if tools.doesDirectoryExist(xmlSharingPath .. "/" .. folder) then

						submenu = {}
						for file in fs.dir(xmlSharingPath .. "/" .. folder) do
							if file:sub(-7) == ".fcpxml" then
								emptySharedXMLFiles = false
								local xmlPath = xmlSharingPath .. folder .. "/" .. file
								table.insert(submenu, {title = file:sub(1, -8), fn = function() fcp:importXML(xmlPath) end, disabled = not fcpxRunning})
							end
						end

						if next(submenu) ~= nil then
							table.insert(menu, {title = folder, menu = submenu})
						end
					end
				end

				if emptySharedXMLFiles then
					--------------------------------------------------------------------------------
					-- Nothing in the Shared Clipboard:
					--------------------------------------------------------------------------------
					table.insert(menu, { title = "Empty", disabled = true })
				else
					--------------------------------------------------------------------------------
					-- Something in the Shared Clipboard:
					--------------------------------------------------------------------------------
					table.insert(menu, { title = "-" })
					table.insert(menu, { title = "Clear Shared XML Files", fn = mod.clearSharedFiles })
				end
			end
			mod._filesMenuCache = menu
			return menu
		end
	end

	--------------------------------------------------------------------------------
	-- SHARED XML FILE WATCHER:
	--------------------------------------------------------------------------------
	local function sharedXMLFileWatcher(files)
		--log.d("Refreshing Shared XML Folder.")
		for _,file in ipairs(files) do
			if file:sub(-7) == ".fcpxml" then
				local testFile = io.open(file, "r")
				if testFile ~= nil then
					testFile:close()

					local editorName = string.reverse(string.sub(string.reverse(file), string.find(string.reverse(file), "/", 1) + 1, string.find(string.reverse(file), "/", string.find(string.reverse(file), "/", 1) + 1) - 1))

					if host.localizedName() ~= editorName then
						local xmlSharingPath = mod.getSharingPath()
						sharedXMLNotification = notify.new(function() fcp:importXML(file) end)
							--:setIdImage(image.imageFromPath(metadata.iconPath))
							:title("Shared XML File Received")
							:subTitle(file:sub(string.len(xmlSharingPath) + 1 + string.len(editorName) + 1, -8))
							--:informativeText(metadata.scriptName .. " has received a new XML file.")
							:hasActionButton(true)
							:actionButtonTitle("Import XML")
							:send()
					end

					-- Update Cache:
					mod._filesMenuCache = nil
					mod.listFilesMenu()

				end
			end
		end
	end

	--------------------------------------------------------------------------------
	-- UPDATE:
	--------------------------------------------------------------------------------
	function mod.update()
		local enabled = mod.isEnabled()

		if enabled then
			--log.d("Enabling XML Sharing")
			local sharingPath = mod.getSharingPath()
			if sharingPath == nil then
				sharingPath = dialog.displayChooseFolder("Which folder would you like to use for XML Sharing?")

				if sharingPath ~= false then
					mod.setSharingPath(sharingPath)
				else
					mod.setEnabled(false)
					return
				end
			end

			-- Ensure the directory actually exists.
			if not tools.doesDirectoryExist(sharingPath) then
				mod.setEnabled(false)
				return
			end

			--------------------------------------------------------------------------------
			-- Watch for Shared XML Folder Changes:
			--------------------------------------------------------------------------------
			if not mod._watcher then
				mod._watcher = pathwatcher.new(sharingPath, sharedXMLFileWatcher):start()
			end
		else
			--log.d("Disabling XML Sharing")
			--------------------------------------------------------------------------------
			-- Stop Watchers:
			--------------------------------------------------------------------------------
			if mod._watcher then
				mod._watcher:stop()
				mod._watcher = nil
			end

			--------------------------------------------------------------------------------
			-- Clear Settings:
			--------------------------------------------------------------------------------
			mod.setSharingPath(nil)
		end
	end

	--------------------------------------------------------------------------------
	-- WATCH EVENTS:
	--------------------------------------------------------------------------------
	function mod:watch(events)
		if not self.watchers then
			self.watchers = {}
		end
		self.watchers[#self.watchers + 1] = events
	end

	--------------------------------------------------------------------------------
	-- NOTIFY WATCHERS:
	--------------------------------------------------------------------------------
	function mod:_notify(type, ...)
		if self.watchers then
			for _,watcher in ipairs(self.watchers) do
				if watcher[type] then
					watcher[type](...)
				end
			end
		end
	end

--------------------------------------------------------------------------------
-- THE PLUGIN:
--------------------------------------------------------------------------------
local plugin = {}

	--------------------------------------------------------------------------------
	-- PLUGIN DEPENDENCIES:
	--------------------------------------------------------------------------------
	plugin.dependencies = {
		["cp.plugins.finalcutpro.menu.tools"]			= "tools",
	}

	--------------------------------------------------------------------------------
	-- INITIALISE PLUGIN:
	--------------------------------------------------------------------------------
	function plugin.init(deps)

		--------------------------------------------------------------------------------
		-- Generate Files Menu for Cache:
		--------------------------------------------------------------------------------
		mod.update()
		mod.listFilesMenu()

		--------------------------------------------------------------------------------
		-- Tools Menus:
		--------------------------------------------------------------------------------
		deps.tools:addMenu(PRIORITY, function() return i18n("sharedXMLFiles") end)

			:addItem(1, function()
				return { title = i18n("enableXMLSharing"),	fn = mod.toggleEnabled,	checked = mod.isEnabled()}
			end)
			:addSeparator(2)
			:addItems(3, mod.listFilesMenu)

		return mod
	end

return plugin