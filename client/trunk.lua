local config = require 'config.client'

local lastVehicle = nil
local trunkCam = 0
local polarAngleDeg = 0
local yawAngleDeg = 60
local radiusDeg = -4.5
local DEG_TO_RAD = math.pi / 180.0

---@param entityPosition vector3
---@param radiusDeg float
---@param polarAngleDeg number
---@param yawAngleDeg number
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

---@param bool boolean
local function camControl(bool)
    local camPos = GetOffsetFromEntityInWorldCoords(lastVehicle, 0, -5.5, 0)
    local vehHeading = GetEntityHeading(lastVehicle)
    if bool then
        RenderScriptCams(false, false, 0, true, false)
        if DoesCamExist(trunkCam) then
            DestroyCam(trunkCam, false)
            trunkCam = 0
        end

        trunkCam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
        SetCamActive(trunkCam, true)
        SetCamCoord(trunkCam, camPos.x, camPos.y, camPos.z + 2)
        SetCamRot(trunkCam, -2.5, 0.0, vehHeading, 0.0)
        RenderScriptCams(true, false, 0, true, true)
    else
        RenderScriptCams(false, false, 0, true, false)
        if DoesCamExist(trunkCam) then
            DestroyCam(trunkCam, false)
            trunkCam = 0
        end
        lastVehicle = nil
    end
end

local function exitTrunk()
    local min, max = GetModelDimensions(GetEntityModel(lastVehicle))
    local backOffset = vec3(0.0, min.y - 0.6, 0.0)
    local entityOffset = GetOffsetFromEntityInWorldCoords(lastVehicle, backOffset.x, backOffset.y, backOffset.z)
    SetEntityCoords(cache.ped, entityOffset.x, entityOffset.y, entityOffset.z, false, false, false, false)
end

local function cancelTrunk()
    DetachEntity(cache.ped, true, true)
    ClearPedTasks(cache.ped)
    LocalPlayer.state:set('insideTrunk', false, true)
    LocalPlayer.state:set('isKidnapped', false, true)
    if DoesEntityExist(lastVehicle) then
        TriggerServerEvent('qbx_vehiclefeatures:server:setTrunkBusy', NetworkGetNetworkIdFromEntity(lastVehicle), false)
        exitTrunk()
        PointCamAtEntity(trunkCam, cache.ped)
        local vehicleSpeed = (GetEntitySpeed(lastVehicle) * 3.6)
        if vehicleSpeed > 5 and vehicleSpeed < config.allowedTrunkSpeed then
            local velocity = GetEntityVelocity(lastVehicle) / 6.0
            SetEntityHeading(cache.ped, (GetEntityHeading(lastVehicle) + 180) % 360)
            lib.playAnim(cache.ped, 'nm@stunt_jump', 'jump_loop', 8.0, -8.0, -1, 0, 0, false, false, false)
            SetEntityVelocity(cache.ped, velocity.x, velocity.y, velocity.z)
            Wait(1000)
            SetPedToRagdoll(cache.ped, 4000, 4000, 0, false, false, false)
        end
    end
    if not config.pedVisible then
        SetEntityVisible(cache.ped, true, true)
    end
    camControl(false)
end

