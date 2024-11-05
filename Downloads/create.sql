-- Create tables for the University Tycoon game
CREATE TABLE players (
    player_id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    token TEXT NOT NULL UNIQUE,
    credits INTEGER DEFAULT 0,
    current_location TEXT,
    is_suspended BOOLEAN DEFAULT FALSE,
    CHECK (token IN ('Mortarboard', 'Book', 'Certificate', 'Gown', 'Laptop', 'Pen'))
);

CREATE TABLE locations (
    location_id INTEGER PRIMARY KEY,
    name TEXT NOT NULL UNIQUE,
    type TEXT CHECK (type IN ('Corner', 'Hearing', 'Rag', 'Building')),
    tuition_fee INTEGER,
    color TEXT
);

CREATE TABLE building_ownership (
    building_id INTEGER PRIMARY KEY AUTOINCREMENT,
    location_id INTEGER,
    owner_id INTEGER,
    FOREIGN KEY (location_id) REFERENCES locations(location_id),
    FOREIGN KEY (owner_id) REFERENCES players(player_id)
);

CREATE TABLE specials (
    special_id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    type TEXT CHECK (type IN ('Corner', 'Hearing', 'RAG'))
);

CREATE TABLE audit_log (
    log_id INTEGER PRIMARY KEY AUTOINCREMENT,
    round_number INTEGER,
    player_id INTEGER,
    location TEXT,
    credits INTEGER,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (player_id) REFERENCES players(player_id)
);

-- Create a table for dice rolls
CREATE TABLE dice_rolls (
    roll_id INTEGER PRIMARY KEY AUTOINCREMENT,
    player_id INTEGER,
    roll_value INTEGER,
    round_number INTEGER,
    is_extra_roll BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (player_id) REFERENCES players(player_id)
);

-- First, let's create a trigger that handles all property-related transactions
CREATE TRIGGER after_dice_roll
AFTER INSERT ON dice_rolls
FOR EACH ROW
BEGIN
    UPDATE players 
    SET current_location = (
        SELECT name 
        FROM locations 
        WHERE location_id = (
             (               
                    SELECT l.location_id 
                    FROM locations l
                    JOIN players p ON l.name = p.current_location
                    WHERE p.player_id = NEW.player_id
                 + NEW.roll_value
            ) % (SELECT COUNT(*) FROM locations)
        )
    )
    WHERE player_id = NEW.player_id;
END;

