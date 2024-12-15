local config = require 'config.client'
local lastVehicle = nil
local trunkCam = 0

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
	LocalPlayer.state:set('insideTrunk', false, true)
end)

RegisterNetEvent('qbx_hidetrunk:client:syncDoor', function(plate, door, open)
    if not cache.vehicle then return end

    local pl = qbx.getVehiclePlate(cache.vehicle)
    if pl ~= plate then return end

    if open then
        SetVehicleDoorOpen(cache.vehicle, door, false, false)
    else
        SetVehicleDoorShut(cache.vehicle, door, false)
    end
end)

local polarAngleDeg = 0;
local yawAngleDeg = 60;
local radiusDeg = -4.5;
local DEG_TO_RAD = math.pi / 180.0
local function polar3DToWorld3D(entityPosition, radiusDeg, polarAngleDeg, yawAngleDeg)
    local polarAngleRad = polarAngleDeg * DEG_TO_RAD
    local yawAngleRad = yawAngleDeg * DEG_TO_RAD

    local sinYaw = math.sin(yawAngleRad)
    local cosPolar = math.cos(polarAngleRad)
    local sinPolar = math.sin(polarAngleRad)
    local cosYaw = math.cos(yawAngleRad)

    return {
        x = entityPosition.x + radiusDeg * (sinYaw * cosPolar),
        y = entityPosition.y - radiusDeg * (sinYaw * sinPolar),
        z = entityPosition.z - radiusDeg * cosYaw
    }
end

local function camControl(bool)
    local drawPos = GetOffsetFromEntityInWorldCoords(lastVehicle, 0, -5.5, 0)
    local vehHeading = GetEntityHeading(lastVehicle)
    if bool then
        RenderScriptCams(false, false, 0, true, false)
        if DoesCamExist(trunkCam) then
            DestroyCam(trunkCam, false)
            trunkCam = 0
        end

        trunkCam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
        SetCamActive(trunkCam, true)
        SetCamCoord(trunkCam, drawPos.x, drawPos.y, drawPos.z + 2)
        SetCamRot(trunkCam, -2.5, 0.0, vehHeading, 0.0)
        RenderScriptCams(true, false, 0, true, true)
    else
        RenderScriptCams(false, false, 0, true, false)
        if DoesCamExist(trunkCam) then
            DestroyCam(trunkCam, false)
            trunkCam = 0
        end
    end
end

local function exitTrunk()
	local vehCoords = GetEntityCoords(lastVehicle)
	local min, max = GetModelDimensions(GetEntityModel(lastVehicle))
	local backOffset = vec3(0.0, min.y - 0.3, 0.0)
	local entityOffset = GetOffsetFromEntityInWorldCoords(lastVehicle, backOffset.x, backOffset.y, backOffset.z)
	SetEntityCoords(cache.ped, entityOffset.x, entityOffset.y, entityOffset.z, false, false, false, false)
	lastVehicle = nil
end

