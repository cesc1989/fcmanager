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

      def find(id)
        players.by_pk(id).one
      end

      def update(id, attributes)
        players.by_pk(id).changeset(:update, attributes).commit
      end
    end
  end
end
