# frozen_string_literal: true

module Fcmanager
  module Repos
    class PlayerRepo < Fcmanager::DB::Repo
      include Deps["repos.club_repo"]

      def create(attributes)
        players.changeset(:create, attributes).commit
      end

      def all
        players
          .where(club_id: club_repo.grimsby_town[:id])
          .combine(player_traits: :trait).to_a
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

      # Ids de la plantilla, sin cargar traits.
      def squad_ids
        players.where(club_id: club_repo.grimsby_town[:id]).pluck(:id)
      end

      # Saca al jugador de la plantilla pasándolo al club "Agente Libre" y lo
      # quita del once.
      def release(id)
        transaction do
          lineup_slots.where(player_id: id).delete

          update(id, club_id: club_repo.free_agent[:id])
        end
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
