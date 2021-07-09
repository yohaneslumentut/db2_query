# frozen_string_literal: true

require "db2_query"
require "rails"

module Db2Query
  class Railtie < ::Rails::Railtie
    railtie_name :db2_query

    rake_tasks do
      Dir.glob("#{Db2Query.root}/db2_query/tasks/*.rake").each { |f| load f }
    end

    config.app_generators do
      require "#{Db2Query.root}/rails/query_generator.rb"
    end
  end
end
