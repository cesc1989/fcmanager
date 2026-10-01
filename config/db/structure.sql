CREATE TABLE `schema_migrations`(`filename` varchar(255) NOT NULL PRIMARY KEY);
CREATE TABLE `traits`(
  `id` integer NOT NULL PRIMARY KEY AUTOINCREMENT,
  `name` string NOT NULL,
  `kind` integer NOT NULL
);
CREATE TABLE `clubes`(
  `id` integer NOT NULL PRIMARY KEY AUTOINCREMENT,
  `name` string NOT NULL
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
  `secondary_position` integer NOT NULL,
  `club_id` integer REFERENCES `clubs` ON DELETE RESTRICT
);
INSERT INTO schema_migrations (filename) VALUES
('20260930191342_create_traits.rb'),
('20260930192839_create_clubs.rb'),
('20260930193007_create_players.rb');
