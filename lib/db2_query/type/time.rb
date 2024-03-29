# frozen_string_literal: true

module Db2Query
  module Type
    class Time < Value
      def type
        :time
      end

      def serialize(value)
        if value.is_a?(::String)
          case value
          when /\A(\d\d)[:,.](\d\d)[:,.](\d\d)\z/
            quote(value)
          else
            nil
          end
        elsif value.is_a?(::Time)
          quote(value.strftime("%T"))
        else
          nil
        end
      end

      def deserialize(value)
        value.strftime("%H:%M:%S")
      end
    end
  end
end
