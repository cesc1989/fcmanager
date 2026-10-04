# auto_register: false
# frozen_string_literal: true

module Fcmanager
  module Views
    module Helpers
      # Claves de `primary_position` (app/relations/players.rb) → presentación.
      POSITIONS = {
        "gk" => {short: "POR", group: "POR", label: "Portero"},
        "cb" => {short: "DFC", group: "DEF", label: "Defensa central"},
        "rb" => {short: "LD", group: "DEF", label: "Lateral derecho"},
        "lb" => {short: "LI", group: "DEF", label: "Lateral izquierdo"},
        "cdm" => {short: "MCD", group: "MED", label: "Mediocentro defensivo"},
        "cm" => {short: "MC", group: "MED", label: "Mediocentro"},
        "rm" => {short: "MD", group: "MED", label: "Interior derecho"},
        "lm" => {short: "MI", group: "MED", label: "Interior izquierdo"},
        "cam" => {short: "MP", group: "MED", label: "Mediapunta"},
        "rw" => {short: "ED", group: "DEL", label: "Extremo derecho"},
        "lw" => {short: "EI", group: "DEL", label: "Extremo izquierdo"},
        "cf" => {short: "DC", group: "DEL", label: "Delantero centro"}
      }.freeze

      # Claves de `role` (app/relations/players.rb) → presentación.
      ROLES = {
        "promesa" => "Promesa",
        "esporádico" => "Esporadico",
        "rotación" => "Rotacion",
        "importante" => "Importante",
        "esencial" => "Esencial"
      }.freeze

      # Escala de colores de valoración usada en el prototipo.
      def rating_class(value)
        case value.to_i
        when 80.. then "is-elite"
        when 74...80 then "is-good"
        when 67...74 then "is-mid"
        else "is-low"
        end
      end

      def position_info(key)
        POSITIONS.fetch(key.to_s, {short: "—", group: "MED", label: key.to_s})
      end

      def role_label(key)
        ROLES.fetch(key.to_s, key.to_s)
      end

      def trait_short(name)
        normalized = name.to_s.unicode_normalize(:nfkd).gsub(/\p{Mn}/, "")
        normalized.upcase[0, 3]
      end
    end
  end
end
