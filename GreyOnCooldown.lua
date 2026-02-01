-- ------------------------------------------------------------ --
-- Addon: GreyOnCooldown                                        --
--                                                              --
-- Version: 1.1.7                                               --
-- WoW Game Version: 5.5.3                                      --
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
		disabledConsoleStatusMessages = false,
		desaturateUnusableActions = true,
		desaturatePetActionButtons = true,
		minDuration = 2.01
	}
}

-- Global variables
GreyOnCooldown.VERSION = "1.1.7"
GreyOnCooldown.NUM_ACTIONBAR_BUTTONS = NUM_ACTIONBAR_BUTTONS or 12
GreyOnCooldown.NUM_PET_ACTION_SLOTS = NUM_PET_ACTION_SLOTS or 10
GreyOnCooldown.CheckAddonsWindowTime = 90
GreyOnCooldown.CheckAddonsTickTime = 4
GreyOnCooldown.CheckAddonsTicker = nil
GreyOnCooldown.AddonLABIsPresent = nil
GreyOnCooldown.AddonBT4IsPresent = nil
GreyOnCooldown.LABButtonsTable = {}
GreyOnCooldown.LABUpdateFuncCache1 = {}
GreyOnCooldown.LABUpdateFuncCache2 = {}
GreyOnCooldown.GOCLoadTimestamp = nil

