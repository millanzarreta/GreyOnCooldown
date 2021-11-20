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
				minDuration = {
					order = 6,
					type = "range",
					width = "double",
					min = 0.01,
					softMin = 0.01,
					softMax = 12,
					step = 0.01,
					bigStep = 0.05,
					name = L['minDuration'],
					desc = L['minDurationDesc'],
					get = function() return GreyOnCooldown.db.profile.minDuration end,
					set = function(_,value)
						GreyOnCooldown.db.profile.minDuration = value
					end
				},
				minDurationToDefault = {
					order = 7,
					type = "execute",
					name = L["Default"],
					desc = L["DefaultDesc"],
					func  = function() GreyOnCooldown.db.profile.minDuration = GreyOnCooldown.db.defaults.profile.minDuration end
				}
			}
		}
	}
}
