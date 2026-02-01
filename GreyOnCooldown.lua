-- ------------------------------------------------------------ --
-- Addon: GreyOnCooldown                                        --
--                                                              --
-- Version: 1.1.7                                               --
-- WoW Game Version: 2.5.5                                      --
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
local type = type
local pairs = pairs
local ipairs = ipairs
local next = next
local GetPetActionInfo = GetPetActionInfo
local GetPetActionSlotUsable = GetPetActionSlotUsable
local GetPetActionCooldown = GetPetActionCooldown
local IsUsableAction = IsUsableAction
local GetActionCooldown = GetActionCooldown
local C_Spell_IsSpellUsable = C_Spell.IsSpellUsable
local C_Spell_GetSpellCooldown = C_Spell.GetSpellCooldown

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
GreyOnCooldown.UpdateFuncCache2 = {}
GreyOnCooldown.AddonLABIsPresent = nil
GreyOnCooldown.AddonBT4IsPresent = nil
GreyOnCooldown.AddonDominosIsPresent = nil
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
			self:MainFunction()
		end
	else
		if (self.db.profile.enabled) then
			self:Enable()
			self:MainFunction()
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
					if (GREYONCOOLDOWN_HOOKED == GreyOnCooldown) then
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
					if (GREYONCOOLDOWN_HOOKED == GreyOnCooldown) then
						GreyOnCooldown:HookGOCPetActionButtons()
						if (GreyOnCooldown:CheckAddonBT4()) then
							GreyOnCooldown:HookGOCBT4PetActionButtons()
						end
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

-- Function to call the GOCUpdateCheck() for all action buttons
function GreyOnCooldown:UpdateAllActionButtons()
	for i = 1, GreyOnCooldown.NUM_ACTIONBAR_BUTTONS do
		local actionButton
		actionButton = _G["ExtraActionButton"..i]
		if (actionButton and actionButton.GOCUpdateCheck) then
			actionButton:GOCUpdateCheck()
		end
		actionButton = _G["ActionButton"..i]
		if (actionButton and actionButton.GOCUpdateCheck) then
			actionButton:GOCUpdateCheck()
		end
		actionButton = _G["MultiBarBottomLeftButton"..i]
		if (actionButton and actionButton.GOCUpdateCheck) then
			actionButton:GOCUpdateCheck()
		end
		actionButton = _G["MultiBarBottomRightButton"..i]
		if (actionButton and actionButton.GOCUpdateCheck) then
			actionButton:GOCUpdateCheck()
		end
		actionButton = _G["MultiBarLeftButton"..i]
		if (actionButton and actionButton.GOCUpdateCheck) then
			actionButton:GOCUpdateCheck()
		end
		actionButton = _G["MultiBarRightButton"..i]
		if (actionButton and actionButton.GOCUpdateCheck) then
			actionButton:GOCUpdateCheck()
		end
		actionButton = _G["StanceButton"..i]
		if (actionButton and actionButton.GOCUpdateCheck) then
			actionButton:GOCUpdateCheck()
		end
		actionButton = _G["PossessButton"..i]
		if (actionButton and actionButton.GOCUpdateCheck) then
			actionButton:GOCUpdateCheck()
		end
		actionButton = _G["OverrideActionBarButton"..i]
		if (actionButton and actionButton.GOCUpdateCheck) then
			actionButton:GOCUpdateCheck()
		end
	end
	for i = 1, 40 do
		local actionButton = _G["SpellFlyoutPopupButton"..i]
		if (actionButton and actionButton.GOCUpdateCheck) then
			actionButton:GOCUpdateCheck()
		end
	end
	if (GreyOnCooldown.db.profile.desaturatePetActionButtons) then
		for i = 1, GreyOnCooldown.NUM_PET_ACTION_SLOTS do
			local actionButton = _G["PetActionButton"..i]
			if (actionButton and actionButton.GOCUpdateCheck) then
				actionButton:GOCUpdateCheck()
			end
		end
		if (GreyOnCooldown:CheckAddonBT4()) then
			local petBarModule = Bartender4 ~= nil and Bartender4.GetModule ~= nil and Bartender4:GetModule("PetBar")
			if (petBarModule) then
				if (petBarModule.bar and petBarModule.bar.buttons) then
					for _, petActionButton in ipairs(petBarModule.bar.buttons) do
						if (petActionButton.GOCUpdateCheck) then
							petActionButton:GOCUpdateCheck()
						end
					end
				end
			end
		end
	end
	if (GreyOnCooldown:CheckAddonLAB()) then
		local LibActionButton = LibStub:GetLibrary("LibActionButton-1.0", true)
		if LibActionButton then
			for actionButton in next, LibActionButton.buttonRegistry do
				if (actionButton.GOCUpdateCheck) then
					actionButton:GOCUpdateCheck()
				end
			end
		end
	end
	if (GreyOnCooldown:CheckAddonDominos()) then
		if (Dominos ~= nil and Dominos.ActionButtons ~= nil and Dominos.ActionButtons.buttons ~= nil) then
			for button in next, Dominos.ActionButtons.buttons do
				GreyOnCooldown:HookGOCActionButtonUpdate(button)
			end
		end
	end
