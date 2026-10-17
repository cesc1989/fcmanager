# frozen_string_literal: true

module Fcmanager
  module Actions
    module Squad
      class Update < Fcmanager::Action
        include Deps["repos.player_repo", "repos.trait_repo"]

        params Contracts::PlayerParams

        def handle(request, response)
          player = player_repo.find_with_traits(request.params[:id])

          return response.redirect_to(routes.path(:squad)) unless player

          if request.params.valid?
            player_repo.update_with_traits(
              player.id,
              PlayerForm.attributes(request.params[:player]),
              PlayerForm.traits(request.params[:player][:traits], trait_repo.ids)
            )
            response.redirect_to routes.path(:squad)
          else
            response[:player_id] = player.id
            response[:player] = PlayerForm.values(player)
            response[:traits] = trait_repo.all
            response.status = 422
          end
        end
      end
    end
  end
end
