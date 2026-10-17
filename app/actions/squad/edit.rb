# frozen_string_literal: true

module Fcmanager
  module Actions
    module Squad
      class Edit < Fcmanager::Action
        include Deps["repos.player_repo", "repos.trait_repo"]

        def handle(request, response)
          player = player_repo.find_with_traits(request.params[:id])

          return response.redirect_to(routes.path(:squad)) unless player

          response[:player_id] = player.id
          response[:player] = PlayerForm.values(player)
          response[:traits] = trait_repo.all
        end
      end
    end
  end
end
