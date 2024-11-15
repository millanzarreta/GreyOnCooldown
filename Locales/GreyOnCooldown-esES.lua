local L = LibStub("AceLocale-3.0"):NewLocale("GreyOnCooldown","esES",false)
if not L then return end 

L[''] = true
L['GreyOnCooldown'] = true
L['Version'] = 'Version'
L['Author: Millán-Sanguino'] = 'Autor: Millán-Sanguino'
L['Enable'] = 'Activar'
L['Enable GreyOnCooldown'] = 'Activar GreyOnCooldown'
L['Hide'] = 'Ocultar'
L['Enabled'] = 'Activado'
L['Disabled'] = 'Desactivado'
L['enabled'] = 'activado'
L['disabled'] = 'desactivado'
L['General Settings'] = 'Opciones generales'
L['Profiles'] = 'Perfiles'
L['ReloadUI'] = 'ReloadUI'

L["Default"] = 'Por defecto'
L['DefaultDesc'] = 'Establece la opción a su valor por defecto'
L['DisableConsoleStatusMessages'] = 'Deshabilitar los mensajes de estado de la consola'
L['DisableConsoleStatusMessagesDesc'] = 'Marca esta opción para evitar que se muestren los mensajes de estado en la consola'
L['DesaturateUnusableActions'] = 'Desaturar acciones no usables'
L['DesaturateUnusableActionsDesc'] = 'Desaturar las acciones no usables (como talentos no aprendidos) independientemente de su cooldown'
L['minDuration'] = 'minDuration'
L['minDurationDesc'] = 'Establece el valor mínimo (en segundos) del cooldown para ser desaturado'
L['RELOADUI_MSG'] = '|cffffd200GreyOnCooldown|r\n\n|cffff0000ReloadUI:|r Para aplicar esta acción es necesario recargar la inferfaz. Si deseas seguir con esta operación, pulsa \'Aceptar\', de lo contrario pulsa \'Cancelar\' o la tecla \'Escape\''

L['GREYONCOOLDOWN_HELP_LINE1'] = 'Comandos disponibles:'
L['GREYONCOOLDOWN_HELP_LINE2'] = '-----------------'
L['GREYONCOOLDOWN_HELP_LINE3'] = '/GreyOnCooldown (o /GOC): Muestra el panel de configuración de GreyOnCooldown.'
L['GREYONCOOLDOWN_HELP_LINE4'] = '/GreyOnCooldown <enable|disable> o /GreyOnCooldown <on|off>: Activa o desactiva GreyOnCooldown.'
L['GREYONCOOLDOWN_HELP_LINE5'] = '/GreyOnCooldown dcsm <on|off|default>: Activa/desactiva los mensajes de estado de la consola.'
L['GREYONCOOLDOWN_HELP_LINE6'] = '/GreyOnCooldown dua <on|off|default>: Activa/desactiva la desaturación de acciones no usables.'
L['GREYONCOOLDOWN_HELP_LINE7'] = '/GreyOnCooldown minduration <value|default>: Establece el valor de la opción minDuration.'
L['GREYONCOOLDOWN_HELP_LINE8'] = '/GreyOnCooldown profiles: Muestra el panel de configuración de perfiles de GreyOnCooldown.'