end

-- Main GOC ActionButton Update function to desaturate the entire action icon when the spell is on cooldown or unusable
GreyOnCooldown.GOCActionButtonUpdateCheck = function(self)
	if not(self.icon) then return end
	local action
	local spellID
	if GreyOnCooldown:CheckAddonLAB() then
		if (self._state_type == "action") then
			action = self._state_action
		elseif (self._state_type == "spell") then
			spellID = self._state_action
		end
	else
		action = self.action
		spellID = self.spellID
	end
	if (action) then
		if (GreyOnCooldown.db.profile.desaturateUnusableActions) then
			local isUsable, notEnoughMana = IsUsableAction(action)
			if not(isUsable or notEnoughMana) then
				self.icon:SetDesaturated(true)
				return
			end
		end
		local _, duration = GetActionCooldown(action)
		if (duration >= GreyOnCooldown.db.profile.minDuration) then
			self.icon:SetDesaturated(true)
		else
			self.icon:SetDesaturated(false)
		end
	elseif (spellID) then
		if (GreyOnCooldown.db.profile.desaturateUnusableActions) then
			local isUsable, notEnoughMana = C_Spell_IsSpellUsable(spellID)
			if not(isUsable or notEnoughMana) then
				self.icon:SetDesaturated(true)
				return
			end
		end
		local spellCooldownInfo = C_Spell_GetSpellCooldown(spellID)
		if spellCooldownInfo then
			if (spellCooldownInfo.duration >= GreyOnCooldown.db.profile.minDuration) then
				self.icon:SetDesaturated(true)
			else
				self.icon:SetDesaturated(false)
			end
		end
	end
end

-- Main GOC PetActionButton Update function to desaturate the entire action icon when the spell is on cooldown or unusable
GreyOnCooldown.GOCPetActionButtonUpdateCheck = function(self)
	local index = self.index or self.id
	if not(self.icon and index and GetPetActionInfo(index)) then return end
	if (GreyOnCooldown.db.profile.desaturatePetActionButtons) then
		if (GreyOnCooldown.db.profile.desaturateUnusableActions) then
			if not(GetPetActionSlotUsable(index)) then
				self.icon:SetDesaturated(true)
				return
			end
		end
		local _, duration, enable = GetPetActionCooldown(index)
		if (enable and duration and duration >= GreyOnCooldown.db.profile.minDuration) then
			self.icon:SetDesaturated(true)
		else
			self.icon:SetDesaturated(false)
		end
	else
		self.icon:SetDesaturated(false)
	end
end

-- Hook function to update the ActionButton (self)
GreyOnCooldown.ButtonUpdateHookFunc = function(self)
	if (self.GOCUpdateCheck) then
		self:GOCUpdateCheck()
	end
end

-- Hook function to update the ActionButton (self:GetParent())
GreyOnCooldown.ButtonParentUpdateHookFunc = function(self)
	if (self:GetParent().GOCUpdateCheck) then
		self:GetParent():GOCUpdateCheck()
	end
