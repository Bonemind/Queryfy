require 'bundler/setup'
require 'active_record'
require 'minitest/autorun'
require 'queryfy'
require_relative 'test_helpers'

setup!

class QueryfyTest < test_framework
	def setup
		ActiveRecord::Base.connection.tables.each do |table|
			ActiveRecord::Base.connection.execute "DELETE FROM #{table}"
		end
	end

	def test_has_queryfy
		assert(TestModel.respond_to?(:queryfy))
	end

	def test_no_queryfy
		assert(!PlainModel.respond_to?(:queryfy))
	end

	def test_returns_all_with_empty_query
		TestModel.populate(3)
		query_string = ''
		assert_equal 3, TestModel.queryfy(query_string).count
	end

	def test_returns_all_with_nil_query
		TestModel.populate(3)
		query_string = nil
		assert_equal 3, TestModel.queryfy(query_string).count
	end
end
