# frozen_string_literal: true

DB2_QUERY_INITIALIZER_TEMPLATE ||= <<-EOF
# frozen_string_literal: true

require "db2_query"
require "db2_query/formatter"

DB2Query::Base.initiation do |base|
  base.configurations = base.parent.config
  base.establish_connection ENV['RAILS_ENV'].to_sym
end

# Example

class FirstNameFormatter < DB2Query::AbstractFormatter
  def format(value)
    "Dr." + value
  end
end

DB2Query::Formatter.registration do |format|
  format.register(:first_name_formatter, FirstNameFormatter)
end
EOF

namespace :db2query do
  desc "Create Initializer file"
  task :initializer do
    # Create initializer file
    initializer_path = "#{Rails.root}/config/initializers/db2query.rb"
    if File.exist?(initializer_path)
      raise ArgumentError, "File exists."
    else
      puts "  Creating initializer file ..."
      File.open(initializer_path, "w") do |file|
        file.puts DB2_QUERY_INITIALIZER_TEMPLATE
      end
      puts "  File '#{initializer_path}' created."
    end
  end
end
