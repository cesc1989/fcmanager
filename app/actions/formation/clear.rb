# frozen_string_literal: true

module Fcmanager
  module Actions
    module Formation
      # Vacía el once.
      class Clear < Fcmanager::Action
        include Deps["repos.player_repo", "repos.club_repo", "repos.lineup_repo"]

        def handle(_request, response)
          lineup_repo.change(club_repo.grimsby_town, player_repo.squad_ids, &:clear_all)

          response.redirect_to(routes.path(:formation))
        end
      end
    end
  end
end
