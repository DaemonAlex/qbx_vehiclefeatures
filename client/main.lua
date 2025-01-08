local config = require 'config.client'

---@param extra number
local function setExtra(extra)
    if cache.vehicle ~= nil then
        if cache.seat == -1 then
            SetVehicleAutoRepairDisabled(cache.vehicle, true) -- Forces Auto Repair off when Toggling Extra [GTA 5 Niche Issue]
            if DoesExtraExist(cache.vehicle, extra) then
                if IsVehicleExtraTurnedOn(cache.vehicle, extra) then
                    qbx.setVehicleExtra(cache.vehicle, extra, false)
                    exports.qbx_core:Notify(locale('error.extra_deactivated', extra), 'error', 2500)
                else
                    qbx.setVehicleExtra(cache.vehicle, extra, true)
                    exports.qbx_core:Notify(locale('success.extra_activated', extra), 'success', 2500)
                end
            else
                exports.qbx_core:Notify(locale('error.extra_not_present', extra), 'error', 2500)
            end
        else
            exports.qbx_core:Notify(locale('error.not_driver'), 'error', 2500)
        end
    end
end

---@param id number
---@param label string
local function changeSeat(id, label)
    local isSeatFree = IsVehicleSeatFree(cache.vehicle, id - 2)
    local speed = GetEntitySpeed(cache.vehicle)
    if LocalPlayer.state?.harness then
        return exports.qbx_core:Notify(locale('error.race_harness_on'), 'error', 2500)
    end

    if LocalPlayer.state?.seatbelt then
        return exports.qbx_core:Notify(locale('error.vehicle_seatbelt_on'), 'error', 2500)
    end

    if not isSeatFree then
        return exports.qbx_core:Notify(locale('error.seat_occupied'), 'error', 2500)
    end

    if (speed * 3.6) > config.allowedSeatSpeed then
        return exports.qbx_core:Notify(locale('error.vehicle_driving_fast'), 'error', 2500)
    end

    SetPedIntoVehicle(cache.ped, cache.vehicle, id - 2)
    exports.qbx_core:Notify(locale('info.switched_seats', label), 'inform', 2500)
end

---@param door number
local function doorControl(door)
    local coords = GetEntityCoords(cache.ped)
    local closestVehicle = cache.vehicle or lib.getClosestVehicle(coords, 5.0, false)
    if closestVehicle ~= 0 then
        if closestVehicle ~= cache.vehicle then
            if GetVehicleDoorAngleRatio(closestVehicle, door) > 0.0 then
                if not IsVehicleSeatFree(closestVehicle, -1) then
                    TriggerServerEvent('qbx_vehiclefeatures:server:syncDoor', false, qbx.getVehiclePlate(closestVehicle), door)
                else
                    SetVehicleDoorShut(closestVehicle, door, false)
                end
            else
                if not IsVehicleSeatFree(closestVehicle, -1) then
                    TriggerServerEvent('qbx_vehiclefeatures:server:syncDoor', true, qbx.getVehiclePlate(closestVehicle), door)
                else
                    SetVehicleDoorOpen(closestVehicle, door, false, false)
                end
            end
        else
            if GetVehicleDoorAngleRatio(closestVehicle, door) > 0.0 then
                SetVehicleDoorShut(closestVehicle, door, false)
            else
                SetVehicleDoorOpen(closestVehicle, door, false, false)
            end
        end
    else
        exports.qbx_core:Notify(locale('error.no_vehicle_found'), 'error', 2500)
    end
end

local cachedWindows = {}
---@param window number
local function windowControl(window)
    if cache.vehicle ~= nil then
        if cache.seat == -1 then
            if not cachedWindows[cache.vehicle] then cachedWindows[cache.vehicle] = {} end
            if not cachedWindows[cache.vehicle][window] then
                RollDownWindow(cache.vehicle, window)
                cachedWindows[cache.vehicle][window] = true
            else
                RollUpWindow(cache.vehicle, window)
                cachedWindows[cache.vehicle][window] = nil
            end
        else
            exports.qbx_core:Notify(locale('error.not_driver'), 'error', 2500)
        end
    end
end

local function flipVehicle()
    if cache.vehicle then return end
    local coords = GetEntityCoords(cache.ped)
    local vehicle = lib.getClosestVehicle(coords, 5.0, false)
    if not vehicle then return exports.qbx_core:Notify(locale('error.no_vehicle_nearby'), 'error', 2500) end
    if lib.progressBar({
        label = locale('progress.flipping_car'),
        duration = config.flipVehicleTime,
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = true,
            car = true,
            mouse = false,
            combat = true
        },
        anim = {
            dict = 'missfinale_c2ig_11',
            clip = 'pushcar_offcliff_f'
        },
    })
    then
        SetVehicleOnGroundProperly(vehicle)
        exports.qbx_core:Notify(locale('success.flipped_car'), 'success', 2500)
    else
        exports.qbx_core:Notify(locale('error.cancel_task'), 'error', 2500)
    end
