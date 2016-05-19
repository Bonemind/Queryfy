require 'bundler/setup'
require 'active_record'
require 'minitest/autorun'
require 'queryfy'
require_relative 'test_helpers'
require 'rack'
require 'pry'
require 'pp'


setup!

class NestingTest < test_framework
	def setup
		ActiveRecord::Base.connection.tables.each do |table|
			ActiveRecord::Base.connection.execute "DELETE FROM #{table}"
		end
	end

	

	def test_ordering_query
		Ancestor.populate(5)
		first = Ancestor.all.first
		last = Ancestor.all.last
		Child.populate(3, first)
		querystring = 'ancestorid==1'
		assert_equal Child.all.size, 3
		pp Child.queryfy(querystring)[:data]


		assert_equal Child.all.first.ancestor.id, Ancestor.all.first.id
	end
end
