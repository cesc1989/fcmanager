# frozen_string_literal: true

ROM::SQL.migration do
  change do
    create_table :players do
      primary_key :id

      column :name, :string, null: false

      # En una aplicación normal estos campos son calculados. En este caso me toca modificar manualmente.
      column :age, :string, null: false
      column :overall, :string, null: false

      # Esto será para lo que corresponde al tiempo de juego:
      #  Promesa, Esporadico, Rotación, Ipmortante o Esenecial.
      column :role, :integer, null: false

      column :comment, :text
      column :height, :string, null: false

      # Que sea un enum con Left, Right.
      column :dominant_foot, :integer, null: false

      # Primary es si es defensa, laterla, mediocampo, etc.
      # Secondary es por si tiene posiciones adicionales.
      column :primary_position, :integer, null: false
      column :secondary_position, :integer, null: false

      # No se puede borrar el club si tiene hijos en players.
      foreign_key :club_id, :clubs, on_delete: :restrict
    end
  end
end
