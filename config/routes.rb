# frozen_string_literal: true

module Fcmanager
  class Routes < Hanami::Routes
    root to: "squad.index"

    get "/squad", to: "squad.index", as: :squad
    get "/squad/new", to: "squad.new", as: :new_squad
    post "/squad", to: "squad.create"
  end
end