local function startThreads()
	CreateThread(function()
		if not config.canCamMove then return end
		while LocalPlayer.state?.insideTrunk do
			local vehicleCoords = GetEntityCoords(lastVehicle)
			if trunkCam ~= nil then
				if IsControlPressed(2, 241) then
					radiusDeg = radiusDeg + 1.0
				end
				if IsControlPressed(2, 242) then
					radiusDeg = radiusDeg - 1.0
				end
				if radiusDeg > -2.0 then
					radiusDeg = -2.0
				end
				if math.abs(radiusDeg) > 5.5 then
					radiusDeg = -5.5
				end
				local xMagnitude = GetDisabledControlNormal(0, 1)
				local yMagnitude = GetDisabledControlNormal(0, 2)
				polarAngleDeg = polarAngleDeg + xMagnitude * 10
				if polarAngleDeg >= 360 then
					polarAngleDeg = 0
				end
				yawAngleDeg = yawAngleDeg + yMagnitude * 10
				if yawAngleDeg >= 360 then
					yawAngleDeg = 0
				end
				if math.abs(yawAngleDeg) >= 85 then
					yawAngleDeg = 86
				end
				local nextCamLocation = polar3DToWorld3D(vehicleCoords, radiusDeg, polarAngleDeg, yawAngleDeg)
				SetCamCoord(trunkCam, nextCamLocation.x, nextCamLocation.y, nextCamLocation.z)
				PointCamAtEntity(trunkCam, lastVehicle)
			else
				Citizen.Wait(1000)
			end
			Citizen.Wait(1)
		end
	end)
	CreateThread(function()
		while LocalPlayer.state?.insideTrunk do
			local sleep = 1000
			if not isKidnapped then
				local drawPos = GetOffsetFromEntityInWorldCoords(lastVehicle, 0, -2.5, 0)
				if DoesEntityExist(lastVehicle) then
					sleep = 0
					qbx.drawText3d({coords = vector3(drawPos.x, drawPos.y, drawPos.z + 0.75), text =  locale("general.get_out_trunk_button")})
					if IsControlJustPressed(0, 38) then
						if GetVehicleDoorAngleRatio(lastVehicle, 5) > 0 then
							DetachEntity(cache.ped, true, true)
							ClearPedTasks(cache.ped)
							LocalPlayer.state:set('insideTrunk', false, true)
							TriggerServerEvent('qbx_hidetrunk:server:setTrunkBusy', NetworkGetNetworkIdFromEntity(lastVehicle), false)
							exitTrunk()
							if GetEntitySpeed(lastVehicle) >= 1 then
								local velocity = GetEntityVelocity(lastVehicle)
								SetPedToRagdoll(cache.ped, 3000, 3000, 0, 0, 0, 0)
    							SetEntityVelocity(cache.ped, velocity / 6.0)
							end
							if not config.pedVisible then
								SetEntityVisible(cache.ped, true, true)
							end
							camControl(false)
						else
							exports.qbx_core:Notify(locale("error.trunk_closed"), 'error', 2500)
						end
						Wait(100)
					end
					if GetVehicleDoorAngleRatio(lastVehicle, 5) > 0 then
						qbx.drawText3d({coords = vector3(drawPos.x, drawPos.y, drawPos.z + 0.5), text = locale("general.close_trunk_button")})
						if IsControlJustPressed(0, 47) then
							if not IsVehicleSeatFree(lastVehicle, -1) then
								TriggerServerEvent('qbx_hidetrunk:server:syncDoor', false, qbx.getVehiclePlate(lastVehicle), 5)
							else
								SetVehicleDoorShut(lastVehicle, 5, false)
							end
							Wait(100)
						end
					else
						qbx.drawText3d({coords = vector3(drawPos.x, drawPos.y, drawPos.z + 0.5), text = locale("general.open_trunk_button")})
						if IsControlJustPressed(0, 47) then
							if not IsVehicleSeatFree(lastVehicle, -1) then
								TriggerServerEvent('qbx_hidetrunk:server:syncDoor', true, qbx.getVehiclePlate(lastVehicle), 5)
							else
								SetVehicleDoorOpen(lastVehicle, 5, false, false)
							end
							Wait(100)
						end
					end
					if GetVehicleBodyHealth(lastVehicle) <= 0.0 then
						exports.qbx_core:Notify(locale("error.trunk_damaged"), 'error', 2500)
						DetachEntity(cache.ped, true, true)
						ClearPedTasks(cache.ped)
						LocalPlayer.state:set('insideTrunk', false, true)
						TriggerServerEvent('qbx_hidetrunk:server:setTrunkBusy', NetworkGetNetworkIdFromEntity(lastVehicle), false)
						exitTrunk()
						if not config.pedVisible then
							SetEntityVisible(cache.ped, true, true)
						end
						camControl(false)
						break
					end
				else
					DetachEntity(cache.ped, true, true)
					ClearPedTasks(cache.ped)
					LocalPlayer.state:set('insideTrunk', false, true)
					TriggerServerEvent('qbx_hidetrunk:server:setTrunkBusy', NetworkGetNetworkIdFromEntity(lastVehicle), false)
					if not config.pedVisible then
						SetEntityVisible(cache.ped, true, true)
					end
					camControl(false)
					break
				end
				if config.barPeeking then
					if not (GetVehicleDoorAngleRatio(lastVehicle, 5) > 0) then
						DrawRect(0.0, 0.0, 2.0, 0.76, 0, 0, 0, 255)
						DrawRect(0.0, 1.0, 2.0, 0.76, 0, 0, 0, 255)
					end
				end
			end
			Wait(sleep)
		end
	end)
