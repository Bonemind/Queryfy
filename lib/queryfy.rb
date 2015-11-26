require "queryfy/version"
require 'queryfy/enum.rb'
require 'queryfy/filter_condition.rb'
require 'queryfy/condition_group.rb'
require 'queryfy/conditions.rb'
require 'queryfy/operators.rb'

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

		# Get pagination data
		pagination = page_and_offset(querystring)
		querystring = pagination[2]
		page = pagination[0].to_i
		limit = pagination[1].to_i

		# Calculate offset
		offset = page * limit

		# Build the conditiongroup and filter tree
		condition_tree = groupify(querystring)

		# Turn into an arel tree
		arel_tree = condition_tree.to_arel(klass.arel_table)

		# Build the query with pagination
		query = klass.arel_table.project(Arel.star).take(limit).skip(offset)

		# If we want to actually query, add the conditions to query
		query = query.where(arel_tree) unless arel_tree.nil?

		# Return the results
		return klass.find_by_sql(query.to_sql)
	end

	private

	# Checks if the passed strings braces are balanced
	def self.balanced_braces?(str)
		stack = []
		symbols = { '(' => ')' }
		str.each_char.with_index do |c, i|
			# If this character is escaped, ignore
			next if  i > 0 && str[i - 1] == '\\'
			stack << c if symbols.key?(c)
			return false if symbols.key(c) && symbols.key(c) != stack.pop
		end
		stack.empty?
	end

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


	# Find the next conditional operator, return its enum and its index
	# Returns the length of the string left and Condition::EOG if there are no conditions left
	# Returns  index till next condition, matching condition with previous
	def self.get_condition(str)
		Condition.all.each do |c|
			return c if str.start_with?(c.value)
		end
		return Condition.enum_object(:EOG)
	end

	# Returns the contents of a group in parantheses
	def self.get_inside_braces(str)
		a = str.match(BRACE_MATCHER)[1]
		return a
	end

	# Grabs a set of input and splits the input into either filterconditions or conditiongroups
	def self.groupify(str)
		# Create a conditiongroup for the input we are working with now
		groups = ConditionGroup.new([], '')

		# Keep processing while string still has contents
		while str.length > 0
			# This string starts with an opening brace denoting a group
			if nested_group?(str)
				# Get the contents of the group
				# This would be x=1||x=2 for (x=1||x=2)
				group_string = get_inside_braces(str)

				# Process this group into filterconditions and conditiongroups
				nested_group = groupify(group_string)

				# Replace the group with a temporary value, this to not trip up condition_group()
				str = str.gsub("#{START_BRACE}#{group_string}#{END_BRACE}", 'rep=x')

				# Get the index of the next join condition, which is the same as the end of this group
				next_match = next_cond_index(str)

				# Add the current conditiongroup and the matching_condition to the working list of filterconditions
				groups.filterconditions << ConditionGroup.new([nested_group], str) unless nested_group.nil?
			else
				# Get the index of the next join condition, which is the same as the end of this group
				next_match = next_cond_index(str)

				# If next_match is nil we are processing the last condition in the string
				val = str
				val = str.slice(0, next_match) unless next_match.nil?

				# Add the filtercondition to the current conditiongroup
				groups.filterconditions << FilterCondition.new(val)
			end
			# Slice the group we have processed off of the input left
			# If match length is nil? then this is the last condition to process so slice off the whole string
			match_length = str.length
			match_length = next_match unless next_match.nil?
			str = str.slice(match_length, str.length)
		end
		return groups
	end

	# Checks whether this string is the start of a nested group
	def self.nested_group?(str)
		condition_regex = Condition.regexify

		# Regex matches: 0-1 Condition (
		a = str.match(/^(?:#{condition_regex})?\(/)
		return !a.nil?
	end

	# Get the index of the next condition
	def self.next_cond_index(str)
		condition_regex = Condition.regexify
		operator_regex = Operator.regexify

		# Regex matches:
		# [any word char, escaped ( or )] until the first operator (excluding)
		field_match = /([\w\W(?<=\\)\(+((?<=\\)\)]+?(?=#{operator_regex}))/

		# [any word char, escaped ( or )] until the first condition (excluding)
		value_match = /([\w\W(?<=\\)\(+((?<=\\)\)]+?(?=#{condition_regex}))/
		regex = /(#{condition_regex})?(#{field_match}(?:#{operator_regex}){1}#{value_match})(?:#{condition_regex})?/
		match = str.match(/#{regex}/)

		# There is no next match, return nil
		return nil if match.nil?

		# The index is at least the length of the field name and operator
		idx = match[2].length

		# If this string started with a condition, add it's length to the index
		idx += match[1].length unless match[1].nil?
		return idx
	end
end

class ActiveRecord::Base
	def self.queryfy(querystring)
		return Queryfy.build_query(querystring, self)
	end
end
