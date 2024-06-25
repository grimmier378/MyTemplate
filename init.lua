--[[
	Title: Generic Script Template
	Author: Grimmier
	Includes: 
	Description: Generic Script Template with ThemeZ Suppport
]]

-- Load Libraries
local mq = require('mq')
local ImGui = require('ImGui')
local LoadTheme = require('lib.theme_loader')
local Icon = require('mq.ICONS')
local rIcon -- resize icon variable holder
local lIcon -- lock icon variable holder

-- Variables
local script = 'ChangeMe' -- Change this to the name of your script
local meName -- Character Name
local themeName = 'Default'
local gIcon = Icon.MD_SETTINGS -- Gear Icon for Settings
local themeID = 1
local theme, defaults, settings = {}, {}, {}
local RUNNING = true
local showMainGUI, showConfigGUI = true, false
local scale = 1
local aSize, locked, hasThemeZ = false, false, false

-- GUI Settings
local winFlags = bit32.bor(ImGuiWindowFlags.None)

-- File Paths
local themeFile = string.format('%s/MyUI/MyThemeZ.lua', mq.configDir)
local configFile = string.format('%s/MyUI/%s/%s_Configs.lua', mq.configDir, script, script)
local themezDir = mq.luaDir .. '/themez/init.lua'

-- Default Settings
defaults = {
	Scale = 1.0,
	LoadTheme = 'Default',
	locked = false,
	AutoSize = false,
}

---comment Check to see if the file we want to work on exists.
---@param name string -- Full Path to file
---@return boolean -- returns true if the file exists and false otherwise
local function File_Exists(name)
	local f=io.open(name,"r")
	if f~=nil then io.close(f) return true else return false end
end

local function loadTheme()
	-- Check for the Theme File
	if File_Exists(themeFile) then
		theme = dofile(themeFile)
	else
		-- Create the theme file from the defaults
		theme = require('themes') -- your local themes file incase the user doesn't have one in config folder
		mq.pickle(themeFile, theme)
	end
	-- Load the theme from the settings file
	themeName = settings[script].LoadTheme or 'Default'
	-- Find the theme ID
	if theme and theme.Theme then
		for tID, tData in pairs(theme.Theme) do
			if tData['Name'] == themeName then
				themeID = tID
			end
		end
	end
end

local function loadSettings()
	local newSetting = false -- Check if we need to save the settings file

	-- Check Settings File_Exists
	if not File_Exists(configFile) then
		-- Create the settings file from the defaults
		settings[script] = defaults
		mq.pickle(configFile, settings)
		loadSettings()
	else
		-- Load settings from the Lua config file
		settings = dofile(configFile)
		-- Check if the settings are missing from the file
		if settings[script] == nil then
			settings[script] = {}
			settings[script] = defaults
			newSetting = true
		end
	end

	-- Check if the settings are missing and use defaults if they are

	if settings[script].locked == nil then
		settings[script].locked = false
		newSetting = true
	end

	if settings[script].Scale == nil then
		settings[script].Scale = 1
		newSetting = true
	end

	if not settings[script].LoadTheme then
		settings[script].LoadTheme = 'Default'
		newSetting = true
	end

	if settings[script].AutoSize == nil then
		settings[script].AutoSize = aSize
		newSetting = true
	end

	-- Load the theme
	loadTheme()

	-- Set the settings to the variables
	aSize = settings[script].AutoSize
	locked = settings[script].locked
	scale = settings[script].Scale
	themeName = settings[script].LoadTheme

	-- Save the settings if new settings were added
	if newSetting then mq.pickle(configFile, settings) end

end

