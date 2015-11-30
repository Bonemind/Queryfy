# Base exception class
class QueryfyError < StandardError
end

class FilterParseError < QueryfyError
end

class NoSuchFieldError < QueryfyError
end

class InvalidFilterFormat < QueryfyError
end
