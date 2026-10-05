# frozen_string_literal: true

module Fcmanager
  # Traducción entre los params validados del formulario y los atributos de la DB,
  # y viceversa para precargar la edición.
  module PlayerForm
    # Valor por defecto de cada característica.
    DEFAULT_TRAIT_VALUE = 50

    module_function

    def attributes(params)
      {
        name: params[:name].to_s.strip,
        age: params[:age].to_s,
        overall: params[:overall].to_s,
        role: PlayersCatalog.role_db(params[:role]),
        comment: params[:comment].to_s.empty? ? nil : params[:comment].to_s,
        height: params[:height].to_s,
        dominant_foot: PlayersCatalog.foot_db(params[:foot]),
        primary_position: PlayersCatalog.position_db(params[:position])
      }
    end

    def values(player)
      {
        name: player.name,
        age: player.age,
        position: PlayersCatalog.position_value(player.primary_position),
        role: PlayersCatalog.role_value(player.role),
        overall: player.overall,
        height: player.height,
        foot: PlayersCatalog.foot_value(player.dominant_foot),
        comment: player.comment.to_s,
        traits: player.player_traits.to_h { |pt| [pt.trait_id, pt.value] }
      }
    end

    # Normaliza el hash de traits: recorre todos los ids válidos, cae a 50 si
    # viene vacío o menor a 1, y clampa a 1..99.
    def traits(raw, allowed_ids)
      raw = {} unless raw.is_a?(Hash)

      allowed_ids.each_with_object({}) do |id, acc|
        value = raw[id] || raw[id.to_s]
        int = Integer(value, exception: false)
        acc[id] = (int.nil? || int < 1) ? DEFAULT_TRAIT_VALUE : int.clamp(1, 99)
      end
    end
  end
end