-- First function fired
function GreyOnCooldown:OnInitialize()
	self.GOCLoadTimestamp = GetTime()
	self.db = AceDB:New("GreyOnCooldown_DB", self.defaults, true)

	self.optionsTable.args.profiles = AceDBOptions:GetOptionsTable(self.db)

	AceConfig:RegisterOptionsTable("GreyOnCooldown", self.optionsTable)

	self.db.RegisterCallback(self, "OnProfileChanged", "RefreshConfig")
	self.db.RegisterCallback(self, "OnProfileCopied", "RefreshConfig")
	self.db.RegisterCallback(self, "OnProfileReset", "RefreshConfig")

	self.optionsFramesCatId = {}
	self.optionsFrames = {}
	self.optionsFrames.general, self.optionsFramesCatId.general = AceConfigDialog:AddToBlizOptions("GreyOnCooldown", nil, nil, "general")
	self.optionsFrames.profiles, self.optionsFramesCatId.profiles = AceConfigDialog:AddToBlizOptions("GreyOnCooldown", L["Profiles"], "GreyOnCooldown", "profiles")

	self:RegisterChatCommand("GreyOnCooldown", "SlashCommand")
	self:RegisterChatCommand("GOC", "SlashCommand")

	if NUM_ACTIONBAR_BUTTONS ~= nil then
		GreyOnCooldown.NUM_ACTIONBAR_BUTTONS = NUM_ACTIONBAR_BUTTONS
	end
	if NUM_PET_ACTION_SLOTS ~= nil then
		GreyOnCooldown.NUM_PET_ACTION_SLOTS = NUM_PET_ACTION_SLOTS
	end

	-- Start GreyOnCooldown Core
	if (self.db.profile.enabled) then
		self:Enable()
		self:MainFunction()
	else
		self:Disable()
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
			self:CheckAddonLAB()
		end
	else
		if (self.db.profile.enabled) then
			self:Enable()
			self:HookGreyOnCooldownIcons()
			self:CheckAddonLAB()
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
	elseif (cmd == "disableconsolestatusmessages") or (cmd == "disablecsm") or (cmd == "dcsm") then
		local newValue
		if (arg1 == "") or (arg1 == "toggle") then
			newValue = not(GreyOnCooldown.db.profile.disabledConsoleStatusMessages)
		elseif (arg1 == "default") then
			newValue = GreyOnCooldown.db.defaults.profile.disabledConsoleStatusMessages
		elseif (arg1 == "on") or (arg1 == "enable") or (arg1 == "1") then
			newValue = true
		elseif (arg1 == "off") or (arg1 == "disable") or (arg1 == "0") or (arg1 == "-1") then
			newValue = false
		end
		if (newValue ~= nil) then
			if (GreyOnCooldown.db.profile.disabledConsoleStatusMessages ~= newValue) then
				GreyOnCooldown.db.profile.disabledConsoleStatusMessages = newValue
			end
			if not(GreyOnCooldown.db.profile.disabledConsoleStatusMessages) then
				GreyOnCooldown:Print("|cffd2a679" .. L['GreyOnCooldown'] .. '->disabledConsoleStatusMessages = ' .. tostring(GreyOnCooldown.db.profile.disabledConsoleStatusMessages) .. "|r")
			end
		end
	elseif (cmd == "desaturateunusableactions") or (cmd == "desaturateua") or (cmd == "dua") then
		local newValue
		if (arg1 == "") or (arg1 == "toggle") then
			newValue = not(GreyOnCooldown.db.profile.desaturateUnusableActions)
		elseif (arg1 == "default") then
			newValue = GreyOnCooldown.db.defaults.profile.desaturateUnusableActions
		elseif (arg1 == "on") or (arg1 == "enable") or (arg1 == "1") then
			newValue = true
		elseif (arg1 == "off") or (arg1 == "disable") or (arg1 == "0") or (arg1 == "-1") then
			newValue = false
		end
		if (newValue ~= nil) then
			if (GreyOnCooldown.db.profile.desaturateUnusableActions ~= newValue) then
				GreyOnCooldown.db.profile.desaturateUnusableActions = newValue
				if (GreyOnCooldown:IsEnabled()) then
					if (newValue) then
						GreyOnCooldown:HookGreyOnCooldownIcons()
					else
						GreyOnCooldown:UpdateAllActionButtons()
					end
				end
			end
			if not(GreyOnCooldown.db.profile.disabledConsoleStatusMessages) then
				GreyOnCooldown:Print("|cffd2a679" .. L['GreyOnCooldown'] .. '->desaturateUnusableActions = ' .. tostring(GreyOnCooldown.db.profile.desaturateUnusableActions) .. "|r")
			end
		end
	elseif (cmd == "desaturatepetactionbuttons") or (cmd == "desaturatepab") or (cmd == "dpab") then
		local newValue
		if (arg1 == "") or (arg1 == "toggle") then
			newValue = not(GreyOnCooldown.db.profile.desaturatePetActionButtons)
		elseif (arg1 == "default") then
			newValue = GreyOnCooldown.db.defaults.profile.desaturatePetActionButtons
		elseif (arg1 == "on") or (arg1 == "enable") or (arg1 == "1") then
			newValue = true
		elseif (arg1 == "off") or (arg1 == "disable") or (arg1 == "0") or (arg1 == "-1") then
			newValue = false
		end
		if (newValue ~= nil) then
			if (GreyOnCooldown.db.profile.desaturatePetActionButtons ~= newValue) then
				GreyOnCooldown.db.profile.desaturatePetActionButtons = newValue
				if (GreyOnCooldown:IsEnabled()) then
					GreyOnCooldown:HookPetActionButtons()
					if (GreyOnCooldown:CheckAddonBT4()) then
						GreyOnCooldown:HookGOCBT4PetActionButtons()
					end
				end
			end
			if not(GreyOnCooldown.db.profile.disabledConsoleStatusMessages) then
				GreyOnCooldown:Print("|cffd2a679" .. L['GreyOnCooldown'] .. '->desaturatePetActionButtons = ' .. tostring(GreyOnCooldown.db.profile.desaturatePetActionButtons) .. "|r")
			end
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
			if not(GreyOnCooldown.db.profile.disabledConsoleStatusMessages) then
				GreyOnCooldown:Print("|cffd2a679" .. L['GreyOnCooldown'] .. '->minDuration = ' .. tostring(GreyOnCooldown.db.profile.minDuration) .. "|r")
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
	GreyOnCooldown:Print("|cffd2a679" .. L['GREYONCOOLDOWN_HELP_LINE7'] .. "|r")
	GreyOnCooldown:Print("|cffd2a679" .. L['GREYONCOOLDOWN_HELP_LINE8'] .. "|r")
	GreyOnCooldown:Print("|cffd2a679" .. L['GREYONCOOLDOWN_HELP_LINE9'] .. "|r")
