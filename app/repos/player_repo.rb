# frozen_string_literal: true

module Fcmanager
  module Repos
    class PlayerRepo < Fcmanager::DB::Repo
      def create(attributes)
        players.changeset(:create, attributes).commit
      end

      def all
        players.combine(player_traits: :trait).order(:primary_position).to_a
      end
    end
  end
end
