# frozen_string_literal: true

module Fcmanager
  module Actions
    module Squad
      class Update < Fcmanager::Action
        include Deps["repos.player_repo"]

        params Contracts::PlayerParams

        def handle(request, response)
          player = player_repo.find(request.params[:id])

          return response.redirect_to(routes.path(:squad)) unless player

          if request.params.valid?
            player_repo.update(player.id, PlayerForm.attributes(request.params[:player]))
            response.redirect_to routes.path(:squad)
          else
            response[:player_id] = player.id
            response[:player_values] = PlayerForm.values(player)
            response.status = 422
          end
        end
      end
    end
  end
end
