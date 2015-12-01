# Base exception class
class QueryfyError < StandardError
end

class FilterParseError < QueryfyError
end

class NoSuchFieldError < QueryfyError
	attr_accessor :field
	def initialize(message = nil, field = nil)
		super(message)
		self.field = field
	end
end

class InvalidFilterFormat < QueryfyError
end
