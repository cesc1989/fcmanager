# frozen_string_literal: true

module Fcmanager
  module Actions
    module Formation
      # Saca a un jugador del once.
      class Bench < Fcmanager::Action
        include Deps["repos.player_repo", "repos.club_repo", "repos.lineup_repo"]

        # Solo se vuelve a la ficha de un jugador; cualquier otra cosa va a /formation.
        RETURN_TO = %r{\A/squad/\d+\z}

        def handle(request, response)
          player_id = Lineup.parse_id(request.params[:player_id])
          return_to = request.params[:return_to].to_s

          lineup_repo.change(club_repo.grimsby_town, player_repo.squad_ids) do |lineup|
            lineup.bench(player_id)
          end

          response.redirect_to(return_to.match?(RETURN_TO) ? return_to : routes.path(:formation))
        end
      end
    end
  end
end