local function startThreads()
    -- CreateThread(function()
    --     while LocalPlayer.state?.insideTrunk do
    --         if not IsEntityPlayingAnim(cache.ped, 'fin_ext_p1-7', 'cs_devin_dual-7', 3) then
    --             lib.playAnim(cache.ped, 'fin_ext_p1-7', 'cs_devin_dual-7', 8.0, 8.0, -1, 1, 0, false, false, false)
    --         end
    --         Wait(0)
    --     end
    -- end)
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
                if config.barPeeking then
                    if not (GetVehicleDoorAngleRatio(lastVehicle, 5) > 0) then
                        DrawRect(0.0, 0.0, 2.0, 0.76, 0, 0, 0, 255)
                        DrawRect(0.0, 1.0, 2.0, 0.76, 0, 0, 0, 255)
                    end
                end
            else
                Citizen.Wait(1000)
            end
            Citizen.Wait(1)
        end
    end)
    CreateThread(function()
        while LocalPlayer.state?.insideTrunk do
            if DoesEntityExist(lastVehicle) then
                if not LocalPlayer.state?.isKidnapped then
                    local drawPos = GetOffsetFromEntityInWorldCoords(lastVehicle, 0, -0.3, 0.1)
                    if config.drawText3dTrunk then
                        qbx.drawText3d({coords = vector3(drawPos.x, drawPos.y, drawPos.z + 0.25), text =  locale('general.get_out_trunk_button')})
                    end
                    if IsControlJustPressed(0, 38) then
                        if GetVehicleDoorAngleRatio(lastVehicle, 5) > 0 then
                            local vehicleSpeed = (GetEntitySpeed(lastVehicle) * 3.6)
                            if vehicleSpeed < config.allowedTrunkSpeed then
                                cancelTrunk()
                            else
                                exports.qbx_core:Notify(locale('error.vehicle_driving_fast'), 'error', 2500)
                            end
                        else
                            exports.qbx_core:Notify(locale('error.trunk_closed'), 'error', 2500)
                        end
                        Wait(100)
                    end
                    if GetVehicleDoorAngleRatio(lastVehicle, 5) > 0 then
                        if config.drawText3dTrunk then
                            qbx.drawText3d({coords = vector3(drawPos.x, drawPos.y, drawPos.z), text = locale('general.close_trunk_button')})
                        end
                        if IsControlJustPressed(0, 47) then
                            if not IsVehicleSeatFree(lastVehicle, -1) then
                                TriggerServerEvent('qbx_vehiclefeatures:server:syncDoor', false, qbx.getVehiclePlate(lastVehicle), 5)
                            else
                                SetVehicleDoorShut(lastVehicle, 5, false)
                            end
                            Wait(100)
                        end
                    else
                        if config.drawText3dTrunk then
                            qbx.drawText3d({coords = vector3(drawPos.x, drawPos.y, drawPos.z), text = locale('general.open_trunk_button')})
                        end
                        if IsControlJustPressed(0, 47) then
                            if not IsVehicleSeatFree(lastVehicle, -1) then
                                TriggerServerEvent('qbx_vehiclefeatures:server:syncDoor', true, qbx.getVehiclePlate(lastVehicle), 5)
                            else
                                SetVehicleDoorOpen(lastVehicle, 5, false, false)
                            end
                            Wait(100)
                        end
                    end
                end
                if GetVehicleBodyHealth(lastVehicle) <= 0.0 then
                    exports.qbx_core:Notify(locale('error.trunk_damaged'), 'error', 2500)
                    cancelTrunk()
                    break
                end
            else
                cancelTrunk()
                break
            end
            if LocalPlayer.state?.isDead then
                cancelTrunk()
                break
            end
            Wait(0)
        end
    end)
end

local function putInTrunk()
    TriggerServerEvent('qbx_vehiclefeatures:server:setTrunkBusy', NetworkGetNetworkIdFromEntity(lastVehicle), true)
    lib.playAnim(cache.ped, 'fin_ext_p1-7', 'cs_devin_dual-7', 8.0, 8.0, -1, 1, 0, false, false, false)
    -- TODO: Find a way to check if the boot is in front of the vehicle.
    local vehModel = GetEntityModel(lastVehicle)
    local min, max = GetModelDimensions(vehModel)
    local leftOffset, backOffset, heightOffset = -0.1, min.y + 0.8, 0.22
    local customOffset = config.customOffset[vehModel]
    if customOffset then
        leftOffset = leftOffset + customOffset.leftOffset
        backOffset = backOffset + customOffset.backOffset
        heightOffset = heightOffset + customOffset.heightOffset
    end
    AttachEntityToEntity(cache.ped, lastVehicle, -1, leftOffset, backOffset, heightOffset, 15.0, 5.0, 55.0, true, true, false, true, 1, true)
    if not config.pedVisible then
        SetEntityVisible(cache.ped, false, false)
    end
    LocalPlayer.state:set('insideTrunk', true, true)
    Wait(500)
    if not IsVehicleSeatFree(lastVehicle, -1) then
        TriggerServerEvent('qbx_vehiclefeatures:server:syncDoor', false, qbx.getVehiclePlate(lastVehicle), 5)
    else
        SetVehicleDoorShut(lastVehicle, 5, false)
    end
    exports.qbx_core:Notify(locale('success.entered_trunk'), 'success', 4000)
    camControl(true)
    startThreads()
