# frozen_string_literal: true

module Fcmanager
  module Repos
    class ClubRepo < Fcmanager::DB::Repo
      def grimsby_town
        clubs.where(name: "Grimsby Town").one
      end
    end
  end
end
