# Holds where clause conditions
# For example: x = 1 AND y = 4 for x = 1 && y = 4
class Condition
	include Enum
	Condition.define :AND, '$AND$'
	Condition.define :OR, '$OR$'
	Condition.define :EOG, '$ENONE$'
	Condition.define :SOG, '$SNONE$'
end
