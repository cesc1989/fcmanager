# frozen_string_literal: true

module Fcmanager
  module Actions
    module Formation
      class Show < Fcmanager::Action
        include Deps["repos.player_repo", "repos.club_repo", "repos.lineup_repo"]

        def handle(request, response)
          players = player_repo.all
          squad_ids = players.map(&:id)
          selected_id = Lineup.parse_id(request.params[:sel])

          response[:players] = players
          response[:lineup] = lineup_repo.for_club(club_repo.grimsby_town, squad_ids)
          response[:selected_id] = squad_ids.include?(selected_id) ? selected_id : nil
        end
      end
    end
  end
end
