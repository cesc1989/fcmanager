# auto_register: false
# frozen_string_literal: true

module Fcmanager
  module Views
    class Context < Hanami::View::Context
      include Deps["repos.club_repo"]

      def club_name
        club_repo.grimsby_town[:name]
      end

      def club_id
        club_repo.grimsby_town[:id]
      end
    end
  end
end
