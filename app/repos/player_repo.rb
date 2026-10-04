# frozen_string_literal: true

module Fcmanager
  module Repos
    class PlayerRepo < Fcmanager::DB::Repo
      def create(attributes)
        players.changeset(:create, attributes).commit
      end
    end
  end
end
