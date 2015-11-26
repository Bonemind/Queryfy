# A filtercondition holds a single condition to filter on, and the operator to combine the next filter with
class FilterCondition
	attr_accessor :val, :condition, :field, :value, :operator

	# val: The value of the filtercondition, i.e. field0=x
	# cond: The condition, i.e. Condition::OR
	def initialize(val)
		process_val(val)
	end

	# Identifies the comparison operator for this filter, and the field name and value to compare
	def process_val(val)
		@condition = Queryfy.get_condition(val)
		binding.pry if @condition.nil?
		val.slice!(@condition.value)
		Operator.all.each do |o|
			next unless val.include?(o.value)
			split = val.split(o.value)
			@field = split[0]
			@value = split[1]
			@operator = o
		end
	end

	def to_arel(arel_table)
		field_index = arel_table.engine.column_names.index(field)
		if field_index.nil?
			puts "Unknown column #{@field}"
			fail
		else
			field = arel_table.engine.column_names[field_index]
		end
		ast_node = arel_table[field.to_sym]
		return resolve_operator(ast_node)
	end

	# rubocop:disable Metrics/CyclomaticComplexity
	def resolve_operator(ast_node)
		case @operator.value
			when Operator::EQL
			return ast_node.eq(@value)
			when Operator::NEQL
			return ast_node.not_eq(@value)
			when Operator::GT
			return ast_node.gt(@value)
			when Operator::LT
			return ast_node.lt(@value)
			when Operator::LEQ
			return ast_node.lteq(@value)
			when Operator::GEQ
			return ast_node.gteq(@value)
			when Operator::CNT
			return ast_node.matches("%#{@value}%")
			when Operator::SW
			return ast_node.matches("#{@value}%")
			when Operator::EW
			return ast_node.matches("%#{@value}")
			when Operator::NCNT
			return ast_node.does_not_match("%#{@value}%")
			when Operator::NSW
			return ast_node.does_not_match("#{@value}%")
			when Operator::NEW
			return ast_node.does_not_match("%#{@value}")
		end
	end
	# rubocop:enable Metrics/CyclomaticComplexity
end


