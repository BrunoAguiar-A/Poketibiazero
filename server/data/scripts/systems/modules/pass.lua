PASS = {
    ITEM_FREE = 1,
    ITEM_PREMIUM = 2,
}

-- Stones IDs
local STONES = {
    FIRE = 26728,
    WATER = 26736,
    LEAF = 26731,
    THUNDER = 26734,
    ICE = 26730,
    ROCK = 26733,
    VENOM = 26735,
    PUNCH = 26732,
    CRYSTAL = 26725,
    DARKNESS = 26726,
    ANCIENT = 26749,
    BOOST = 26723,
}

-- Money
local CRYSTAL_COIN = 2160  -- 1 = 10k gold, 100 = 1kk gold

-- Gerar 100 níveis de recompensas
PASS.ITEMS = {}

for level = 1, 100 do
    PASS.ITEMS[level] = {}
    
    -- Calcular recompensas baseado no nível
    local baseCoins = math.floor(level / 2) + 5  -- 5-55 coins
    local premiumCoins = math.floor(level / 1.5) + 10  -- 10-76 coins
    
    -- Escolher stone baseada no nível
    local stoneList = {STONES.FIRE, STONES.WATER, STONES.LEAF, STONES.THUNDER}
    if level > 25 then
        table.insert(stoneList, STONES.ICE)
        table.insert(stoneList, STONES.ROCK)
    end
    if level > 50 then
        table.insert(stoneList, STONES.VENOM)
        table.insert(stoneList, STONES.PUNCH)
        table.insert(stoneList, STONES.CRYSTAL)
    end
    if level > 75 then
        table.insert(stoneList, STONES.DARKNESS)
        table.insert(stoneList, STONES.ANCIENT)
        table.insert(stoneList, STONES.BOOST)
    end
    
    local stoneId = stoneList[((level - 1) % #stoneList) + 1]
    local stoneCount = math.floor(level / 10) + 1  -- 1-11 stones
    
    -- FREE rewards (dinheiro + stone)
    if level % 2 == 1 then  -- Níveis ímpares: dinheiro
        PASS.ITEMS[level][PASS.ITEM_FREE] = {
            itemId = CRYSTAL_COIN,
            count = baseCoins,
        }
    else  -- Níveis pares: stones
        PASS.ITEMS[level][PASS.ITEM_FREE] = {
            itemId = stoneId,
            count = stoneCount,
        }
    end
    
    -- PREMIUM rewards (mais dinheiro + mais stones)
    if level % 2 == 1 then  -- Níveis ímpares: mais dinheiro
        PASS.ITEMS[level][PASS.ITEM_PREMIUM] = {
            itemId = CRYSTAL_COIN,
            count = premiumCoins,
        }
    else  -- Níveis pares: mais stones
        PASS.ITEMS[level][PASS.ITEM_PREMIUM] = {
            itemId = stoneId,
            count = stoneCount * 2,
        }
    end
    
    -- Bônus especiais em níveis múltiplos de 10
    if level % 10 == 0 then
        PASS.ITEMS[level][PASS.ITEM_FREE] = {
            itemId = CRYSTAL_COIN,
            count = 100,  -- 1kk gold
        }
        PASS.ITEMS[level][PASS.ITEM_PREMIUM] = {
            itemId = CRYSTAL_COIN,
            count = 150,  -- 1.5kk gold
        }
    end
    
    -- Mega bônus no nível 100
    if level == 100 then
        PASS.ITEMS[level][PASS.ITEM_FREE] = {
            itemId = CRYSTAL_COIN,
            count = 500,  -- 5kk gold
        }
        PASS.ITEMS[level][PASS.ITEM_PREMIUM] = {
            itemId = CRYSTAL_COIN,
            count = 1000,  -- 10kk gold
        }
    end
end

CONSTANT_PASS = {
    callbackId = 0x1,
    rewardFree = 9250000,
    rewardPremium = 9260000,
    missionsStates = 9270000
}

function Player.hasCollectedPassReward(self, level, passItemType)
    local stoId = passItemType == PASS.ITEM_FREE and CONSTANT_PASS.rewardFree or passItemType == PASS.ITEM_PREMIUM and CONSTANT_PASS.rewardPremium
    local value = math.max(0, self:getStorageValue(stoId))
    if value < 1 then
        return false
    end
    return true
end

function NetworkMessage:sendPassItems(items)
    self:addU16(#items)
    for id, levelItems in ipairs(items) do
        for passItemType, item in pairs(levelItems) do
            local itemType = ItemType(item.itemId)
            self:addByte(passItemType)
            self:addString(itemType:getName())
            
            -- Descrição customizada com quantidade
            local desc = itemType:getDescription()
            if item.count and item.count > 1 then
                desc = desc .. " (x" .. item.count .. ")"
            end
            self:addString(desc)
            
            self:addU16(itemType:getClientId())
        end
    end
end

function NetworkMessage:setCallbackId(id)
    self:addByte(0xFF)
    self:addByte(id)
end

function NetworkMessage:finish(player)
	self:sendToPlayer(player)
	self:delete()
end

function Player.sendPassData(self)
    -- Enviar info básica do Pass
    local hasPremium = self:getStorageValue(CONSTANT_PASS.rewardPremium) > 0
    local passXP = math.max(0, self:getStorageValue(9270000))
    local passLevel = math.floor(passXP / 100)
    local passStars = math.floor((passXP % 100) / 10)  -- 0-9 stars
    local passDaysLeft = 30  -- Calcular dias restantes da temporada
    local passTime = 0  -- Tempo em segundos
    
    -- Formato esperado pelo cliente: {{valores...}, índice, "tipo"}
    local passData = string.format([[{{%s, %d, %d, %d, %d, %d}, 0, 'Pass'}]], 
        tostring(hasPremium), passLevel, 100, passStars, passDaysLeft, passTime)
    
    -- print("[PASS] Enviando Pass: " .. passData)
    self:sendExtendedOpcode(20, passData)
    
    -- Enviar itens do Pass
    self:sendPassItems()
    
    -- Enviar missões
    self:sendPassMissionsData()
end

function Player:sendPassItems()
    -- Formato: {{true, {{item1,item2,level}, {item1,item2,level}, ...}, {}}, 0, 'Items'}
    local buffer = "{{true,{"
    
    for level = 1, 100 do
        if PASS.ITEMS[level] then
            buffer = buffer .. "{"
            
            -- FREE item (índice 1)
            local freeItem = PASS.ITEMS[level][PASS.ITEM_FREE]
            local freeType = ItemType(freeItem.itemId)
            buffer = buffer .. "{style='UIPassItem',name='" .. freeType:getName():gsub("'", "") .. "',item={id=" .. freeItem.itemId .. ",clientId=" .. freeType:getClientId() .. ",count=" .. (freeItem.count or 1) .. "}},"
            
            -- PREMIUM item (índice 2)
            local premItem = PASS.ITEMS[level][PASS.ITEM_PREMIUM]
            local premType = ItemType(premItem.itemId)
            buffer = buffer .. "{style='UIPassItem',name='" .. premType:getName():gsub("'", "") .. "',item={id=" .. premItem.itemId .. ",clientId=" .. premType:getClientId() .. ",count=" .. (premItem.count or 1) .. "}},"
            
            -- Nível (índice 3)
            buffer = buffer .. level
            
            buffer = buffer .. "},"
        end
    end
    
    buffer = buffer .. "},"
    
    -- Adicionar lista de recompensas coletadas
    -- collecteds = {[1]={níveis FREE coletados}, [2]={níveis PREMIUM coletados}}
    buffer = buffer .. "{"
    
    -- FREE coletados
    buffer = buffer .. "{"
    for level = 1, 100 do
        local stoIdFree = 9250000 + level
        if self:getStorageValue(stoIdFree) > 0 then
            buffer = buffer .. level .. ","
        end
    end
    buffer = buffer .. "},"
    
    -- PREMIUM coletados
    buffer = buffer .. "{"
    for level = 1, 100 do
        local stoIdPremium = 9260000 + level
        if self:getStorageValue(stoIdPremium) > 0 then
            buffer = buffer .. level .. ","
        end
    end
    buffer = buffer .. "}"
    
    buffer = buffer .. "}},0,'Items'}"
    
    -- print("[PASS] Enviando 100 níveis com collecteds")
    self:sendExtendedOpcode(20, buffer)
end

function Player:sendPassMissionsData()
    -- Formato: {{true, {mission1, mission2, ...}}, 0, 'Missions'}
    local buffer = "{{true,{"
    
    -- Missão dummy
    buffer = buffer .. "{progress=0,max=0,stars=0,lookType=0,size='32 32',position={x=0,y=0},desc=''},"
    
    -- Adicionar missões reais
    if PASS_MISSIONS then
        for _, mission in ipairs(PASS_MISSIONS.DAILY) do
            local progress = math.max(0, self:getStorageValue(mission.storage))
            buffer = buffer .. "{progress=" .. progress .. ",max=" .. mission.max .. ",stars=" .. mission.stars .. ",lookType=" .. mission.lookType .. ",size='" .. mission.size .. "',position={x=" .. mission.position.x .. ",y=" .. mission.position.y .. "},desc='" .. mission.desc:gsub("'", "") .. "'},"
        end
        
        for _, mission in ipairs(PASS_MISSIONS.WEEKLY) do
            local progress = math.max(0, self:getStorageValue(mission.storage))
            buffer = buffer .. "{progress=" .. progress .. ",max=" .. mission.max .. ",stars=" .. mission.stars .. ",lookType=" .. mission.lookType .. ",size='" .. mission.size .. "',position={x=" .. mission.position.x .. ",y=" .. mission.position.y .. "},desc='" .. mission.desc:gsub("'", "") .. "'},"
        end
    end
    
    buffer = buffer .. "}},0,'Missions'}"
    
    -- print("[PASS] Enviando missões")
    self:sendExtendedOpcode(20, buffer)
end

-- Função para coletar recompensa
function Player:collectPassReward(level, passItemType)
    if level < 1 or level > 100 then
        return false, "Nível inválido"
    end
    
    if not PASS.ITEMS[level] or not PASS.ITEMS[level][passItemType] then
        return false, "Recompensa não encontrada"
    end
    
    if self:hasCollectedPassReward(level, passItemType) then
        return false, "Você já coletou essa recompensa"
    end
    
    local reward = PASS.ITEMS[level][passItemType]
    local item = self:addItem(reward.itemId, reward.count or 1)
    
    if not item then
        return false, "Inventário cheio"
    end
    
    -- Marcar como coletado
    local stoId = passItemType == PASS.ITEM_FREE and CONSTANT_PASS.rewardFree or CONSTANT_PASS.rewardPremium
    self:setStorageValue(stoId, 1)
    
    return true, "Recompensa coletada!"
end

-- Callback handlers são processados automaticamente pelo sistema
-- A lógica de coleta está em extendedopcode.lua

-- print("[PASS System] Sistema de Pass carregado com 100 níveis!")
-- print("[PASS System] FREE: Dinheiro + Stones | PREMIUM: Mais recompensas!")