end

local function pushVehicle()
    if cache.vehicle then return end
    local coords = GetEntityCoords(cache.ped)
    local vehicle = lib.getClosestVehicle(coords, 5.0, false)
    if not vehicle then return exports.qbx_core:Notify(locale('error.no_vehicle_nearby'), 'error', 2500) end
    if GetIsVehicleEngineRunning(vehicle) then return end
    if IsEntityUpsidedown(vehicle) then return end
    if GetVehicleDoorLockStatus(vehicle) == 2 then return exports.qbx_core:Notify(locale('error.vehicle_locked'), 'error', 2500) end
    if not IsVehicleSeatFree(vehicle, -1) then return exports.qbx_core:Notify(locale('error.seat_occupied'), 'error', 2500) end
    local getFront = #(GetWorldPositionOfEntityBone(vehicle, GetEntityBoneIndexByName(vehicle, 'wheel_rr')) - coords) > #(GetWorldPositionOfEntityBone(vehicle, GetEntityBoneIndexByName(vehicle, 'wheel_rf')) - coords)
    local dimension = GetModelDimensions(GetEntityModel(vehicle), vector3(0.0, 0.0, 0.0), vector3(5.0, 5.0, 5.0))
    if getFront then
        AttachEntityToEntity(cache.ped, vehicle, GetPedBoneIndex(6286), 0.0, dimension.y * -1 + 0.1 , dimension.z + 1.0, 0.0, 0.0, 180.0, 0.0, false, false, true, false, true)
    else
        AttachEntityToEntity(cache.ped, vehicle, GetPedBoneIndex(6286), 0.0, dimension.y - 0.3, dimension.z  + 1.0, 0.0, 0.0, 0.0, 0.0, false, false, true, false, true)
    end
    lib.requestAnimDict('missfinale_c2ig_11')
    lib.requestAnimDict('rcmjosh2')
    TaskPlayAnim(cache.ped, 'missfinale_c2ig_11', 'pushcar_offcliff_m', 2.0, -8.0, -1, 35, 0, 0, 0, 0)
    Wait(200)
    local currentVehicle = vehicle
    while true do
        if not IsEntityAttached(cache.ped) or not DoesEntityExist(currentVehicle) then
            DetachEntity(cache.ped, false, false)
            StopAnimTask(cache.ped, 'rcmjosh2', 'stand_lean_back_beckon_b', 2.0)
            StopAnimTask(cache.ped, 'missfinale_c2ig_11', 'pushcar_offcliff_m', 2.0)
            FreezeEntityPosition(cache.ped, false)
            break
        end
        Wait(5)
        if IsControlPressed(0, 34) then -- A
            TaskVehicleTempAction(cache.ped, currentVehicle, 11, 1000)
        end
        if IsControlPressed(0, 9) then -- D
            TaskVehicleTempAction(cache.ped, currentVehicle, 10, 1000)
        end
        if IsControlPressed(0, 71) then -- W
            if IsEntityPlayingAnim(cache.ped, 'rcmjosh2', 'stand_lean_back_beckon_b', 3) then
                StopAnimTask(cache.ped, 'rcmjosh2', 'stand_lean_back_beckon_b', 2.0)
                TaskPlayAnim(cache.ped, 'missfinale_c2ig_11', 'pushcar_offcliff_m', 2.0, -8.0, -1, 35, 0, 0, 0, 0)
            end
            if getFront then
                SetVehicleForwardSpeed(currentVehicle, -1.0)
            else
                SetVehicleForwardSpeed(currentVehicle, 1.0)
            end
        else
            if IsEntityPlayingAnim(cache.ped, 'missfinale_c2ig_11', 'pushcar_offcliff_m', 3) then
                StopAnimTask(cache.ped, 'missfinale_c2ig_11', 'pushcar_offcliff_m', 2.0)
                TaskPlayAnim(cache.ped, 'rcmjosh2', 'stand_lean_back_beckon_b', 2.0, -8.0, -1, 35, 0, 0, 0, 0)
            end
        end
        if HasEntityCollidedWithAnything(currentVehicle) then
            SetVehicleOnGroundProperly(currentVehicle)
        end
        if IsControlPressed(0, 25) or IsControlPressed(0, 48) or IsControlPressed(0, 73) then -- RIGHT MOUSE BUTTON, Z, X
            DetachEntity(cache.ped, false, false)
            StopAnimTask(cache.ped, 'rcmjosh2', 'stand_lean_back_beckon_b', 2.0)
            StopAnimTask(cache.ped, 'missfinale_c2ig_11', 'pushcar_offcliff_m', 2.0)
            FreezeEntityPosition(cache.ped, false)
            break
        end
    end
    RemoveAnimDict('missfinale_c2ig_11')
    RemoveAnimDict('rcmjosh2')
