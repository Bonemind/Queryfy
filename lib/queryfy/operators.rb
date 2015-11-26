# Holds equality operators
# For example: x EQL 5 for x = 5
class Operator
	include Enum
	Operator.define :EQL, '='
	Operator.define :NEQL, '!='
	Operator.define :GT, '>'
	Operator.define :LT, '<'
	Operator.define :LEQ, '<='
	Operator.define :GEQ, '>='
	Operator.define :CNT, '$CNT$'
	Operator.define :SW, '$SW$'
	Operator.define :EW, '$EW$'
end
