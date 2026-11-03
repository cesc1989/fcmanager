# frozen_string_literal: true

ROM::SQL.migration do
  change do
    alter_table :clubs do
      # Enum: 0 = "4-1-4-1" (ver app/relations/clubs.rb y Fcmanager::Formation).
      add_column :formation, Integer, null: false, default: 0
    end
  end
end
