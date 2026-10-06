# frozen_string_literal: true

module Fcmanager
  # Catálogo de opciones del formulario de jugador.
  #
  # Cada opción conoce:
  #   - `:key`   la clave que expone la relación (`app/relations/players.rb`)
  #   - `:value` el valor que viaja en el formulario
  #   - `:label` la etiqueta para la UI
  #   - `:db`    el entero con el que se persiste
  module PlayersCatalog
    POSITIONS = [
      {key: "po", value: "POR", label: "POR · Portero", group: "POR", db: 0},
      {key: "dfi", value: "DFI", label: "DFI · Lateral izquierdo", group: "DEF", db: 4},
      {key: "dfc", value: "DFC", label: "DFC · Defensa central", group: "DEF", db: 2},
      {key: "dfd", value: "DFD", label: "DFD · Lateral derecho", group: "DEF", db: 3},
      {key: "mcd", value: "MCD", label: "MCD · Mediocentro defensivo", group: "MED", db: 5},
      {key: "mi", value: "MI", label: "MI · Interior izquierdo", group: "MED", db: 8},
      {key: "mc", value: "MC", label: "MC · Mediocentro", group: "MED", db: 6},
      {key: "mco", value: "MCO", label: "MCO · Mediocentro ofensivo", group: "MED", db: 9},
      {key: "md", value: "MD", label: "MD · Interior derecho", group: "MED", db: 7},
      {key: "ei", value: "EI", label: "EI · Extremo izquierdo", group: "DEL", db: 11},
      {key: "ed", value: "ED", label: "ED · Extremo derecho", group: "DEL", db: 10},
      {key: "dc", value: "DC", label: "DC · Delantero centro", group: "DEL", db: 12}
    ].freeze

    POSITION_ORDER = POSITIONS.map { |position| position[:key] }.freeze

    ROLES = [
      {key: "promesa", value: "Promesa", label: "Promesa", db: 0},
      {key: "esporádico", value: "Esporadico", label: "Esporadico", db: 1},
      {key: "rotación", value: "Rotacion", label: "Rotacion", db: 2},
      {key: "importante", value: "Importante", label: "Importante", db: 3},
      {key: "esencial", value: "Esencial", label: "Esencial", db: 4}
    ].freeze

    FEET = [
      {key: "derecho", value: "derecho", label: "Derecho", db: 0},
      {key: "izquierdo", value: "izquierdo", label: "Izquierdo", db: 1}
    ].freeze

    POSITION_DB = POSITIONS.to_h { |position| [position[:value], position[:db]] }.freeze
    POSITION_VALUE = POSITIONS.to_h { |position| [position[:key], position[:value]] }.freeze
    ROLE_DB = ROLES.to_h { |role| [role[:value], role[:db]] }.freeze
    ROLE_VALUE = ROLES.to_h { |role| [role[:key], role[:value]] }.freeze
    FOOT_DB = FEET.to_h { |foot| [foot[:value], foot[:db]] }.freeze
    FOOT_VALUE = FEET.to_h { |foot| [foot[:key], foot[:value]] }.freeze

    module_function

    def position_options
      POSITIONS.map { |position| [position[:label], position[:value]] }
    end

    # Posición (clave de la relación) → índice en el orden canónico del juego.
    def position_rank(key)
      POSITION_ORDER.index(key.to_s) || POSITION_ORDER.size
    end

    def role_options
      ROLES.map { |role| [role[:label], role[:value]] }
    end

    def foot_options
      FEET.map { |foot| [foot[:label], foot[:value]] }
    end

    # Valor de formulario → entero para la DB.
    def position_db(value)
      POSITION_DB.fetch(value, 6)
    end

    def role_db(value)
      ROLE_DB.fetch(value, 1)
    end

    def foot_db(value)
      FOOT_DB.fetch(value, 0)
    end

    # Clave de la relación → valor de formulario (para precargar la edición).
    def position_value(key)
      POSITION_VALUE.fetch(key.to_s, "MC")
    end

    def role_value(key)
      ROLE_VALUE.fetch(key.to_s, "Esporadico")
    end

    def foot_value(key)
      FOOT_VALUE.fetch(key.to_s, "derecho")
    end
  end
end
