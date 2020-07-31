# frozen_string_literal: true

require "odbc_utf8"
require "db2_query/odbc_connector"
require "db2_query/database_statements"

module ActiveRecord
  module ConnectionHandling
    def db2_query_connection(config)
      conn_type = (config.keys & DB2Query::CONNECTION_TYPES).first
      if conn_type.nil?
        raise ArgumentError, "No data source name (:dsn) or connection string (:conn_str) provided."
      end
      connector = DB2Query::ODBCConnector.new(conn_type, config)
      ConnectionAdapters::DB2QueryConnection.new(connector, config)
    end
  end

  module ConnectionAdapters
    class DB2QueryConnection
      ADAPTER_NAME = "DB2Query"

      include DB2Query::DatabaseStatements
      include ActiveSupport::Callbacks
      define_callbacks :checkout, :checkin

      set_callback :checkin, :after, :enable_lazy_transactions!

      attr_accessor :pool
      attr_reader :owner, :connector, :lock
      alias :in_use? :owner

      def initialize(connector, config)
        @connector = connector
        @instrumenter  = ActiveSupport::Notifications.instrumenter
        @config = config
        @pool = ActiveRecord::ConnectionAdapters::NullPool.new
        @lock = ActiveSupport::Concurrency::LoadInterlockAwareMonitor.new
        connect
      end

      def adapter_name
        self.class::ADAPTER_NAME
      end

      def begin_transaction(options = {})
      end

      def connect
        @connection = connector.connect
        @connection.use_time = true
      end

      def active?
        @connection.connected?
      end

      def reconnect!
        disconnect!
        connect
      end
      alias reset! reconnect!

      def disconnect!
        if @connection.connected?
          @connection.commit
          @connection.disconnect
        end
      end

      def check_version
      end

      def enable_lazy_transactions!
        @lazy_transactions_enabled = true
      end

      def lease
        if in_use?
          msg = +"Cannot lease connection, "
          if @owner == Thread.current
            msg << "it is already leased by the current thread."
          else
            msg << "it is already in use by a different thread: #{@owner}. " \
                   "Current thread: #{Thread.current}."
          end
          raise ActiveRecordError, msg
        end

        @owner = Thread.current
      end

      def verify!
        reconnect! unless active?
      end

      def translate_exception_class(e, sql, binds)
        message = "#{e.class.name}: #{e.message}"

        exception = translate_exception(
          e, message: message, sql: sql, binds: binds
        )
        exception.set_backtrace e.backtrace
        exception
      end

      def log(sql, name = "SQL", binds = [], type_casted_binds = [], statement_name = nil) # :doc:
        @instrumenter.instrument(
          "sql.active_record",
          sql:               sql,
          name:              name,
          binds:             binds,
          type_casted_binds: type_casted_binds,
          statement_name:    statement_name,
          connection_id:     object_id,
          connection:        self) do
          @lock.synchronize do
            yield
          end
        rescue => e
          raise translate_exception_class(e, sql, binds)
        end
      end

      def translate_exception(exception, message:, sql:, binds:)
        case exception
        when RuntimeError
          exception
        else
          ActiveRecord::StatementInvalid.new(message, sql: sql, binds: binds)
        end
      end

      def expire
        if in_use?
          if @owner != Thread.current
            raise ActiveRecordError, "Cannot expire connection, " \
              "it is owned by a different thread: #{@owner}. " \
              "Current thread: #{Thread.current}."
          end

          @idle_since = Concurrent.monotonic_time
          @owner = nil
        else
          raise ActiveRecordError, "Cannot expire connection, it is not currently leased."
        end
      end

      def steal!
        if in_use?
          if @owner != Thread.current
            pool.send :remove_connection_from_thread_cache, self, @owner

            @owner = Thread.current
          end
        else
          raise ActiveRecordError, "Cannot steal connection, it is not currently leased."
        end
      end

      def seconds_idle # :nodoc:
        return 0 if in_use?
        Concurrent.monotonic_time - @idle_since
      end
    end
  end
end
