local playersInTrunk = {}

---@param open boolean
---@param plate string
---@param door number
RegisterNetEvent('qbx_vehiclefeatures:server:syncDoor', function(open, plate, door)
    if GetInvokingResource() then return end
    TriggerClientEvent('qbx_vehiclefeatures:client:syncDoor', -1, plate, door, open)
end)

---@param vehNetId number
---@param state boolean
RegisterNetEvent('qbx_vehiclefeatures:server:setTrunkBusy', function(vehNetId, state)
    if GetInvokingResource() then return end
    local vehicleEntity = NetworkGetEntityFromNetworkId(vehNetId)
    if type(state) ~= 'boolean' or not DoesEntityExist(vehicleEntity) then return end
    Entity(vehicleEntity).state:set('trunkbusy', (state and source or false), true)
    playersInTrunk[source] = (state and vehNetId or false)
end)

---@param vehNetId number
---@param playerId number
RegisterNetEvent('qbx_vehiclefeatures:server:kidnapTrunk', function(vehNetId, playerId)
    if GetInvokingResource() then return end
    if not exports.qbx_core:GetPlayer(playerId) then return end
    local vehicleEntity = NetworkGetEntityFromNetworkId(vehNetId)
    if type(playerId) ~= 'number' or not DoesEntityExist(vehicleEntity) then return end
    TriggerClientEvent('qbx_vehiclefeatures:client:kidnapTrunk', playerId, vehNetId)
end)

lib.addCommand('getintrunk', {
    help = locale('general.getintrunk_command_desc'),
}, function(source)
    TriggerClientEvent('qbx_vehiclefeatures:client:getInTrunk', source, false)
end)

lib.addCommand('putintrunk', {
    help = locale('general.putintrunk_command_desc'),
}, function(source)
    TriggerClientEvent('qbx_vehiclefeatures:client:getInTrunk', source, true)
end)

lib.addCommand('getouttrunk', {
    help = locale('general.getouttrunk_command_desc'),
}, function(source)
    TriggerClientEvent('qbx_vehiclefeatures:client:getOutTrunk', source)
end)

---@param source number
local function onPlayerUnload(source)
    if playersInTrunk[source] then
        local vehicleEntity = NetworkGetEntityFromNetworkId(playersInTrunk[source])
        if DoesEntityExist(vehicleEntity) then
            Entity(vehicleEntity).state:set('trunkbusy', false, true)
        end
        playersInTrunk[source] = nil
    end
end

---@param source number
AddEventHandler('QBCore:Server:OnPlayerUnload', function()
    onPlayerUnload(source)
end)

---@param source number
AddEventHandler('playerDropped', function()
    onPlayerUnload(source)
end)