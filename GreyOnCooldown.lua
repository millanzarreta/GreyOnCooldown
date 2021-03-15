-- ------------------------------------------------------------ --
-- Addon: GreyOnCooldown                                        --
--                                                              --
-- Version: 1.0.7                                               --
-- WoW Game Version: 9.0.5                                      --
-- Author: Millán - Sanguino                                    --
--                                                              --
-- License: GNU GENERAL PUBLIC LICENSE, Version 3, 29 June 2007 --
-- ------------------------------------------------------------ --

GreyOnCooldown = LibStub("AceAddon-3.0"):NewAddon("GreyOnCooldown", "AceConsole-3.0")

local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceDB = LibStub("AceDB-3.0")
local AceDBOptions = LibStub("AceDBOptions-3.0")

GreyOnCooldown.frame = GreyOnCooldown.frame or CreateFrame("Frame", "GreyOnCooldownFrame")

function GreyOnCooldown:OnEvent(event, ...) -- functions created in "object:method"-style have an implicit first parameter of "self", which points to object
	GreyOnCooldown[event](GreyOnCooldown, ...) -- route event parameters to GreyOnCooldown:event methods
end
GreyOnCooldown.frame:SetScript("OnEvent", GreyOnCooldown.OnEvent)

local L = LibStub("AceLocale-3.0"):GetLocale("GreyOnCooldown")

local _G = _G
local _
local STANDARD_EPSILON = 0.0001

-- Default settings
GreyOnCooldown.defaults = {
	profile = {
		enabled = true,
		minDuration = 1.51
	}
}

-- Global variables
GreyOnCooldown.VERSION = "1.0.7"
GreyOnCooldown.AddonBartender4IsPresent = false
GreyOnCooldown.Bartender4ButtonsTable = {}

-- First function fired
function GreyOnCooldown:OnInitialize()
	self.db = AceDB:New("GreyOnCooldown_DB", self.defaults, true)
	
	self.optionsTable.args.profiles = AceDBOptions:GetOptionsTable(self.db)
	
	AceConfig:RegisterOptionsTable("GreyOnCooldown", self.optionsTable)
	
	self.db.RegisterCallback(self, "OnProfileChanged", "RefreshConfig")
	self.db.RegisterCallback(self, "OnProfileCopied", "RefreshConfig")
	self.db.RegisterCallback(self, "OnProfileReset", "RefreshConfig")
	
	self.optionsFrames = {}
	self.optionsFrames.general = AceConfigDialog:AddToBlizOptions("GreyOnCooldown", nil, nil, "general")
	self.optionsFrames.profiles = AceConfigDialog:AddToBlizOptions("GreyOnCooldown", L["Profiles"], "GreyOnCooldown", "profiles")
	
	self:RegisterChatCommand("GreyOnCooldown", "SlashCommand")
	
	-- Start GreyOnCooldown Core
	if (self.db.profile.enabled) then
		GreyOnCooldown:Enable()
		GreyOnCooldown:MainFunction() 
	else
		GreyOnCooldown:Disable()
	end
end

-- Executed after modifying, resetting or changing profiles from the profile configuration menu
function GreyOnCooldown:RefreshConfig()
	if (self:IsEnabled()) then
		if (not self.db.profile.enabled) then
			self:Disable()
			ReloadUI()
		else
			self:Enable()
			self:HookGreyOnCooldownIcons()
		end
	else
		if (self.db.profile.enabled) then
			self:Enable()
			self:HookGreyOnCooldownIcons()
		else
			self:Disable()
		end
	end
end

