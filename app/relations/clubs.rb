# frozen_string_literal: true

module Fcmanager
  module Relations
    class Clubs < Fcmanager::DB::Relation
      schema :clubs, infer: true
    end
  end
end
