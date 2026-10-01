# frozen_string_literal: true

ROM::SQL.migration do
  change do
    create_table :player_traits do
      primary_key :id

      foreign_key :player_id, :players
      foreign_key :trait_id, :traits

      column :value, :integer, default: 0, null: false

      unique [:player_id, :trait_id]
    end
  end
end
