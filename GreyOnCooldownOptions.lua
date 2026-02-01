local L = LibStub("AceLocale-3.0"):GetLocale("GreyOnCooldown")

GreyOnCooldown.optionsTable = {
	type = 'group',
	icon = '',
	name = L['GreyOnCooldown'],
	args = {
		general = {
			order = 1,
			type = "group",
			name = L['General Settings'],
			childGroups = "tab",
			args = {
				versionD = {
					order = 1,
					type = "description",
					name = '\124cfffb5e26' .. L['Version'] .. ': v' .. GreyOnCooldown.VERSION .. '\124r'
				},
				authorD = {
					order = 2,
					type = "description",
					name = '\124cfffb5e26' .. L['Author: Millán-Sanguino'] .. '\124r'
				},
				Spacer1 = {
					type = "description",
					order = 3,
					name = " "
				},
				enabled = {
					order = 4,
					type = "toggle",
					name = L['Enable GreyOnCooldown'],
					desc = L['Enable GreyOnCooldown'],
					width = "double",
					confirm = function(_, newValue)
						if (not newValue) then
							return L['RELOADUI_MSG']
						else
							return false
						end
					end,
					get = function() return GreyOnCooldown.db.profile.enabled end,
					set = function(_,value)
						GreyOnCooldown.db.profile.enabled = value
						if value then
							if (not GreyOnCooldown:IsEnabled()) then
								GreyOnCooldown:Enable()
								GreyOnCooldown:MainFunction()
							end
						else
							if (GreyOnCooldown:IsEnabled()) then
								GreyOnCooldown:Disable()
								ReloadUI()
							end
						end
					end
				},
				Header1 = {
					type = 'header',
					order = 5,
					name = L['General Settings']
				},
				disabledConsoleStatusMessages = {
					order = 6,
					type = "toggle",
					name = L['DisableConsoleStatusMessages'],
					desc = L['DisableConsoleStatusMessagesDesc'],
					width = "double",
					get = function() return GreyOnCooldown.db.profile.disabledConsoleStatusMessages end,
					set = function(_,value)
						GreyOnCooldown.db.profile.disabledConsoleStatusMessages = value
					end
				},
				disabledAddonCompartmentIntegration = {
					order = 7,
					type = "toggle",
					name = L['DisableAddonCompartmentIntegration'],
					desc = L['DisableAddonCompartmentIntegrationDesc'],
					width = "double",
					get = function() return GreyOnCooldown.db.profile.disabledAddonCompartmentIntegration end,
					set = function(_,value)
						GreyOnCooldown.db.profile.disabledAddonCompartmentIntegration = value
						GreyOnCooldown:AddonCompartmentIntegration(not(value))
					end
				},
				Spacer2 = {
					type = "description",
					order = 8,
					name = " "
				},
				desaturateUnusableActions = {
					order = 9,
					type = "toggle",
					name = L['DesaturateUnusableActions'],
					desc = L['DesaturateUnusableActionsDesc'],
					width = "double",
					get = function() return GreyOnCooldown.db.profile.desaturateUnusableActions end,
					set = function(_,value)
						GreyOnCooldown.db.profile.desaturateUnusableActions = value
						if (GreyOnCooldown:IsEnabled()) then
							if (GREYONCOOLDOWN_HOOKED == GreyOnCooldown) then
								GreyOnCooldown:UpdateAllActionButtons()
							end
						end
					end
				},
				desaturatePetActionButtons = {
					order = 10,
					type = "toggle",
					name = L['DesaturatePetActionButtons'],
					desc = L['DesaturatePetActionButtonsDesc'],
					width = "double",
					get = function() return GreyOnCooldown.db.profile.desaturatePetActionButtons end,
					set = function(_,value)
						GreyOnCooldown.db.profile.desaturatePetActionButtons = value
						if (GreyOnCooldown:IsEnabled()) then
							if (GREYONCOOLDOWN_HOOKED == GreyOnCooldown) then
								GreyOnCooldown:HookGOCPetActionButtons()
								if (GreyOnCooldown:CheckAddonBT4()) then
									GreyOnCooldown:HookGOCBT4PetActionButtons()
								end
							end
						end
					end
				}
			}
		}
	}
}
