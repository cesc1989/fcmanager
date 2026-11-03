# frozen_string_literal: true

module Fcmanager
  module Actions
    module Formation
      # Rellena los huecos vacíos por posición y promedio.
      class Auto < Fcmanager::Action
        include Deps["repos.player_repo", "repos.club_repo", "repos.lineup_repo"]

        def handle(_request, response)
          players = player_repo.all

          lineup_repo.change(club_repo.grimsby_town, players.map(&:id)) do |lineup|
            lineup.auto_fill(players)
          end

          response.redirect_to(routes.path(:formation))
        end
      end
    end
  end
end