end

-- Function loaded when GreyOnCooldown is Enabled
function GreyOnCooldown:OnEnable()
	if not(GreyOnCooldown.db.profile.disabledConsoleStatusMessages) then
		DEFAULT_CHAT_FRAME:AddMessage('|cffd78900' .. L['GreyOnCooldown'] .. ' v' .. GreyOnCooldown.VERSION .. '|r ' .. L['enabled'])
	end
end

-- Function loaded when GreyOnCooldown is Disabled
function GreyOnCooldown:OnDisable()
	if not(GreyOnCooldown.db.profile.disabledConsoleStatusMessages) then
		DEFAULT_CHAT_FRAME:AddMessage('|cffd78900' .. L['GreyOnCooldown'] .. ' v' .. GreyOnCooldown.VERSION .. '|r ' .. L['disabled'])
	end
end

-- Show Options Menu
function GreyOnCooldown:ShowConfig(category)
	if (category ~= nil) then
		if (category == 0) then
			Settings.OpenToCategory(self.optionsFramesCatId.general)
		elseif (category == 1) then
			Settings.OpenToCategory(self.optionsFramesCatId.profiles)
		end
	else
		Settings.OpenToCategory(self.optionsFramesCatId.general)
	end
end

-- GreyOnCooldown MainFunction
function GreyOnCooldown:MainFunction()
	-- Set ActionButton hooks to desaturate the entire action icon when the spell is on cooldown or unusable
	GreyOnCooldown:HookGreyOnCooldownIcons()
	-- Check for the presence of addons (LAB and BT4)
	GreyOnCooldown:CheckAddonLAB()
	GreyOnCooldown:CheckAddonBT4()
	-- Create a ticker to periodically check for the presence of addons
	if (GreyOnCooldown.CheckAddonsTicker == nil and (GreyOnCooldown.AddonLABIsPresent == nil or GreyOnCooldown.AddonBT4IsPresent == nil)) then
		GreyOnCooldown.CheckAddonsTicker = C_Timer.NewTicker(GreyOnCooldown.CheckAddonsTickTime, function()
			GreyOnCooldown:CheckAddonLAB()
			GreyOnCooldown:CheckAddonBT4()
			if (GreyOnCooldown.AddonLABIsPresent ~= nil and GreyOnCooldown.AddonBT4IsPresent ~= nil) then
				GreyOnCooldown.CheckAddonsTicker:Cancel()
				GreyOnCooldown.CheckAddonsTicker = nil
			end
		end, math.floor(GreyOnCooldown.CheckAddonsWindowTime/GreyOnCooldown.CheckAddonsTickTime)+1)
	end
end

