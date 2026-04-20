-- Storages para salvar o outfit original
local STORAGE_LOOKTYPE = 50000
local STORAGE_HEAD     = 50001
local STORAGE_BODY     = 50002
local STORAGE_LEGS     = 50003
local STORAGE_FEET     = 50004

-- Outfit do piso
local OUTFIT_MALE   = 4115
local OUTFIT_FEMALE = 4114

local function clearSavedOutfit(player)
    player:setStorageValue(STORAGE_LOOKTYPE, -1)
    player:setStorageValue(STORAGE_HEAD, -1)
    player:setStorageValue(STORAGE_BODY, -1)
    player:setStorageValue(STORAGE_LEGS, -1)
    player:setStorageValue(STORAGE_FEET, -1)
end

local function isPlayerFlying(player)
    return player:isOnFly() or (storageFly and player:getStorageValue(storageFly) == 1)
end

function onStepIn(creature, item, position, fromPosition)
    if not creature:isPlayer() then
        return true
    end

    local player = creature
    if isPlayerFlying(player) then
        clearSavedOutfit(player)
        return true
    end

    -- Salva o outfit atual apenas se ainda não estiver salvo
    if player:getStorageValue(STORAGE_LOOKTYPE) <= 0 then
        local outfit = player:getOutfit()

        player:setStorageValue(STORAGE_LOOKTYPE, outfit.lookType)
        player:setStorageValue(STORAGE_HEAD, outfit.lookHead)
        player:setStorageValue(STORAGE_BODY, outfit.lookBody)
        player:setStorageValue(STORAGE_LEGS, outfit.lookLegs)
        player:setStorageValue(STORAGE_FEET, outfit.lookFeet)
    end

    local current = player:getOutfit()
    local desiredLookType = player:getSex() == PLAYERSEX_FEMALE and OUTFIT_FEMALE or OUTFIT_MALE

    -- Só aplica se ainda não estiver com o outfit do gelo
    if current.lookType ~= desiredLookType then
        local newOutfit = {
            lookType = desiredLookType,
            lookHead = current.lookHead,
            lookBody = current.lookBody,
            lookLegs = current.lookLegs,
            lookFeet = current.lookFeet
        }
        player:setOutfit(newOutfit)
    end

    return true
end

function onStepOut(creature, item, position, fromPosition)
    if not creature:isPlayer() then
        return true
    end

    local player = creature
    if isPlayerFlying(player) then
        clearSavedOutfit(player)
        return true
    end

    local lookType = player:getStorageValue(STORAGE_LOOKTYPE)
    if lookType <= 0 then
        return true
    end

    local oldOutfit = {
        lookType = lookType,
        lookHead = player:getStorageValue(STORAGE_HEAD),
        lookBody = player:getStorageValue(STORAGE_BODY),
        lookLegs = player:getStorageValue(STORAGE_LEGS),
        lookFeet = player:getStorageValue(STORAGE_FEET)
    }

    -- Só restaura se realmente estiver diferente
    if player:getOutfit().lookType ~= oldOutfit.lookType then
        player:setOutfit(oldOutfit)
    end

    -- Limpa os storages
    clearSavedOutfit(player)

    return true
end