end

---@param kidnapping boolean
local function getInTrunk(kidnapping)
    local closestVehicle, closestCoords = lib.getClosestVehicle(GetEntityCoords(cache.ped), 5.0, false)
    if closestVehicle == 0 or not DoesEntityExist(closestVehicle) then return exports.qbx_core:Notify(locale('error.no_vehicle_found'), 'error', 2500) end
    lastVehicle = closestVehicle
    local vehClass = GetVehicleClass(lastVehicle)
    local vehModel = GetEntityModel(lastVehicle)
    if config.classDisabled[vehClass] then return exports.qbx_core:Notify(locale('error.cant_enter_trunk'), 'error', 2500) end
    if config.trunkDisabled[vehModel] then return exports.qbx_core:Notify(locale('error.cant_enter_trunk'), 'error', 2500) end
    if LocalPlayer.state?.insideTrunk then return exports.qbx_core:Notify(locale('error.already_in_trunk'), 'error', 2500) end
    if Entity(lastVehicle).state?.trunkbusy then return exports.qbx_core:Notify(locale('error.someone_in_trunk'), 'error', 2500) end
    if not (GetVehicleDoorAngleRatio(lastVehicle, 5) > 0) then return exports.qbx_core:Notify(locale('error.trunk_closed'), 'error', 2500) end
    if kidnapping then
        -- if not LocalPlayer.state?.isEscorting then return exports.qbx_core:Notify(locale('error.not_kidnapped'), 'error', 2500) end
        local TargetPlayer, _, _ = lib.getClosestPlayer(GetEntityCoords(cache.ped), 1.5, false)
        if not TargetPlayer then return exports.qbx_core:Notify(locale('error.not_kidnapped'), 'error', 2500) end
        TriggerServerEvent('qbx_vehiclefeatures:server:kidnapTrunk', NetworkGetNetworkIdFromEntity(lastVehicle), GetPlayerServerId(TargetPlayer))
        return
    end
    putInTrunk()
end

---@param vehNetId number
RegisterNetEvent('qbx_vehiclefeatures:client:kidnapTrunk', function(vehNetId)
    local vehicleEntity = NetworkGetEntityFromNetworkId(vehNetId)
    if not DoesEntityExist(vehicleEntity) then return end
    if LocalPlayer.state?.insideTrunk then return cancelTrunk() end
    if not LocalPlayer.state?.isKidnapped then return end
    lastVehicle = vehicleEntity
    putInTrunk(true)
end)

---@param kidnapping boolean
RegisterNetEvent('qbx_vehiclefeatures:client:getInTrunk', function(kidnapping)
    getInTrunk(kidnapping)
end)

RegisterNetEvent('qbx_vehiclefeatures:client:getOutTrunk', function()
    local closestVehicle, closestCoords = lib.getClosestVehicle(GetEntityCoords(cache.ped), 5.0, false)
    if closestVehicle == 0 or not DoesEntityExist(closestVehicle) then return exports.qbx_core:Notify(locale('error.no_vehicle_found'), 'error', 2500) end
    if not (GetVehicleDoorAngleRatio(closestVehicle, 5) > 0) then return exports.qbx_core:Notify(locale('error.trunk_closed'), 'error', 2500) end
    local targetPlayerId = Entity(closestVehicle).state?.trunkbusy
    if targetPlayerId then
        TriggerServerEvent('qbx_vehiclefeatures:server:kidnapTrunk', NetworkGetNetworkIdFromEntity(closestVehicle), targetPlayerId)
    end
end)

