# DB2Query

[![Gem Version](https://badge.fury.io/rb/db2_query.svg)](https://badge.fury.io/rb/db2_query)

A Rails 6+ query plugin to fetch data from Db2 database by using ODBC connection

## Installation
Add this line to your application's Gemfile:

```ruby
gem 'db2_query'
```

And then execute:
```bash
$ bundle
```

Or install it yourself as:
```bash
$ gem install db2_query
```

## Initialization
Execute init task at the app root
```bash
$ rake db2query:init
```
DB2Query will generate two required files:
- `config/db2query_database.yml`
- `config/initializers/db2query`

Edit these files according to the requirement.

Note: 

To upgrade from the previous version to v.0.2.1, please delete all the files generated by init task and do init task again (don't forget to backup your db2query_database.yml).

In v.0.2.0, we have to `require 'db2_query'` at initializer manually.

### Database Configuration
At `db2query_database.yml` we can use two type of connection:
1. DSN connection config
2. Connection String config
```yml
development:
  primary:                          # Connection String Example
    adapter: db2_query
    conn_string:
      driver: DB2
      database: SAMPLE
      dbalias: SAMPLE
      hostname: LOCALHOST
      currentschema: LIBTEST
      port: "0"
      protocol: IPC
      uid: <%= ENV["DB2EC_UID"] %>
      pwd: <%= ENV["DB2EC_PWD"] %>
  secondary:
    adapter: db2_query             # DSN Example
    dsn: iseries
    uid: <%= ENV["ISERIES_UID"] %>
    pwd: <%= ENV["ISERIES_PWD"] %>
```

Ensure that `unixodbc` have been installed and test your connection first by using `isql` commands.

Example:

Secondary database connection test
```bash
$ isql -v iseries
+---------------------------------------+
| Connected!                            |
|                                       |
| sql-statement                         |
| help [tablename]                      |
| quit                                  |
|                                       |
+---------------------------------------+
SQL> 
```

## Usage
Note: Version 0.1.0 use `Db2Query` namespace. Please use `DB2Query` in versions other than it.

### Basic Usage
Create query class that inherit from `DB2Query::Base` in `app/queries` folder
```ruby
class User < DB2Query::Base
  query :find_by, <<-SQL
    SELECT * FROM LIBTEST.USERS WHERE id = ?
  SQL
end
```
Or use a normal sql method (don't forget the `_sql` suffix)
```ruby
class User < DB2Query::Base 
  def find_by_sql
    "SELECT * FROM LIBTEST.USERS WHERE id = ?"
  end
end
```
Check it at rails console
```bash
User.find_by 10000
SQL Load (3.28ms)  SELECT * FROM LIBTEST.USERS WHERE id = ? [[nil, 10000]]
=> #<DB2Query::Result @records=[#<Record id: 10000, first_name: "Strange", last_name: "Stephen", email: "strange@marvel.universe.com">]>
```
Or using keywords argument
```bash
User.by_name first_name: "Strange", last_name: "Stephen"
SQL Load (3.28ms)  SELECT * FROM LIBTEST.USERS WHERE first_name = ? AND last_name = ? [["first_name", Strange], ["last_name", Stephen]]
=> #<DB2Query::Result @records=[#<Record id: 10000, first_name: "Strange", last_name: "Stephen", email: "strange@marvel.universe.com">]>
```

### Formatter
In order to get different result column format, a query result can be reformatted by add a formatter class that inherit `DB2Query::AbstractFormatter` then register at `config\initializers\db2query.rb`
```ruby
require "db2_query/formatter"

# create a formatter class
class FirstNameFormatter < DB2Query::AbstractFormatter
  def format(value)
    "Dr." + value
  end
end

# register the formatter class
DB2Query::Formatter.registration do |format|
  format.register(:first_name_formatter, FirstNameFormatter)
end
```
Use it at query class
```ruby
class Doctor < User
  attributes :first_name, :first_name_formatter
end
```
Check it at rails console
```bash
Doctor.find_by id: 10000
SQL Load (3.28ms)  SELECT * FROM LIBTEST.USERS WHERE id = ? [["id", 10000]]
=> #<DB2Query::Result @records=[#<Record id: 10000, first_name: "Dr.Strange", last_name: "Stephen", email: "strange@marvel.universe.com">]>
```

### Available methods
`DB2Query::Result` inherit all `ActiveRecord::Result` methods with additional custom `records` method.

### ActiveRecord Combination

Create an abstract class that inherit from `ActiveRecord::Base`
```ruby
class DB2Record < ActiveRecord::Base
  self.abstract_class = true

  def self.query(sql, formatter = {}, args = [])
    DB2Query::Base.connection.exec_query(sql, formatter, args).to_a.map(&:deep_symbolize_keys)
  end
end
```

Utilize the goodness of rails model `scope`
```ruby
class User < DB2Record
  scope :by_name, -> *args {
    query(
      "SELECT * FROM LIBTEST.USERS WHERE first_name = ? AND last_name = ?", {}, args
    )
  }
end
```
Then, call it as usuall
```bash
User.by_name first_name: "Strange", last_name: "Stephen"
SQL Load (3.28ms)  SELECT * FROM LIBTEST.USERS WHERE first_name = ? AND last_name = ? [["first_name", Strange], ["last_name", Stephen]]
=> [{:id=> 10000, :first_name=> "Strange", :last_name=> "Stephen", :email=> "strange@marvel.universe.com"}]
```

## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