-- Function to Update the state of all action buttons
function GreyOnCooldown:UpdateAllActionButtons()
	if (ActionButtonGreyOnCooldown_UpdateCooldown) then
		for i = 1, GreyOnCooldown.NUM_ACTIONBAR_BUTTONS do
			local actionButton
			actionButton = _G["ExtraActionButton"..i]
			if (actionButton) then
				ActionButtonGreyOnCooldown_UpdateCooldown(actionButton)
			end
			actionButton = _G["ActionButton"..i]
			if (actionButton) then
				ActionButtonGreyOnCooldown_UpdateCooldown(actionButton)
			end
			actionButton = _G["MultiBarBottomLeftButton"..i]
			if (actionButton) then
				ActionButtonGreyOnCooldown_UpdateCooldown(actionButton)
			end
			actionButton = _G["MultiBarBottomRightButton"..i]
			if (actionButton) then
				ActionButtonGreyOnCooldown_UpdateCooldown(actionButton)
			end
			actionButton = _G["MultiBarLeftButton"..i]
			if (actionButton) then
				ActionButtonGreyOnCooldown_UpdateCooldown(actionButton)
			end
			actionButton = _G["MultiBarRightButton"..i]
			if (actionButton) then
				ActionButtonGreyOnCooldown_UpdateCooldown(actionButton)
			end
			actionButton = _G["StanceButton"..i]
			if (actionButton) then
				ActionButtonGreyOnCooldown_UpdateCooldown(actionButton)
			end
			actionButton = _G["PossessButton"..i]
			if (actionButton) then
				ActionButtonGreyOnCooldown_UpdateCooldown(actionButton)
			end
			actionButton = _G["OverrideActionBarButton"..i]
			if (actionButton) then
				ActionButtonGreyOnCooldown_UpdateCooldown(actionButton)
			end
		end
		for i = 1, 40 do
			local actionButton = _G["SpellFlyoutPopupButton"..i]
			if (actionButton) then
				ActionButtonGreyOnCooldown_UpdateCooldown(actionButton)
			end
		end
		if (GreyOnCooldown:CheckAddonLAB()) then
			local LibActionButton = LibStub:GetLibrary("LibActionButton-1.0", true)
			if LibActionButton then
				for actionButton in next, LibActionButton.buttonRegistry do
					ActionButtonGreyOnCooldown_UpdateCooldown(actionButton)
				end
			end
		end
	end
	if (GreyOnCooldown.db.profile.desaturatePetActionButtons and PetActionButtonGreyOnCooldown_Update) then
		for i = 1, GreyOnCooldown.NUM_PET_ACTION_SLOTS do
			local actionButton = _G["PetActionButton"..i]
			if (actionButton) then
				PetActionButtonGreyOnCooldown_Update(actionButton)
			end
		end
		if (GreyOnCooldown:CheckAddonBT4()) then
			local petBarModule = Bartender4 ~= nil and Bartender4.GetModule ~= nil and Bartender4:GetModule("PetBar")
			if (petBarModule) then
				if (petBarModule.bar and petBarModule.bar.buttons) then
					for _, petActionButton in ipairs(petBarModule.bar.buttons) do
						if (petActionButton) then
							PetActionButtonGreyOnCooldown_Update(petActionButton)
						end
					end
				end
			end
		end
	end
end

