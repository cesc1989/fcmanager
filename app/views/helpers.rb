# auto_register: false
# frozen_string_literal: true

module Fcmanager
  module Views
    module Helpers
      # Cantidad de traits a mostrar por cada jugador en el index.
      #
      # Sin esto cada celda se estira demasiado hacía abajo.
      QTY_OF_TRAITS_TO_SHOW = 10

      # Claves de `primary_position` (app/relations/players.rb) → presentación.
      POSITIONS = {
        "po" => {short: "POR", group: "POR", label: "Portero"},
        "dfi" => {short: "DFI", group: "DEF", label: "Lateral izquierdo"},
        "dfc" => {short: "DFC", group: "DEF", label: "Defensa central"},
        "dfd" => {short: "DFD", group: "DEF", label: "Lateral derecho"},
        "mcd" => {short: "MCD", group: "MED", label: "Mediocentro defensivo"},
        "mi" => {short: "MI", group: "MED", label: "Interior izquierdo"},
        "mc" => {short: "MC", group: "MED", label: "Mediocentro"},
        "mco" => {short: "MCO", group: "MED", label: "Mediocentro ofensivo"},
        "md" => {short: "MD", group: "MED", label: "Interior derecho"},
        "ei" => {short: "EI", group: "DEL", label: "Extremo izquierdo"},
        "ed" => {short: "ED", group: "DEL", label: "Extremo derecho"},
        "dc" => {short: "DC", group: "DEL", label: "Delantero centro"}
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

      # Traits de un jugador agrupados por `kind`, ordenados por valor desc.
      def grouped_player_traits(player_traits)
        TraitsCatalog::KIND_ORDER.filter_map do |kind|
          group = player_traits
            .select { |pt| pt.trait.kind.to_s == kind }
            .sort_by { |pt| pt.trait.name }
          next if group.empty?

          {kind: kind, label: TraitsCatalog.kind_label(kind), traits: group}
        end
      end

      # Plantilla agrupada por línea para la lista de la página Comparar.
      def grouped_squad(players)
        PlayersCatalog::GROUPS.filter_map do |group|
          members = players.select { |player| PlayersCatalog.group_of(player.primary_position) == group[:key] }
          next if members.empty?

          {key: group[:key], label: group[:label], players: members}
        end
      end

      def compare_path(pair)
        routes.path(:compare, **pair.to_params)
      end

      # Clase de una pestaña del header según la ruta actual.
      def tab_class(section)
        path = request? ? request.path : ""
        active = case section
                 when :squad then path == "/" || path.start_with?("/squad")
                 when :compare then path.start_with?("/compare")
                 else false
                 end

        active ? "tab is-active" : "tab"
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
