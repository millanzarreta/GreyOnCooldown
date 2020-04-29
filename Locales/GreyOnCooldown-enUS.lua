local L = LibStub("AceLocale-3.0"):NewLocale("GreyOnCooldown","enUS",true)
if not L then return end 

L[''] = true
L['GreyOnCooldown'] = true
L['Version'] = true
L['Author: Millán-C\'Thun'] = true
L['Enable'] = true
L['Enable GreyOnCooldown'] = true
L['Hide'] = true
L['Enabled'] = true
L['Disabled'] = true
L['enabled'] = true
L['disabled'] = true
L['General Settings'] = true
L['Profiles'] = true
L['ReloadUI'] = true

L["Default"] = true
L['DefaultDesc'] = 'Set option to the default value'
L['minDuration'] = true
L['minDurationDesc'] = 'Set the minimum value (in seconds) of the cooldown to be desaturated'
L['RELOADUI_MSG'] = '|cffffd200GreyOnCooldown|r\n\n|cffff0000ReloadUI:|r To apply this action an interface reload is needed. If you wish to continue with this operation, push \'Accept\', otherwise push \'Cancel\' or the \'Escape\' key'

L['GREYONCOOLDOWN_HELP_LINE1'] = 'Available slash commands:'
L['GREYONCOOLDOWN_HELP_LINE2'] = '-----------------'
L['GREYONCOOLDOWN_HELP_LINE3'] = '/GreyOnCooldown: Shows the main GreyOnCooldown config panel.'
L['GREYONCOOLDOWN_HELP_LINE4'] = '/GreyOnCooldown <enable|disable> or /GreyOnCooldown <on|off>: Enable or disable GreyOnCooldown.'
L['GREYONCOOLDOWN_HELP_LINE5'] = '/GreyOnCooldown minduration <value|default>: Set the minDuration option value.'
L['GREYONCOOLDOWN_HELP_LINE6'] = '/GreyOnCooldown profiles: Shows the profiles GreyOnCooldown config panel.'
