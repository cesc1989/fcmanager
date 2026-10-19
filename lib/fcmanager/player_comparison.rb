# frozen_string_literal: true

module Fcmanager
  # Enfrenta a dos jugadores para la página Comparar.
  #
  # Los jugadores deben venir con `player_traits: :trait` combinados (ver
  # `PlayerRepo#all`). `age` y `overall` se guardan como string en la DB, así
  # que aquí se pasan a entero antes de comparar.
  class PlayerComparison
    # Una fila enfrentada. `a`/`b` son nil si ese jugador no tiene el trait.
    # mode: :higher (gana el más alto) o :neutral (sin ganador, p. ej. la edad).
    Row = Data.define(:label, :a, :b, :mode, :tooltip) do
      def both?
        !a.nil? && !b.nil?
      end

      def diff
        both? ? a - b : nil
      end

      # :a, :b o nil (empate, modo neutral o falta un valor).
      def winner
        return nil unless mode == :higher && both? && !diff.zero?

        diff.positive? ? :a : :b
      end

      def diff_label
        return nil unless both?
        return "=" if diff.zero?

        size = diff.abs

        if mode == :higher
          diff.positive? ? "◀ +#{size}" : "+#{size} ▶"
        else
          diff.positive? ? "#{size} ▶" : "◀ #{size}"
        end
      end
    end

    Section = Data.define(:title, :rows)

    attr_reader :a, :b

    def initialize(player_a, player_b)
      @a = player_a
      @b = player_b
    end

    # "Datos" (Promedio, Edad) seguido de una sección por kind de trait.
    def sections
      [data_section, *trait_sections]
    end

    # Cuántos traits gana cada uno; solo filas de traits con valor en ambos lados.
    def wins
      rows = trait_sections.flat_map(&:rows).select(&:both?)

      {
        a: rows.count { |row| row.winner == :a },
        b: rows.count { |row| row.winner == :b },
        tie: rows.count { |row| row.diff.zero? }
      }
    end

    def different_lines?
      group(a) != group(b)
    end

    private

    def row(label, value_a, value_b, mode: :higher, tooltip: nil)
      Row.new(
        label: label,
        a: value_a,
        b: value_b,
        mode: mode,
        tooltip: tooltip
      )
    end

    def data_section
      Section.new(
        title: "Datos",
        rows: [
          row("Promedio", a.overall.to_i, b.overall.to_i),
          row("Edad", a.age.to_i, b.age.to_i, mode: :neutral, tooltip: age_tooltip)
        ]
      )
    end

    def trait_sections
      @trait_sections ||= kinds.filter_map do |kind|
        names = trait_names(kind)
        next if names.empty?

        rows = names.map { |name| row(name, trait_value(a, name), trait_value(b, name)) }

        Section.new(title: TraitsCatalog.kind_label(kind), rows: rows)
      end
    end

    # Arquería solo cuenta si alguno de los dos es portero.
    def kinds
      return TraitsCatalog::KIND_ORDER if [a, b].any? { |player| group(player) == "POR" }

      TraitsCatalog::KIND_ORDER - ["arqueria"]
    end

    # Unión de los traits de ambos de ese kind, para no perder los que tiene solo uno.
    def trait_names(kind)
      player_traits = [a, b].flat_map(&:player_traits).select { |pt| pt.trait.kind.to_s == kind }

      player_traits.map { |pt| pt.trait.name }.uniq.sort
    end

    def trait_value(player, name)
      player.player_traits.find { |pt| pt.trait.name == name }&.value
    end

    def age_tooltip
      diff = a.age.to_i - b.age.to_i
      return nil if diff.zero?

      younger = diff.positive? ? b : a
      years = diff.abs
      unit = years == 1 ? "año" : "años"

      "#{younger.name} es #{years} #{unit} más joven"
    end

    def group(player)
      PlayersCatalog.group_of(player.primary_position)
    end
  end
end
