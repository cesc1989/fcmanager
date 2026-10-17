# AGENTS.md

Hanami 3 app (NOT Rails) for managing FC 26 squads. Ruby + SQLite (Sequel/ROM) + esbuild assets.
App is in an early DB-modeling stage: routes, actions, and views are still empty.

## Commands

- Setup: `bin/setup` (bundle install, npm install, `hanami db prepare`)
- Dev server (web + asset watcher via foreman): `bin/dev` → http://localhost:2300
- All tests: `bundle exec rake` (default task runs RSpec)
- Single test: `bundle exec rspec spec/requests/root_spec.rb:5`
- Migrations + seeds: `hanami db prepare` (or `hanami db migrate` / `hanami db seed`)
- Asset build (prod): `hanami assets compile`

- Lint: `bundle exec rubocop` (config in `.rubocop.yml`; existing offenses not yet fixed)
- Solargraph (LSP for the editor) is configured in `.solargraph.yml`; after changing gems run `bundle exec solargraph gems`.

## Non-obvious conventions

- Ruby namespace is `Fcmanager` (lowercase `c`), matching the `fcmanager` dir.
- Port is 2300 (not 3000), set in `config/puma.rb` / `Guardfile`.
- DB is SQLite from `DATABASE_URL` in `.env` (`db/fcmanager.sqlite`); tests use `db/fcmanager_test.sqlite`.
- Enums are stored as **integers** but exposed as Spanish strings via `read: Types::String.enum(...)` in `app/relations/*.rb`. When adding/changing an enum column, keep the DB column integer and add the `read:` mapping (see `players.rb`, `traits.rb`).
- `players.secondary_positions` is NOT an enum: it is a comma-separated string of position keys (e.g. `"10,7"`). See comment in `app/relations/players.rb`.
- Schema dump is `config/db/structure.sql`; migrations live in `config/db/migrate` and must be `ROM::SQL.migration` blocks.
- Test DB is only cleaned for examples tagged `:db`; all `type: :feature` specs are auto-tagged `:db` (`spec/support/db.rb`).
- `test_models.rb` in the repo root is a scratch console snippet (relies on a local `app` var), NOT a test.

## Reference

- README.md for the project pitch and basic workflow.
