# frozen_string_literal: true

module Fcmanager
  # Formaciones del equipo y sus huecos en el campo (port de `CM.FORMATION`).
  #
  # `clubs.formation` guarda la clave de la formación del club y
  # `lineup_slots.slot` el `db` de cada hueco.
  class Formation
    # `position`: clave de `players.primary_position`. `x`/`y`: % en el campo.
    Slot = Data.define(:key, :label, :position, :x, :y, :db)

    attr_reader :key, :name, :slots

    def initialize(key:, name:, slots:)
      @key = key
      @name = name
      @slots = slots.freeze
    end

    ALL = {
      "4-1-4-1" => new(
        key: "4-1-4-1",
        name: "1-4-1-4-1",
        slots: [
          Slot.new(key: "gk", label: "POR", position: "po", x: 50, y: 90, db: 0),
          Slot.new(key: "lb", label: "DFI", position: "dfi", x: 12, y: 71, db: 1),
          Slot.new(key: "cbl", label: "DFC", position: "dfc", x: 36, y: 77, db: 2),
          Slot.new(key: "cbr", label: "DFC", position: "dfc", x: 64, y: 77, db: 3),
          Slot.new(key: "rb", label: "DFD", position: "dfd", x: 88, y: 71, db: 4),
          Slot.new(key: "cdm", label: "MCD", position: "mcd", x: 50, y: 57, db: 5),
          Slot.new(key: "lm", label: "MI", position: "mi", x: 12, y: 36, db: 6),
          Slot.new(key: "cml", label: "MC", position: "mc", x: 37, y: 41, db: 7),
          Slot.new(key: "cmr", label: "MC", position: "mc", x: 63, y: 41, db: 8),
          Slot.new(key: "rm", label: "MD", position: "md", x: 88, y: 36, db: 9),
          Slot.new(key: "st", label: "DC", position: "dc", x: 50, y: 15, db: 10)
        ]
      )
    }.freeze

    DEFAULT_KEY = "4-1-4-1"

    # Clave desconocida o nil → la formación por defecto.
    def self.fetch(key)
      ALL.fetch(key.to_s) { ALL.fetch(DEFAULT_KEY) }
    end

    # Hueco por clave ("gk", "cbl", …) o nil.
    def slot(key)
      slots.find { |slot| slot.key == key.to_s }
    end

    def slot_keys
      slots.map(&:key)
    end

    def size
      slots.size
    end

    # :exact (misma posición), :line (misma línea POR/DEF/MED/DEL) u :off.
    def fit_of(position_key, slot)
      return :exact if position_key.to_s == slot.position
      return :line if PlayersCatalog.group_of(position_key) == PlayersCatalog.group_of(slot.position)

      :off
    end
  end
end
