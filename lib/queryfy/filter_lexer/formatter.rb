require 'queryfy/queryfy_errors'
require 'pry'
module FilterLexer
	class Filter
		# Converts a FilterLexer::Filter to an arel node
		def to_arel(table)
			field = elements[0].text_value
			nested_query = field.include?('.')
			puts table.to_s
			binding.pry if table.to_s.include?('hild') || table.to_s.include?('arent')
			arel_table = table.arel_table
			





			# Get the elements we want to operate on
			operator_method = elements[1].to_arel
			val = elements[2].text_value

			return from_field(arel_table, field, operator_method, val) unless nested_query
			return from_nested(table, field, operator_method, val) if nested_query
		end

		def from_field(arel_table, field, operator_method, val)
			field = Queryfy.get_arel_field(arel_table, field)

			ast_node = arel_table[field.to_sym]

			# Build an arel node from the resolved operator, value and field
			return ast_node.send(operator_method, val)
		end

		# Nested filtering
		def from_nested(table, fieldset, operator_method, val)
			# Get table associations
			assocs = table.reflect_on_all_associations

			# Split the fields per association
			nested_split = fieldset.split('.')

			# Get the association this field represents
			assoc = assocs.select { |lassoc| lassoc.name == field.to_sym }.first
			node = nil
			if nested_split.size > 1
				node = from_nested(assoc.klass, nested_split.pop.join('.'), operator_method, val)
			end

			# Handle Belongs_to
			if assoc.is_a?(ActiveRecord::Reflection::BelongsToReflection)
				ftable_klass = assoc.klass
				ftable_arel = assoc.klass.arel_table
				pkey = ftable_klass.primary_key.to_sym
				infield = ftable_arel.where(from_field(ftable_arel, field, operator_method, val)).project(pkey)
				innode = table.arel_table[assoc.foreign_key.to_sym].in(infield) if node.nil?
				innode = table.arel_table[assoc.foreign_key.to_sym].in(node) unless node.nil?
				return innode
			elsif assoc.is_a?(ActiveRecord::Reflection::HasManyReflection || ActiveRecord::Reflection::HasOneReflection)
				ftable_klass = assoc.klass
				ftable_arel = assoc.klass.arel_table
				pkey = ftable_klass.primary_key.to_sym
				infield = ftable_arel.where(from_field(ftable_arel, field, operator_method, val)).project(assoc.foreign_key.to_sym)
				innode = table.arel_table[pkey].in(infield) if node.nil?
				innode = table.arel_table[pkey].in(node) if node.nil?
				return innode
			end
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
