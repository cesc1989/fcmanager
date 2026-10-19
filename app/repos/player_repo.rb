# frozen_string_literal: true

module Fcmanager
  module Repos
    class PlayerRepo < Fcmanager::DB::Repo
      def create(attributes)
        players.changeset(:create, attributes).commit
      end

      def all
        players.combine(player_traits: :trait).to_a
          .sort_by { |player| [PlayersCatalog.position_rank(player.primary_position), player.id] }
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
        rows = traits.map { |trait_id, value| {player_id: player_id, trait_id: trait_id, value: value} }
        return if rows.empty?

        player_traits.dataset
          .insert_conflict(target: [:player_id, :trait_id], update: {value: Sequel[:excluded][:value]})
          .multi_insert(rows)
      end
    end
  end
end
