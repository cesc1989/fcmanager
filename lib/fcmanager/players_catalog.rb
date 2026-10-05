# frozen_string_literal: true

module Fcmanager
  # Catálogo de opciones del formulario de jugador.
  #
  # Cada opción conoce su etiqueta para la UI (`:label`), el valor que viaja en el
  # formulario (`:value`) y el entero con el que se persiste en la DB (`:db`),
  # alineado con los enums de `app/relations/players.rb`.
  module PlayersCatalog
    POSITIONS = [
      {value: "POR", label: "POR · Portero", group: "POR", db: 0},
      {value: "LI", label: "LI · Lateral izquierdo", group: "DEF", db: 4},
      {value: "DFC", label: "DFC · Defensa central", group: "DEF", db: 2},
      {value: "LD", label: "LD · Lateral derecho", group: "DEF", db: 3},
      {value: "MCD", label: "MCD · Mediocentro defensivo", group: "MED", db: 5},
      {value: "MI", label: "MI · Interior izquierdo", group: "MED", db: 8},
      {value: "MC", label: "MC · Mediocentro", group: "MED", db: 6},
      {value: "MD", label: "MD · Interior derecho", group: "MED", db: 7},
      {value: "DC", label: "DC · Delantero centro", group: "DEL", db: 12}
    ].freeze

    ROLES = [
      {value: "Promesa", label: "Promesa", db: 0},
      {value: "Esporadico", label: "Esporadico", db: 1},
      {value: "Rotacion", label: "Rotacion", db: 2},
      {value: "Importante", label: "Importante", db: 3},
      {value: "Esencial", label: "Esencial", db: 4}
    ].freeze

    FEET = [
      {value: "derecho", label: "Derecho", db: 0},
      {value: "izquierdo", label: "Izquierdo", db: 1}
    ].freeze

    POSITION_DB = POSITIONS.to_h { |position| [position[:value], position[:db]] }.freeze
    ROLE_DB = ROLES.to_h { |role| [role[:value], role[:db]] }.freeze
    FOOT_DB = FEET.to_h { |foot| [foot[:value], foot[:db]] }.freeze

    module_function

    def position_options
      POSITIONS.map { |position| [position[:label], position[:value]] }
    end

    def role_options
      ROLES.map { |role| [role[:label], role[:value]] }
    end

    def foot_options
      FEET.map { |foot| [foot[:label], foot[:value]] }
    end

    def position_db(value)
      POSITION_DB.fetch(value, 6)
    end

    def role_db(value)
      ROLE_DB.fetch(value, 1)
    end

    def foot_db(value)
      FOOT_DB.fetch(value, 0)
    end
  end
end
