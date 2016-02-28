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
		begin
			TestModel.queryfy(querystring)
		rescue NoSuchFieldError => e
			assert_equal e.field, 'aaaaaa'
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

	def test_max_limit
		TestModel.populate(150)
		querystring = "limit=30"
		resp = TestModel.queryfy(Rack::Utils.parse_nested_query(querystring))
		assert_equal 30, resp[:data].count

		querystring = 'limit=50'
		resp = TestModel.queryfy(Rack::Utils.parse_nested_query(querystring))
		assert_equal 50, resp[:data].count

		querystring = 'limit=100'
		resp = TestModel.queryfy(Rack::Utils.parse_nested_query(querystring))
		assert_equal 100, resp[:data].count

		querystring = 'limit=120'
		resp = TestModel.queryfy(Rack::Utils.parse_nested_query(querystring))
		assert_equal 100, resp[:data].count

		Queryfy.max_limit = 50

		querystring = 'limit=100'
		resp = TestModel.queryfy(Rack::Utils.parse_nested_query(querystring))
		assert_equal 50, resp[:data].count

		Queryfy.max_limit = 100
	end

	def test_config
		assert_equal 100, Queryfy.max_limit
		assert_equal 50, Queryfy.default_limit
		Queryfy.configuration do |config|
			config.max_limit = 50
			config.default_limit = 10
		end

		assert_equal 50, Queryfy.max_limit
		assert_equal 10, Queryfy.default_limit

		Queryfy.configuration do |config|
			config.max_limit = 100
			config.default_limit = 50
		end
		assert_equal 100, Queryfy.max_limit
		assert_equal 50, Queryfy.default_limit
	end

	def test_offset_string
		TestModel.populate(150)

		querystring = 'id>0'
		resp = Queryfy.build_query(TestModel, querystring, '', "50", "50")
		assert_equal 50, resp[:data].count
	end

	def test_multiple_ordering
		t1 = TestModel.create(name: '1', seqnum: 2)
		t2 = TestModel.create(name: '1', seqnum: 3)
		t3 = TestModel.create(name: '2', seqnum: 1)
		querystring = 'order=name,seqnum-'
		resp = TestModel.queryfy(Rack::Utils.parse_nested_query(querystring))
		assert_equal t2, resp[:data].first
	end

	def test_ordering_no_query
		TestModel.populate(10)
		querystring = 'order=seqnum-'
		resp = TestModel.queryfy(Rack::Utils.parse_nested_query(querystring))
		prev = 11
		resp[:data].each do |tm|
				  assert_equal true, tm.seqnum < prev
				  prev = tm.seqnum
		end
	end

	def test_ordering_query
		TestModel.populate(10)
		querystring = 'filter=seqnum>5&order=seqnum-'
		resp = TestModel.queryfy(Rack::Utils.parse_nested_query(querystring))
		assert_equal resp[:data].size, 5
		prev = 11
		resp[:data].each do |tm|
				  assert_equal true, tm.seqnum < prev
				  prev = tm.seqnum
		end
	end
end
