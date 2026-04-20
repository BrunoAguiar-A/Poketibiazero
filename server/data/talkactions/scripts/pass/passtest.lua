-- Comandos de teste para o Pass
function onSay(player, words, param)
    local split = param:split(",")
    
    -- /passmission <tipo>,<quantidade>
    if words == "/passmission" then
        local missionType = split[1]
        local amount = tonumber(split[2]) or 1
        
        player:updatePassMission(missionType, amount)
        player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, 
            "Progresso atualizado: " .. missionType .. " +" .. amount)
        return false
    end
    
    -- /passxp <quantidade>
    if words == "/passxp" then
        local xp = tonumber(param) or 100
        player:addPassXP(xp)
        return false
    end
    
    -- /passlevel - Ver nível atual
    if words == "/passlevel" then
        local xp = math.max(0, player:getStorageValue(9270000))
        local level = math.floor(xp / 100)
        local progress = xp % 100
        
        player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE,
            "Pass Level: " .. level .. " | XP: " .. xp .. " (" .. progress .. "/100)")
        return false
    end
    
    -- /passmissions - Ver todas as missões
    if words == "/passmissions" then
        player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "=== MISSÕES DIÁRIAS ===")
        for _, mission in ipairs(PASS_MISSIONS.DAILY) do
            local progress = math.max(0, player:getStorageValue(mission.storage))
            player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE,
                mission.name .. ": " .. progress .. "/" .. mission.max .. " (+" .. (mission.stars*10) .. " XP)")
        end
        
        player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "=== MISSÕES SEMANAIS ===")
        for _, mission in ipairs(PASS_MISSIONS.WEEKLY) do
            local progress = math.max(0, player:getStorageValue(mission.storage))
            player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE,
                mission.name .. ": " .. progress .. "/" .. mission.max .. " (+" .. (mission.stars*10) .. " XP)")
        end
        return false
    end
    
    return true
end