end

-- Hook function to delayed-update the ActionButton (self:GetParent())
GreyOnCooldown.ButtonParentDelayedUpdateHookFunc = function(self)
	local func = GreyOnCooldown.UpdateFuncCache2[self]
	if not func then
		func = function() self:GetParent():GOCUpdateCheck() end
		GreyOnCooldown.UpdateFuncCache2[self] = func
	end
	C_Timer.After(0.01, func)
end

-- Function that establishes the needed GOC hooks for an ActionButton
function GreyOnCooldown:HookGOCActionButtonUpdate(button)
	-- Establish the main GOC ActionButton Update function
	if (GREYONCOOLDOWN_UPDATECHECK_SET_AB == nil) then
		GREYONCOOLDOWN_UPDATECHECK_SET_AB = {}
	end
	if not(GREYONCOOLDOWN_UPDATECHECK_SET_AB[button]) then
		button.GOCUpdateCheck = ActionButton_GreyOnCooldown_UpdateCheck
		GREYONCOOLDOWN_UPDATECHECK_SET_AB[button] = true
	end
	-- ActionButton essentials GOC hooks (AB hooks: OnCooldownDone, OnShow, OnHide, Update, UpdateUsable)
	if button.cooldown then
		if (GREYONCOOLDOWN_ONCOOLDOWNDONE_HOOKED_ABC == nil) then
			GREYONCOOLDOWN_ONCOOLDOWNDONE_HOOKED_ABC = {}
		end
		if not(GREYONCOOLDOWN_ONCOOLDOWNDONE_HOOKED_ABC[button]) then
			button.cooldown:HookScript("OnCooldownDone", GreyOnCooldown.ButtonParentDelayedUpdateHookFunc)
			GREYONCOOLDOWN_ONCOOLDOWNDONE_HOOKED_ABC[button] = true
		end
		if (GREYONCOOLDOWN_ONSHOW_HOOKED_ABC == nil) then
			GREYONCOOLDOWN_ONSHOW_HOOKED_ABC = {}
		end
		if not(GREYONCOOLDOWN_ONSHOW_HOOKED_ABC[button]) then
			button.cooldown:HookScript("OnShow", GreyOnCooldown.ButtonParentUpdateHookFunc)
			GREYONCOOLDOWN_ONSHOW_HOOKED_ABC[button] = true
		end
		if (GREYONCOOLDOWN_ONHIDE_HOOKED_ABC == nil) then
			GREYONCOOLDOWN_ONHIDE_HOOKED_ABC = {}
		end
		if not(GREYONCOOLDOWN_ONHIDE_HOOKED_ABC[button]) then
			button.cooldown:HookScript("OnHide", GreyOnCooldown.ButtonParentDelayedUpdateHookFunc)
			GREYONCOOLDOWN_ONHIDE_HOOKED_ABC[button] = true
		end
	end
	if type(button.Update)=="function" then
		if (GREYONCOOLDOWN_UPDATE_HOOKED_AB == nil) then
			GREYONCOOLDOWN_UPDATE_HOOKED_AB = {}
		end
		if not(GREYONCOOLDOWN_UPDATE_HOOKED_AB[button]) then
			hooksecurefunc(button, "Update", GreyOnCooldown.ButtonUpdateHookFunc)
			GREYONCOOLDOWN_UPDATE_HOOKED_AB[button] = true
		end
	end
	if type(button.UpdateUsable)=="function" then
		if (GREYONCOOLDOWN_UPDATEUSABLE_HOOKED_AB == nil) then
			GREYONCOOLDOWN_UPDATEUSABLE_HOOKED_AB = {}
		end
		if not(GREYONCOOLDOWN_UPDATEUSABLE_HOOKED_AB[button]) then
			hooksecurefunc(button, "UpdateUsable", GreyOnCooldown.ButtonUpdateHookFunc)
			GREYONCOOLDOWN_UPDATEUSABLE_HOOKED_AB[button] = true
		end
	end
	if type(button.UpdateAction) == "function" then
		if (GREYONCOOLDOWN_UPDATEACTION_HOOKED_AB == nil) then
			GREYONCOOLDOWN_UPDATEACTION_HOOKED_AB = {}
		end
		if not(GREYONCOOLDOWN_UPDATEACTION_HOOKED_AB[button]) then
			hooksecurefunc(button, "UpdateAction", GreyOnCooldown.ButtonUpdateHookFunc)
			GREYONCOOLDOWN_UPDATEACTION_HOOKED_AB[button] = true
		end
	end
	if (button.GOCUpdateCheck) then
		button:GOCUpdateCheck()
	end