end

---@param vehicle number
local function SetupVehicleSeats(vehicle)
    lib.removeRadialItem('vehicleSeatsMenu')
    local vehicleSeats = {}
    local seatTable = {
        [1] = locale('options.driver_seat'),
        [2] = locale('options.passenger_seat'),
        [3] = locale('options.rear_left_seat'),
        [4] = locale('options.rear_right_seat'),
    }
    local amountOfSeats = vehicle and GetVehicleModelNumberOfSeats(GetEntityModel(vehicle)) or 2
    for i = 1, amountOfSeats do
        vehicleSeats[#vehicleSeats + 1] = {
            id = 'vehicleSeat'..i,
            label = seatTable[i] or locale('options.other_seats'),
            icon = 'caret-up',
            onSelect = function()
                if cache.vehicle then
                    changeSeat(i, seatTable[i] or locale('options.other_seats'))
                else
                    exports.qbx_core:Notify(locale('error.not_in_vehicle'), 'error', 2500)
                end
            end,
        }
    end
    lib.registerRadial({
        id = 'vehicleSeatsMenu',
        items = vehicleSeats
    })
end

local function SetupVehicleWindows()
    local vehicleWindows = {}
    local windowsTable = {
        [1] = locale('options.driver_window'), -- VEH_EXT_WINDOW_LF
        [2] = locale('options.passenger_window'), -- VEH_EXT_WINDOW_RF
        [3] = locale('options.rear_left_window'), -- VEH_EXT_WINDOW_LR
        [4] = locale('options.rear_right_window'), -- VEH_EXT_WINDOW_RR
        -- [5] = 'VEH_EXT_WINDOW_LM',
        -- [6] = 'VEH_EXT_WINDOW_RM',
        -- [7] = 'VEH_EXT_WINDSCREEN',
        -- [8] = 'VEH_EXT_WINDSCREEN_R',
    }
    for i = 1, 4 do
        vehicleWindows[#vehicleWindows + 1] = {
            id = 'vehicleWindow'..tostring(i),
            label = windowsTable[i],
            icon = 'car',
            onSelect = function()
                if cache.vehicle then
                    windowControl(i-1)
                else
                    exports.qbx_core:Notify(locale('error.not_in_vehicle'), 'error', 2500)
                end
            end,
            keepOpen = true
        }
    end
    lib.registerRadial({
        id = 'vehicleWindowsMenu',
        items = vehicleWindows
    })
end

local function SetupVehicleExtras()
    local vehicleExtras = {}
    for i = 1, 13 do
        vehicleExtras[#vehicleExtras + 1] = {
            id = 'vehicleExtra'..tostring(i),
            label = 'Extra '..tostring(i),
            icon = 'box-open',
            onSelect = function()
                if cache.vehicle then
                    setExtra(i)
                else
                    exports.qbx_core:Notify(locale('error.not_in_vehicle'), 'error', 2500)
                end
            end,
            keepOpen = true
        }
    end
    lib.registerRadial({
        id = 'vehicleExtrasMenu',
        items = vehicleExtras
    })
end

local function SetupVehicleDoors()
    local vehicleDoors = {}
    local doorsTable = {
        [1] = locale('options.driver_door'), 
        [2] = locale('options.passenger_door'),
        [3] = locale('options.rear_left_door'),
        [4] = locale('options.rear_right_door'),
        [5] = locale('options.hood_door'),
        [6] = locale('options.trunk_door'),
    }
    for i = 1, 6 do
        vehicleDoors[#vehicleDoors + 1] = {
            id = 'vehicleDoor'..tostring(i),
            label = doorsTable[i],
            icon = 'car-side',
            onSelect = function()
                if cache.vehicle then
                    doorControl(i-1)
                else
                    exports.qbx_core:Notify(locale('error.not_in_vehicle'), 'error', 2500)
                end
            end,
            keepOpen = true
        }
    end
    lib.registerRadial({
        id = 'vehicleDoorsMenu',
        items = vehicleDoors
    })
end

