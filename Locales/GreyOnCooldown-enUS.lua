local L = LibStub("AceLocale-3.0"):NewLocale("GreyOnCooldown","enUS",true)
if not L then return end

L[''] = true
L['GreyOnCooldown'] = true
L['Version'] = true
L['Author: Millán-Sanguino'] = true
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
L['DisableConsoleStatusMessages'] = 'Disable console status messages'
L['DisableConsoleStatusMessagesDesc'] = 'Check this option to prevent the console status messages from being displayed'
L['DesaturateUnusableActions'] = 'Desaturate unusable actions'
L['DesaturateUnusableActionsDesc'] = 'Desaturate unusable actions (such as unlearned talents) regardless of their cooldown status'
L['DesaturatePetActionButtons'] = 'Desaturate PetActionButtons'
L['DesaturatePetActionButtonsDesc'] = 'Check this option to desaturate pet action buttons on the pet action bar when they are on cooldown'
L['DisableAddonCompartmentIntegration'] = 'Disable AddonCompartment integration'
L['DisableAddonCompartmentIntegrationDesc'] = 'Check this option to not list the GreyOnCooldown addon in the addon compartment dropdown menu (accessible from the minimap)'
L['minDuration'] = true
L['minDurationDesc'] = 'Set the minimum value (in seconds) of the cooldown to be desaturated'
L['RELOADUI_MSG'] = '|cffffd200GreyOnCooldown|r\n\n|cffff0000ReloadUI:|r To apply this action an interface reload is needed. If you wish to continue with this operation, push \'Accept\', otherwise push \'Cancel\' or the \'Escape\' key'

L['GREYONCOOLDOWN_OPENPANEL_AFTERCOMBAT'] = 'The options panel will open after combat ends.'
L['GREYONCOOLDOWN_HELP_LINE1'] = 'Available slash commands:'
L['GREYONCOOLDOWN_HELP_LINE2'] = '-----------------'
L['GREYONCOOLDOWN_HELP_LINE3'] = '/GreyOnCooldown (or /GOC): Shows the main GreyOnCooldown config panel.'
L['GREYONCOOLDOWN_HELP_LINE4'] = '/GreyOnCooldown <enable|disable> or /GreyOnCooldown <on|off>: Enable or disable GreyOnCooldown.'
L['GREYONCOOLDOWN_HELP_LINE5'] = '/GreyOnCooldown dcsm <on|off|default>: Turns on/off the console status messages.'
L['GREYONCOOLDOWN_HELP_LINE6'] = '/GreyOnCooldown dua <on|off|default>: Turns on/off the desaturation of unusable actions.'
L['GREYONCOOLDOWN_HELP_LINE7'] = '/GreyOnCooldown dpab <on|off|default>: Turns on/off the desaturation of pet action buttons.'
L['GREYONCOOLDOWN_HELP_LINE8'] = '/GreyOnCooldown profiles: Shows the profiles GreyOnCooldown config panel.'
