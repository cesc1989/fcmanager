CREATE TABLE `schema_migrations`(`filename` varchar(255) NOT NULL PRIMARY KEY);
CREATE TABLE `traits`(
  `id` integer NOT NULL PRIMARY KEY AUTOINCREMENT,
  `name` string NOT NULL,
  `kind` integer NOT NULL
);
CREATE TABLE IF NOT EXISTS "clubs"(
  `id` integer NOT NULL PRIMARY KEY AUTOINCREMENT,
  `name` string NOT NULL,
  `formation` integer DEFAULT(0) NOT NULL
);
CREATE TABLE `players`(
  `id` integer NOT NULL PRIMARY KEY AUTOINCREMENT,
  `name` string NOT NULL,
  `age` string NOT NULL,
  `overall` string NOT NULL,
  `role` integer NOT NULL,
  `comment` text,
  `height` string NOT NULL,
  `dominant_foot` integer NOT NULL,
  `primary_position` integer NOT NULL,
  `club_id` integer REFERENCES `clubs` ON DELETE RESTRICT,
  `secondary_positions` string
);
CREATE TABLE `player_traits`(
  `id` integer NOT NULL PRIMARY KEY AUTOINCREMENT,
  `player_id` integer REFERENCES `players`,
  `trait_id` integer REFERENCES `traits`,
  `value` integer DEFAULT(0) NOT NULL,
  UNIQUE(`player_id`, `trait_id`)
);
CREATE UNIQUE INDEX `traits_name_index` ON `traits`(`name`);
CREATE TABLE `lineup_slots`(
  `id` integer NOT NULL PRIMARY KEY AUTOINCREMENT,
  `club_id` integer NOT NULL REFERENCES `clubs` ON DELETE CASCADE,
  `player_id` integer NOT NULL REFERENCES `players` ON DELETE CASCADE,
  `slot` integer NOT NULL
);
CREATE UNIQUE INDEX `lineup_slots_club_id_slot_index` ON `lineup_slots`(
  `club_id`,
  `slot`
);
CREATE UNIQUE INDEX `lineup_slots_player_id_index` ON `lineup_slots`(
  `player_id`
);
INSERT INTO schema_migrations (filename) VALUES
('20260930191342_create_traits.rb'),
('20260930192839_create_clubs.rb'),
('20260930193007_create_players.rb'),
('20260930194845_create_player_traits.rb'),
('20260930202012_rename_clubs.rb'),
('20261001182736_alter_players_secondary_position.rb'),
('20261003120000_add_unique_index_to_traits_name.rb'),
('20261103120000_add_formation_to_clubs.rb'),
('20261103120100_create_lineup_slots.rb');