-- Function to control the slash commands
function GreyOnCooldown:SlashCommand(str)
	local cmd, arg1 = GreyOnCooldown:GetArgs(str, 2, 1)
	cmd = strlower(cmd or "")
	arg1 = strlower(arg1 or "")
	if (cmd == "enable") or (cmd == "on") then
		if (not GreyOnCooldown:IsEnabled()) then
			GreyOnCooldown.db.profile.enabled = true
			GreyOnCooldown:Enable()
			GreyOnCooldown:MainFunction() 
		end
	elseif (cmd == "disable") or (cmd == "off") then
		if (GreyOnCooldown:IsEnabled()) then
			GreyOnCooldown.db.profile.enabled = false
			GreyOnCooldown:Disable()
			ReloadUI()
		end
	elseif (cmd == "minduration") then
		if (arg1 ~= "") then
			if (arg1 == "default") then
				GreyOnCooldown.db.profile.minDuration = GreyOnCooldown.db.defaults.profile.minDuration
			else
				local newValue = tonumber(arg1)
				if (newValue ~= nil) then
					if (newValue < 0.01) then
						newValue = 0.01
					end
					GreyOnCooldown.db.profile.minDuration = newValue
				end
			end
		end
	elseif (cmd == "profiles") then
		GreyOnCooldown:ShowConfig(1)
	elseif (cmd == "help") then
		GreyOnCooldown:ShowHelp()
	else
		GreyOnCooldown:ShowConfig()
	end
end

-- Print the help
function GreyOnCooldown:ShowHelp()
	GreyOnCooldown:Print('|cffd78900' .. L['GreyOnCooldown'] .. ' v' .. GreyOnCooldown.VERSION .. '|r')
	GreyOnCooldown:Print("|cffd2a679" .. L['GREYONCOOLDOWN_HELP_LINE1'] .. "|r")
	GreyOnCooldown:Print("|cffd2a679" .. L['GREYONCOOLDOWN_HELP_LINE2'] .. "|r")
	GreyOnCooldown:Print("|cffd2a679" .. L['GREYONCOOLDOWN_HELP_LINE3'] .. "|r")
	GreyOnCooldown:Print("|cffd2a679" .. L['GREYONCOOLDOWN_HELP_LINE4'] .. "|r")
	GreyOnCooldown:Print("|cffd2a679" .. L['GREYONCOOLDOWN_HELP_LINE5'] .. "|r")
	GreyOnCooldown:Print("|cffd2a679" .. L['GREYONCOOLDOWN_HELP_LINE6'] .. "|r")
end

function GreyOnCooldown:OnEnable()
	DEFAULT_CHAT_FRAME:AddMessage('|cffd78900' .. L['GreyOnCooldown'] .. ' v' .. GreyOnCooldown.VERSION .. '|r ' .. L['enabled'])
end

function GreyOnCooldown:OnDisable()
	DEFAULT_CHAT_FRAME:AddMessage('|cffd78900' .. L['GreyOnCooldown'] .. ' v' .. GreyOnCooldown.VERSION .. '|r ' .. L['disabled'])
end

--Show Options Menu
function GreyOnCooldown:ShowConfig(category)
	-- Call twice to workaround a bug in Blizzard's function
	InterfaceOptionsFrame_OpenToCategory(self.optionsFrames.profiles)
	InterfaceOptionsFrame_OpenToCategory(self.optionsFrames.profiles)
	if (category ~= nil) then
		if (category == 0) then
			InterfaceOptionsFrame_OpenToCategory(self.optionsFrames.general)
		elseif (category == 1) then
			InterfaceOptionsFrame_OpenToCategory(self.optionsFrames.profiles)
		end
	else
		InterfaceOptionsFrame_OpenToCategory(self.optionsFrames.general)
	end
end

function GreyOnCooldown:MainFunction()
	GreyOnCooldown:HookGreyOnCooldownIcons()
	GreyOnCooldown:CheckAddonBartender4()
end

-- Function to fast-check if Bartender4 addon is present
function GreyOnCooldown:CheckAddonBartender4()
	if (self.AddonBartender4IsPresent) then
		return true
	else
		if ((BINDING_HEADER_Bartender4 == nil) or (BINDING_NAME_BTTOGGLEACTIONBARLOCK == nil) or (Bartender4 == nil) or (Bartender4.ActionBar == nil)) then
			return false
		else
			if (not Bartender4.ActionBar.GREYONCOOLDOWN_BT4_HOOKED) then
				hooksecurefunc(Bartender4.ActionBar, 'ApplyConfig', GreyOnCooldown.HookBartender4GreyOnCooldownIcons)
				Bartender4.ActionBar.GREYONCOOLDOWN_BT4_HOOKED = true
			end
			local LibActionButton = LibStub:GetLibrary("LibActionButton-1.0", true)
			if LibActionButton then
				LibActionButton.RegisterCallback(self, "OnButtonUpdate", function(event, button)
					ActionButtonGreyOnCooldown_UpdateCooldown(button)
				end)
			end
			self.AddonBartender4IsPresent = true
			return true
		end
	end
