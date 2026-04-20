function onSay(player, words, param)
    -- CONFIG
    local STORAGE_ACTIVE = 128238
    local STORAGE_DELAY  = 128250
    local DELAY_SECONDS  = 5

    local BIKE_ITEM_ID = 41505

    -- Delay
    local now = os.time()
    local nextUse = player:getStorageValue(STORAGE_DELAY)
    if nextUse > now then
        player:sendCancelMessage(
            string.format("Aguarde %d segundos para usar novamente.", nextUse - now)
        )
        return false
    end

    -- Não está usando bike
    local originalLookType = player:getStorageValue(STORAGE_ACTIVE)
    if originalLookType <= 0 then
        player:sendCancelMessage("Você não está usando uma bike.")
        return false
    end

    -- Restaura outfit
    player:setOutfit({
        lookType   = originalLookType,
        lookHead   = player:getStorageValue(128239),
        lookBody   = player:getStorageValue(128240),
        lookLegs   = player:getStorageValue(128241),
        lookFeet   = player:getStorageValue(128242),
        lookAddons = player:getStorageValue(128243)
    })

    -- Limpa storages
    player:setStorageValue(128238, 0)
    player:setStorageValue(128239, 0)
    player:setStorageValue(128240, 0)
    player:setStorageValue(128241, 0)
    player:setStorageValue(128242, 0)
    player:setStorageValue(128243, 0)

    -- Remove velocidade
    player:removeCondition(CONDITION_HASTE)

    -- Devolve bike
    player:addItem(BIKE_ITEM_ID, 1)

    -- Mensagens
    player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "Você desceu da bike.")

    -- Aplica delay
    player:setStorageValue(STORAGE_DELAY, now + DELAY_SECONDS)

    return false
end