end

-- Function that establishes the needed GOC hooks for an PetActionButton
function GreyOnCooldown:HookGOCPetActionButtonUpdate(button)
	-- Establish the main GOC PetActionButton Update function
	if (GREYONCOOLDOWN_UPDATECHECK_SET_AB == nil) then
		GREYONCOOLDOWN_UPDATECHECK_SET_AB = {}
	end
	if not(GREYONCOOLDOWN_UPDATECHECK_SET_AB[button]) then
		button.GOCUpdateCheck = PetActionButton_GreyOnCooldown_UpdateCheck
		GREYONCOOLDOWN_UPDATECHECK_SET_AB[button] = true
	end
	-- PetActionButton essentials GOC hooks (AB hooks: OnCooldownDone, OnShow, OnHide, Update, UpdateCooldowns)
	if button.cooldown then
		if (GREYONCOOLDOWN_ONCOOLDOWNDONE_HOOKED_ABC == nil) then
			GREYONCOOLDOWN_ONCOOLDOWNDONE_HOOKED_ABC = {}
		end
		if not(GREYONCOOLDOWN_ONCOOLDOWNDONE_HOOKED_ABC[button]) then
			button.cooldown:HookScript("OnCooldownDone", GreyOnCooldown.ButtonParentDelayedUpdateHookFunc)
			GREYONCOOLDOWN_ONCOOLDOWNDONE_HOOKED_ABC[button] = true
		end
		if (GREYONCOOLDOWN_ONSHOW_HOOKED_ABC == nil) then
			GREYONCOOLDOWN_ONSHOW_HOOKED_ABC = {}
		end
		if not(GREYONCOOLDOWN_ONSHOW_HOOKED_ABC[button]) then
			button.cooldown:HookScript("OnShow", GreyOnCooldown.ButtonParentUpdateHookFunc)
			GREYONCOOLDOWN_ONSHOW_HOOKED_ABC[button] = true
		end
		if (GREYONCOOLDOWN_ONHIDE_HOOKED_ABC == nil) then
			GREYONCOOLDOWN_ONHIDE_HOOKED_ABC = {}
		end
		if not(GREYONCOOLDOWN_ONHIDE_HOOKED_ABC[button]) then
			button.cooldown:HookScript("OnHide", GreyOnCooldown.ButtonParentDelayedUpdateHookFunc)
			GREYONCOOLDOWN_ONHIDE_HOOKED_ABC[button] = true
		end
	end
	if type(button.Update)=="function" then
		if (GREYONCOOLDOWN_UPDATE_HOOKED_AB == nil) then
			GREYONCOOLDOWN_UPDATE_HOOKED_AB = {}
		end
		if not(GREYONCOOLDOWN_UPDATE_HOOKED_AB[button]) then
			hooksecurefunc(button, "Update", GreyOnCooldown.ButtonUpdateHookFunc)
			GREYONCOOLDOWN_UPDATE_HOOKED_AB[button] = true
		end
	end
	if not(GREYONCOOLDOWN_UPDATECOOLDOWNS_HOOKED_PAB) then
		if (PetActionBar ~= nil and type(PetActionBar.UpdateCooldowns) == "function") then
			hooksecurefunc(PetActionBar, "UpdateCooldowns", function(self)
				for i = 1, GreyOnCooldown.NUM_PET_ACTION_SLOTS do
					local button = self.actionButtons[i]
					if (button and button.GOCUpdateCheck) then
						button:GOCUpdateCheck()
					end
				end
			end)
		end
		GREYONCOOLDOWN_UPDATECOOLDOWNS_HOOKED_PAB = true
	end
	if (button.GOCUpdateCheck) then
		button:GOCUpdateCheck()
	end
