# frozen_string_literal: true

module Fcmanager
  module Actions
    module Squad
      class Create < Fcmanager::Action
        include Deps["repos.player_repo", "repos.trait_repo"]

        params Contracts::PlayerParams

        def handle(request, response)
          if request.params.valid?
            player_repo.create_with_traits(
              PlayerForm.attributes(request.params[:player]),
              PlayerForm.traits(request.params[:player][:traits], trait_repo.ids)
            )
            response.redirect_to routes.path(:squad)
          else
            response[:traits] = trait_repo.all
            response.status = 422
          end
        end
      end
    end
  end
end
