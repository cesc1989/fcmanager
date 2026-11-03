# frozen_string_literal: true

module Fcmanager
  class Routes < Hanami::Routes
    root to: "squad.index"

    get "/squad", to: "squad.index", as: :squad
    get "/squad/new", to: "squad.new", as: :new_squad
    get "/squad/:id/edit", to: "squad.edit", as: :edit_squad
    patch "/squad/:id/edit", to: "squad.update", as: :update_squad
    patch "/squad/:id/release", to: "squad.release", as: :release_squad
    post "/squad", to: "squad.create"
    get "/squad/:id", to: "squad.show", as: :squad_player

    get "/compare", to: "compare.show", as: :compare

    get "/formation", to: "formation.show", as: :formation
    post "/formation/assign", to: "formation.assign", as: :formation_assign
    post "/formation/bench", to: "formation.bench", as: :formation_bench
    post "/formation/auto", to: "formation.auto", as: :formation_auto
    post "/formation/clear", to: "formation.clear", as: :formation_clear
  end
end
