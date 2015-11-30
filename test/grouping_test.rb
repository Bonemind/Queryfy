require 'bundler/setup'
require 'active_record'
require 'minitest/autorun'
require 'queryfy'
require_relative 'test_helpers'

setup!

class GroupingTest < test_framework
	def setup
		ActiveRecord::Base.connection.tables.each do |table|
			ActiveRecord::Base.connection.execute "DELETE FROM #{table}"
		end
		TestModel.populate(3)
	end

	def test_nested_and_or
		query_string = '(name=="name1"&&description=="desc1")||description=="desc2"'
		assert_equal 2, TestModel.queryfy(query_string)[:data].count
	end

	def test_and_then_nested_or
		query_string = 'name=="name2"&&(description=="desc1"||description=="desc2")'
		assert_equal 1, TestModel.queryfy(query_string)[:data].count

		query_string = 'name=="name2"&&(description=="desc1"||description=="desc3")'
		assert_equal 0, TestModel.queryfy(query_string)[:data].count
	end

	def test_multi_and
		query_string = 'name=="name2"&&(description=="desc2"&&name=="desc3")'
		assert_equal 0, TestModel.queryfy(query_string)[:data].count

		query_string = 'name=="name2"&&(description=="desc2"&&name=="name2")'
		assert_equal 1, TestModel.queryfy(query_string)[:data].count
	end

	def test_multi_or
		query_string = 'name=="name2"||(description=="desc2"||description=="desc3")'
		assert_equal 2, TestModel.queryfy(query_string)[:data].count

		query_string = 'name=="name2"||(description=="desc2"||name=="name2")'
		assert_equal 1, TestModel.queryfy(query_string)[:data].count
	end

	def test_multi_nested_or
		query_string = 'name=="name2"||(description=="desc2"||(description=="desc3"||description=="desc1"))'
		assert_equal 3, TestModel.queryfy(query_string)[:data].count

		query_string = 'name=="name2"||(description=="desc2"||(name=="name2"||name=="name1"))'
		assert_equal 2, TestModel.queryfy(query_string)[:data].count
	end

	def test_multi_nested_and
		query_string = 'name=="name2"&&(description=="desc2"&&(description=="desc3"&&description=="desc1"))'
		assert_equal 0, TestModel.queryfy(query_string)[:data].count

		query_string = 'name=="name2"&&(description=="desc2"&&(name=="name2"&&name=="name1"))'
		assert_equal 0, TestModel.queryfy(query_string)[:data].count

		query_string = 'name=="name2"&&(description=="desc2"&&(name=="name2"&&name=="name2"))'
		assert_equal 1, TestModel.queryfy(query_string)[:data].count
	end

	def test_multi_nested_and_then_or
		query_string = 'name=="name2"&&(description=="desc2"&&(name=="name2"&&name=="name1"))||name=="name1"'
		assert_equal 1, TestModel.queryfy(query_string)[:data].count

		query_string = 'name=="name2"&&(description=="desc2"&&(name=="name2"&&name=="name1"))||name=~"%name%"'
		assert_equal 3, TestModel.queryfy(query_string)[:data].count
	end
end