end

local function getInTrunk()
    local closestVehicle, closestCoords = lib.getClosestVehicle(GetEntityCoords(cache.ped), 5.0, false)
    if closestVehicle ~= 0 and DoesEntityExist(closestVehicle) then
		lastVehicle = closestVehicle
        local vehClass = GetVehicleClass(lastVehicle)
		local vehModel = GetEntityModel(lastVehicle)
        if not config.classDisabled[vehClass] then
            if not config.trunkDisabled[vehModel] then
                if not LocalPlayer.state?.insideTrunk then
                    if not Entity(lastVehicle).state?.trunkbusy then
                        if GetVehicleDoorAngleRatio(lastVehicle, 5) > 0 then
							TriggerServerEvent('qbx_hidetrunk:server:setTrunkBusy', NetworkGetNetworkIdFromEntity(lastVehicle), true)
							lib.playAnim(cache.ped, "fin_ext_p1-7", "cs_devin_dual-7", 8.0, 8.0, -1, 1, 0, false, false, false)
							local min, max = GetModelDimensions(vehModel)
							local leftOffset, backOffset, heightOffset = -0.1, min.y + 0.8, 0.22
							local customOffset = config.customOffset[vehModel]
							if customOffset then
								leftOffset = leftOffset + customOffset.leftOffset
								backOffset = backOffset + customOffset.backOffset
								heightOffset = heightOffset + customOffset.heightOffset
							end
							local attachOffset = vec3(leftOffset, backOffset, heightOffset)
                            AttachEntityToEntity(cache.ped, lastVehicle, -1, attachOffset.x, attachOffset.y, attachOffset.z, 15.0, 5.0, 55.0, true, true, false, true, 1, true)
							if not config.pedVisible then
                            	SetEntityVisible(cache.ped, false, false)
							end
                            LocalPlayer.state:set('insideTrunk', true, true)
                            Wait(500)
                            SetVehicleDoorShut(lastVehicle, 5, false)
                            exports.qbx_core:Notify(locale("success.entered_trunk"), 'success', 4000)
                            camControl(true)
							startThreads()
                        else
                            exports.qbx_core:Notify(locale("error.trunk_closed"), 'error', 2500)
                        end
                    else
                        exports.qbx_core:Notify(locale("error.someone_in_trunk"), 'error', 2500)
                    end
                else
                    exports.qbx_core:Notify(locale("error.already_in_trunk"), 'error', 2500)
                end
            else
                exports.qbx_core:Notify(locale("error.cant_enter_trunk"), 'error', 2500)
            end
        else
            exports.qbx_core:Notify(locale("error.cant_enter_trunk"), 'error', 2500)
        end
    else
        exports.qbx_core:Notify(locale("error.no_vehicle_found"), 'error', 2500)
    end
end

RegisterNetEvent('qbx_hidetrunk:client:getInTrunk', function()
	getInTrunk()
end)

exports.ox_target:addGlobalVehicle({
    {
        name = 'qbx_hidetrunk:getintrunk',
        icon = 'fa-solid fa-car-rear',
        label = locale("general.getintrunk_target"),
        offset = vec3(0.5, 0, 0.5),
        distance = 2,
        canInteract = function(entity, distance, coords, name)
			local vehClass = GetVehicleClass(entity)
			local vehModel = GetEntityModel(entity)
			local disabled = config.classDisabled[vehClass] or config.trunkDisabled[vehModel]
			return not disabled and GetVehicleDoorAngleRatio(entity, 5) > 0
        end,
        onSelect = function(data)
            getInTrunk()
        end
    }
})
