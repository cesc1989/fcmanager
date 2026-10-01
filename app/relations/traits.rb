# frozen_string_literal: true

module Fcmanager
  module Relations
    class Traits < Fcmanager::DB::Relation
      schema :traits, infer: true do
        attribute(
          :kind,
          Types::Integer,
          read: Types::String.enum(
            "fisicos" => 0,
            "mentales" => 1,
            "tecnicos" => 2,
            "arqueria" => 3
          )
        )
      end
    end
  end
end
