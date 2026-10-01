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
INSERT INTO schema_migrations (filename) VALUES
('20260930191342_create_traits.rb'),
('20260930192839_create_clubs.rb');
