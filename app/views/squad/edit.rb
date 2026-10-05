# frozen_string_literal: true

module Fcmanager
  module Views
    module Squad
      class Edit < Fcmanager::View
        config.layout = "app"

        expose :player_id
        expose :player_values
      end
    end
  end
end
