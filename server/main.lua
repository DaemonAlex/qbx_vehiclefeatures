lib.versionCheck('0Programmer/qbx_vehiclefeatures')
if not lib.checkDependency('ox_lib', '3.27.0', true) then
    warn('ox_lib version 3.27.0 or higher is recommended')
elseif not lib.checkDependency('ox_inventory', '2.43.4', true) then
    warn('ox_inventory version 2.43.4 or higher is recommended')
elseif not lib.checkDependency('qbx_core', '1.22.3', true) then
    warn('qbx_core version 1.22.3 or higher is recommended')
elseif GetConvarInt('onesync_enableInfinity', 0) ~= 1 then
    error('OneSync Infinity is not enabled. You can do so in txAdmin settings or add +set onesync on to your server startup command line')
end