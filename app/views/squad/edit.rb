# frozen_string_literal: true

module Fcmanager
  module Views
    module Squad
      class Edit < Fcmanager::View
        include Deps["routes"]

        expose :traits
        expose :player, decorate: false

        # player_id llega como input de la acción, no hace falta exponerlo.
        expose :form_action do |player_id:|
          routes.path(:update_squad, id: player_id)
        end

        expose :form_method do
          :patch
        end

        expose :submit_label do
          "Guardar cambios"
        end
      end
    end
  end
end
