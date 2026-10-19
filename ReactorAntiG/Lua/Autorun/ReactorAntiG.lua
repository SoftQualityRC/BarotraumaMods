
if not SERVER then return end

local CHECK_INTERVAL = 0.25
local RESET_TEMPERATURE = 70
local EJECT_OFFSET_Y = 1.5
local EJECT_DELAY = 10 -- Сколько секунд дать игроку на спасение реактора
local criticalSince = {}

local nextCheck = 0
local armed = {}

local function log(message)
    print("[ReactorSafety] " .. message)
end

local function getInventory(item)
    local ok, container = pcall(function()
        return item.GetComponentString("ItemContainer")
    end)

    if ok and container ~= nil then
        local success, inventory = pcall(function()
            return container.Inventory
        end)

        if success and inventory ~= nil then
            return inventory
        end
    end

    local okOwn, ownInventory = pcall(function()
        return item.OwnInventory
    end)

    if okOwn then
        return ownInventory
    end

    return nil
end

local function getItems(inventory)
    local result = {}

    if inventory == nil then return result end

    local ok = pcall(function()
        for contained in inventory.AllItems do
            if contained ~= nil and not contained.Removed then
                table.insert(result, contained)
            end
        end
    end)

    if not ok then
        log("Не удалось прочитать содержимое инвентаря")
    end

    return result
end

local function ejectItems(item, id)
    local inventory = getInventory(item)
    local contents = getItems(inventory)

    if #contents == 0 then
        log("ID=" .. id .. ": инвентарь пуст или не найден")
        return 0
    end

    local position = item.SimPosition
    local rotation = item.Rotation
    local ejected = 0

    for _, contained in ipairs(contents) do
        local ok, err = pcall(function()
            contained.Drop(nil, true, false)

            if position ~= nil then
                contained.SetTransform(
                    Vector2(position.X, position.Y + EJECT_OFFSET_Y),
                    rotation,
                    true,
                    true
                )
            end
        end)

        if ok then
            ejected = ejected + 1
            log("Извлечён предмет: " .. tostring(contained.Name))
        else
            log("Ошибка извлечения: " .. tostring(err))
        end
    end

    log("ID=" .. id .. ": извлечено предметов: " .. ejected)
    return ejected
end

Hook.Add("think", "ReactorSafetyProtection", function()
    local now = Timer.GetTime()
    if now < nextCheck then return end
    nextCheck = now + CHECK_INTERVAL

    for item in Item.ItemList do
        if item ~= nil and not item.Removed then
            local ok, reactor = pcall(function()
                return item.GetComponentString("Reactor")
            end)

            if ok and reactor ~= nil then
                local id = tostring(item.ID)

                local stateOK, temperature, critical = pcall(function()
                    return reactor.Temperature, reactor.TemperatureCritical
                end)

                if stateOK then
    if not critical then
        -- Реактор вышел из красной зоны: отменяем отсчёт
        criticalSince[id] = nil
        armed[id] = true
    else
        -- Запускаем таймер при первом попадании в красную зону
        if criticalSince[id] == nil then
            criticalSince[id] = now
            log("ВНИМАНИЕ! ID=" .. id ..
                ": критическая температура. Есть " ..
                EJECT_DELAY .. " секунд на охлаждение!")
        end

        -- Выбрасываем стержни только после задержки
        if armed[id] and now - criticalSince[id] >= EJECT_DELAY then
            armed[id] = false
            criticalSince[id] = nil

            log("ВРЕМЯ ВЫШЛО! ID=" .. id ..
                ": температура оставалась критической " ..
                EJECT_DELAY .. " секунд.")

            ejectItems(item, id)
						end
					end
				end
            end
        end
    end
end)

log("Защита реактора загружена.")
