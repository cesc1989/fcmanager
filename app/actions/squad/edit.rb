# frozen_string_literal: true

module Fcmanager
  module Actions
    module Squad
      class Edit < Fcmanager::Action
        include Deps["repos.player_repo"]

        def handle(request, response)
          player = player_repo.find(request.params[:id])

          return response.redirect_to(routes.path(:squad)) unless player

          response[:player_id] = player.id
          response[:player_values] = PlayerForm.values(player)
        end
      end
    end
  end
end
