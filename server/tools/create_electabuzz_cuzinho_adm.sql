INSERT INTO `player_items` (`player_id`, `pid`, `sid`, `itemtype`, `count`, `attributes`)
SELECT
    `p`.`id`,
    102,
    COALESCE(MAX(`pi`.`sid`), 105) + 1,
    26677,
    1,
    0x2e06000000000000000800706f6b654e616d65010a00456c6563746162757a7a0900706f6b65426f6f73740205000000000000000900706f6b654c6576656c0264000000000000000600706f6b65424c020c000000000000000d00706f6b654d61784865616c74680271660000000000000a00706f6b654865616c7468027166000000000000
FROM `players` AS `p`
LEFT JOIN `player_items` AS `pi` ON `pi`.`player_id` = `p`.`id`
WHERE `p`.`name` = 'Cuzinho adm'
GROUP BY `p`.`id`;

UPDATE `players`
SET `pokemons` = CASE
    WHEN `pokemons` IS NULL OR `pokemons` = '' OR `pokemons` = '[]'
        THEN '[{\"name\":\"Electabuzz\",\"boost\":5,\"level\":100,\"looktype\":{\"lookType\":125}}]'
    ELSE CONCAT(
        LEFT(`pokemons`, CHAR_LENGTH(`pokemons`) - 1),
        ',{\"name\":\"Electabuzz\",\"boost\":5,\"level\":100,\"looktype\":{\"lookType\":125}}]'
    )
END
WHERE `name` = 'Cuzinho adm';
