# frozen_string_literal: true

module Fcmanager
  module Views
    module Squad
      class Index < Fcmanager::View
        config.layout = "app"

        expose :players
      end
    end
  end
end