local function Draw_GUI()

	if showMainGUI then
		-- Set Window Name
		local winName = string.format('%s##Main_%s', script, meName)
		-- Load Theme
		local ColorCount, StyleCount = LoadTheme.StartTheme(theme.Theme[themeID])
		-- Create Main Window
		local openMain, showMain = ImGui.Begin(winName,true,winFlags)
		-- Check if the window is open
		if not openMain then
			showMainGUI = false
		end
		-- Check if the window is showing
		if showMain then
			-- Set Window Font Scale
			ImGui.SetWindowFontScale(scale)
			-- right click context window for settings (Right Click Title Bar or Empty Space on Window)
			if ImGui.BeginPopupContextWindow() then
				if ImGui.MenuItem ("Settings") then
					-- Toggle Config Window
					showConfigGUI = not showConfigGUI
				end
				if ImGui.MenuItem ("Exit") then
					RUNNING = false
				end
				ImGui.EndPopup()
			end

			-- Draw Config Gear Icon for settings (Clickable Text)			
			ImGui.Text(gIcon)
			if ImGui.IsItemHovered() then
				-- Set Tooltip
				ImGui.SetTooltip("Settings")
				-- Check if the Gear Icon is clicked
				if ImGui.IsMouseReleased(0) then
					-- Toggle Config Window
					showConfigGUI = not showConfigGUI
				end
			end

			-- Text and Buttons
			ImGui.Text("Hello World")
			lIcon = locked and Icon.FA_LOCK or Icon.FA_UNLOCK -- Lock Icon
			if ImGui.Button(lIcon) then
				locked = not locked
			end

			ImGui.SameLine()
			rIcon = aSize and Icon.FA_EXPAND or Icon.FA_COMPRESS -- Auto Size Window Icon
			if ImGui.Button(rIcon) then
				aSize = not aSize
			end
			local txtLocked = locked and "Unlock Window" or "Lock Window"
			ImGui.Text(txtLocked)

			ImGui.SameLine()

			local txtAutoSize = aSize and "Disable Auto Size" or "Enable Auto Size"
			ImGui.Text(txtAutoSize)

			-- Reset Font Scale
			ImGui.SetWindowFontScale(1)

		end

		-- Unload Theme
		LoadTheme.EndTheme(ColorCount, StyleCount)
		ImGui.End()
	end

	if showConfigGUI then
		local winName = string.format('%s Config##Config_%s',script, meName)
		local ColCntConf, StyCntConf = LoadTheme.StartTheme(theme.Theme[themeID])
		local openConfig, showConfig = ImGui.Begin(winName,true,bit32.bor(ImGuiWindowFlags.NoCollapse, ImGuiWindowFlags.AlwaysAutoResize))
		if not openConfig then
			showConfigGUI = false
		end
		if showConfig then

			-- Configure ThemeZ --
			ImGui.SeparatorText("Theme##"..script)
			ImGui.Text("Cur Theme: %s", themeName)

			-- Combo Box Load Theme
			if ImGui.BeginCombo("Load Theme##"..script, themeName) then
				for k, data in pairs(theme.Theme) do
					local isSelected = data.Name == themeName
					if ImGui.Selectable(data.Name, isSelected) then
						theme.LoadTheme = data.Name
						themeID = k
						themeName = theme.LoadTheme
					end
				end
				ImGui.EndCombo()
			end

			-- Configure Scale --
			scale = ImGui.SliderFloat("Scale##"..script, scale, 0.5, 2)
			if scale ~= settings[script].Scale then
				if scale < 0.5 then scale = 0.5 end
				if scale > 2 then scale = 2 end
			end

			-- Edit ThemeZ Button if ThemeZ lua exists.
			if hasThemeZ then
				if ImGui.Button('Edit ThemeZ') then
					mq.cmd("/lua run themez")
				end
				ImGui.SameLine()
			end

			-- Reload Theme File incase of changes --
			if ImGui.Button('Reload Theme File') then
				loadTheme()
			end

			-- Save & Close Button --
			if ImGui.Button("Save & Close") then
				settings = dofile(configFile)
				settings[script].Scale = scale
				settings[script].LoadTheme = themeName
				mq.pickle(configFile, settings)
				showConfigGUI = false
			end
		end
		LoadTheme.EndTheme(ColCntConf, StyCntConf)
		ImGui.End()
	end

end

-- binds function to process commands and arugments
local function binds(...)
	local args = {...}
	if args[1] == "gui" then
		showMainGUI = not showMainGUI
	end
	if args[1] == "config" then
		showConfigGUI = not showConfigGUI
	end
	if args[1] == "exit" then
		RUNNING = false
	end
end

local function Init()
	-- Load Settings
	loadSettings()
	-- Get Character Name
	meName = mq.TLO.Me.Name()
	-- setup bind
	mq.bind("/"..script, binds)
	printf("\aw[\at%s\ax] \ayLoaded!", script)
	printf("\aw[\at%s\ax] \ayType \ag/%s gui\ay to toggle the GUI", script, script)
	printf("\aw[\at%s\ax] \ayType \ag/%s config\ay to toggle the Config GUI", script, script)
	printf("\aw[\at%s\ax] \ayType \ag/%s exit\ay to exit the script", script, script)
	-- Check if ThemeZ exists
	if File_Exists(themezDir) then
		hasThemeZ = true
	end
	-- Initialize ImGui
	mq.imgui.init(script, Draw_GUI)
end

local function Loop()
	-- Main Loop
	while RUNNING do
		-- Make sure we are still in game or exit the script.
		if mq.TLO.EverQuest.GameState() ~= "INGAME" then printf("\aw[\at%s\ax] \arNot in game, \ayTry again later...", script) mq.exit() end

		-- Process ImGui Window Flag Changes
		winFlags = locked and bit32.bor(ImGuiWindowFlags.NoMove) or bit32.bor(ImGuiWindowFlags.None)
		winFlags = aSize and bit32.bor(winFlags, ImGuiWindowFlags.AlwaysAutoResize) or winFlags

		mq.delay(10) 

	end
end
-- Make sure we are in game before running the script
if mq.TLO.EverQuest.GameState() ~= "INGAME" then printf("\aw[\at%s\ax] \arNot in game, \ayTry again later...", script) mq.exit() end
Init()
Loop()