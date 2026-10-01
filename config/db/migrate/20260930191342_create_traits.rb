# frozen_string_literal: true

ROM::SQL.migration do
  change do
    create_table :traits do
      primary_key :id

      column :name, :string, null: false

      # kind es para diferenciar los atributos Físicos, Mentales, Técnicos y de Arquería.
      column :kind, :integer, null: false
    end
  end
end
