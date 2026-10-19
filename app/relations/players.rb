# frozen_string_literal: true

module Fcmanager
  module Relations
    class Players < Fcmanager::DB::Relation
      schema :players, infer: true do
        associations do
          # Puede ser nulo. Cuando el jugador sale de la plantilla (botón "Liberar")
          # se le asigna el club "Agente Libre" en vez de dejarlo en nulo.
          belongs_to :club

          has_many :player_traits
        end

        attribute(
          :role,
          Types::Integer,
          read: Types::String.enum(
            "promesa" => 0,
            "esporádico" => 1,
            "rotación" => 2,
            "importante" => 3,
            "esencial" => 4
          )
        )

        attribute(
          :dominant_foot,
          Types::Integer,
          read: Types::String.enum(
            "derecho" => 0,
            "izquierdo" => 1,
          )
        )

        # Sobre `primary_position` y `secondary_positions`
        #
        # Inicialmente `secondary_positions` iba a ser un enum también
        # pero eso no cuadra bien así que lo cambié a un campo string.
        #
        # La idea es que reciba una lista de posiciones separadas por coma.
        attribute(
          :primary_position,
          Types::Integer,
          read: Types::String.enum(
            "po" => 0,
            "dfc" => 2,
            "dfd" => 3,
            "dfi" => 4,
            "mcd" => 5,
            "mc" => 6,
            "md" => 7,
            "mi" => 8,
            "mco" => 9,
            "ed" => 10,
            "ei" => 11,
            "dc" => 12
          )
        )
      end
    end
  end
end
