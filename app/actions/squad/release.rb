# frozen_string_literal: true

module Fcmanager
  module Actions
    module Squad
      class Release < Fcmanager::Action
        include Deps["repos.player_repo"]

        def handle(request, response)
          player = player_repo.find(request.params[:id])

          player_repo.release(player.id) if player

          response.redirect_to routes.path(:squad)
        end
      end
    end
  end
end
