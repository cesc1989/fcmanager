# frozen_string_literal: true

module Fcmanager
  module Views
    module Squad
      class Edit < Fcmanager::View
        expose :player_id
        expose :player_values
        expose :traits
      end
    end
  end
end
