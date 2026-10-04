# frozen_string_literal: true

module Fcmanager
  class Routes < Hanami::Routes
    root to: "squad.index"

    get "/squad", to: "squad.index"
  end
end
