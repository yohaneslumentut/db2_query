# frozen_string_literal: true

module Definitions
  class BinaryQueryDefinitions < Db2Query::Definitions
    def describe
      query_definition :all do |c|
        c.id    :integer
        c.name  :string
        c.data  :string
      end

      query_definition :insert do |c|
        c.id    :integer
        c.name  :string
        c.data  :binary
      end
    end
  end
end
