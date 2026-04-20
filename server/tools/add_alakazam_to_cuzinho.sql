UPDATE `players` AS `p`
JOIN `accounts` AS `a` ON `a`.`id` = `p`.`account_id`
SET `p`.`pokemons` = CASE
    WHEN `p`.`pokemons` IS NULL OR `p`.`pokemons` = '' OR `p`.`pokemons` = '[]'
        THEN '[{\"name\":\"alakazam\",\"boost\":0,\"level\":0,\"looktype\":{\"lookType\":65}}]'
    WHEN `p`.`pokemons` LIKE '%\"name\":\"alakazam\"%'
        THEN `p`.`pokemons`
    ELSE CONCAT(
        LEFT(`p`.`pokemons`, CHAR_LENGTH(`p`.`pokemons`) - 1),
        ',{\"name\":\"alakazam\",\"boost\":0,\"level\":0,\"looktype\":{\"lookType\":65}}]'
    )
END
WHERE `a`.`name` = 'cuzinho';
