# frozen_string_literal: true

module Fcmanager
  module Relations
    class Players < Fcmanager::DB::Relation
      schema :players, infer: true do
        associations do
          belongs_to :club
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
            "gk" => 0,
            "cb" => 2,
            "rb" => 3,
            "lb" => 4,
            "cdm" => 5,
            "cm" => 6,
            "rm" => 7,
            "lm" => 8,
            "cam" => 9,
            "rw" => 10,
            "lw" => 11,
            "cf" => 12
          )
        )
      end
    end
  end
end
