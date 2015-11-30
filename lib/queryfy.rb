require "queryfy/version"
require 'filter_lexer'
require 'queryfy/filter_lexer/formatter.rb'
require 'queryfy/queryfy_errors.rb'

module Queryfy
	# Actually builds the query
	def self.build_query(querystring, klass)
		# Handle empty and nil queries
		if (querystring.nil? || querystring == '')
			return klass.all
		end

		begin
			tree = FilterLexer::Parser.parse(querystring)
		rescue FilterLexer::ParseException => e
			raise FilterParseError, "Failed to parse querystring, #{ e.message }"
			return
		end

		# Get pagination data
		# pagination = page_and_offset(querystring)
		# querystring = pagination[2]
		# page = pagination[0].to_i
		# limit = pagination[1].to_i

		# Calculate offset
		# offset = page * limit

		# Build the query with pagination
		query = klass.arel_table.project(Arel.star)

		cleaned_tree = self.clean_tree(tree)
		arel_tree = self.cleaned_to_arel(klass.arel_table, cleaned_tree)
		# If we want to actually query, add the conditions to query
		query = query.where(arel_tree) unless arel_tree.nil?

		# Return the results
		return klass.find_by_sql(query.to_sql)
	end

	# Cleans the filterlexer tree
	# Output is an array with either filterentries and operators, or an array of filterentries and operators
	# The latter represents a group
	def self.clean_tree(tree, input = [])
		tree.elements.each do |el|
			if el.is_a?(FilterLexer::Expression)
				input += clean_tree(el)
			elsif el.is_a?(FilterLexer::Group)
				input += [clean_tree(el)]
			else
				input.push(el)
			end
		end
		return input
	end

	# Converts a cleaned tree to something arel can understand
	def self.cleaned_to_arel(arel_table, tree, ast = nil)
		tree.each_with_index do |el, idx|
			next if el.is_a?(FilterLexer::LogicalOperator)
			operator = nil
			operator = tree[idx - 1] if idx > 0
			if el.is_a?(Array)
				ast = join_ast(ast, arel_table.grouping(cleaned_to_arel(arel_table, el)), operator)
			else
				ast = join_ast(ast, el.to_arel(arel_table), operator)
			end
		end

		return ast
	end

	# Merges an existing ast with the passed nodes and uses the operator as a merge operator
	def self.join_ast(ast, nodes, operator)
		if ast.nil? && !operator.nil?
			raise InvalidFilterFormat, "Cannot join on nil tree with operator near #{operator.text_value}"
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
