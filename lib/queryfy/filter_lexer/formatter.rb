require 'queryfy/queryfy_errors'
module FilterLexer
	class Filter
		# Converts a FilterLexer::Filter to an arel node
		def to_arel(arel_table)
			# Get the elements we want to operate on
			field = elements[0].text_value
			operator_method = elements[1].to_arel
			val = elements[2].text_value

			field = Queryfy.get_arel_field(arel_table, field)

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