-- Backward compatibility with qb police job
---@param bool boolean
RegisterNetEvent('qb-kidnapping:client:SetKidnapping', function(bool)
    LocalPlayer.state:set('isKidnapped', bool, true)
end)

---@param open boolean
---@param plate string
---@param door number
RegisterNetEvent('qbx_vehiclefeatures:client:syncDoor', function(plate, door, open)
    if not cache.vehicle then return end

    local pl = qbx.getVehiclePlate(cache.vehicle)
    if pl ~= plate then return end

    if open then
        SetVehicleDoorOpen(cache.vehicle, door, false, false)
    else
        SetVehicleDoorShut(cache.vehicle, door, false)
    end
end)

local function setupTrunkTargets()
    exports.ox_target:addGlobalVehicle({
        {
            name = 'qbx_vehiclefeatures:getintrunk',
            icon = 'fa-solid fa-truck-ramp-box',
            label = locale('targets.getintrunk'),
            offset = vec3(0.5, 0, 0.5),
            distance = 2,
            canInteract = function(entity, distance, coords, name)
                local vehClass = GetVehicleClass(entity)
                local vehModel = GetEntityModel(entity)
                local disabled = config.classDisabled[vehClass] or config.trunkDisabled[vehModel] or Entity(entity).state?.trunkbusy
                return not disabled and GetVehicleDoorAngleRatio(entity, 5) > 0
            end,
            onSelect = function(data)
                getInTrunk()
            end
        },
        {
            name = 'qbx_vehiclefeatures:getintrunk',
            icon = 'fa-solid fa-truck-ramp-box',
            label = locale('targets.putintrunk'),
            offset = vec3(0.5, 0, 0.5),
            distance = 2,
            canInteract = function(entity, distance, coords, name)
                local vehClass = GetVehicleClass(entity)
                local vehModel = GetEntityModel(entity)
                local disabled = config.classDisabled[vehClass] or config.trunkDisabled[vehModel] or Entity(entity).state?.trunkbusy -- and not LocalPlayer.state?.isEscorting
                return not disabled and GetVehicleDoorAngleRatio(entity, 5) > 0
            end,
            onSelect = function(data)
                getInTrunk(true)
            end
        },
        {
            name = 'qbx_vehiclefeatures:getouttrunk',
            icon = 'fa-solid fa-truck-ramp-box',
            label = locale('targets.getouttrunk'),
            offset = vec3(0.5, 0, 0.5),
            distance = 2,
            canInteract = function(entity, distance, coords, name)
                return GetVehicleDoorAngleRatio(entity, 5) > 0 and Entity(entity).state?.trunkbusy
            end,
            onSelect = function(data)
                local targetPlayerId = Entity(data.entity).state?.trunkbusy
                if targetPlayerId then
                    TriggerServerEvent('qbx_vehiclefeatures:server:kidnapTrunk', NetworkGetNetworkIdFromEntity(data.entity), targetPlayerId)
                end
            end
        }
    })
end

---@param resource string
AddEventHandler('onResourceStart', function(resource)
    if cache.resource ~= resource then return end
    if LocalPlayer.state.isLoggedIn then
        LocalPlayer.state:set('insideTrunk', false, true)
        LocalPlayer.state:set('isKidnapped', false, true)
        if config.enableTargets and config.enableTrunkTarget then
            setupTrunkTargets()
        end
    end
end)

AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
    LocalPlayer.state:set('insideTrunk', false, true)
    LocalPlayer.state:set('isKidnapped', false, true)
    if config.enableTargets and config.enableTrunkTarget then
        setupTrunkTargets()
    end
end)