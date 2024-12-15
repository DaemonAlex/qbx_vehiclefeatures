RegisterNetEvent('qbx_vehiclefeatures:server:syncDoor', function(open, plate, door)
	if GetInvokingResource() then return end
    TriggerClientEvent('qbx_vehiclefeatures:client:syncDoor', -1, plate, door, open)
end)

RegisterNetEvent('qbx_vehiclefeatures:server:setTrunkBusy', function(vehNetId, state)
	if GetInvokingResource() then return end
	local vehicleEntity = NetworkGetEntityFromNetworkId(vehNetId)
	if type(state) ~= 'boolean' or not DoesEntityExist(vehicleEntity) then return end
	Entity(vehicleEntity).state:set('trunkbusy', state, true)
end)

lib.addCommand('getintrunk', {
    help = locale("general.getintrunk_command_desc"),
}, function(source)
    TriggerClientEvent('qbx_vehiclefeatures:client:getInTrunk', source)
end)