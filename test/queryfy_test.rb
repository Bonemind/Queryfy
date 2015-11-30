require 'bundler/setup'
require 'active_record'
require 'minitest/autorun'
require 'queryfy'
require_relative 'test_helpers'
require 'rack'

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
		assert_equal 3, TestModel.queryfy(query_string)[:data].count
	end

	def test_returns_all_with_nil_query
		TestModel.populate(3)
		query_string = nil
		assert_equal 3, TestModel.queryfy(query_string)[:data].count
	end

	def test_raises_filter_parse_error
		querystring = 'aaaaaa'
		assert_raises FilterParseError do
			TestModel.queryfy(querystring)
		end
	end

	def test_raises_no_such_field_error
		querystring = 'aaaaaa==1'
		assert_raises NoSuchFieldError do
			TestModel.queryfy(querystring)
		end
	end

	def test_raises_are_queryfy_exceptions
		querystring = 'aaaaaa==1'
		assert_raises QueryfyError do
			TestModel.queryfy(querystring)
		end

		querystring = 'aaaaaa'
		assert_raises QueryfyError do
			TestModel.queryfy(querystring)
		end
	end

	def test_with_rack_hash
		TestModel.populate(3)
		filter = 'name=="name1"&&description=="desc1"'
		encoded = CGI.escape(filter)
		querystring = "filter=#{encoded}"
		assert_equal 1, TestModel.queryfy(Rack::Utils.parse_nested_query(querystring))[:data].count
	end

	def test_offset_only
		TestModel.populate(100)
		querystring = "offset=70"
		resp = TestModel.queryfy(Rack::Utils.parse_nested_query(querystring))
		assert_equal 30, resp[:data].count
		assert_equal 70, resp[:offset]
	end

	def test_offset_limit_only
		TestModel.populate(100)
		querystring = "offset=70&limit=10"
		resp = TestModel.queryfy(Rack::Utils.parse_nested_query(querystring))
		assert_equal 10, resp[:data].count
		assert_equal 70, resp[:offset]
		assert_equal 10, resp[:limit]
	end

	def test_limit_only
		TestModel.populate(100)
		querystring = "limit=10"
		resp = TestModel.queryfy(Rack::Utils.parse_nested_query(querystring))
		assert_equal 10, resp[:data].count
		assert_equal 10, resp[:limit]
	end

	def test_total_count
		TestModel.populate(100)
		querystring = "limit=10"
		resp = TestModel.queryfy(Rack::Utils.parse_nested_query(querystring))
		assert_equal 100, resp[:count]

		querystring = 'filter=name=="name1"&limit=10'
		resp = TestModel.queryfy(Rack::Utils.parse_nested_query(querystring))
		assert_equal 1, resp[:count]
	end
end
