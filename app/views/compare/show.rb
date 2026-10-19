# frozen_string_literal: true

module Fcmanager
  module Views
    module Compare
      class Show < Fcmanager::View
        expose :players, :pair, :player_a, :player_b, :comparison
      end
    end
  end
end
