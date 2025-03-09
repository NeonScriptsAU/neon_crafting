CREATE TABLE IF NOT EXISTS neon_crafting_levels (
    id INT AUTO_INCREMENT PRIMARY KEY,
    identifier VARCHAR(255) NOT NULL UNIQUE,
    xp_amount INT DEFAULT 0,
    level INT DEFAULT 0
);