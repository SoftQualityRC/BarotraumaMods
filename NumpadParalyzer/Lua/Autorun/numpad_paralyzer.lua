local TAG = "[NumpadParalyzer]"

-- СЕРВЕРНАЯ ЧАСТЬ: управление параличом по персонажам
if SERVER then
    local function ToggleParalysis(targetCharacter)
        if not targetCharacter or targetCharacter.IsDead then return end

        local health = targetCharacter.CharacterHealth
        local paralysisAffliction = health.GetAffliction("paralysis")
        
        -- Если у персонажа уже есть паралич (> 10), снимаем его полностью
        if paralysisAffliction and paralysisAffliction.Strength > 10 then
            paralysisAffliction.Strength = 0
            print(TAG .. " Паралич снят с: " .. targetCharacter.Name)
        else
            -- Иначе накладываем полный паралич (100)
            local pref = AfflictionPrefab.Prefabs["paralysis"]
            if pref then
                health.ApplyAffliction(targetCharacter.AnimController.MainLimb, pref.Instantiate(100))
                print(TAG .. " Паралич наложен на: " .. targetCharacter.Name)
            end
        end
    end

    -- Прием сетевого сообщения от хоста/админа
    Networking.Receive("NumpadParalyzer_Toggle", function(msg, sender)
        -- Проверка прав (разрешено только хосту / админу с правами консоли)
        if not sender.HasPermission(ClientPermissions.ConsoleCommands) then return end

        local targetIndex = msg.ReadInt32()
        
        -- Собираем ТОЛЬКО членов экипажа (игроков и ботов нашей команды)
        local characters = {}
        for character in Character.CharacterList do
            if not character.IsDead and character.IsHuman then
                -- Team1 — это команда игроков/экипажа по умолчанию
                if character.TeamID == CharacterTeamType.Team1 then
                    table.insert(characters, character)
                end
            end
        end
        
        -- Если персонаж под этим номером существует, применяем эффект
        if targetIndex > 0 and targetIndex <= #characters then
            ToggleParalysis(characters[targetIndex])
        end
    end)
end

-- КЛИЕНТСКАЯ ЧАСТЬ: отслеживание нажатий NumPad у хоста/админа
if CLIENT then
    Hook.Add("keyUpdate", "NumpadParalyzer_KeyBind", function()
        for i = 1, 9 do
            local keyName = "NumPad" .. i
            local key = Keys[keyName]
            
            if key and PlayerInput.KeyHit(key) then
                local msg = Networking.Start("NumpadParalyzer_Toggle")
                msg.WriteInt32(i)
                Networking.Send(msg)
            end
        end
    end)
end

print(TAG .. " загружен")