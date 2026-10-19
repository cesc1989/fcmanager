# frozen_string_literal: true

module Fcmanager
  module Actions
    module Compare
      class Show < Fcmanager::Action
        include Deps["repos.player_repo"]

        def handle(request, response)
          players = player_repo.all
          pair = ComparePair.from_params(request.params, players.map(&:id))
          player_a = players.find { |player| player.id == pair.a }
          player_b = players.find { |player| player.id == pair.b }

          response[:players] = players
          response[:pair] = pair
          response[:player_a] = player_a
          response[:player_b] = player_b
          response[:comparison] = pair.complete? ? PlayerComparison.new(player_a, player_b) : nil
        end
      end
    end
  end
end
