CREATE VIEW leaderboard AS
SELECT 
    p.name,
    LOWER(REPLACE(p.current_location, ' ', '_')) as location,
    p.credits,
    COALESCE(GROUP_CONCAT(
        LOWER(l.name)
        FILTER (WHERE l.name IS NOT NULL)
        ORDER BY l.location_id
    ), '') as buildings
FROM players p
LEFT JOIN building_ownership bo ON p.player_id = bo.owner_id
LEFT JOIN locations l ON bo.location_id = l.location_id
GROUP BY p.player_id
ORDER BY p.credits DESC;