end

-- Function to set hooks for SpellFlyout frame to detect the newly created SpellFlyoutButtons
function GreyOnCooldown:HookGOCSpellFlyout()
	if not(GREYONCOOLDOWN_SPELLFLYOUT_HOOKED) then
		hooksecurefunc(SpellFlyout, "Toggle", function(self, flyoutButton, flyoutID, isActionBar, specID, showFullTooltip, reason)
			if (not(self:IsShown()) and self.glyphActivating) then
				return
			end
			if (not(self:IsShown()) and self.flyoutButton == nil) then
				return
			end
			local offSpec = specID and (specID ~= 0)
			local _, _, numSlots, isKnown = GetFlyoutInfo(flyoutID)
			if ((not isKnown and not offSpec) or numSlots == 0) then
				return
			end
			local numButtons = 0
			for i = 1, numSlots do
				local spellID, _, isKnownSlot, _, slotSpecID = GetFlyoutSlotInfo(flyoutID, i)
				local visible = true
				local petIndex, petName = GetCallPetSpellInfo(spellID)
				if (isActionBar and petIndex and (not petName or petName == "")) then
					visible = false
				end
				if (((not offSpec or slotSpecID == 0) and visible and isKnownSlot) or (offSpec and slotSpecID == specID)) then
					local button = _G["SpellFlyoutPopupButton"..numButtons+1]
					if (button ~= nil) then
						GreyOnCooldown:HookGOCActionButtonUpdate(button)
					end
					numButtons = numButtons+1
				end
			end
		end)
		GREYONCOOLDOWN_SPELLFLYOUT_HOOKED = true
	end
end

-- Function to iterate through ActionButtons and hook them
function GreyOnCooldown:HookGOCActionButtons()
	for i = 1, GreyOnCooldown.NUM_ACTIONBAR_BUTTONS do
		local actionButton
		actionButton = _G["ExtraActionButton"..i]
		if (actionButton) then
			GreyOnCooldown:HookGOCActionButtonUpdate(actionButton)
		end
		actionButton = _G["ActionButton"..i]
		if (actionButton) then
			GreyOnCooldown:HookGOCActionButtonUpdate(actionButton)
		end
		actionButton = _G["MultiBarBottomLeftButton"..i]
		if (actionButton) then
			GreyOnCooldown:HookGOCActionButtonUpdate(actionButton)
		end
		actionButton = _G["MultiBarBottomRightButton"..i]
		if (actionButton) then
			GreyOnCooldown:HookGOCActionButtonUpdate(actionButton)
		end
		actionButton = _G["MultiBarLeftButton"..i]
		if (actionButton) then
			GreyOnCooldown:HookGOCActionButtonUpdate(actionButton)
		end
		actionButton = _G["MultiBarRightButton"..i]
		if (actionButton) then
			GreyOnCooldown:HookGOCActionButtonUpdate(actionButton)
		end
		actionButton = _G["StanceButton"..i]
		if (actionButton) then
			GreyOnCooldown:HookGOCActionButtonUpdate(actionButton)
		end
		actionButton = _G["PossessButton"..i]
		if (actionButton) then
			GreyOnCooldown:HookGOCActionButtonUpdate(actionButton)
		end
		actionButton = _G["OverrideActionBarButton"..i]
		if (actionButton) then
			GreyOnCooldown:HookGOCActionButtonUpdate(actionButton)
		end
	end
	for i = 1, 40 do
		local actionButton = _G["SpellFlyoutPopupButton"..i]
		if (actionButton) then
			GreyOnCooldown:HookGOCActionButtonUpdate(actionButton)
		end
	end
	-- SpellFlyoutButtons are created dynamically as needed. This needs to be monitored to apply GOC hooks to new ones.
	GreyOnCooldown:HookGOCSpellFlyout()
	if not(GREYONCOOLDOWN_ACTIONBUTTON_UPDATECOOLDOWN_HOOKED) then
		hooksecurefunc("ActionButton_UpdateCooldown", GreyOnCooldown.ButtonUpdateHookFunc)
		GREYONCOOLDOWN_ACTIONBUTTON_UPDATECOOLDOWN_HOOKED = true
	end
	if not(GREYONCOOLDOWN_ACTIONBUTTON_ONCOOLDOWNDONE_HOOKED) then
		hooksecurefunc("ActionButtonCooldown_OnCooldownDone", GreyOnCooldown.ButtonParentDelayedUpdateHookFunc)
		GREYONCOOLDOWN_ACTIONBUTTON_ONCOOLDOWNDONE_HOOKED = true
	end
