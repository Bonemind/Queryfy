require 'bundler/setup'
require 'active_record'
require 'minitest/autorun'
require 'queryfy'

test_framework = defined?(MiniTest::Test) ? MiniTest::Test : MiniTest::Unit::TestCase

def connect!
	ActiveRecord::Base.establish_connection adapter: 'sqlite3', database: ':memory:'
end

def setup!
	puts 'connect'
	connect!
	{
		'test_models' => 'name STRING, description STRING',
		'plain_models' => 'name STRING, description STRING'
	}.each do |table_name, columns_as_string|
		ActiveRecord::Base.connection.execute "CREATE TABLE #{table_name} (id INTEGER NOT NULL PRIMARY KEY, #{columns_as_string})"
	end
end

setup!

class QueryfyTest < test_framework
	def setup
		ActiveRecord::Base.connection.tables.each do |table|
			ActiveRecord::Base.connection.execute "DELETE FROM #{table}"
		end
	end

	def teardown
	end

	def test_has_queryfy
		assert(TestModel.respond_to?(:queryfy))
	end

	def test_no_queryfy
		assert(!PlainModel.respond_to?(:queryfy))
	end

	def test_returns_all_with_empty_query
		TestModel.populate
		query_string = ''
		assert(TestModel.queryfy(query_string).count == 3);
	end

	def test_returns_all_with_nil_query
		TestModel.populate
		query_string = nil
		assert(TestModel.queryfy(query_string).count == 3);
	end
end

class TestModel < ActiveRecord::Base
	include Queryfy

	def self.populate
		self.create(name: '1', description: '2')
		self.create(name: '3', description: '4')
		self.create(name: '5', description: '6')
	end
end

class PlainModel
end
