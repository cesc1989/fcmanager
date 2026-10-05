# frozen_string_literal: true

module Fcmanager
  module Actions
    module Squad
      class Create < Fcmanager::Action
        include Deps["repos.player_repo"]

        params Contracts::PlayerParams

        def handle(request, response)
          if request.params.valid?
            player_repo.create(PlayerForm.attributes(request.params[:player]))
            response.redirect_to routes.path(:squad)
          else
            response.status = 422
          end
        end
      end
    end
  end
end
