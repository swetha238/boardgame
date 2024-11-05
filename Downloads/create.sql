-- Create tables for the University Tycoon game
CREATE TABLE players (
    player_id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    token TEXT NOT NULL UNIQUE,
    credits INTEGER DEFAULT 0,
    current_location TEXT,
    is_suspended BOOLEAN DEFAULT FALSE,
    is_visiting BOOLEAN DEFAULT FALSE,  -- Added for R8
    current_special_id INTEGER,
    CHECK (token IN ('Mortarboard', 'Book', 'Certificate', 'Gown', 'Laptop', 'Pen')),
    FOREIGN KEY (current_special_id) REFERENCES specials(special_id),
    CHECK ((SELECT COUNT(*) FROM players) <= 6)  -- Maximum 6 players
);

-- Rest of the tables remain same

-- Modified dice roll trigger
CREATE TRIGGER after_dice_roll
AFTER INSERT ON dice_rolls
FOR EACH ROW
BEGIN
    -- Handle suspended players
    UPDATE players 
    SET is_suspended = CASE
            WHEN is_suspended = TRUE AND NEW.roll_value = 6 THEN FALSE
            WHEN is_suspended = TRUE THEN TRUE
            ELSE is_suspended
        END,
        is_visiting = CASE
            WHEN current_location = 'suspension' AND NOT is_suspended THEN TRUE
            ELSE FALSE
        END
    WHERE player_id = NEW.player_id;

    -- Update location
    UPDATE players 
    SET current_location = CASE
        -- Stay in suspension if suspended and didn't roll 6
        WHEN is_suspended = TRUE AND NEW.roll_value != 6 THEN 'suspension'
        -- Handle You're Suspended landing
        WHEN (
            SELECT (
                COALESCE((
                    SELECT l.location_id 
                    FROM locations l
                    JOIN players p ON l.name = p.current_location
                    WHERE p.player_id = NEW.player_id
                ), 0) + NEW.roll_value
            ) % (SELECT COUNT(*) FROM locations)
        ) = 18 THEN 'suspension'
        -- Normal movement
        ELSE (
            SELECT name 
            FROM locations 
            WHERE location_id = (
                SELECT (
                    COALESCE((
                        SELECT l.location_id 
                        FROM locations l
                        JOIN players p ON l.name = p.current_location
                        WHERE p.player_id = NEW.player_id
                    ), 0) + NEW.roll_value
                ) % (SELECT COUNT(*) FROM locations)
            )
        )
        END,
        is_suspended = CASE
            WHEN (
                SELECT (
                    COALESCE((
                        SELECT l.location_id 
                        FROM locations l
                        JOIN players p ON l.name = p.current_location
                        WHERE p.player_id = NEW.player_id
                    ), 0) + NEW.roll_value
                ) % (SELECT COUNT(*) FROM locations)
            ) = 18 THEN TRUE
            ELSE is_suspended
        END
    WHERE player_id = NEW.player_id;
END;

-- Rest of the triggers with proper BEGIN/END blocks