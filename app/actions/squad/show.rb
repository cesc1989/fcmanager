# frozen_string_literal: true

module Fcmanager
  module Actions
    module Squad
      class Show < Fcmanager::Action
        include Deps["repos.player_repo"]

        def handle(request, response)
          player = player_repo.find_with_traits(request.params[:id])

          return response.redirect_to(routes.path(:squad)) unless player

          response[:player] = player
        end
      end
    end
  end
end
