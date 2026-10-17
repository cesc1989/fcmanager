# frozen_string_literal: true

module Fcmanager
  module Views
    module Squad
      class New < Fcmanager::View
        include Deps["routes"]

        expose :traits

        # decorate: false para que form_for reciba el Hash y no un Part.
        expose :player, decorate: false do
          PlayerForm::DEFAULTS
        end

        expose :form_action do
          routes.path(:squad)
        end

        expose :form_method do
          :post
        end

        expose :submit_label do
          "Guardar"
        end
      end
    end
  end
end
