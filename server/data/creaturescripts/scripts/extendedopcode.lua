local OPCODE_DONATIONGOALS = 8
local OPCODE_REQUEST_MANAGER = 1

function onExtendedOpcode(player, opcode, buffer)

	if opcode == OPCODE_MARKET then
		player:handleMarket(buffer)
		return
	end

	if opcode == OPCODE_TASKS_KILL then
		player:handleTasksKill(buffer)
		return
	end

	if opcode == EXTENDED_OPCODE_CONTRACT then
		player:handleContract(buffer)
		return
	end

	if opcode == OPCODE_REQUEST_MANAGER then
		player:requestModule(buffer)
		return
	end

	if opcode == OPCODE_BANK then
		player:handleBank(buffer)
		return
	end

	if opcode == OPCODE_REDEEM_CODES then
		player:handleRedeemCodes(buffer)
		return
	end

	if opcode == OPCODE_NEW_SHOP then
		player:handleShop(buffer)
		return
	end
	
	-- Opcode 20 = Pass System
	if opcode == 20 then
		-- Comprar Passe Elite (30 diamonds)
		if buffer == "BuyPass35" then
			-- print("[PASS] Tentando comprar Passe Elite...")
			
			-- Verificar se já tem o passe
			if player:getStorageValue(9260000) > 0 then
				player:sendTextMessage(MESSAGE_STATUS_WARNING, "Você já possui o Passe Elite!")
				return
			end
			
			-- Verificar se tem 30 diamonds
			if player:getItemCount(27635) < 30 then
				player:sendTextMessage(MESSAGE_STATUS_WARNING, "Você precisa de 30 diamonds!")
				player:sendExtendedOpcode(20, "{{}, 0, 'NoDiamondsBuyPass'}")
				return
			end
			
			-- Remover diamonds
			if not player:removeItem(27635, 30) then
				player:sendTextMessage(MESSAGE_STATUS_WARNING, "Erro ao processar pagamento!")
				return
			end
			
			-- Ativar Passe Elite
			player:setStorageValue(9260000, 1)
			
			player:sendTextMessage(MESSAGE_EVENT_ADVANCE, 
				"Parabéns! Você comprou o Passe Elite! Agora pode coletar todas as recompensas!")
			
			-- Reenviar dados do Pass para atualizar UI
			player:sendPassData()
			
			-- print("[PASS] Passe Elite vendido para " .. player:getName())
			return
		end
		
		-- Processar ação do Pass
		if buffer:find("#Collect#") then
			local parts = buffer:split("#")
			local level = tonumber(parts[1])
			local passType = tonumber(parts[3])
			
			-- print("[PASS] Coletando recompensa: level=" .. level .. ", type=" .. passType)
			
			-- Verificar se pode coletar
			local passXP = math.max(0, player:getStorageValue(9270000))
			local passLevel = math.floor(passXP / 100)
			
			if level > passLevel then
				player:sendTextMessage(MESSAGE_STATUS_WARNING, "Você ainda não alcançou este nível!")
				return
			end
			
			-- Storage específico por nível
			local stoId = (passType == 1) and 9250000 or 9260000
			local specificStoId = stoId + level
			
			if player:getStorageValue(specificStoId) > 0 then
				player:sendTextMessage(MESSAGE_STATUS_WARNING, "Você já coletou esta recompensa!")
				return
			end
			
			-- Verificar se tem Premium (se for recompensa premium)
			if passType == 2 then
				if player:getStorageValue(9260000) <= 0 then
					player:sendTextMessage(MESSAGE_STATUS_WARNING, "Você precisa do Passe Elite!")
					return
				end
			end
			
			-- Coletar recompensa
			if PASS.ITEMS[level] and PASS.ITEMS[level][passType] then
				local reward = PASS.ITEMS[level][passType]
				local item = player:addItem(reward.itemId, reward.count or 1)
				
				if not item then
					player:sendTextMessage(MESSAGE_STATUS_WARNING, "Inventário cheio!")
					return
				end
				
				-- Marcar como coletado
				player:setStorageValue(specificStoId, 1)
				
				local itemType = ItemType(reward.itemId)
				player:sendTextMessage(MESSAGE_EVENT_ADVANCE, 
					"Recompensa coletada: " .. (reward.count or 1) .. "x " .. itemType:getName() .. "!")
				
				-- Enviar atualização para o cliente
				local updateMsg = "{{" .. level .. ", " .. passType .. "}, 0, 'UpdateReward'}"
				player:sendExtendedOpcode(20, updateMsg)
				
				-- print("[PASS] Recompensa entregue!")
			end
		end
		return
	end

    if opcode == 53 then
        player:handlePokebar(buffer)
      	return
    end
	
	if opcode == 57 then
		-- Toggle autoloot ON/OFF
		if buffer == "ligar" then
			player:setStorageValue(AUTOLOOT_ALL_ENABLED, 1)
			player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "Auto-Loot ATIVADO - Todos os itens serão coletados!")
		else
			player:setStorageValue(AUTOLOOT_ALL_ENABLED, -1)
			player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "Auto-Loot DESATIVADO")
		end
		return
	end
	
    if opcode == POKEDEX_OPCODE then
        player:handlePokedex(buffer)
        return
    end

    if opcode == OPCODE_DONATIONGOALS then
        if buffer == "doCollectPersonalReward1" then
            doCollectGoalReward(player, 1)
        elseif buffer == "doCollectPersonalReward2" then
            doCollectGoalReward(player, 2)
        elseif buffer == "doCollectPersonalReward3" then
            doCollectGoalReward(player, 3)
        elseif buffer == "doCollectGlobalReward" then
            doCollectGlobalReward(player)
        end
		return
    end

	if opcode == 78 then
		local data = json.decode(buffer)
		local type = data.type
		
		if type == "check" then
			if #player:getSummons() == 0 then
				doPlayerPopupFYI(player, "Voc� n�o possui o pokemon ativo.")
				return true
			end
			local ball = player:getUsingBall()
			if not ball then return end
			if ball:getSpecialAttribute("shader") then
				local shaderId = tonumber(data.shader)
				local shader = SHADERSLIST[shaderId]
				if shader then
					ball:setSpecialAttribute("shader", shaderId)
					doPlayerPopupFYI(player, "Particle aura alterado.")
					player:modifierPokemon(0, 0, SHADER_NAMES_TO_IDS[shader], -1)
				end
			else
				doPlayerPopupFYI(player, "Este pok�mon n�o possui particle aura.")
			end
		end
		return true
	end

	if opcode == CODE_GAMESTORE then
		if not GAME_STORE then
			gameStoreInitialize()
			addEvent(refreshPlayersPoints, 10 * 1000)
		end
	
		local status, json_data =
			pcall(
			function()
				return json.decode(buffer)
			end
		)
		if not status then
			return
		end
	
		local action = json_data.action
		local data = json_data.data
		if not action or not data then
			return
		end
	
		if action == "fetch" then
			gameStoreFetch(player)
		elseif action == "purchase" then
			gameStorePurchase(player, data)
		elseif action == "gift" then
			gameStorePurchaseGift(player, data)
		end
	end
	
	-- Opcode 100 = Protagonist Mode (ativar/desativar)
	if opcode == 100 then
		if buffer == "protagonist_on" then
			print("[PROTAGONIST] " .. player:getName() .. " ativando modo...")
			player:activateProtagonistMode()
		elseif buffer == "protagonist_off" then
			print("[PROTAGONIST] " .. player:getName() .. " desativando modo...")
			player:deactivateProtagonistMode()
		end
		return
	end
	
	-- Opcode 106 = Map ACK (cliente confirmou que processou MapDescription)
	if opcode == 106 then
		if buffer == "protag_map_ack" then
			player:setProtagonistWaitingForMapAck(false)
			print("[PROTAGONIST] ✅ Cliente confirmou processamento do mapa (ACK recebido)")
		end
		return
	end
	
	-- Opcode 2 = Daily Rewards
	if opcode == 2 then
		local status, data = pcall(function() return json.decode(buffer) end)
		if not status then
			return
		end
		
		if data.action == "refresh" then
			-- Enviar dados de recompensas com clientId convertido do itemId
			local rewardsDataServer = {
				[1] = {itemId = 26731, count = 1, name = "Leaf Stone"},
				[2] = {itemId = 26728, count = 1, name = "Fire Stone"},
				[3] = {itemId = 26736, count = 1, name = "Water Stone"},
				[4] = {itemId = 26734, count = 1, name = "Thunder Stone"},
				[5] = {itemId = 2152, count = 5, name = "Hundred Dollar"},
				[6] = {itemId = 27643, count = 3, name = "Great Potion"},
				[7] = {itemId = 26748, count = 1, name = "Sun Stone"},
				[8] = {itemId = 38787, count = 2, name = "Rare Candy"},
				[9] = {itemId = 2160, count = 1, name = "Ten Thousand Dollar"},
				[10] = {itemId = 27641, count = 2, name = "Ultra Potion"},
				[11] = {itemId = 26731, count = 2, name = "Leaf Stone"},
				[12] = {itemId = 27645, count = 3, name = "Revive"},
				[13] = {itemId = 2152, count = 10, name = "Hundred Dollar"},
				[14] = {itemId = 26728, count = 2, name = "Fire Stone"},
				[15] = {itemId = 38787, count = 3, name = "Rare Candy"},
				[16] = {itemId = 26736, count = 2, name = "Water Stone"},
				[17] = {itemId = 2160, count = 2, name = "Ten Thousand Dollar"},
				[18] = {itemId = 27647, count = 5, name = "Hyper Potion"},
				[19] = {itemId = 26734, count = 2, name = "Thunder Stone"},
				[20] = {itemId = 38787, count = 5, name = "Rare Candy"},
				[21] = {itemId = 2160, count = 10, name = "Ten Thousand Dollar"}
			}
			
			-- Converter itemId para clientId
			local rewardsData = {}
			for day, reward in pairs(rewardsDataServer) do
				local itemType = ItemType(reward.itemId)
				local clientId = itemType and itemType:getClientId() or reward.itemId
				rewardsData[day] = {
					clientId = clientId,
					count = reward.count,
					name = reward.name
				}
			end
			
			local currentDay = math.max(1, player:getStorageValue(STORAGE_DAILY_REWARDS_DAY) or 1)
			local lastClaimTime = player:getStorageValue(STORAGE_DAILY_REWARDS_LAST_CLAIM) or 0
			local now = os.time()
			local canClaim = false
			local nextClaim = 0
			
			-- Verificar se pode coletar hoje
			if lastClaimTime == 0 or (now - lastClaimTime) >= 86400 then
				canClaim = true
				nextClaim = now + 86400
			else
				nextClaim = lastClaimTime + 86400
			end
			
			local response = {
				rewards = rewardsData,
				currentDay = currentDay,
				canClaim = canClaim,
				nextClaim = nextClaim,
				autoShow = false
			}
			
			player:sendExtendedOpcode(2, json.encode(response))
			
		elseif data.action == "claim" then
			-- Coletar recompensa
			local currentDay = math.max(1, player:getStorageValue(STORAGE_DAILY_REWARDS_DAY) or 1)
			local lastClaimTime = player:getStorageValue(STORAGE_DAILY_REWARDS_LAST_CLAIM) or 0
			local now = os.time()
			
			-- Verificar se pode coletar
			if lastClaimTime > 0 and (now - lastClaimTime) < 86400 then
				player:sendTextMessage(MESSAGE_STATUS_WARNING, "Você já coletou a recompensa de hoje!")
				return
			end
			
			-- Itens de recompensa (DEVE SER IGUAL AO CLIENTE!)
			local rewardsData = {
				[1] = {itemId = 26731, count = 1},
				[2] = {itemId = 26728, count = 1},
				[3] = {itemId = 26736, count = 1},
				[4] = {itemId = 26734, count = 1},
				[5] = {itemId = 2152, count = 5},
				[6] = {itemId = 27643, count = 3},
				[7] = {itemId = 26748, count = 1},
				[8] = {itemId = 38787, count = 2},
				[9] = {itemId = 2160, count = 1},
				[10] = {itemId = 27641, count = 2},
				[11] = {itemId = 26731, count = 2},
				[12] = {itemId = 27645, count = 3},
				[13] = {itemId = 2152, count = 10},
				[14] = {itemId = 26728, count = 2},
				[15] = {itemId = 38787, count = 3},
				[16] = {itemId = 26736, count = 2},
				[17] = {itemId = 2160, count = 2},
				[18] = {itemId = 27647, count = 5},
				[19] = {itemId = 26734, count = 2},
				[20] = {itemId = 38787, count = 5},
				[21] = {itemId = 2160, count = 10}
			}
			
			local reward = rewardsData[currentDay]
			if not reward then
				player:sendTextMessage(MESSAGE_STATUS_WARNING, "Recompensa não encontrada!")
				return
			end
			
			-- Adicionar item ao jogador
			local item = Game.createItem(reward.itemId, reward.count)
			if not item or not player:addItemEx(item) then
				player:sendTextMessage(MESSAGE_STATUS_WARNING, "Seu inventário está cheio!")
				return
			end
			
			-- Atualizar storage
			local newDay = currentDay + 1
			if newDay > 21 then
				newDay = 1
			end
			
			player:setStorageValue(STORAGE_DAILY_REWARDS_DAY, newDay)
			player:setStorageValue(STORAGE_DAILY_REWARDS_LAST_CLAIM, now)
			
			player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Recompensa coletada com sucesso!")
			
			-- Enviar dados atualizados com clientId convertido
			local rewardsDataServer = {
				[1] = {itemId = 26731, count = 1, name = "Leaf Stone"},
				[2] = {itemId = 26728, count = 1, name = "Fire Stone"},
				[3] = {itemId = 26736, count = 1, name = "Water Stone"},
				[4] = {itemId = 26734, count = 1, name = "Thunder Stone"},
				[5] = {itemId = 2152, count = 5, name = "Hundred Dollar"},
				[6] = {itemId = 27643, count = 3, name = "Great Potion"},
				[7] = {itemId = 26748, count = 1, name = "Sun Stone"},
				[8] = {itemId = 38787, count = 2, name = "Rare Candy"},
				[9] = {itemId = 2160, count = 1, name = "Ten Thousand Dollar"},
				[10] = {itemId = 27641, count = 2, name = "Ultra Potion"},
				[11] = {itemId = 26731, count = 2, name = "Leaf Stone"},
				[12] = {itemId = 27645, count = 3, name = "Revive"},
				[13] = {itemId = 2152, count = 10, name = "Hundred Dollar"},
				[14] = {itemId = 26728, count = 2, name = "Fire Stone"},
				[15] = {itemId = 38787, count = 3, name = "Rare Candy"},
				[16] = {itemId = 26736, count = 2, name = "Water Stone"},
				[17] = {itemId = 2160, count = 2, name = "Ten Thousand Dollar"},
				[18] = {itemId = 27647, count = 5, name = "Hyper Potion"},
				[19] = {itemId = 26734, count = 2, name = "Thunder Stone"},
				[20] = {itemId = 38787, count = 5, name = "Rare Candy"},
				[21] = {itemId = 2160, count = 10, name = "Ten Thousand Dollar"}
			}
			
			-- Converter itemId para clientId
			local rewardsDataResponse = {}
			for day, reward in pairs(rewardsDataServer) do
				local itemType = ItemType(reward.itemId)
				local clientId = itemType and itemType:getClientId() or reward.itemId
				rewardsDataResponse[day] = {
					clientId = clientId,
					count = reward.count,
					name = reward.name
				}
			end
			
			local response = {
				rewards = rewardsDataResponse,
				currentDay = newDay,
				canClaim = false,
				nextClaim = now + 86400,
				autoShow = false
			}
			
			player:sendExtendedOpcode(2, json.encode(response))
		end
		
		return
	end
	
	if opcode == 101 then
		if player:isProtagonistMode() then
			local data = PROTAGONIST_MODE[player:getId()]
			if data and data.pokemon then
				local pokemon = data.pokemon
				
				-- VALIDAÇÃO ULTRA RIGOROSA: verificar pokeball E nome
				local ball = player:getUsingBall()
				if not ball then
					print("[PROTAGONIST] ERRO: Pokeball removida!")
					player:deactivateProtagonistMode()
					return
				end
				
				local pokeName = ball:getSpecialAttribute("pokeName")
				if not pokeName or pokemon:getName():lower() ~= pokeName:lower() then
					print("[PROTAGONIST] ERRO: Pokémon (" .. pokemon:getName() .. ") não corresponde à pokeball (" .. (pokeName or "null") .. ")!")
					player:deactivateProtagonistMode()
					return
				end
				
				-- VALIDAR que é summon do player
				if not pokemon:getMaster() or pokemon:getMaster():getId() ~= player:getId() then
					print("[PROTAGONIST] ERRO: Pokémon não pertence ao player!")
					player:deactivateProtagonistMode()
					return
				end
				
				-- GARANTIR que pokémon não está seguindo ninguém
				if pokemon:getFollowCreature() then
					pokemon:setFollowCreature(nil)
				end
				local dirMap = {
					north = DIRECTION_NORTH,
					east = DIRECTION_EAST,
					south = DIRECTION_SOUTH,
					west = DIRECTION_WEST,
					northeast = DIRECTION_NORTHEAST,
					southeast = DIRECTION_SOUTHEAST,
					southwest = DIRECTION_SOUTHWEST,
					northwest = DIRECTION_NORTHWEST
				}
				local direction = dirMap[buffer:lower()]
				if direction then
					-- Verificar se não está em exhaust (anti-spam)
					local now = os.mtime()
					local lastMove = data.lastMove or 0
					
					-- Delay mínimo de 150ms entre movimentos (evita speed hack)
					if now - lastMove >= 150 then
						-- COLISÃO INTELIGENTE: pokemon:move() considera automaticamente:
						-- ✅ Propriedades da criatura (voar, atravessar água, etc)
						-- ✅ Colisões com outras criaturas
						-- ✅ Bloqueios de terreno específicos para aquele tipo
						-- ✅ Se o tile existe e é válido
						local result = pokemon:move(direction)
						if result then
							data.lastMove = now
						end
						-- Se move() retornar false/nil, o Pokémon não se move (bloqueio válido para aquela criatura)
					end
				end
			end
		end
		return
	end

end