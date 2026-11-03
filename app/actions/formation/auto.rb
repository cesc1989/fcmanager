# frozen_string_literal: true

module Fcmanager
  module Actions
    module Formation
      class Auto < Fcmanager::Action
        def handle(_request, response)
          response.redirect_to(routes.path(:formation))
        end
      end
    end
  end
end
