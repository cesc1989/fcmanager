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

      def find_with_traits(id)
        players.combine(player_traits: :trait).by_pk(id).one
      end

      def update(id, attributes)
        players.by_pk(id).changeset(:update, attributes).commit
      end

      def create_with_traits(attributes, traits)
        transaction do
          player = players.changeset(:create, attributes).commit
          sync_traits(player.id, traits)
          player
        end
      end

      def update_with_traits(id, attributes, traits)
        transaction do
          players.by_pk(id).changeset(:update, attributes).commit
          sync_traits(id, traits)
        end
      end

      private

      def sync_traits(player_id, traits)
        traits.each do |trait_id, value|
          player_traits.upsert(
            {player_id: player_id, trait_id: trait_id, value: value},
            target: [:player_id, :trait_id],
            update: {value: value}
          )
        end
      end
    end
  end
end
