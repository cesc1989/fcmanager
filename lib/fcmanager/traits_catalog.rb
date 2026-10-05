# frozen_string_literal: true

module Fcmanager
  # Agrupación y etiquetas de los traits para el formulario.
  module TraitsCatalog
    # Orden de los `kind` según el enum de `app/relations/traits.rb`.
    KIND_ORDER = %w[fisicos mentales tecnicos arqueria].freeze

    module_function

    def kind_label(kind)
      kind.to_s.upcase
    end

    # Devuelve [{kind:, label:, traits: [...]}] en orden, omitiendo grupos vacíos.
    def grouped(traits)
      KIND_ORDER.filter_map do |kind|
        group = traits.select { |trait| trait.kind.to_s == kind }
        next if group.empty?

        {kind: kind, label: kind_label(kind), traits: group}
      end
    end
  end
end
