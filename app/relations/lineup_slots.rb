# frozen_string_literal: true

module Fcmanager
  module Relations
    class LineupSlots < Fcmanager::DB::Relation
      schema :lineup_slots, infer: true do
        associations do
          belongs_to :club
          belongs_to :player
        end

        # Claves de los huecos de Fcmanager::Formation. Si se añade otra
        # formación, sus huecos necesitan claves y enteros nuevos aquí.
        attribute(
          :slot,
          Types::Integer,
          read: Types::String.enum(
            "gk" => 0,
            "lb" => 1,
            "cbl" => 2,
            "cbr" => 3,
            "rb" => 4,
            "cdm" => 5,
            "lm" => 6,
            "cml" => 7,
            "cmr" => 8,
            "rm" => 9,
            "st" => 10
          )
        )
      end
    end
  end
end