local function setupVehicleMenu()
    local vehicleItems = {}
    if config.enableFlipMenu then
        vehicleItems[#vehicleItems + 1] = {
            id = 'vehicleFlip',
            label = locale('options.flip'),
            icon = 'car-burst',
            onSelect = function()
                flipVehicle()
            end,
        }
    end
    if config.enablePushMenu then
        vehicleItems[#vehicleItems + 1] = {
            id = 'vehiclePush',
            label = locale('options.push'),
            icon = 'fa-arrow-down-up-across-line',
            onSelect = function()
                pushVehicle()
            end,
        }
    end
    if config.enableSeatsMenu then
        vehicleItems[#vehicleItems + 1] = {
            id = 'vehicleSeats',
            label = locale('options.vehicleseats'),
            icon = 'chair',
            menu = 'vehicleSeatsMenu'
        }
    end
    if config.enableWindowsMenu then
        vehicleItems[#vehicleItems + 1] = {
            id = 'vehicleWindows',
            label = locale('options.vehiclewindows'),
            icon = 'car',
            menu = 'vehicleWindowsMenu'
        }
    end
    if config.enableExtraMenu then
        vehicleItems[#vehicleItems + 1] = {
            id = 'vehicleExtras',
            label = locale('options.vehicleextras'),
            icon = 'plus',
            menu = 'vehicleExtrasMenu'
        }
    end
    if config.enableDoorsMenu then
        vehicleItems[#vehicleItems + 1] = {
            id = 'vehicleDoors',
            label = locale('options.vehicledoors'),
            icon = 'car-side',
            menu = 'vehicleDoorsMenu'
        }
    end
    if config.enableTrunkMenu then
        vehicleItems[#vehicleItems + 1] = {
            id = 'vehicleGetInTrunk',
            label = locale('options.getintrunk'),
            icon = 'truck-ramp-box',
            onSelect = function()
                TriggerEvent('qbx_vehiclefeatures:client:getInTrunk', false)
            end
        }
        vehicleItems[#vehicleItems + 1] = {
            id = 'vehiclePutInTrunk',
            label = locale('options.putintrunk'),
            icon = 'truck-ramp-box',
            onSelect = function()
                TriggerEvent('qbx_vehiclefeatures:client:getInTrunk', true)
            end
        }
        vehicleItems[#vehicleItems + 1] = {
            id = 'vehicleGetOutTrunk',
            label = locale('options.getouttrunk'),
            icon = 'truck-ramp-box',
            onSelect = function()
                TriggerEvent('qbx_vehiclefeatures:client:getOutTrunk')
            end
        }
    end
    lib.registerRadial({
        id = 'vehicleMenu',
        items = vehicleItems
    })
    lib.addRadialItem({
        id = 'vehicle',
        label = locale('options.vehicle'),
        icon = 'fa-car-rear',
        menu = 'vehicleMenu'
    })
end

local function setupFlipTarget()
    exports.ox_target:addGlobalVehicle({
        {
            name = 'qbx_vehiclefeatures:flipvehicle',
            icon = 'fa-solid fa-car-burst',
            label = locale('targets.flip'),
            distance = 2,
            onSelect = function(data)
                flipVehicle()
            end
        }
    })
end

local function setupPushTarget()
    exports.ox_target:addGlobalVehicle({
        {
            name = 'qbx_vehiclefeatures:pushvehicle',
            icon = 'fas fa-arrow-down-up-across-line',
            label = locale('targets.push'),
            distance = 2,
            onSelect = function(data)
                pushVehicle()
            end
        }
    })
end

lib.onCache('vehicle', function(v)
    if not cachedWindows[v] then cachedWindows = {} end
    if config.enableSeatsMenu then SetupVehicleSeats(v) end
end)

---@param resource string
AddEventHandler('onResourceStart', function(resource)
    if cache.resource ~= resource then return end
    if config.enableTargets then
        if config.enableFlipTarget then setupFlipTarget() end
        if config.enablePushTarget then setupPushTarget() end
    end
    if not config.enableRadialMenu then return end
    if LocalPlayer.state.isLoggedIn then
        if config.enableSeatsMenu then
            SetupVehicleSeats()
        end
        if config.enableWindowsMenu then
            SetupVehicleWindows()
        end
        if config.enableExtraMenu then
            SetupVehicleExtras()
        end
        if config.enableDoorsMenu then
            SetupVehicleDoors()
        end
        setupVehicleMenu()
    end
end)

AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
    if config.enableTargets then
        if config.enableFlipTarget then setupFlipTarget() end
        if config.enablePushTarget then setupPushTarget() end
    end
    if not config.enableRadialMenu then return end
    if config.enableSeatsMenu then
        SetupVehicleSeats()
    end
    if config.enableWindowsMenu then
        SetupVehicleWindows()
    end
    if config.enableExtraMenu then
        SetupVehicleExtras()
    end
    if config.enableDoorsMenu then
        SetupVehicleDoors()
    end
    setupVehicleMenu()
end)