-- Trigger for handling property transactions and Welcome Week
CREATE TRIGGER after_player_move_transactions
AFTER UPDATE OF current_location ON players
FOR EACH ROW
BEGIN
  
    WHEN NOT EXISTS (
        SELECT 1 FROM dice_rolls 
        WHERE player_id = NEW.player_id 
        AND roll_value = 6 
        AND NOT is_extra_roll 
        AND roll_id = (SELECT MAX(roll_id) FROM dice_rolls WHERE player_id = NEW.player_id)
    )
    BEGIN
    -- Rule 4: Award 100 credits when passing Welcome Week
    -- Check if player passed Welcome Week by comparing old and new location_ids
    UPDATE players 
    SET credits = credits + 100
    WHERE player_id = NEW.player_id 
    AND (
        SELECT l1.location_id FROM locations l1 WHERE l1.name = OLD.current_location
    ) > (
        SELECT l2.location_id FROM locations l2 WHERE l2.name = NEW.current_location
    );

    -- Rule 1: Buy unowned property
    UPDATE players
    SET credits = credits - (
        SELECT tuition_fee * 2
        FROM locations
        WHERE name = NEW.current_location
        AND type = 'Building'
        AND NOT EXISTS (
            SELECT 1 FROM building_ownership bo 
            JOIN locations l ON bo.location_id = l.location_id 
            WHERE l.name = NEW.current_location
        )
    )
    WHERE player_id = NEW.player_id;

    -- Insert new building ownership record if property was bought
    INSERT INTO building_ownership (location_id, owner_id)
    SELECT l.location_id, NEW.player_id
    FROM locations l
    WHERE l.name = NEW.current_location 
    AND l.type = 'Building'
    AND NOT EXISTS (
        SELECT 1 FROM building_ownership bo 
        WHERE bo.location_id = l.location_id
    );

    -- Rules 2 & 3: Pay rent (with color set bonus)
    UPDATE players
    SET credits = credits - (
        SELECT 
            CASE 
                -- Double rent if owner has all properties of same color
                WHEN (
                    SELECT COUNT(bo2.location_id) 
                    FROM building_ownership bo2 
                    JOIN locations l2 ON bo2.location_id = l2.location_id 
                    WHERE l2.color = l1.color 
                    AND bo2.owner_id = bo1.owner_id
                ) = (
                    SELECT COUNT(*) 
                    FROM locations l3 
                    WHERE l3.color = l1.color
                ) THEN l1.tuition_fee * 2
                -- Normal rent
                ELSE l1.tuition_fee
            END
        FROM locations l1
        JOIN building_ownership bo1 ON l1.location_id = bo1.location_id
        WHERE l1.name = NEW.current_location
        AND bo1.owner_id != NEW.player_id
    )
    WHERE player_id = NEW.player_id;

    -- Pay rent to property owner
    UPDATE players
    SET credits = credits + (
        SELECT 
            CASE 
                -- Double rent if owner has all properties of same color
                WHEN (
                    SELECT COUNT(bo2.location_id) 
                    FROM building_ownership bo2 
                    JOIN locations l2 ON bo2.location_id = l2.location_id 
                    WHERE l2.color = l1.color 
                    AND bo2.owner_id = bo1.owner_id
                ) = (
                    SELECT COUNT(*) 
                    FROM locations l3 
                    WHERE l3.color = l1.color
                ) THEN l1.tuition_fee * 2
                -- Normal rent
                ELSE l1.tuition_fee
            END
        FROM locations l1
        JOIN building_ownership bo1 ON l1.location_id = bo1.location_id
        WHERE l1.name = NEW.current_location
        AND bo1.owner_id = players.player_id
    )
    WHERE player_id IN (
        SELECT bo.owner_id
        FROM building_ownership bo
        JOIN locations l ON bo.location_id = l.location_id
        WHERE l.name = NEW.current_location
    );
    END;
END;
-- Third trigger for special spaces (RAG and Hearing)
CREATE TRIGGER after_player_move_special
AFTER UPDATE OF current_location ON players
FOR EACH ROW  y
BEGIN
    -- Handle RAG spaces
    UPDATE players
    SET credits = CASE 
        WHEN NEW.current_location = 'rag_1' THEN credits + 15
        WHEN NEW.current_location = 'rag_2' THEN 
            CASE 
                -- Current player gives 10 credits to each other player
                WHEN player_id != NEW.player_id THEN credits + 10
                WHEN player_id = NEW.player_id THEN credits - ((SELECT COUNT(*) FROM players) - 1) * 10
            END
        ELSE credits
    END;

    -- Handle Hearing spaces
    UPDATE players
    SET credits = CASE 
        WHEN NEW.current_location = 'hearing_1' THEN credits - 20
        WHEN NEW.current_location = 'hearing_2' THEN credits - 25
        ELSE credits
    END
    WHERE player_id = NEW.player_id;
END;

-- Fourth trigger for audit logging
CREATE TRIGGER after_player_move_audit
AFTER UPDATE OF current_location ON players
FOR EACH ROW
WHEN NEW.current_location != OLD.current_location
BEGIN
    INSERT INTO audit_log (round_number, player_id, location, credits)
    VALUES (
        (SELECT COALESCE(MAX(round_number), 0) FROM audit_log WHERE player_id = NEW.player_id),
        NEW.player_id,
        NEW.current_location,
        (SELECT credits FROM players WHERE player_id = NEW.player_id)
    );
END;