end

-- Function to iterate through PetActionButtons and hook them
function GreyOnCooldown:HookGOCPetActionButtons()
	for i = 1, GreyOnCooldown.NUM_PET_ACTION_SLOTS do
		local petActionButton = _G["PetActionButton"..i]
		if (petActionButton) then
			GreyOnCooldown:HookGOCPetActionButtonUpdate(petActionButton)
		end
	end
end

-- GreyOnCooldown MainFunction
function GreyOnCooldown:MainFunction()
	-- Set ActionButton hooks to desaturate the entire action icon when the spell is on cooldown or unusable
	if not(GREYONCOOLDOWN_HOOKED) then
		ActionButton_GreyOnCooldown_UpdateCheck = GreyOnCooldown.GOCActionButtonUpdateCheck
		PetActionButton_GreyOnCooldown_UpdateCheck = GreyOnCooldown.GOCPetActionButtonUpdateCheck
		-- Main ActionButtons
		GreyOnCooldown:HookGOCActionButtons()
		-- Handle PetActionButtons
		if (GreyOnCooldown.db.profile.desaturatePetActionButtons) then
			GreyOnCooldown:HookGOCPetActionButtons()
		end
		-- Check for the presence of addons (LAB, BT4 and Dominos)
		GreyOnCooldown:CheckAddonLAB()
		GreyOnCooldown:CheckAddonBT4()
		GreyOnCooldown:CheckAddonDominos()
		-- Create a ticker to periodically check for the presence of addons
		if (GreyOnCooldown.AddonLABIsPresent == nil or GreyOnCooldown.AddonBT4IsPresent == nil or GreyOnCooldown.AddonDominosIsPresent == nil) then
			GreyOnCooldown.CheckAddonsTicker = C_Timer.NewTicker(GreyOnCooldown.CheckAddonsTickTime, function()
				GreyOnCooldown:CheckAddonLAB()
				GreyOnCooldown:CheckAddonBT4()
				GreyOnCooldown:CheckAddonDominos()
				if (GreyOnCooldown.AddonLABIsPresent ~= nil and GreyOnCooldown.AddonBT4IsPresent ~= nil and GreyOnCooldown.AddonDominosIsPresent ~= nil) then
					GreyOnCooldown.CheckAddonsTicker:Cancel()
					GreyOnCooldown.CheckAddonsTicker = nil
				end
			end, math.floor(GreyOnCooldown.CheckAddonsWindowTime/GreyOnCooldown.CheckAddonsTickTime)+1)
		end
		GREYONCOOLDOWN_HOOKED = GreyOnCooldown or true
	end
end

-- Hook function to update the LAB ActionButton (self)
GreyOnCooldown.LABButtonUpdateHookFunc = function(self)
	local func = GreyOnCooldown.LABUpdateFuncCache1[self]
	if not func then
		func = function() self:GOCUpdateCheck() end
		GreyOnCooldown.LABUpdateFuncCache1[self] = func
	end
	C_Timer.After(0.01, func)
end

-- Hook function to update the LAB ActionButton (self:GetParent())
GreyOnCooldown.LABButtonParentUpdateHookFunc = function(self)
	local func = GreyOnCooldown.LABUpdateFuncCache2[self]
	if not func then
		func = function() self:GetParent():GOCUpdateCheck() end
		GreyOnCooldown.LABUpdateFuncCache2[self] = func
	end
	C_Timer.After(0.01, func)
