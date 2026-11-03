# frozen_string_literal: true

module Fcmanager
  module Relations
    class Clubs < Fcmanager::DB::Relation
      schema :clubs, infer: true do
        associations do
          has_many :players
          has_many :lineup_slots
        end

        # Formación activa del club (ver Fcmanager::Formation).
        attribute(
          :formation,
          Types::Integer,
          read: Types::String.enum(
            "4-1-4-1" => 0
          )
        )
      end
    end
  end
end
