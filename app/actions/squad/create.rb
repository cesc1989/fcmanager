# frozen_string_literal: true

module Fcmanager
  module Actions
    module Squad
      class Create < Fcmanager::Action
        include Deps["repos.player_repo"]

        params do
          required(:player).hash do
            required(:name).filled(:string)
            required(:age).filled(:integer, gteq?: 15, lteq?: 45)
            required(:position).filled(:string)
            required(:role).filled(:string)
            required(:overall).filled(:integer, gteq?: 1, lteq?: 99)
            required(:height).filled(:integer, gteq?: 150, lteq?: 210)
            required(:foot).filled(:string)
            optional(:comment).maybe(:string)
          end
        end

        def handle(request, response)
          if request.params.valid?
            player_repo.create(player_attributes(request.params[:player]))
            response.redirect_to routes.path(:squad)
          else
            response.status = 422
          end
        end

        private

        def player_attributes(params)
          {
            name: params[:name].strip,
            age: params[:age].to_s,
            overall: params[:overall].to_s,
            role: PlayersCatalog.role_db(params[:role]),
            comment: params[:comment].to_s.empty? ? nil : params[:comment].to_s,
            height: params[:height].to_s,
            dominant_foot: PlayersCatalog.foot_db(params[:foot]),
            primary_position: PlayersCatalog.position_db(params[:position])
          }
        end
      end
    end
  end
end
