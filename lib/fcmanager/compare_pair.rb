# frozen_string_literal: true

module Fcmanager
  # Pareja de jugadores de la página Comparar (cuadros A y B), tomada de `?a=&b=`.
  #
  # Es inmutable: cada operación devuelve una pareja nueva y `to_params` da los
  # query params del enlace correspondiente.
  class ComparePair
    attr_reader :a, :b

    # Descarta ids que no son enteros en base 10 o que no están en `allowed_ids`
    # (los ids de la plantilla).
    def self.from_params(params, allowed_ids)
      ids = %i[a b].map do |box|
        id = Integer(params[box].to_s, 10, exception: false)

        allowed_ids.include?(id) ? id : nil
      end

      new(*ids)
    end

    def initialize(a_id = nil, b_id = nil)
      @a = a_id
      @b = b_id == a_id ? nil : b_id
    end

    def complete?
      !a.nil? && !b.nil?
    end

    # :a, :b o nil.
    def box_of(id)
      return nil if id.nil?
      return :a if id == a
      return :b if id == b

      nil
    end

    # Clic en la lista: primer cuadro libre; si los dos están ocupados reemplaza el B.
    # Si el jugador ya está en un cuadro, no cambia nada.
    def with(id)
      return self if box_of(id)

      a.nil? ? self.class.new(id, b) : self.class.new(a, id)
    end

    def swap
      self.class.new(b, a)
    end

    def without(box)
      box == :a ? self.class.new(nil, b) : self.class.new(a, nil)
    end

    def to_params
      {a: a, b: b}.compact
    end
  end
end
