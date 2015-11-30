require "queryfy/version"
require 'filter_lexer'
require 'queryfy/filter_lexer/formatter.rb'
require 'queryfy/queryfy_errors.rb'
require 'queryfy/configuration'
require 'active_record'

module Queryfy
	extend Configuration
	define_setting :max_limit, 100
	define_setting :default_limit, 50

	# Actually builds the query
	def self.build_query(klass, querystring, limit = 50, offset = 0)
		limit = [max_limit, limit.to_i].min
		# Handle empty and nil queries
		if (querystring.nil? || querystring == '')
			return {
				data: klass.limit(limit).offset(offset), 
				count: klass.all.count, 
				limit: limit.to_i, offset: offset.to_i
			}
		end

		begin
			tree = FilterLexer::Parser.parse(querystring)
		rescue FilterLexer::ParseException => e
			raise FilterParseError, "Failed to parse querystring, #{ e.message }"
			return
		end

		# Build the query with pagination
		query = klass.arel_table.project(Arel.star).take(limit).skip(offset)

		cleaned_tree = self.clean_tree(tree)
		arel_tree = self.cleaned_to_arel(klass.arel_table, cleaned_tree)
		# If we want to actually query, add the conditions to query
		query = query.where(arel_tree) unless arel_tree.nil?

		total = 0
		if arel_tree.nil?
			total = klass.all.count
		else
			countquery = klass.arel_table.project(klass.arel_table[klass.primary_key.to_sym].count.as('total')).where(arel_tree)
			results = klass.connection.execute(countquery.to_sql)
			if results.count == 0
				raise QueryfyError, 'Failed to select count, this should not happen'
			else
				total = results[0]['total']
			end
		end

		# Return the results
		return {data: klass.find_by_sql(query.to_sql), count: total.to_i, limit: limit.to_i, offset: offset.to_i}
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

	def self.from_queryparams(klass, queryparams)
		filter = ''
		offset = 0
		limit = Queryfy::default_limit
		if (queryparams.is_a?(Hash))
			filter = queryparams['filter'] unless queryparams['filter'].nil?
			offset = queryparams['offset'] unless queryparams['offset'].nil?
			limit = queryparams['limit'] unless queryparams['limit'].nil?
		elsif(queryparams.is_a?(String))
			filter = queryparams
		end
		return Queryfy.build_query(klass, filter, limit, offset)
	end
end
