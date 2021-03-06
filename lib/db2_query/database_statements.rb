# frozen_String_literal: true

module DB2Query
  module DatabaseStatements
    def query(sql)
      stmt = @connection.run(sql)
      stmt.to_a
    ensure
      stmt.drop unless stmt.nil?
      close
    end

    def query_rows(sql)
      query(sql)
    end

    def query_value(sql)
      single_value_from_rows(query(sql))
    end

    def query_values(sql)
      query(sql).map(&:first)
    end

    def execute(sql, args = [])
      @connection.do(sql, *args)
    end

    def exec_query(formatters, sql, args = [])
      binds, args = extract_binds_from_sql(sql, args)
      log(sql, "SQL", binds, args) do
        sql = exec_query_sql(sql)
        begin
          if args.empty?
            stmt = @connection.run(sql)
          else
            stmt = @connection.run(sql, *args)
          end
          columns = stmt.columns.values.map { |col| col.name.downcase }
          rows = stmt.to_a
        ensure
          stmt.drop unless stmt.nil?
          close
        end
        DB2Query::Result.new(columns, rows, formatters)
      end
    end

    private
      def single_value_from_rows(rows)
        row = rows.first
        row && row.first
      end

      def key_finder_regex(k)
        /#{k} .\\? | #{k}.\\? | #{k}. \\? /i
      end

      def extract_binds_from_sql(sql, args)
        question_mark_positions = sql.enum_for(:scan, /\?/i).map { Regexp.last_match.begin(0) }
        args = args.first.is_a?(Hash) ? args.first : args
        given, expected = args.length, question_mark_positions.length

        if given != expected
          raise DB2Query::Error, "wrong number of arguments (given #{given}, expected #{expected})"
        end

        if args.is_a?(Hash)
          binds = args.map do |key, value|
            position = sql.enum_for(:scan, key_finder_regex(key)).map { Regexp.last_match.begin(0) }
            if position.empty?
              raise DB2Query::Error, "Column name: `#{key}` not found inside sql statement."
            elsif position.length > 1
              raise DB2Query::Error, "Can't handle such this kind of sql. Please refactor your sql."
            else
              index = position[0]
            end

            DB2Query::Bind.new(key.to_s, value, index)
          end
          binds = binds.sort_by { |bind| bind.index }
          [binds.map { |bind| [bind, bind.value] }, binds.map { |bind| bind.value }]
        elsif question_mark_positions.length == 1 && args.length == 1
          column = sql[/(.*?) . \?|(.*?) .\?|(.*?). \?|(.*?).\?/m, 1].split.last.downcase
          bind = DB2Query::Bind.new(column.gsub(/[)(]/, ""), args, 0)
          [[[bind, bind.value]], bind.value]
        else
          [args.map { |arg| [nil, arg] }, args]
        end
      end

      def iud_sql?(sql)
        sql.match?(/insert into|update|delete/i)
      end

      def iud_ref_table(sql)
        sql.match?(/delete/i) ? "OLD TABLE" : "NEW TABLE"
      end

      def exec_query_sql(sql)
        if iud_sql?(sql)
          "SELECT * FROM #{iud_ref_table(sql)} (#{sql})"
        else
          sql
        end
      end
  end
end