-- Function that establishes the needed GOC hooks for an PetActionButton
function GreyOnCooldown:HookGOCPetActionButtonUpdate(button)
	if (button == nil) then return end
	if (button.cooldown) then
		if (GREYONCOOLDOWN_ONCOOLDOWNDONE_HOOKED_ABC == nil) then
			GREYONCOOLDOWN_ONCOOLDOWNDONE_HOOKED_ABC = {}
		end
		if not(GREYONCOOLDOWN_ONCOOLDOWNDONE_HOOKED_ABC[button]) then
			button.cooldown:HookScript("OnCooldownDone", PetActionButtonGreyOnCooldown_ParentUpdateHookFunc)
			GREYONCOOLDOWN_ONCOOLDOWNDONE_HOOKED_ABC[button] = true
		end
		if (GREYONCOOLDOWN_ONSHOW_HOOKED_ABC == nil) then
			GREYONCOOLDOWN_ONSHOW_HOOKED_ABC = {}
		end
		if not(GREYONCOOLDOWN_ONSHOW_HOOKED_ABC[button]) then
			button.cooldown:HookScript("OnShow", PetActionButtonGreyOnCooldown_ParentUpdateHookFunc)
			GREYONCOOLDOWN_ONSHOW_HOOKED_ABC[button] = true
		end
		if (GREYONCOOLDOWN_ONHIDE_HOOKED_ABC == nil) then
			GREYONCOOLDOWN_ONHIDE_HOOKED_ABC = {}
		end
		if not(GREYONCOOLDOWN_ONHIDE_HOOKED_ABC[button]) then
			button.cooldown:HookScript("OnHide", PetActionButtonGreyOnCooldown_ParentUpdateHookFunc)
			GREYONCOOLDOWN_ONHIDE_HOOKED_ABC[button] = true
		end
	end
	if type(button.Update)=="function" then
		if (GREYONCOOLDOWN_UPDATE_HOOKED_AB == nil) then
			GREYONCOOLDOWN_UPDATE_HOOKED_AB = {}
		end
		if not(GREYONCOOLDOWN_UPDATE_HOOKED_AB[button]) then
			hooksecurefunc(button, "Update", PetActionButtonGreyOnCooldown_UpdateHookFunc)
			GREYONCOOLDOWN_UPDATE_HOOKED_AB[button] = true
		end
	end
	if not(GREYONCOOLDOWN_UPDATECOOLDOWNS_HOOKED_PAB) then
		hooksecurefunc('PetActionBar_UpdateCooldowns', function()
			if (GreyOnCooldown.db.profile.desaturatePetActionButtons) then
				for i = 1, GreyOnCooldown.NUM_PET_ACTION_SLOTS, 1 do
					local petActionButton = _G["PetActionButton"..i]
					PetActionButtonGreyOnCooldown_Update(petActionButton, i)
				end
			end
		end)
		GREYONCOOLDOWN_UPDATECOOLDOWNS_HOOKED_PAB = true
	end
	if (PetActionButtonGreyOnCooldown_Update) then
		PetActionButtonGreyOnCooldown_Update(button)
	end
end

-- GreyOnCooldown function to desaturate pet action buttons when the spell is on cooldown or unusable
function GreyOnCooldown:HookPetActionButtons()
	if (not GREYONCOOLDOWN_HOOKED_PAB) then
		function PetActionButtonGreyOnCooldown_Update(petActionButton, index)
			if (petActionButton == nil and index == nil) then return end
			if (petActionButton == nil) then
				petActionButton = _G["PetActionButton"..index]
				if (petActionButton == nil) then return end
			end
			if (index == nil) then
				index = petActionButton:GetID()
				if (index == nil) then return end
			end
			if (petActionButton and petActionButton.icon) then
				if (GreyOnCooldown.db.profile.desaturatePetActionButtons) then
					if (GreyOnCooldown.db.profile.desaturateUnusableActions) then
						if not(GetPetActionSlotUsable(index)) then
							petActionButton.icon:SetDesaturated(true)
							return
						end
					end
					local _, duration, enable = GetPetActionCooldown(index)
					if (enable and duration and duration > 0 and duration >= GreyOnCooldown.db.profile.minDuration) then
						petActionButton.icon:SetDesaturated(true)
					else
						petActionButton.icon:SetDesaturated(false)
					end
				else
					petActionButton.icon:SetDesaturated(false)
				end
			end
		end
		function PetActionButtonGreyOnCooldown_UpdateHookFunc(self)
			PetActionButtonGreyOnCooldown_Update(self)
		end
		function PetActionButtonGreyOnCooldown_ParentUpdateHookFunc(self)
			PetActionButtonGreyOnCooldown_Update(self:GetParent())
		end
		for i = 1, GreyOnCooldown.NUM_PET_ACTION_SLOTS, 1 do
			local button = _G["PetActionButton"..i]
			if (button) then
				GreyOnCooldown:HookGOCPetActionButtonUpdate(button)
			end
		end
		GREYONCOOLDOWN_HOOKED_PAB = true
	end
	if (PetActionButtonGreyOnCooldown_Update) then
		for i = 1, GreyOnCooldown.NUM_PET_ACTION_SLOTS, 1 do
			PetActionButtonGreyOnCooldown_Update(nil, i)
		end
	end
end

