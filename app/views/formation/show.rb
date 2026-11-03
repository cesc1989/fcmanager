# frozen_string_literal: true

module Fcmanager
  module Views
    module Formation
      class Show < Fcmanager::View
        expose :players, :lineup, :selected_id

        expose :players_by_id do |players|
          players.to_h { |player| [player.id, player] }
        end
      end
    end
  end
end
