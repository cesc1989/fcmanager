# frozen_string_literal: true

module Fcmanager
  module Views
    module Squad
      class New < Fcmanager::View
        config.layout = "app"

        expose :traits
      end
    end
  end
end
