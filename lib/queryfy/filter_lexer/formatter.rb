require 'queryfy/queryfy_errors'
module FilterLexer
	class Filter
		# Converts a FilterLexer::Filter to an arel node
		def to_arel(arel_table)
			# Get the elements we want to operate on
			field = elements[0].text_value
			operator_method = elements[1].to_arel
			val = elements[2].text_value

			# Check if the field we want to filter on exists
			field_index = arel_table.engine.column_names.index(field)

			# Field does not exist, fail
			if field_index.nil?
				raise NoSuchFieldError.new("Unknown field #{ field }", field)
			else
				# Get the arel field name from our input, just to make sure
				# there is nothing weird is in the input
				field = arel_table.engine.column_names[field_index]
			end
			ast_node = arel_table[field.to_sym]

			# Build an arel node from the resolved operator, value and field
			return ast_node.send(operator_method, val)
		end
	end

	# The list below converts Filter::Operators to arel functions
	class AndOperator
		def to_arel
			return 'and'
		end
	end

	class OrOperator
		def to_arel
			return 'or'
		end
	end

	class EQOperator
		def to_arel
			return 'eq'
		end
	end

	class NEQOperator
		def to_arel
			return 'not_eq'
		end
	end

	class LTOperator
		def to_arel
			return 'lt'
		end
	end

	class LEOperator
		def to_arel
			return 'lteq'
		end
	end

	class GTOperator
		def to_arel
			return 'gt'
		end
	end

	class GEOperator
		def to_arel
			return 'gteq'
		end
	end

	class NotLikeOperator
		def to_arel
			return 'does_not_match'
		end
	end

	class LikeOperator
		def to_arel
			return 'matches'
		end
	end

	class StringLiteral
		def text_value
			val = super
			return val.gsub!(/\A["']|["']\Z/, '')
		end
	end
end
