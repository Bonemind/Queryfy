# Holds a set for filterconditions and the condition to filter this group and the next filter with
class ConditionGroup
	attr_accessor :filterconditions, :condition

	# filterconditions: The array containing the conditions
	# condition: The condition to apply between this and the previous operator
	def initialize(filterconditions, str)
		@filterconditions = filterconditions
		@condition = Queryfy.get_condition(str)
		binding.pry if @condition.nil?
	end

	# Build an arel tree out of this conditiongroup
	def to_arel(arel_table)
		ast = nil
		@filterconditions.each do |fc|
			if fc.is_a?(ConditionGroup)
				ast = join_ast(ast, arel_table.grouping(fc.to_arel(arel_table)), fc)
			else
				ast = join_ast(ast, fc.to_arel(arel_table), fc)
			end
		end
		return ast
	end

	# Join the passed arel ast with the passed nodes
	# Join is done using fc.condition as a condition
	def join_ast(ast, nodes, fc)
		condition = fc.condition.value
		if ast.nil?
			fail('No join condition for non-start operator') unless condition == Condition::EOG || condition == Condition::SOG
			ast = nodes
		else
			case condition
				when Condition::OR
				ast = ast.or(nodes)
				when Condition::AND
				ast = ast.and(nodes)
			end
			return ast
		end
	end
end
