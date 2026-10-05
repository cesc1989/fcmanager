# frozen_string_literal: true

module Fcmanager
  module Actions
    module Squad
      class New < Fcmanager::Action
        include Deps["repos.trait_repo"]

        def handle(*, response)
          response[:traits] = trait_repo.all
        end
      end
    end
  end
end
