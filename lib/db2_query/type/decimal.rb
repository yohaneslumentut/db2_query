# frozen_string_literal: true

module Db2Query
  module Type
    class Decimal < Value
      def type
        :decimal
      end

      def deserialize(value)
        value.to_f
      end
    end
  end
end