end

-- Function to hook to 'Bartender4.ActionBar.ApplyConfig' to reconfigure all BT4Buttons when Bartender4 ActionBars are loaded or modified
function GreyOnCooldown:HookBartender4GreyOnCooldownIcons()
	for i = 1, 120 do
		if (not GreyOnCooldown.Bartender4ButtonsTable[i]) then
			GreyOnCooldown.Bartender4ButtonsTable[i] = _G["BT4Button"..i]
			local button = GreyOnCooldown.Bartender4ButtonsTable[i]
			if (button and (not button.GREYONCOOLDOWN_BT4_HOOKED)) then
				-- Hook to 'GetCooldown' (BT4Button) function because we can't hook the local 'UpdateCooldown' (BT4Button) function
				hooksecurefunc(button, 'GetCooldown', ActionButtonGreyOnCooldown_UpdateCooldown)
				button.GREYONCOOLDOWN_BT4_HOOKED = true
			end
		end
	end
end

-- Function to desaturate the entire action icon when the spell is on cooldown
function GreyOnCooldown:HookGreyOnCooldownIcons()
	if (not GREYONCOOLDOWN_HOOKED) then
		local UpdateFuncCache = {}
		function ActionButtonGreyOnCooldown_UpdateCooldown(self, expectedUpdate)
			local icon = self.icon
			local action = GreyOnCooldown:CheckAddonBartender4() and self._state_action or self.action
			if (icon and action) then
				local start, duration = GetActionCooldown(action)
				if (duration >= GreyOnCooldown.db.profile.minDuration) then
					if start > 3085367 and start <= 4294967.295 then
						start = start - 4294967.296
					end
					if ((not self.onCooldown) or (self.onCooldown == 0)) then
						local nextTime = start + duration - GetTime() - 1.0
						if (nextTime < -1.0) then
							nextTime = 0.05
						elseif (nextTime < 0) then
							nextTime = -nextTime / 2
						end
						if nextTime <= 4294967.295 then
							local func = UpdateFuncCache[self]
							if not func then
								func = function() ActionButtonGreyOnCooldown_UpdateCooldown(self, true) end
								UpdateFuncCache[self] = func
							end
							C_Timer.After(nextTime, func)
						end
					elseif (expectedUpdate) then
						if ((not self.onCooldown) or (self.onCooldown < start + duration)) then
							self.onCooldown = start + duration
						end
						local nextTime = 0.05
						local timeRemains = self.onCooldown-GetTime()
						if (timeRemains > 0.31) then
							nextTime = timeRemains / 5
						elseif (timeRemains < 0) then
							nextTime = 0.05
						end
						if nextTime <= 4294967.295 then
							local func = UpdateFuncCache[self]
							if not func then
								func = function() ActionButtonGreyOnCooldown_UpdateCooldown(self, true) end
								UpdateFuncCache[self] = func
							end
							C_Timer.After(nextTime, func)
						end
					end
					if ((not self.onCooldown) or (self.onCooldown < start + duration)) then
						self.onCooldown = start + duration
					end
					if (not icon:IsDesaturated()) then
						icon:SetDesaturated(true)
					end
				else
					self.onCooldown = 0
					if (icon:IsDesaturated()) then
						icon:SetDesaturated(false)
					end
				end
			end
		end
		-- We hook to 'ActionButton_UpdateCooldown' instead of 'ActionButton_OnUpdate' because 'ActionButton_OnUpdate' is much more expensive. So, we need use C_Timer.After to trigger the function when cooldown ends.
		hooksecurefunc('ActionButton_UpdateCooldown', ActionButtonGreyOnCooldown_UpdateCooldown)
		GREYONCOOLDOWN_HOOKED = true
	end
end
