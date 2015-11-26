require 'bundler/setup'
require 'active_record'
require 'minitest/autorun'
require 'queryfy'
require_relative 'test_helpers'

setup!

class ConditionTest < test_framework
	def setup
		ActiveRecord::Base.connection.tables.each do |table|
			ActiveRecord::Base.connection.execute "DELETE FROM #{table}"
		end
		TestModel.populate(3)
	end

	def test_single_and
		query_string = 'name=="name1"&&description=="desc1"'
		assert_equal 1, TestModel.queryfy(query_string).count

		query_string = 'name=="name2"&&description=="desc1"'
		assert_equal 0, TestModel.queryfy(query_string).count
	end

	def test_single_or
		query_string = 'name=="name1"||description=="desc1"'
		assert_equal 1, TestModel.queryfy(query_string).count

		query_string = 'name=="name2"||description=="desc1"'
		assert_equal 2, TestModel.queryfy(query_string).count
	end

	def test_and_then_or
		query_string = 'name=="name1"&&description=="desc1"||description=="desc1"'
		assert_equal 1, TestModel.queryfy(query_string).count

		query_string = 'name=="name2"&&description=="desc1"||description=="desc2"'
		assert_equal 1, TestModel.queryfy(query_string).count

		query_string = 'name=="name2"&&description=="desc1"||description=~"%desc%"'
		assert_equal 3, TestModel.queryfy(query_string).count
	end

	def test_or_then_and
		query_string = 'description=="desc1"||name=="name1"&&description=="desc1"'
		assert_equal 1, TestModel.queryfy(query_string).count

		query_string = 'description=="desc1"||name=="name2"&&description=="desc1"'
		assert_equal 1, TestModel.queryfy(query_string).count
	end

	def test_and_and
		query_string = 'description=="desc1"&&name=="name1"&&seqnum==1'
		assert_equal 1, TestModel.queryfy(query_string).count

		query_string = 'description=="desc1"&&name=="name1"&&seqnum==2'
		assert_equal 0, TestModel.queryfy(query_string).count
	end

	def test_or_or
		query_string = 'description=="desc1"||name=="name1"||seqnum==1'
		assert_equal 1, TestModel.queryfy(query_string).count

		query_string = 'description=="desc1"||name=="name1"||seqnum==2'
		assert_equal 2, TestModel.queryfy(query_string).count
	end
end
