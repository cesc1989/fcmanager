# frozen_string_literal: true

module Fcmanager
  module Actions
    module Formation
      # Coloca a un jugador en un hueco (con intercambio si venía de otro hueco).
      class Assign < Fcmanager::Action
        include Deps["repos.player_repo", "repos.club_repo", "repos.lineup_repo"]

        def handle(request, response)
          player_id = Lineup.parse_id(request.params[:player_id])

          lineup_repo.change(club_repo.grimsby_town, player_repo.squad_ids) do |lineup|
            lineup.assign(request.params[:slot], player_id)
          end

          response.redirect_to(routes.path(:formation))
        end
      end
    end
  end
end
