# frozen_string_literal: true

ROM::SQL.migration do
  change do
    alter_table :players do
      drop_column :secondary_position

      add_column :secondary_positions, :string
    end
  end
end