-- GreyOnCooldown main function to desaturate the entire action icon when the spell is on cooldown or unusable
function GreyOnCooldown:HookGreyOnCooldownIcons()
	if (not GREYONCOOLDOWN_HOOKED) then
		local UpdateFuncCache = {}
		-- Main hooks for 'ActionButtons'
		function ActionButtonGreyOnCooldown_UpdateCooldown(self, expectedUpdate)
			local icon = self.icon
			local spellID
			local action
			if GreyOnCooldown:CheckAddonLAB() then
				if (self._state_type == "spell") then
					spellID = self._state_action
				else
					spellID = self.spellID
					action = self._state_action
				end
			else
				spellID = self.spellID
				action = self.action
			end
			if (icon and ((action and type(action)~="table" and type(action)~="string") or (spellID and type(spellID)~="table" and type(spellID)~="string"))) then
				local start, duration
				if (spellID) then
					start, duration = GetSpellCooldown(spellID)
				else
					start, duration = GetActionCooldown(action)
				end
				if (duration >= GreyOnCooldown.db.profile.minDuration) then
					if start > 3085367 and start <= 4294967.295 then
						start = start - 4294967.296
					end
					if ((not self.onCooldown) or (self.onCooldown == 0)) then
						self.onCooldown = start + duration
						local nextTime = start + duration - GetTime() - 0.1
						if (nextTime < -0.1) then
							nextTime = 0.025
						elseif (nextTime < 0) then
							nextTime = 0.051
						end
						if nextTime <= 4294967.295 then
							local func = UpdateFuncCache[self]
							if not func then
								func = function() ActionButtonGreyOnCooldown_UpdateCooldown(self, true) end
								UpdateFuncCache[self] = func
							end
							C_Timer.After(nextTime, func)
						end
					elseif (expectedUpdate or (self.onCooldown > start + duration + 0.025)) then
						if (self.onCooldown ~= start + duration) then
							self.onCooldown = start + duration
						end
						local nextTime = 0.025
						local timeRemains = self.onCooldown - GetTime()
						if (timeRemains > 0.041) then
							nextTime = timeRemains / 1.5
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
					if (not icon:IsDesaturated()) then
						icon:SetDesaturated(true)
					end
				else
					self.onCooldown = 0
					if (GreyOnCooldown.db.profile.desaturateUnusableActions and action) then
						local isUsable, notEnoughMana = IsUsableAction(action)
						if (isUsable or notEnoughMana) then
							if (icon:IsDesaturated()) then
								icon:SetDesaturated(false)
							end
						else
							if (not icon:IsDesaturated()) then
								icon:SetDesaturated(true)
							end
						end
					else
						if (icon:IsDesaturated()) then
							icon:SetDesaturated(false)
						end
					end
				end
			end
		end
		-- We hook to 'ActionButton_UpdateCooldown' instead of 'ActionButton_OnUpdate' because 'ActionButton_OnUpdate' is much more expensive. So, we need use C_Timer.After to trigger the function when cooldown ends.
		hooksecurefunc('ActionButton_UpdateCooldown', ActionButtonGreyOnCooldown_UpdateCooldown)
		-- Hooks for 'PetActionButtons'
		if (GreyOnCooldown.db.profile.desaturatePetActionButtons) then
			GreyOnCooldown:HookPetActionButtons()
		end
		GREYONCOOLDOWN_HOOKED = true
	end
	if (GreyOnCooldown.db.profile.desaturateUnusableActions) then
		-- Aux hooks for 'UpdateUsable'
		if (not GREYONCOOLDOWN_UPDATEUSABLE_HOOKED) then
			hooksecurefunc('ActionButton_UpdateUsable', function(self)
				if (GreyOnCooldown.db.profile.desaturateUnusableActions) then
					if ((not self.onCooldown) or (self.onCooldown == 0)) then
						local icon = self.icon
						local spellID
						local action
						if GreyOnCooldown:CheckAddonLAB() then
							if (self._state_type == "spell") then
								spellID = self._state_action
							else
								spellID = self.spellID
								action = self._state_action
							end
						else
							spellID = self.spellID
							action = self.action
						end
						if (icon) then
							if (action and type(action)~="table" and type(action)~="string") then
								local isUsable, notEnoughMana = IsUsableAction(action)
								if (isUsable or notEnoughMana) then
									if (icon:IsDesaturated()) then
										icon:SetDesaturated(false)
									end
								else
									if (not icon:IsDesaturated()) then
										icon:SetDesaturated(true)
									end
								end
							elseif (spellID and type(spellID)~="table" and type(spellID)~="string") then
								local isUsable, notEnoughMana = C_Spell.IsSpellUsable(spellID)
								if (isUsable or notEnoughMana) then
									if (icon:IsDesaturated()) then
										icon:SetDesaturated(false)
									end
								else
									if (not icon:IsDesaturated()) then
										icon:SetDesaturated(true)
									end
								end
							end
						end
					end
				end
			end)
			GREYONCOOLDOWN_UPDATEUSABLE_HOOKED = true
		end
		-- Aux hooks for 'UpdateUsable' (LAB action buttons)
		if (GreyOnCooldown.AddonLABIsPresent) then
			local LibActionButton = LibStub:GetLibrary("LibActionButton-1.0", true)
			if LibActionButton then
				if (not LibActionButton.GREYONCOOLDOWN_ONBUTTONUSABLE_LAB_HOOKED) then
					LibActionButton.RegisterCallback(GreyOnCooldown, "OnButtonUsable", function(event, button)
						ActionButtonGreyOnCooldown_UpdateCooldown(button)
					end)
					LibActionButton.GREYONCOOLDOWN_ONBUTTONUSABLE_LAB_HOOKED = true
				end
			end
		end
	end
	GreyOnCooldown:UpdateAllActionButtons()
