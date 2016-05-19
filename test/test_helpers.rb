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
		'ancestors' => 'name STRING, description STRING, seqnum INTEGER, thing_id INTEGER',
		'children' => 'name STRING, description STRING, seqnum INTEGER, ancestor_id INTEGER',
		'things' => 'name STRING, description STRING, seqnum INTEGER, ancestor_id INTEGER',
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

class Ancestor < ActiveRecord::Base
	has_many :children

	def self.populate(count = 3)
		(1..count).each do |i|
			self.create(name: "name#{i}", description: "desc#{i}", seqnum: i)
		end
	end
end

class Thing < ActiveRecord::Base
	has_one :ancestor

	def self.populate(count = 3, ancestor = nil)
		ancestor = Ancestor.all.first unless ancestor
		(1..count).each do |i|
			self.create(name: "name#{i}", description: "desc#{i}", seqnum: i, ancestor: ancestor)
		end
	end
end

class Child < ActiveRecord::Base
	belongs_to :ancestor
	validates_presence_of :ancestor

	def self.populate(count = 3, ancestor = nil)
		ancestor = Ancestor.all.first unless ancestor
		(1..count).each do |i|
			self.create(name: "name#{i}", description: "desc#{i}", seqnum: i, ancestor: ancestor)
		end
	end
end
