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
		query_string = 'name=name1$AND$description=desc1'
		assert_equal 1, TestModel.queryfy(query_string).count

		query_string = 'name=name2$AND$description=desc1'
		assert_equal 0, TestModel.queryfy(query_string).count
	end

	def test_single_or
		query_string = 'name=name1$OR$description=desc1'
		assert_equal 1, TestModel.queryfy(query_string).count

		query_string = 'name=name2$OR$description=desc1'
		assert_equal 2, TestModel.queryfy(query_string).count
	end

	def test_and_then_or
		query_string = 'name=name1$AND$description=desc1$OR$description=desc1'
		assert_equal 1, TestModel.queryfy(query_string).count

		query_string = 'name=name2$AND$description=desc1$OR$description=desc1'
		assert_equal 1, TestModel.queryfy(query_string).count

		query_string = 'name=name2$AND$description=desc1$OR$description$CNT$desc'
		assert_equal 3, TestModel.queryfy(query_string).count
	end

	def test_or_then_and
		query_string = 'description=desc1$OR$name=name1$AND$description=desc1'
		assert_equal 1, TestModel.queryfy(query_string).count

		query_string = 'description=desc1$OR$name=name2$AND$description=desc1'
		assert_equal 1, TestModel.queryfy(query_string).count
	end

	def test_and_and
		query_string = 'description=desc1$AND$name=name1$AND$seqnum=1'
		assert_equal 1, TestModel.queryfy(query_string).count

		query_string = 'description=desc1$AND$name=name1$AND$seqnum=2'
		assert_equal 0, TestModel.queryfy(query_string).count
	end

	def test_or_or
		query_string = 'description=desc1$OR$name=name1$OR$seqnum=1'
		assert_equal 1, TestModel.queryfy(query_string).count

		query_string = 'description=desc1$OR$name=name1$OR$seqnum=2'
		assert_equal 2, TestModel.queryfy(query_string).count
	end
end
