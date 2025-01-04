local config = require 'config.client'

if not config.visualItemsInTrunk then return end

-- Thanks to Renewed-Weaponscarry for an example.
local cachedVehicles = {}

---@param trunk string
local function updateVehicleItems(trunk)
    local vehicleTrunk = cachedVehicles[trunk]
    if vehicleTrunk then
        if DoesEntityExist(vehicleTrunk.entity) then
            Entity(vehicleTrunk.entity).state:set('trunkHasItems', vehicleTrunk?.items or nil, true)
        end
    end
end

---@param plate string
local function checkWorldVehicles(plate)
    local vehicles = GetAllVehicles()

    for i = 1, #vehicles do
        local vehicle = vehicles[i]
        local _plate = GetVehicleNumberPlateText(vehicle)
        if _plate:find(plate) then
            return {entity = vehicle, items = {}}
        end
    end
    return nil
end

---@param payload table
local trunkitemsHook = exports.ox_inventory:registerHook('swapItems', function(payload)
    if payload.toType == 'trunk' or payload.fromType == 'trunk' then
        if payload.fromInventory ~= payload.toInventory then
            local inventoryId = type(payload.fromInventory) == 'string' and payload.fromInventory or payload.toInventory
            local vehicleTrunk = cachedVehicles[inventoryId]
            if vehicleTrunk then
                local itemAmountExist = vehicleTrunk.items[payload.fromSlot.name]
                if type(payload.fromInventory) == 'string' then
                    if itemAmountExist then
                        local newCount = itemAmountExist - payload.count
                        vehicleTrunk.items[payload.fromSlot.name] = newCount >= 1 and newCount or nil
                    end
                else
                    vehicleTrunk.items[payload.fromSlot.name] = itemAmountExist and (itemAmountExist + payload.count) or payload.count
                end
            end
            updateVehicleItems(inventoryId)
        end
    end
end, {
    inventoryFilter = {
        '^trunk[%w]+',
    }
})

---@param playerId number
---@param inventoryId string|number
AddEventHandler('ox_inventory:openedInventory', function(playerId, inventoryId)
    if type(inventoryId) ~= 'string' then return end
    if inventoryId:sub(1, 5) == 'trunk' then
        local plate = inventoryId:match('trunk(.*)')
        cachedVehicles[inventoryId] = checkWorldVehicles(plate)
        if not cachedVehicles[inventoryId] then
            return lib.print.error(('Failed to load vehicle, no entity exists with given plate (%s)'):format(plate))
        end
        local items = {}
        local trunkItems = exports.ox_inventory:GetInventoryItems(inventoryId, false)
        for _, item in pairs(trunkItems) do
            items[item.name] = item.count
        end
        cachedVehicles[inventoryId].items = items
    end
end)

---@param playerId number
---@param inventoryId string|number
AddEventHandler('ox_inventory:closedInventory', function(playerId, inventoryId)
    if type(inventoryId) ~= 'string' then return end
    if inventoryId:sub(1, 5) == 'trunk' then
        cachedVehicles[inventoryId] = nil
    end
end)

---@param entity number
AddEventHandler('entityRemoved', function(entity)
    if not Entity(entity).state.trunkHasItems then return end
    Entity(entity).state:set('trunkHasItems', nil, true)
end)

---@param bagName string
AddStateBagChangeHandler('vehicleid', '', function(bagName)
    local vehicle = GetEntityFromStateBagName(bagName)
    if not vehicle or vehicle == 0 then return end
	local plate = GetVehicleNumberPlateText(vehicle)
	local inventory = exports.ox_inventory:GetInventory('trunk'..plate, false)
	if inventory then
		local items = {}
        for _, item in pairs(inventory.items) do
            items[item.name] = item.count
        end
		Entity(vehicle).state:set('trunkHasItems', items or nil, true)
	end
end)