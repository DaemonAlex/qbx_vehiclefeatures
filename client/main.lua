local config = require 'config.client'

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

local function changeSeat(id, label)
	local isSeatFree = IsVehicleSeatFree(cache.vehicle, id - 2)
    local speed = GetEntitySpeed(cache.vehicle)
    if LocalPlayer.state?.harness then
        return exports.qbx_core:Notify(locale('error.race_harness_on'), 'error')
    end

	if LocalPlayer.state?.seatbelt then
        return exports.qbx_core:Notify(locale('error.vehicle_seatbelt_on'), 'error')
    end

    if not isSeatFree then
        return exports.qbx_core:Notify(locale('error.seat_occupied'), 'error')
    end

    if (speed * 3.6) > config.allowedSeatSpeed then
        return exports.qbx_core:Notify(locale('error.vehicle_driving_fast'), 'error')
    end

    SetPedIntoVehicle(cache.ped, cache.vehicle, id - 2)
    exports.qbx_core:Notify(locale('info.switched_seats', label))
end

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

local function flipVehicle()
	if cache.vehicle then return end
    local coords = GetEntityCoords(cache.ped)
    local vehicle = lib.getClosestVehicle(coords)
    if not vehicle then return exports.qbx_core:Notify(locale('error.no_vehicle_nearby'), 'error') end
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
            dict = 'mini@repair',
            clip = 'fixing_a_ped'
        },
    })
    then
        SetVehicleOnGroundProperly(vehicle)
        exports.qbx_core:Notify(locale('success.flipped_car'), 'success')
    else
        exports.qbx_core:Notify(locale('error.cancel_task'), 'error')
    end
end

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
					exports.qbx_core:Notify(locale('error.not_in_vehicle'), 'error')
				end
			end,
		}
	end
	lib.registerRadial({
		id = 'vehicleSeatsMenu',
		items = vehicleSeats
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
					exports.qbx_core:Notify(locale('error.not_in_vehicle'), 'error')
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
					exports.qbx_core:Notify(locale('error.not_in_vehicle'), 'error')
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
	if config.enableFlipVehicle then
		vehicleItems[#vehicleItems + 1] = {
			id = 'vehicleFlip',
			label = locale('options.flip'),
			icon = 'car-burst',
			onSelect = function()
				flipVehicle()
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
	if config.enableTrunkOptions then
		vehicleItems[#vehicleItems + 1] = {
			id = 'vehicleGetInTrunk',
			label = locale("options.getintrunk"),
			icon = 'truck-ramp-box',
			onSelect = function()
				TriggerEvent('qbx_vehiclefeatures:client:getInTrunk')
			end,
		}
		-- TODO: Add kidnapping item
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

if config.enableSeatsMenu then
	lib.onCache('vehicle', function(v)
		SetupVehicleSeats(v)
	end)
end

AddEventHandler('onResourceStart', function(resource)
    if cache.resource ~= resource then return end
	if config.enableTargets and config.enableFlipVehicle then
		setupFlipTarget()
	end
	if not config.enableRadialMenu then return end
    if LocalPlayer.state.isLoggedIn then
		if config.enableSeatsMenu then
			SetupVehicleSeats()
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
	if config.enableTargets and config.enableFlipVehicle then
		setupFlipTarget()
	end
	if not config.enableRadialMenu then return end
	if config.enableSeatsMenu then
		SetupVehicleSeats()
	end
	if config.enableExtraMenu then
		SetupVehicleExtras()
	end
	if config.enableDoorsMenu then
		SetupVehicleDoors()
	end
    setupVehicleMenu()
end)