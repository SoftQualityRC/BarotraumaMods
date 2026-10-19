-- HostFreecam v0.5 for Barotrauma 1.13.4.0 + LuaCs
-- Client-side camera experiment. Does not enable cheats or send network commands.
local TAG = "[HostFreecam]"
local enabled = false
local savedCharacter = nil
local keyHookSeen = false
local warnedNotHost = false
local lastKeyLog = nil

local function log(message)
    print(TAG .. " " .. message)
end

-- In LuaCs the client game screen is exposed as Game.GameScreen.
-- GameMain.GameScreen is not available in this client Lua context on the user's setup.
local function getCamera()
    local ok, camera = pcall(function()
        return Game.GameScreen.Cam
    end)
    if not ok then
        log("Ошибка доступа к Game.GameScreen.Cam: " .. tostring(camera))
        return nil
    end
    if camera == nil then
        log("Game.GameScreen.Cam вернул nil.")
        return nil
    end
    return camera
end

local function isLocalHost()
    if not CLIENT then return false end
    local ok, isOwner = pcall(function()
        return Game.Client.IsServerOwner
    end)
    return ok and isOwner == true
end

local function toggleFreecam(keyName)
    if not isLocalHost() then
        if not warnedNotHost then
            local ownerValue = "unavailable"
            pcall(function() ownerValue = tostring(Game.Client.IsServerOwner) end)
            log("Клавиша распознана (" .. tostring(keyName) .. "), но Game.Client.IsServerOwner не подтверждает хоста (" .. ownerValue .. "). Камера не изменена.")
            warnedNotHost = true
        end
        return
    end

    local camera = getCamera()
    if camera == nil then
        log("Клавиша распознана, но объект камеры недоступен; персонаж не отключён.")
        return
    end

    local ok, err = pcall(function()
        if not enabled then
            local character = Character.Controlled
            if character == nil then
                log("Клавиша распознана, но Character.Controlled уже nil; персонажа для возврата сохранить нельзя.")
                return
            end
            savedCharacter = character
            Character.Controlled = nil
            camera.TargetPos = Vector2.Zero
            enabled = true
            log("Переключение ВКЛ выполнено по " .. tostring(keyName) .. ". Проверь, двигается ли камера.")
        else
            if savedCharacter ~= nil then
                local valid = true
                pcall(function()
                    if savedCharacter.Removed or savedCharacter.IsDead then valid = false end
                end)
                if valid then Character.Controlled = savedCharacter end
            end
            savedCharacter = nil
            enabled = false
            log("Переключение ВЫКЛ выполнено по " .. tostring(keyName) .. ".")
        end
    end)
    if not ok then log("Ошибка переключения: " .. tostring(err)) end
end

local function hit(key)
    if key == nil then return false end
    local ok, result = pcall(function() return PlayerInput.KeyHit(key) end)
    return ok and result == true
end

Hook.Add("keyUpdate", "HostFreecam.KeyUpdate", function(deltaTime)
    if not CLIENT then return end
    if not keyHookSeen then
        keyHookSeen = true
        log("Хук keyUpdate работает на клиенте; проверяю клавишу \\")
    end

    local candidates = {
        { name = "OemBackslash", key = Keys.OemBackslash },
        { name = "OemPipe", key = Keys.OemPipe }
    }
    for _, candidate in ipairs(candidates) do
        if hit(candidate.key) then
            if lastKeyLog ~= candidate.name then
                lastKeyLog = candidate.name
                toggleFreecam(candidate.name)
            end
            return
        end
    end
    lastKeyLog = nil
end)

log("Загружен v0.5. Проверка хоста: Game.Client.IsServerOwner; камера: Game.GameScreen.Cam. Без enablecheats и сетевых команд.")
