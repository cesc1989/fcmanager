# frozen_string_literal: true

module Fcmanager
  module Actions
    module Squad
      class Create < Fcmanager::Action
        include Deps["repos.player_repo"]

        ROLES = {
          "Promesa" => 0,
          "Esporadico" => 1,
          "Rotacion" => 2,
          "Importante" => 3,
          "Esencial" => 4
        }.freeze

        POSITIONS = {
          "POR" => 0,
          "DFC" => 2,
          "LD" => 3,
          "LI" => 4,
          "MCD" => 5,
          "MC" => 6,
          "MD" => 7,
          "MI" => 8,
          "DC" => 12
        }.freeze

        FEET = {
          "derecho" => 0,
          "izquierdo" => 1
        }.freeze

        def handle(request, response)
          params = request.params
          name = params[:name].to_s.strip

          if name.empty?
            response.redirect_to("/squad")
            return
          end

          player_repo.create(
            name: name,
            age: params[:age].to_s,
            overall: params[:overall].to_s,
            role: ROLES.fetch(params[:role], 1),
            comment: params[:comment].to_s.empty? ? nil : params[:comment].to_s,
            height: params[:height].to_s,
            dominant_foot: FEET.fetch(params[:foot], 0),
            primary_position: POSITIONS.fetch(params[:position], 6)
          )

          response.redirect_to("/squad")
        end
      end
    end
  end
end
