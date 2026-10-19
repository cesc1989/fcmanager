# frozen_string_literal: true

module Fcmanager
  module Repos
    class ClubRepo < Fcmanager::DB::Repo
      def grimsby_town
        clubs.where(name: "Grimsby Town").one
      end

      def free_agent
        clubs.where(name: "Agente Libre").one
      end
    end
  end
end
