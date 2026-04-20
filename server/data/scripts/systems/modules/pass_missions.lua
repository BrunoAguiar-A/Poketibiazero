-- Sistema de Missões do Pass
-- Missões diárias e semanais que dão XP para subir de nível no Pass

PASS_MISSIONS = {
    -- Missões Diárias (resetam todo dia)
    DAILY = {
        {
            id = 1,
            name = "Capturar Pokémons",
            desc = "Capture 10 Pokémons selvagens",
            lookType = 69,  -- Bellsprout
            size = "32 32",
            position = {x = 0, y = 0},
            max = 10,
            stars = 1,  -- 10 XP
            storage = 9270001,
            type = "capture"
        },
        {
            id = 2,
            name = "Pescar Pokémons",
            desc = "Pesque 15 Pokémons",
            lookType = 129,  -- Magikarp
            size = "32 32",
            position = {x = 0, y = 0},
            max = 15,
            stars = 1,
            storage = 9270002,
            type = "fishing"
        },
        {
            id = 3,
            name = "Coletar Madeira",
            desc = "Corte 20 árvores",
            lookType = 2826,  -- Tree
            size = "32 32",
            position = {x = 0, y = 0},
            max = 20,
            stars = 1,
            storage = 9270003,
            type = "wood"
        },
        {
            id = 4,
            name = "Minerar",
            desc = "Minere 15 pedras",
            lookType = 2827,  -- Rock
            size = "32 32",
            position = {x = 0, y = 0},
            max = 15,
            stars = 1,
            storage = 9270004,
            type = "mining"
        },
        {
            id = 5,
            name = "Derrotar Pokémons",
            desc = "Derrote 25 Pokémons selvagens",
            lookType = 6,  -- Charizard
            size = "48 48",
            position = {x = 0, y = 0},
            max = 25,
            stars = 2,  -- 20 XP
            storage = 9270005,
            type = "defeat"
        },
    },
    
    -- Missões Semanais (resetam toda semana)
    WEEKLY = {
        {
            id = 101,
            name = "Mestre Capturador",
            desc = "Capture 100 Pokémons diferentes",
            lookType = 150,  -- Mewtwo
            size = "48 48",
            position = {x = 0, y = 0},
            max = 100,
            stars = 5,  -- 50 XP
            storage = 9270101,
            type = "capture"
        },
        {
            id = 102,
            name = "Pescador Experiente",
            desc = "Pesque 200 Pokémons",
            lookType = 130,  -- Gyarados
            size = "48 48",
            position = {x = 0, y = 0},
            max = 200,
            stars = 5,
            storage = 9270102,
            type = "fishing"
        },
        {
            id = 103,
            name = "Lenhador Profissional",
            desc = "Corte 300 árvores",
            lookType = 2826,
            size = "32 32",
            position = {x = 0, y = 0},
            max = 300,
            stars = 4,  -- 40 XP
            storage = 9270103,
            type = "wood"
        },
        {
            id = 104,
            name = "Minerador Expert",
            desc = "Minere 250 pedras",
            lookType = 2827,
            size = "32 32",
            position = {x = 0, y = 0},
            max = 250,
            stars = 4,
            storage = 9270104,
            type = "mining"
        },
        {
            id = 105,
            name = "Caçador Lendário",
            desc = "Derrote 500 Pokémons",
            lookType = 6,
            size = "48 48",
            position = {x = 0, y = 0},
            max = 500,
            stars = 10,  -- 100 XP (1 nível completo!)
            storage = 9270105,
            type = "defeat"
        },
    }
}

