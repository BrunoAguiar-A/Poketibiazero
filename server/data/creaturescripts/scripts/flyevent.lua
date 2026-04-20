-- Directional water splash effects (reused from surf as fallback for fly-over-water)
local FLY_WATER_SPLASH = {
    [DIRECTION_NORTH] = {x = 0, y = 1, effect = 31},
    [DIRECTION_EAST]  = {x = -1, y = 0, effect = 50},
    [DIRECTION_SOUTH] = {x = 0, y = -1, effect = 31},
    [DIRECTION_WEST]  = {x = 1, y = 0, effect = 52},
}

function onMove(creature, toPosition, fromPosition)
	local player = Player(creature:getId())

	if player:getStorageValue(235760) >= 1 or player:getStorageValue(235165) >= 1 then
		player:setStorageValue(235760, -1) -- reseta storage da mineracao.
		player:setStorageValue(235165, -1) -- reseta storage da coleta.
		player:removeCondition(CONDITION_OUTFIT)
	end

    if player:isOnFly() then
        toPosition:createFlyFloor()

        -- Water splash effect when flying over water at ground level
        -- No fly-specific water effect exists; reusing surf splash as visual fallback
        local fromTile = Tile(fromPosition)
        if fromTile and fromTile:getGround() and isInArray(waterIds, fromTile:getGround():getId()) then
            local direction = creature:getDirection()
            local splash = FLY_WATER_SPLASH[direction]
            if splash then
                local effectPos = Position(fromPosition.x + splash.x, fromPosition.y + splash.y, fromPosition.z)
                doSendMagicEffect(effectPos, splash.effect)
            else
                doSendMagicEffect(fromPosition, 31)
            end
        end
    end
    return true
end
