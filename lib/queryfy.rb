require "queryfy/version"
require 'filter_lexer'
require 'queryfy/filter_lexer/formatter.rb'
require 'pp'
require 'pry'

module Queryfy
	# The start brace that denotes a conditiongroup
	START_BRACE = '('

	# The end brace that denotes a conditiongroup
	END_BRACE = ')'

	# Matches the contents of braces
	# For example: string (some (string (x)) aa) would result in:
	# 1: some (string (x)) aa
	# 2: string (x)
	# 3: x
	BRACE_MATCHER = /(?=\(((?:[^()]++|\(\g<1>\))++)\))/
	
	# Actually builds the query
	def self.build_query(querystring, klass)
		# Handle empty and nil queries
		if (querystring.nil? || querystring == '')
			return klass.all
		end

		tree = FilterLexer::Parser.parse(querystring)
		arel_tree = tree.to_arel(klass.arel_table)

		# Get pagination data
		# pagination = page_and_offset(querystring)
		# querystring = pagination[2]
		# page = pagination[0].to_i
		# limit = pagination[1].to_i

		# Calculate offset
		# offset = page * limit

		# Build the query with pagination
		query = klass.arel_table.project(Arel.star)

		# If we want to actually query, add the conditions to query
		query = query.where(arel_tree) unless arel_tree.nil?

		# Return the results
		return klass.find_by_sql(query.to_sql)
	end

	def self.group_to_arel(arel_table, elements, ast = nil)
		elements.each_with_index do |element, idx|
			next if element.is_a?(FilterLexer::LogicalOperator)
			operator = nil
			operator = elements[idx - 1] if idx > 0
			if element.is_a?(FilterLexer::Expression)
				puts 'expre'
				ast = join_ast(ast, element.to_arel(arel_table, ast), operator)
			elsif element.is_a?(FilterLexer::Group)
				ast = join_ast(ast, arel_table.grouping(element.to_arel(arel_table)), operator)
			elsif element.is_a?(FilterLexer::Filter)
				ast = element.to_arel(arel_table)
			end
		end
		return ast
	end

	def self.join_ast(ast, nodes, operator)
		if ast.nil? && !operator.nil?
			fail ('Cannot join on nil tree with operator')
		end
		if operator.nil? || ast.nil?
			ast = nodes
		else
			ast = ast.send(operator.to_arel, nodes)
		end
		return ast
	end

	private

	# Get page and offset
	# Remove page and offset from querystring
	def self.page_and_offset(str)
		condition_regex = Condition.regexify

		# Matches 0-1 Condition $page = number
		page_matcher = /(#{condition_regex})?\$page=([0-9]+)/

		# Matches 0-1 Condition $limit = number
		limit_matcher = /(#{condition_regex})?\$limit=([0-9]+)/
		page_match = str.match(page_matcher)
		limit_match = str.match(limit_matcher)

		page = 0
		limit = 50

		# If we have a page match, get the page number, and remove page from the string
		if page_match
			page = page_match[2]
			str = str.remove(page_match[0])
		end

		# If we have a limit match, get the limit number, and remove limit from the string
		if limit_match
			limit = limit_match[2]
			str = str.remove(limit_match[0])
		end

		return [page, limit, str]
	end
end

class ActiveRecord::Base
	def self.queryfy(querystring)
		return Queryfy.build_query(querystring, self)
	end
end
