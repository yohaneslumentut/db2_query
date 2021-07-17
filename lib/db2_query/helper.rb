# frozen_string_literal: true

module Db2Query
  module Helper
    def self.included(base)
      base.send(:extend, ClassMethods)
    end

    module ClassMethods
      def sql_with_list(sql, list)
        validate_sql(sql)
        if sql.scan(/\@list+/).length == 0
          raise Db2Query::MissingListError, "Missing @list pointer at SQL"
        elsif !list.is_a?(Array)
          raise Db2Query::ListTypeError, "The arguments should be an array of list"
        else
          sql.gsub("@list", "'#{list.join("', '")}'")
        end
      end

      def sql_with_extention(sql, extention)
        validate_sql(sql)
        if sql.scan(/\@extention+/).length == 0
          raise Db2Query::ExtentionError, "Missing @extention pointer at SQL"
        else
          sql.gsub("@extention", extention.strip)
        end
      end

      private
        def trim_sql(sql)
          sql.tr("$", "")
        end

        def insert_sql?(sql)
          sql.match?(/insert/i)
        end

        def table_name_from_insert_sql(sql)
          sql.split("INTO ").last.split(" ").first
        end

        def sql_methods
          self.instance_methods.grep(/_sql/)
        end

        def sql_query_symbol(method_name)
          "#{method_name}_sql".to_sym
        end

        def sql_method?(method_name)
          sql_query_name = sql_query_symbol(method_name)
          sql_methods.include?(sql_query_name)
        end

        def parameters(sql)
          sql.scan(/\$\S+/).map { |key| key.gsub!(/[$=,)]/, "").to_sym }
        end

        def placeholder_length(sql)
          sql.scan(/\?/i).length
        end

        def bind_variables(sql)
          [sql, parameters(sql), placeholder_length(sql)]
        end

        def validate_sql(sql)
          raise Db2Query::Error, "SQL have to be in string format" unless sql.is_a?(String)
        end
    end
  end
end
