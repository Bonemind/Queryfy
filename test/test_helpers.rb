require 'queryfy/core_ext'

def test_framework
	defined?(MiniTest::Test) ? MiniTest::Test : MiniTest::Unit::TestCase
end

def connect!
	ActiveRecord::Base.establish_connection adapter: 'sqlite3', database: ':memory:'
end

def setup!
	connect!
	{
		'test_models' => 'name STRING, description STRING, seqnum INTEGER',
		'actsas_models' => 'name STRING, description STRING, seqnum INTEGER'
	}.each do |table_name, columns_as_string|
		ActiveRecord::Base.connection.execute "CREATE TABLE #{table_name} (id INTEGER NOT NULL PRIMARY KEY, #{columns_as_string})"
	end
end


class TestModel < ActiveRecord::Base
	def self.populate(count = 3)
		(1..count).each do |i|
			self.create(name: "name#{i}", description: "desc#{i}", seqnum: i)
		end
	end
end
