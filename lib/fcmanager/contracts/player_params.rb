# frozen_string_literal: true

require "dry/validation"

module Fcmanager
  module Contracts
    # Validación de params para crear y actualizar un jugador.
    # `:id` es opcional para poder reutilizarlo en el update.
    class PlayerParams < Dry::Validation::Contract
      params do
        optional(:id).filled(:integer)

        required(:player).hash do
          required(:name).filled(:string)
          required(:age).filled(:integer, gteq?: 15, lteq?: 45)
          required(:position).filled(:string)
          required(:role).filled(:string)
          required(:overall).filled(:integer, gteq?: 1, lteq?: 99)
          required(:height).filled(:integer, gteq?: 150, lteq?: 210)
          required(:foot).filled(:string)
          optional(:comment).maybe(:string)

          # Traits dinámicos: se conservan como hash y se sanitan en la acción.
          optional(:traits).hash
        end
      end
    end
  end
end