-- Função para atualizar progresso de missão
function Player:updatePassMission(missionType, amount)
    amount = amount or 1
    local missionCompleted = false
    
    -- Buscar nas missões diárias
    for _, mission in ipairs(PASS_MISSIONS.DAILY) do
        if mission.type == missionType then
            local progress = math.max(0, self:getStorageValue(mission.storage))
            local newProgress = math.min(progress + amount, mission.max)
            self:setStorageValue(mission.storage, newProgress)
            
            -- Notificar progresso
            self:sendTextMessage(MESSAGE_STATUS_SMALL, 
                mission.name .. ": " .. newProgress .. "/" .. mission.max)
            
            -- Se completou a missão
            if newProgress >= mission.max and progress < mission.max then
                self:addPassXP(mission.stars * 10)
                self:sendTextMessage(MESSAGE_EVENT_ADVANCE, 
                    "Missão Completa: " .. mission.name .. " (+" .. (mission.stars * 10) .. " XP)")
                missionCompleted = true
            end
        end
    end
    
    -- Buscar nas missões semanais
    for _, mission in ipairs(PASS_MISSIONS.WEEKLY) do
        if mission.type == missionType then
            local progress = math.max(0, self:getStorageValue(mission.storage))
            local newProgress = math.min(progress + amount, mission.max)
            self:setStorageValue(mission.storage, newProgress)
            
            if newProgress >= mission.max and progress < mission.max then
                self:addPassXP(mission.stars * 10)
                self:sendTextMessage(MESSAGE_EVENT_ADVANCE, 
                    "Missão Semanal Completa: " .. mission.name .. " (+" .. (mission.stars * 10) .. " XP)")
                missionCompleted = true
            end
        end
    end
    
    -- Reenviar dados do Pass para atualizar a UI
    if missionCompleted then
        addEvent(function()
            if self then
                self:sendPassData()
            end
        end, 100)
    end
end

-- Adicionar XP ao Pass
function Player:addPassXP(amount)
    local currentXP = math.max(0, self:getStorageValue(9270000))  -- Storage de XP
    local newXP = currentXP + amount
    
    self:setStorageValue(9270000, newXP)
    
    -- Verificar se subiu de nível (cada 100 XP = 1 nível)
    local oldLevel = math.floor(currentXP / 100)
    local newLevel = math.floor(newXP / 100)
    
    if newLevel > oldLevel then
        self:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Pass Level UP! Você está no nível " .. newLevel)
        -- Aqui pode adicionar efeitos visuais, broadcast, etc
    end
end

-- Resetar missões diárias (chamar todo dia às 00:00)
function resetDailyMissions()
    for _, mission in ipairs(PASS_MISSIONS.DAILY) do
        db.query("UPDATE player_storage SET value = 0 WHERE key = " .. mission.storage)
    end
    -- print("[PASS] Missões diárias resetadas!")
end

-- Resetar missões semanais (chamar toda segunda-feira às 00:00)
function resetWeeklyMissions()
    for _, mission in ipairs(PASS_MISSIONS.WEEKLY) do
        db.query("UPDATE player_storage SET value = 0 WHERE key = " .. mission.storage)
    end
    -- print("[PASS] Missões semanais resetadas!")
end

-- Enviar missões para o cliente
function Player:sendPassMissions()
    -- Implementar envio via opcode 20 para o cliente mostrar as missões
    local missionsData = {}
    
    -- Adicionar missões diárias
    for _, mission in ipairs(PASS_MISSIONS.DAILY) do
        local progress = math.max(0, self:getStorageValue(mission.storage))
        table.insert(missionsData, {
            id = mission.id,
            name = mission.name,
            desc = mission.desc,
            lookType = mission.lookType,
            size = mission.size,
            position = mission.position,
            progress = progress,
            max = mission.max,
            stars = mission.stars
        })
    end
    
    -- Adicionar missões semanais
    for _, mission in ipairs(PASS_MISSIONS.WEEKLY) do
        local progress = math.max(0, self:getStorageValue(mission.storage))
        table.insert(missionsData, {
            id = mission.id,
            name = mission.name,
            desc = mission.desc,
            lookType = mission.lookType,
            size = mission.size,
            position = mission.position,
            progress = progress,
            max = mission.max,
            stars = mission.stars
        })
    end
    
    -- Enviar para cliente (você precisa implementar o protocolo)
    -- print("[PASS] Enviando " .. #missionsData .. " missões para " .. self:getName())
    return missionsData
end

-- print("[PASS Missions] Sistema de missões carregado!")
-- print("[PASS Missions] " .. #PASS_MISSIONS.DAILY .. " missões diárias")
-- print("[PASS Missions] " .. #PASS_MISSIONS.WEEKLY .. " missões semanais")

