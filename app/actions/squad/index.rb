# frozen_string_literal: true

module Fcmanager
  module Actions
    module Squad
      class Index < Fcmanager::Action
        include Deps["repos.player_repo"]

        def handle(*, response)
          response[:players] = player_repo.all
        end
      end
    end
  end
end
