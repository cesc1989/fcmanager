# frozen_string_literal: true

module Fcmanager
  # Once de un club: qué jugador (id) ocupa cada hueco de su formación.
  #
  # Port de la parte de alineación de `js/store.js` del prototipo (`slotOf`,
  # `assign`, `clearSlot`, `benchPlayer`, `clearLineup`, `autoFill`).
  #
  # Es inmutable: cada operación devuelve un Lineup nuevo. Solo admite ids de
  # `squad_ids` (la plantilla); el resto se descarta en silencio.
  class Lineup
    attr_reader :formation, :squad_ids

    # "12" → 12; "abc", "", "3x", nil → nil. Base 10 ("012" → 12).
    def self.parse_id(value)
      Integer(value.to_s, 10, exception: false)
    end

    # `assignments`: {"gk" => 3, "st" => 9}. Descarta huecos que no son de la
    # formación, ids fuera de `squad_ids` y jugadores repetidos (gana el primer
    # hueco en el orden de la formación).
    def initialize(formation, assignments = {}, squad_ids:)
      @formation = formation
      @squad_ids = squad_ids.to_a
      @assignments = clean(assignments)
    end

    def to_h
      @assignments.dup
    end

    def player_in(slot_key)
      @assignments[slot_key.to_s]
    end

    def slot_of(player_id)
      @assignments.key(player_id)
    end

    def count
      @assignments.size
    end

    # Media redondeada del `overall` de los alineados, o nil si no hay ninguno.
    def average(players)
      overalls = players.select { |player| slot_of(player.id) }.map { |player| player.overall.to_i }

      return nil if overalls.empty?

      (overalls.sum.to_f / overalls.size).round
    end

    # Coloca al jugador en el hueco. Si venía de otro hueco, el ocupante pasa a
    # ese hueco (intercambio); si venía de la lista, el ocupante sale del once.
    def assign(slot_key, player_id)
      slot_key = slot_key.to_s

      return self unless formation.slot(slot_key) && squad_ids.include?(player_id)

      previous = slot_of(player_id)

      return self if previous == slot_key

      occupant = player_in(slot_key)
      changed = to_h.merge(slot_key => player_id)

      changed.delete(previous) if previous
      changed[previous] = occupant if previous && occupant

      with(changed)
    end

    def clear(slot_key)
      with(to_h.except(slot_key.to_s))
    end

    def bench(player_id)
      slot_key = slot_of(player_id)

      slot_key ? clear(slot_key) : self
    end

    def clear_all
      with({})
    end

    # Rellena los huecos vacíos por `overall` desc (empate: id asc): primero
    # con jugadores de la posición exacta y luego con los de la misma línea.
    def auto_fill(players)
      squad = players.select { |player| squad_ids.include?(player.id) }
      ranked = squad.sort_by { |player| [-player.overall.to_i, player.id] }
      changed = to_h
      taken = changed.values

      %i[exact line].each do |pass|
        formation.slots.each do |slot|
          next if changed.key?(slot.key)

          pick = ranked.find { |player| !taken.include?(player.id) && fits?(player, slot, pass) }

          next unless pick

          changed[slot.key] = pick.id
          taken << pick.id
        end
      end

      with(changed)
    end

    private

    def fits?(player, slot, pass)
      fit = formation.fit_of(player.primary_position, slot)

      pass == :exact ? fit == :exact : fit != :off
    end

    def with(assignments)
      self.class.new(formation, assignments, squad_ids: squad_ids)
    end

    def clean(assignments)
      seen = []

      formation.slot_keys.each_with_object({}) do |key, acc|
        id = assignments[key] || assignments[key.to_sym]

        next unless id && squad_ids.include?(id) && !seen.include?(id)

        acc[key] = id
        seen << id
      end
    end
  end
end