end

-- Hook function to update the LAB ActionButton (self)
GreyOnCooldown.LABButtonUpdateHookFunc = function(self)
	local func = GreyOnCooldown.LABUpdateFuncCache1[self]
	if not func then
		func = function() ActionButtonGreyOnCooldown_UpdateCooldown(self) end
		GreyOnCooldown.LABUpdateFuncCache1[self] = func
	end
	C_Timer.After(0.01, func)
end

-- Hook function to update the LAB ActionButton (self:GetParent())
GreyOnCooldown.LABButtonParentUpdateHookFunc = function(self)
	local func = GreyOnCooldown.LABUpdateFuncCache2[self]
	if not func then
		func = function() ActionButtonGreyOnCooldown_UpdateCooldown(self:GetParent()) end
		GreyOnCooldown.LABUpdateFuncCache2[self] = func
	end
	C_Timer.After(0.01, func)
end

-- Function to set the hooks for a new LAB ActionButton
function GreyOnCooldown:HookGOCLABActionButtonUpdate(button)
	if ((button ~= nil) and not(self.LABButtonsTable[button])) then
		if (not button.GREYONCOOLDOWN_LAB_HOOKED) then
			self.LABButtonsTable[button] = true
			-- Hook 'GetPassiveCooldownSpellID' (LABButton) function because we can't hook the local 'UpdateCooldown' (LABButton) function
			hooksecurefunc(button, "GetPassiveCooldownSpellID", GreyOnCooldown.LABButtonUpdateHookFunc)
			-- Hook 'icon.SetVertexColor' (LABButton) function because we can't hook the local 'UpdateUsable' (LABButton) function
			hooksecurefunc(button.icon, "SetVertexColor", GreyOnCooldown.LABButtonParentUpdateHookFunc)
			button.GREYONCOOLDOWN_LAB_HOOKED = true
		end
	end
end

