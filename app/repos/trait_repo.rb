# frozen_string_literal: true

module Fcmanager
  module Repos
    class TraitRepo < Fcmanager::DB::Repo
      def all
        traits.order(:kind, :name).to_a
      end

      def ids
        all.map(&:id)
      end
    end
  end
end
