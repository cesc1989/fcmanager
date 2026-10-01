# frozen_string_literal: true

ROM::SQL.migration do
  change do
    rename_table(:clubes, :clubs)
  end
end
