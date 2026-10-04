# frozen_string_literal: true

ROM::SQL.migration do
  change do
    add_index :traits, :name, unique: true, name: :traits_name_index
  end
end
