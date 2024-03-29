# frozen_string_literal: true

module Definitions
  class TimestampsQueryDefinitions < Db2Query::Definitions
    def describe
      query_definition :all do |c|
        c.id    :integer
        c.name  :string
        c.data  :timestamp
      end

      query_definition :insert do |c|
        c.id    :integer
        c.name  :string
        c.data  :timestamp
      end
    end
  end
end