-- Function to fast-check if some LibActionButtons-1.0 addon is present
function GreyOnCooldown:CheckAddonLAB()
	if (self.AddonLABIsPresent == false) then
		return false
	elseif (self.AddonLABIsPresent) then
		return true
	else
		if ((self.GOCLoadTimestamp == nil) or ((GetTime() - self.GOCLoadTimestamp) < self.CheckAddonsWindowTime)) then
			local LibActionButton = LibStub:GetLibrary("LibActionButton-1.0", true)
			if LibActionButton then
				if (not LibActionButton.GREYONCOOLDOWN_ONBUTTONUPDATE_LAB_HOOKED) then
					LibActionButton.RegisterCallback(self, "OnButtonUpdate", function(event, button)
						ActionButtonGreyOnCooldown_UpdateCooldown(button)
					end)
					LibActionButton.GREYONCOOLDOWN_ONBUTTONUPDATE_LAB_HOOKED = true
				end
				if (self.db.profile.desaturateUnusableActions) then
					if (not LibActionButton.GREYONCOOLDOWN_ONBUTTONUSABLE_LAB_HOOKED) then
						LibActionButton.RegisterCallback(self, "OnButtonUsable", function(event, button)
							ActionButtonGreyOnCooldown_UpdateCooldown(button)
						end)
						LibActionButton.GREYONCOOLDOWN_ONBUTTONUSABLE_LAB_HOOKED = true
					end
				end
				for button in next, LibActionButton.buttonRegistry do
					GreyOnCooldown:HookGOCLABActionButtonUpdate(button)
				end
				LibActionButton.RegisterCallback(self, "OnButtonCreated", function(event, button)
					GreyOnCooldown:HookGOCLABActionButtonUpdate(button)
				end)
				self.AddonLABIsPresent = true
				return true
			else
				return false
			end
		else
			self.AddonLABIsPresent = false
			return false
		end
	end
end

-- Function to iterate through BT4PetActionButtons and hook them
function GreyOnCooldown:HookGOCBT4PetActionButtons(petBarModule)
	if (petBarModule == nil) then
		if (Bartender4 ~= nil and Bartender4.GetModule ~= nil) then
			petBarModule = Bartender4:GetModule("PetBar")
		end
	end
	if (petBarModule ~= nil) then
		if (petBarModule.bar and petBarModule.bar.buttons) then
			for _, petActionButton in ipairs(petBarModule.bar.buttons) do
				GreyOnCooldown:HookGOCPetActionButtonUpdate(petActionButton)
			end
		end
		if (Bartender4 ~= nil and Bartender4.PetButton ~= nil and type(Bartender4.PetButton.Create) == "function") then
			if not(GREYONCOOLDOWN_BT4PETBUTTON_CREATE_HOOKED) then
				hooksecurefunc(Bartender4.PetButton, "Create", function(self, id, parent)
					if (id) then
						local button = _G["BT4PetButton"..id]
						if (button) then
							GreyOnCooldown:HookGOCPetActionButtonUpdate(button)
						end
					end
				end)
				GREYONCOOLDOWN_BT4PETBUTTON_CREATE_HOOKED = true
			end
		end
	end
end

-- Function to fast-check if BT4 addon is present
function GreyOnCooldown:CheckAddonBT4()
	if (self.AddonBT4IsPresent == false) then
		return false
	elseif (self.AddonBT4IsPresent) then
		return true
	else
		if ((self.GOCLoadTimestamp == nil) or ((GetTime() - self.GOCLoadTimestamp) < self.CheckAddonsWindowTime)) then
			if (Bartender4 ~= nil and Bartender4.GetModule ~= nil and Bartender4.PetButton ~= nil and type(Bartender4.PetButton.Create) == "function") then
				local petBarModule = Bartender4:GetModule("PetBar")
				if (petBarModule) then
					if (GreyOnCooldown.db.profile.desaturatePetActionButtons) then
						GreyOnCooldown:HookGOCBT4PetActionButtons(petBarModule)
					end
					self.AddonBT4IsPresent = true
					return true
				else
					return false
				end
			else
				return false
			end
		else
			self.AddonBT4IsPresent = false
			return false
		end
	end
end
