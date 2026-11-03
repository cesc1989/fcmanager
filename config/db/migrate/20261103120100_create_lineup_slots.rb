# frozen_string_literal: true

ROM::SQL.migration do
  change do
    create_table :lineup_slots do
      primary_key :id

      foreign_key :club_id, :clubs, null: false, on_delete: :cascade
      foreign_key :player_id, :players, null: false, on_delete: :cascade

      # Enum: hueco de la formación (ver app/relations/lineup_slots.rb).
      column :slot, Integer, null: false

      index %i[club_id slot], unique: true
      index :player_id, unique: true
    end
  end
end
