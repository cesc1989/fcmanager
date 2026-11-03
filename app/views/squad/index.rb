# frozen_string_literal: true

module Fcmanager
  module Views
    module Squad
      class Index < Fcmanager::View
        expose :players, :lineup
      end
    end
  end
end
