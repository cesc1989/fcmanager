# frozen_string_literal: true

module Fcmanager
  module Actions
    module Squad
      class Index < Fcmanager::Action
        include Deps["repos.player_repo", "repos.club_repo", "repos.lineup_repo"]

        def handle(_request, response)
          players = player_repo.all

          response[:players] = players
          response[:lineup] = lineup_repo.for_club(club_repo.grimsby_town, players.map(&:id))
        end
      end
    end
  end
end
