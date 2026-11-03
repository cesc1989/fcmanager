# frozen_string_literal: true

module Fcmanager
  module Repos
    class LineupRepo < Fcmanager::DB::Repo
      # Once guardado del club, limitado a los jugadores de `squad_ids`.
      def for_club(club, squad_ids)
        formation = Formation.fetch(club[:formation])
        rows = lineup_slots.where(club_id: club[:id]).to_a
        assignments = rows.to_h { |row| [row[:slot], row[:player_id]] }

        Lineup.new(formation, assignments, squad_ids: squad_ids)
      end

      # Reemplaza el once guardado del club por `lineup`.
      def save(club, lineup)
        rows = lineup.to_h.map do |slot_key, player_id|
          {
            club_id: club[:id],
            slot: lineup.formation.slot(slot_key).db,
            player_id: player_id
          }
        end

        transaction do
          lineup_slots.where(club_id: club[:id]).delete
          lineup_slots.dataset.multi_insert(rows) unless rows.empty?
        end
      end

      # Carga el once, le aplica el bloque y guarda el resultado.
      def change(club, squad_ids)
        save(club, yield(for_club(club, squad_ids)))
      end
    end
  end
end
