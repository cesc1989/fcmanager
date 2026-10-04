# auto_register: false
# frozen_string_literal: true

module Fcmanager
  module Views
    module Helpers
      # Escala de colores de valoración usada en el prototipo.
      def rating_class(value)
        case value.to_i
        when 80.. then "is-elite"
        when 74...80 then "is-good"
        when 67...74 then "is-mid"
        else "is-low"
        end
      end
    end
  end
end
