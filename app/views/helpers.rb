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

      # Claves de `dominant_foot` → presentación.
      FOOT_LABELS = {
        "derecho" => "Derecho",
        "izquierdo" => "Izquierdo"
      }.freeze

      def foot_label(key)
        FOOT_LABELS.fetch(key.to_s, key.to_s)
      end

      def trait_short(name)
        normalized = name.to_s.unicode_normalize(:nfkd).gsub(/\p{Mn}/, "")
        normalized.upcase[0, 3]
      end

      # Opciones para los select del formulario de jugador.
      def position_options
        PlayersCatalog.position_options
      end

      def role_options
        PlayersCatalog.role_options
      end

      def foot_options
        PlayersCatalog.foot_options
      end

      # Traits agrupados por `kind` para el formulario.
      def grouped_traits(traits)
        TraitsCatalog.grouped(traits)
      end

      # Valor a mostrar en el input de un trait: primero lo enviado en los params
      # (para repoblar en un 422), luego el valor guardado, y por defecto 50.
      def trait_value(trait_id, values)
        submitted = request.params.dig(:player, :traits)

        if submitted.is_a?(Hash)
          value = submitted[trait_id] || submitted[trait_id.to_s]
          return value unless value.nil? || value.to_s.empty?
        end

        stored = values.is_a?(Hash) ? values.dig(:traits, trait_id) : nil
        stored.nil? ? PlayerForm::DEFAULT_TRAIT_VALUE : stored
      end

      # Etiquetas legibles para el resumen de errores del formulario de jugador.
      PLAYER_FIELD_LABELS = {
        name: "Nombre",
        age: "Edad",
        position: "Posición",
        role: "Rol",
        overall: "Promedio",
        height: "Altura",
        foot: "Pie dominante",
        comment: "Comentario"
      }.freeze

      # Aplana el árbol de errores de `request.params.errors` a una lista de
      # mensajes con el nombre del campo (p. ej. "Edad: must be less than ...").
      def error_messages(errors)
        collect_error_messages(errors.to_h).map do |keys, message|
          label = PLAYER_FIELD_LABELS[keys.last] || keys.last.to_s.capitalize
          "#{label}: #{message}"
        end
      end

      # Devuelve los mensajes de error para un campo anidado (p. ej. `:player, :name`).
      def field_errors(errors, *keys)
        value = keys.reduce(errors.to_h) do |node, key|
          break [] unless node.respond_to?(:[])

          found = node[key] || node[key.to_s]
          break [] if found.nil?

          found
        end

        value.is_a?(Array) ? value : []
      end

      private

      def collect_error_messages(node, keys = [], acc = [])
        case node
        when Hash then node.each { |key, value| collect_error_messages(value, keys + [key], acc) }
        when Array then node.each { |message| acc << [keys, message] }
        else acc << [keys, node.to_s]
        end

        acc
      end
    end
  end
end
