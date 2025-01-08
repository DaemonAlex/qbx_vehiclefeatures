local config = require 'config.client'

if not config.visualItemsInTrunk then return end

-- Thanks to Renewed-Weaponscarry for an example.
local cachedVehicles = {}

---@param data table
local function removeEntitys(data)
    for i = 1, #data do
        local entity = data[i]?.entity
        if entity then
            DeleteEntity(entity)
        end
    end
end

---@param name string
---@param amount number
local function getItemModel(name, amount)
    local itemConfig = config.trunkModels[name]
    if not itemConfig then
        return {model = config.defaultTrunkItem}
    end
    table.sort(itemConfig, function(a, b)
        return a.threshold > b.threshold
    end)
    for _, v in ipairs(itemConfig) do
        if amount >= v.threshold then
            return v
        end
    end
    return {model = config.defaultTrunkItem}
end

---@param items table
---@param maxItems number
local function getPrioritizedItems(items, maxItems)
    local prioritizedItems, added, amount = {}, {}, 0
    for itemName, _ in pairs(config.trunkModels) do
        if items[itemName] and amount < maxItems then
            prioritizedItems[itemName], added[itemName], amount = items[itemName], true, amount + 1
        end
    end
    for itemName, itemCount in pairs(items) do
        if not added[itemName] then
            prioritizedItems[itemName], amount = itemCount, amount + 1
        end
        if amount >= maxItems then
            break
        end
    end
    return prioritizedItems
end

---@param vehicle number
---@param items table
---@param currentTable table
local function createAllObjects(vehicle, items, currentTable)
    local amount = 0
    local prioritizedItems = getPrioritizedItems(items, #config.trunkItems)
    for item, count in pairs(prioritizedItems) do
        amount = amount + 1
        if amount >= #config.trunkItems + 1 then break end
        local itemData = getItemModel(item, count)
        lib.requestModel(itemData.model, 1000)
        local object = CreateObject(itemData.model, 0.0, 0.0, 0.0, false, false, false)
        SetModelAsNoLongerNeeded(itemData.model)
        SetEntityCollision(object, false, false)
        local vehModel = GetEntityModel(vehicle)
        local min, max = GetModelDimensions(vehModel)
        local trunkItemsOffset = config.trunkItems[amount]
        local leftOffset, backOffset, heightOffset = trunkItemsOffset.leftOffset + -0.1, trunkItemsOffset.backOffset + min.y + 0.8, trunkItemsOffset.heightOffset + 0.22
        local pitchOffset, RollOffset, yawOffset = itemData?.pitchOffset or 0.0, itemData?.RollOffset or 0.0, itemData?.yawOffset or 0.0
        local customOffset = config.customOffset[vehModel]
        if customOffset then
            leftOffset = leftOffset + customOffset.leftOffset
            backOffset = backOffset + customOffset.backOffset
            heightOffset = heightOffset + customOffset.heightOffset
        end
        AttachEntityToEntity(object, vehicle, -1, leftOffset, backOffset, heightOffset, pitchOffset, RollOffset, yawOffset, true, true, true, false, 1, true)
        currentTable[amount] = {
            name = item,
            entity = object,
        }
    end
end

---@param entity number
---@param value any
---@param bagName string
qbx.entityStateHandler('trunkHasItems', function(entity, _, value, bagName)
    if entity == 0 then return lib.print.error(('trunkHasItems received invalid entity! (%s)'):format(bagName)) end
    if not cachedVehicles[bagName] then
        cachedVehicles[bagName] = {}
    end
    local currentTable = cachedVehicles[bagName][entity] or {}
    if table.type(currentTable) ~= 'empty' then
        removeEntitys(currentTable)
        table.wipe(currentTable)
    end
    if value and next(value) then
        createAllObjects(entity, value, currentTable)
    end
    cachedVehicles[bagName][entity] = currentTable
end)

---@param resource string
AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        for bagname, _ in pairs(cachedVehicles) do
            if cachedVehicles[bagname] and table.type(cachedVehicles[bagname]) ~= 'empty' then
                for _, props in pairs(cachedVehicles[bagname]) do
                    if props and table.type(props) ~= 'empty' then
                        removeEntitys(props)
                    end
                end
            end
        end
    end
end)

CreateThread(function()
    while true do
        for bagname, _ in pairs(cachedVehicles) do
            local cachedData = cachedVehicles[bagname]
            if cachedData and table.type(cachedData) ~= 'empty' then
                for entity, props in pairs(cachedData) do
                    if not DoesEntityExist(entity) and props and table.type(props) ~= 'empty' then
                        removeEntitys(props)
                        cachedVehicles[bagname][entity] = nil
                    end
                end
            end
        end
        Wait(1500)
    end
end)

-- Testing trunk items
-- local ptest = {}
-- AddEventHandler('onResourceStop', function(resource)
--     if resource == GetCurrentResourceName() then
--         if table.type(ptest) ~= 'empty' then
--             removeEntitys(ptest)
--             ptest = {}
--         end
--     end
-- end)
-- RegisterCommand('testitems', function()
--     if table.type(ptest) ~= 'empty' then
--         removeEntitys(ptest)
--         ptest = {}
--     else
--         local coords = GetEntityCoords(cache.ped)
--            local vehicle,_ = lib.getClosestVehicle(coords, 3.0, false)
--         if vehicle == nil or vehicle == 0 then return false end
--         local currentTable = {}
--         createAllObjects(vehicle, {
--             ['WEAPON_PISTOL'] = 1,
--             ['radioscanner'] = 1,
--             ['radioscanner'] = 1,
--             ['radioscanner'] = 1,
--             ['money'] = 1,
--         }, currentTable)
--         ptest = currentTable
--     end
-- end)