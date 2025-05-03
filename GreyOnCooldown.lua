-- ------------------------------------------------------------ --
-- Addon: GreyOnCooldown                                        --
--                                                              --
-- Version: 1.1.6                                               --
-- WoW Game Version: 11.1.5                                     --
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
		disabledAddonCompartmentIntegration = false,
		desaturateUnusableActions = true,
		minDuration = 1.51
	}
}

-- Global variables
GreyOnCooldown.VERSION = "1.1.6"
GreyOnCooldown.CheckAddonsWindowTime = 90
GreyOnCooldown.AddonLABIsPresent = nil
GreyOnCooldown.LABButtonsTable = {}
GreyOnCooldown.GOCLoadTimestamp = nil
GreyOnCooldown.ACIaddonData = {
	text = "GreyOnCooldown",
	icon = "Interface\\Addons\\GreyOnCooldown\\micon",
	notCheckable = true,
	func = function()
		Settings.OpenToCategory(GreyOnCooldown.optionsFramesCatId.general)
	end
}

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

	if (not(self.db.profile.disabledAddonCompartmentIntegration)) then
		self:AddonCompartmentIntegration(true)
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
				if (GreyOnCooldown:IsEnabled() and newValue) then
					GreyOnCooldown:HookGreyOnCooldownIcons()
					GreyOnCooldown:CheckAddonLAB()
				end
			end
			if not(GreyOnCooldown.db.profile.disabledConsoleStatusMessages) then
				GreyOnCooldown:Print("|cffd2a679" .. L['GreyOnCooldown'] .. '->desaturateUnusableActions = ' .. tostring(GreyOnCooldown.db.profile.desaturateUnusableActions) .. "|r")
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

-- Function to register/unregister the addon integration in the Blizzard AddonCompartment dropdown menu
function GreyOnCooldown:AddonCompartmentIntegration(registerState)
	if (registerState) then
		if (AddonCompartmentFrame ~= nil and self.ACIaddonData ~= nil and AddonCompartmentFrame.registeredAddons ~= nil) then
			local aciIndex
			for k, v in pairs(AddonCompartmentFrame.registeredAddons) do
				if (v == self.ACIaddonData) then
					aciIndex = k
					break
				end
			end
			if not(aciIndex) then
				AddonCompartmentFrame:RegisterAddon(self.ACIaddonData)
			end
		end
	else
		if (AddonCompartmentFrame ~= nil and self.ACIaddonData ~= nil and AddonCompartmentFrame.registeredAddons ~= nil) then
			local aciIndex
			for k, v in pairs(AddonCompartmentFrame.registeredAddons) do
				if (v == self.ACIaddonData) then
					aciIndex = k
					break
				end
			end
			if (aciIndex ~= nil) then
				table.remove(AddonCompartmentFrame.registeredAddons, aciIndex)
				AddonCompartmentFrame:UpdateDisplay()
			end
		end
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
end

function GreyOnCooldown:OnEnable()
	if not(GreyOnCooldown.db.profile.disabledConsoleStatusMessages) then
		DEFAULT_CHAT_FRAME:AddMessage('|cffd78900' .. L['GreyOnCooldown'] .. ' v' .. GreyOnCooldown.VERSION .. '|r ' .. L['enabled'])
	end
end

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
	GreyOnCooldown:HookGreyOnCooldownIcons()
	GreyOnCooldown:CheckAddonLAB()
end

