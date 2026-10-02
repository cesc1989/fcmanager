# frozen_string_literal: true

module Fcmanager
  module Relations
    class Clubs < Fcmanager::DB::Relation
      schema :clubs, infer: true do
        associations do
          has_many :players
        end
      end
    end
  end
end
