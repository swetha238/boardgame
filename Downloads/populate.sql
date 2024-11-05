-- Populate initial game state

-- Insert players
INSERT INTO players (player_id, name, token, credits, current_location) VALUES
(1, 'Gareth', 'Certificate', 345, 'museum'),
(2, 'Uli', 'Mortarboard', 590, 'kilburn'),
(3, 'Pradyumn', 'Book', 465, 'ambs'),
(4, 'Ruth', 'Pen', 360, 'hearing_1');

-- Insert locations
INSERT INTO locations (location_id, name, type, tuition_fee, color) VALUES
(1, 'welcome_week', 'Corner', NULL, NULL),
(2, 'kilburn', 'Building', 50, 'green'),
(3, 'it', 'Building', 50, 'green'),
(4, 'hearing_1', 'Hearing', NULL, NULL),
(5, "uni_place", 'Building', 25, 'orange'),
(6, 'ambs', 'Building', 25, 'orange'),
(7, 'rag_1', 'Rag', NULL, NULL),
(8, 'suspension', 'Corner', NULL, NULL),
(9, 'crawford', 'Building', 30, 'blue'),
(10, 'sugden', 'Building', 30, 'blue'),
(11, 'ali_g', 'Corner', NULL, NULL),
(12, 'shopping_precinct', 'Building', 35, 'brown')
(13, 'mecd', 'Building', 35, 'brown'),
(14, 'rag_2', 'Rag', NULL, NULL),
(15, 'library', 'Building', 40, 'grey'),
(16, 'sam_alex', 'Building', 40, 'grey'),
(17, 'hearing_2', 'Hearing', NULL, NULL),
(18, 'youre_suspended', 'Corner', NULL, NULL),
(19, 'museum', 'Building', 50, 'black'),
(20, 'whitworth_hall', 'Building', 50, 'black');


INSERT INTO specials (special_id, name, description, type) VALUES
(1, 'RAG 1', 'You win a fancy dress competition: Awarded 15 credits', 'RAG'),
(2, 'RAG 2', 'You receive a bursray and share it with your friends: Give all other players 10 credits', 'RAG'),
(3, 'Hearing 1', 'You are found guilty of academic malpractive: Fined 20 credits', 'Hearing'),
(4, 'Hearing 2', 'You are in rent arrears: Fined 25 credits', 'Hearing');

-- Initial building ownership (if any buildings are owned at start)
-- Based on the initial state description, no buildings are owned at the start
-- This table will be populated during gameplay

-- Initial audit log entry for game start
INSERT INTO audit_log (round_number, player_id, location, credits) VALUES 
(0, 1, 'welcome_week', 345),
(0, 2, 'welcome_week', 590),
(0, 3, 'welcome_week', 465),
(0, 4, 'welcome_week', 360);