-- Dummy function to replace GetCooldown function from LAB ActionButtons
local function GreyOnCooldown_ActionButtonGetCooldown(self)
	if (self._state_type == "action") then
		ActionButtonGreyOnCooldown_UpdateCooldown(self)
		return GetActionCooldown(self._state_action)
	elseif (self._state_type == "spell") then
		ActionButtonGreyOnCooldown_UpdateCooldown(self)
		local spellCooldownInfo = C_Spell.GetSpellCooldown(self._state_action) or {startTime = 0, duration = 0, isEnabled = false, modRate = 1}
		return spellCooldownInfo.startTime, spellCooldownInfo.duration, spellCooldownInfo.isEnabled, spellCooldownInfo.modRate
	elseif (self._state_type == "item") then
		return C_Container.GetItemCooldown(self._state_action:match("^item:(%d+)"))
	else
		return nil
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
					if ((button ~= nil) and not(self.LABButtonsTable[button])) then
						if (not button.GREYONCOOLDOWN_LAB_HOOKED) then
							self.LABButtonsTable[button] = true
							-- Replace 'GetCooldown' (LABButton) function because we can't hook the local 'UpdateCooldown' (LABButton) function
							button.GetCooldown = GreyOnCooldown_ActionButtonGetCooldown
							button.GREYONCOOLDOWN_LAB_HOOKED = true
						end
					end
				end
				LibActionButton.RegisterCallback(self, "OnButtonCreated", function(event, button)
					if ((button ~= nil) and (not GreyOnCooldown.LABButtonsTable[button])) then
						if (not button.GREYONCOOLDOWN_LAB_HOOKED) then
							GreyOnCooldown.LABButtonsTable[button] = true
							-- Replace 'GetCooldown' (LABButton) function because we can't hook the local 'UpdateCooldown' (LABButton) function
							button.GetCooldown = GreyOnCooldown_ActionButtonGetCooldown
							button.GREYONCOOLDOWN_LAB_HOOKED = true
						end
					end
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

-- Function to set hooks for SpellFlyout frame to detect the newly created SpellFlyoutButtons
function GreyOnCooldown:HookGOCSpellFlyout()
	if not(GREYONCOOLDOWN_SPELLFLYOUT_HOOKED) then
		hooksecurefunc(SpellFlyout, "Toggle", function(self, flyoutButton, flyoutID, isActionBar, specID, showFullTooltip, reason)
			if (GreyOnCooldown.db.profile.desaturateUnusableActions) then
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
							GreyOnCooldown.HookGOCActionBarButtonUpdateUsable(button)
						end
						numButtons = numButtons+1
					end
				end
			end
		end)
		GREYONCOOLDOWN_SPELLFLYOUT_HOOKED = true
	end
end

-- Function to hook the "UpdateUsable" function of actionButtons
GreyOnCooldown.HookGOCActionBarButtonUpdateUsable = function(actionBarButton)
	if ((ActionButtonGreyOnCooldown_UpdateUsable == nil) or (type(ActionButtonGreyOnCooldown_UpdateUsable) ~= "function")) then
		function ActionButtonGreyOnCooldown_UpdateUsable(self)
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
		end
	end
	if (actionBarButton ~= nil and actionBarButton.UpdateUsable ~= nil) then
		if (GREYONCOOLDOWN_UPDATEUSABLE_HOOKED_AB == nil) then
			GREYONCOOLDOWN_UPDATEUSABLE_HOOKED_AB = {}
		end
		if not(GREYONCOOLDOWN_UPDATEUSABLE_HOOKED_AB[actionBarButton]) then
			hooksecurefunc(actionBarButton, "UpdateUsable", ActionButtonGreyOnCooldown_UpdateUsable)
			GREYONCOOLDOWN_UPDATEUSABLE_HOOKED_AB[actionBarButton] = true
		end
	end
end

-- Function to hook some functions from the CooldownViewer Blizzard
GreyOnCooldown.HookGOCCooldownViewer = function(cooldownViewer)
	if ((CooldownViewerGreyOnCooldown_RefreshIcon == nil) or (type(CooldownViewerGreyOnCooldown_RefreshIcon) ~= "function")) then
		function CooldownViewerGreyOnCooldown_RefreshIcon(self)
			if (self.layoutIndex == nil or not(GreyOnCooldown.db.profile.desaturateUnusableActions)) then return end
			local spellID = self:GetSpellID()
			if not spellID then return end
			local iconTexture = self:GetIconTexture()
			if not iconTexture then return end
			local desaturated = self.cooldownDesaturated and not(self:IsExpired())
			if (desaturated) then
				if not(iconTexture:IsDesaturated()) then
					iconTexture:SetDesaturated(true)
				end
			else
				local isUsable, notEnoughMana = C_Spell.IsSpellUsable(spellID)
				local forceDesaturated = not(isUsable) and not(notEnoughMana)
				if (forceDesaturated) then
					if not(iconTexture:IsDesaturated()) then
						iconTexture:SetDesaturated(true)
					end
				else
					if (iconTexture:IsDesaturated()) then
						iconTexture:SetDesaturated(false)
					end
				end
			end
		end
	end
	if ((CooldownViewerGreyOnCooldown_RefreshLayout == nil) or (type(CooldownViewerGreyOnCooldown_RefreshLayout) ~= "function")) then
		function CooldownViewerGreyOnCooldown_RefreshLayout(self)
			if (GreyOnCooldown.db.profile.desaturateUnusableActions) then
				for k, _ in self.itemFramePool:EnumerateActive() do
					if not(GREYONCOOLDOWN_UPDATEUSABLE_HOOKED_CV_RIC[k]) then
						hooksecurefunc(k, "RefreshIconDesaturation", CooldownViewerGreyOnCooldown_RefreshIcon)
						GREYONCOOLDOWN_UPDATEUSABLE_HOOKED_CV_RIC[k] = true
					end
					if not(GREYONCOOLDOWN_UPDATEUSABLE_HOOKED_CV_RID[k]) then
						hooksecurefunc(k, "RefreshIconColor", CooldownViewerGreyOnCooldown_RefreshIcon)
						GREYONCOOLDOWN_UPDATEUSABLE_HOOKED_CV_RID[k] = true
					end
				end
			end
		end
	end
	if (cooldownViewer ~= nil and cooldownViewer.itemFramePool ~= nil) then
		if (GREYONCOOLDOWN_UPDATEUSABLE_HOOKED_CV_RL == nil) then
			GREYONCOOLDOWN_UPDATEUSABLE_HOOKED_CV_RL = {}
		end
		if (GREYONCOOLDOWN_UPDATEUSABLE_HOOKED_CV_RIC == nil) then
			GREYONCOOLDOWN_UPDATEUSABLE_HOOKED_CV_RIC = {}
		end
		if (GREYONCOOLDOWN_UPDATEUSABLE_HOOKED_CV_RID == nil) then
			GREYONCOOLDOWN_UPDATEUSABLE_HOOKED_CV_RID = {}
		end
		if not(GREYONCOOLDOWN_UPDATEUSABLE_HOOKED_CV_RL[cooldownViewer]) then
			hooksecurefunc(cooldownViewer, "RefreshLayout", CooldownViewerGreyOnCooldown_RefreshLayout)
			GREYONCOOLDOWN_UPDATEUSABLE_HOOKED_CV_RL[cooldownViewer] = true
		end
		CooldownViewerGreyOnCooldown_RefreshLayout(cooldownViewer)
	end
end

-- GreyOnCooldown main function to desaturate the entire action icon when the spell is on cooldown or unusable
function GreyOnCooldown:HookGreyOnCooldownIcons()
	-- Main hooks for 'ActionButtons'
	if (not GREYONCOOLDOWN_HOOKED) then
		local UpdateFuncCache = {}
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
					local spellCooldownInfo = C_Spell.GetSpellCooldown(spellID) or {startTime = 0, duration = 0}
					start, duration = spellCooldownInfo.startTime, spellCooldownInfo.duration
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
		GREYONCOOLDOWN_HOOKED = true
	end
	if (GreyOnCooldown.db.profile.desaturateUnusableActions) then
		-- Aux hooks for 'UpdateUsable'
		if (not GREYONCOOLDOWN_UPDATEUSABLE_HOOKED) then
			for i = 1, 12 do
				local actionButton
				actionButton = _G["ExtraActionButton"..i]
				if (actionButton) then
					GreyOnCooldown.HookGOCActionBarButtonUpdateUsable(actionButton)
				end
				actionButton = _G["ActionButton"..i]
				if (actionButton) then
					GreyOnCooldown.HookGOCActionBarButtonUpdateUsable(actionButton)
				end
				actionButton = _G["MultiBarBottomLeftButton"..i]
				if (actionButton) then
					GreyOnCooldown.HookGOCActionBarButtonUpdateUsable(actionButton)
				end
				actionButton = _G["MultiBarBottomRightButton"..i]
				if (actionButton) then
					GreyOnCooldown.HookGOCActionBarButtonUpdateUsable(actionButton)
				end
				actionButton = _G["MultiBarLeftButton"..i]
				if (actionButton) then
					GreyOnCooldown.HookGOCActionBarButtonUpdateUsable(actionButton)
				end
				actionButton = _G["MultiBarRightButton"..i]
				if (actionButton) then
					GreyOnCooldown.HookGOCActionBarButtonUpdateUsable(actionButton)
				end
				actionButton = _G["PetActionButton"..i]
				if (actionButton) then
					GreyOnCooldown.HookGOCActionBarButtonUpdateUsable(actionButton)
				end
				actionButton = _G["StanceButton"..i]
				if (actionButton) then
					GreyOnCooldown.HookGOCActionBarButtonUpdateUsable(actionButton)
				end
				actionButton = _G["PossessButton"..i]
				if (actionButton) then
					GreyOnCooldown.HookGOCActionBarButtonUpdateUsable(actionButton)
				end
				actionButton = _G["OverrideActionBarButton"..i]
				if (actionButton) then
					GreyOnCooldown.HookGOCActionBarButtonUpdateUsable(actionButton)
				end
			end
			for i = 1, 40 do
				local actionButton = _G["SpellFlyoutPopupButton"..i]
				if (actionButton) then
					GreyOnCooldown.HookGOCActionBarButtonUpdateUsable(actionButton)
				end
			end
			-- Aux hooks for 'CooldownViewer' frames
			GreyOnCooldown.HookGOCCooldownViewer(EssentialCooldownViewer)
			GreyOnCooldown.HookGOCCooldownViewer(UtilityCooldownViewer)
			-- Aux hooks for 'SpellFlyout'
			GreyOnCooldown:HookGOCSpellFlyout()
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
end
