# frozen_string_literal: true

module Fcmanager
  module Relations
    class PlayerTraits < Fcmanager::DB::Relation
      schema :player_traits, infer: true do
        associations do
          belongs_to :player
          belongs_to :trait
        end
      end
    end
  end
end