end

-- Function to set the hooks for a new LAB ActionButton
function GreyOnCooldown:HookGOCLABActionButtonUpdate(button)
	if ((button ~= nil) and not(self.LABButtonsTable[button])) then
		if (not button.GREYONCOOLDOWN_LAB_HOOKED) then
			self.LABButtonsTable[button] = true
			self:HookGOCActionButtonUpdate(button)
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
						ActionButton_GreyOnCooldown_UpdateCheck(button)
					end)
					LibActionButton.GREYONCOOLDOWN_ONBUTTONUPDATE_LAB_HOOKED = true
				end
				if (not LibActionButton.GREYONCOOLDOWN_ONBUTTONUSABLE_LAB_HOOKED) then
					LibActionButton.RegisterCallback(self, "OnButtonUsable", function(event, button)
						ActionButton_GreyOnCooldown_UpdateCheck(button)
					end)
					LibActionButton.GREYONCOOLDOWN_ONBUTTONUSABLE_LAB_HOOKED = true
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

-- Function to get the name of an action button created by Dominos addon
function GreyOnCooldown:DominosGetActionButtonName(id)
	local DOMINOS_ADDON_NAME = Dominos ~= nil and type(Dominos.GetName) == "function" and Dominos:GetName() or "Dominos"
	local DOMINOS_ACTION_BUTTON_NAME_TEMPLATE = DOMINOS_ADDON_NAME.."ActionButton%d"
    if id <= 0 then
        return
    elseif id <= 24 then
        return (DOMINOS_ACTION_BUTTON_NAME_TEMPLATE):format(id)
    elseif id <= 36 then
        return ("MultiBarRightActionButton%d"):format(id - 24)
    elseif id <= 48 then
        return ("MultiBarLeftActionButton%d"):format(id - 36)
    elseif id <= 60 then
        return ("MultiBarBottomRightActionButton%d"):format(id - 48)
    elseif id <= 72 then
        return ("MultiBarBottomLeftActionButton%d"):format(id - 60)
    elseif id <= 132 then
        return DOMINOS_ACTION_BUTTON_NAME_TEMPLATE:format(id)
    elseif id <= 144 then
        return ("MultiBar5ActionButton%d"):format(id - 132)
    elseif id <= 156 then
        return ("MultiBar6ActionButton%d"):format(id - 144)
    elseif id <= 168 then
        return ("MultiBar7ActionButton%d"):format(id - 156)
    end
end

-- Function to fast-check if Dominos addon is present
function GreyOnCooldown:CheckAddonDominos()
	if (self.AddonDominosIsPresent == false) then
		return false
	elseif (self.AddonDominosIsPresent) then
		return true
	else
		if ((self.GOCLoadTimestamp == nil) or ((GetTime() - self.GOCLoadTimestamp) < self.CheckAddonsWindowTime)) then
			if (Dominos ~= nil and Dominos.ActionButtons ~= nil and type(Dominos.ActionButtons.GetOrCreateActionButton) == "function") then
				if not(GREYONCOOLDOWN_DOMINOSACTIONBUTTONS_GETORCREATEACTIONBUTTON_HOOKED) then
					if (Dominos.ActionButtons.buttons) then
						for button in next, Dominos.ActionButtons.buttons do
							GreyOnCooldown:HookGOCActionButtonUpdate(button)
						end
					end
					hooksecurefunc(Dominos.ActionButtons, "GetOrCreateActionButton", function(self, id, parent)
						if (id) then
							local buttonName = GreyOnCooldown:DominosGetActionButtonName(id)
							if (buttonName) then
								local button = _G[buttonName]
								if (button) then
									GreyOnCooldown:HookGOCActionButtonUpdate(button)
								end
							end
						end
					end)
					GREYONCOOLDOWN_DOMINOSACTIONBUTTONS_GETORCREATEACTIONBUTTON_HOOKED = true
				end
				self.AddonDominosIsPresent = true
				return true
			else
				return false
			end
		else
			self.AddonDominosIsPresent = false
			return false
		end
	end
end
