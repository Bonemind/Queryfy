require 'bundler/setup'
require 'active_record'
require 'minitest/autorun'
require 'queryfy'
require_relative 'test_helpers'

setup!

class OperatorTest < test_framework
	def setup
		ActiveRecord::Base.connection.tables.each do |table|
			ActiveRecord::Base.connection.execute "DELETE FROM #{table}"
		end
	end

	def test_query_for_eql
		TestModel.populate(3)
		query_string = 'name=="name1"'
		assert_equal 1, TestModel.queryfy(query_string).count
	end

	def test_query_for_neql
		TestModel.populate(3)
		query_string = 'name!="name1"'
		assert_equal 2, TestModel.queryfy(query_string).count
	end

	def test_query_for_like
		TestModel.populate(3)
		query_string = 'name=~"%name%"'
		assert_equal 3, TestModel.queryfy(query_string).count
	end

	def test_query_for_ends_with
		TestModel.populate(3)
		query_string = 'name=~"%2"'
		assert_equal 1, TestModel.queryfy(query_string).count
	end

	def test_query_for_starts_with
		TestModel.populate(3)
		TestModel.create(name: 'something', description: '', seqnum: '7')
		query_string = 'name=~"name%"'
		assert_equal 3, TestModel.queryfy(query_string).count
	end

	def test_query_for_gt
		TestModel.populate(3)
		query_string = 'seqnum>1'
		assert_equal 2, TestModel.queryfy(query_string).count
	end

	def test_query_for_gt_eq
		TestModel.populate(3)
		query_string = 'seqnum>=1'
		assert_equal 3, TestModel.queryfy(query_string).count
	end

	def test_query_for_lt
		TestModel.populate(3)
		query_string = 'seqnum<3'
		assert_equal 2, TestModel.queryfy(query_string).count
	end

	def test_query_for_lt_eq
		TestModel.populate(3)
		query_string = 'seqnum<=3'
		assert_equal 3, TestModel.queryfy(query_string).count
	end
end
