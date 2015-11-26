# Provides enums
# Source: http://code.dblock.org/2011/03/16/how-to-define-enums-in-ruby.html
module Enum
	def initialize(key, value)
		@key = key
		@value = value
	end

	def key
		@key
	end

	def value
		@value
	end

	def self.included(base)
		base.extend(ClassMethods)
	end

	module ClassMethods
		def define(key, value)
			@hash ||= {}
			@hash[key] = new(key, value)
		end

		def const_missing(key)
			@hash[key].value
		end

		def enum_object(key)
			return @hash[key]
		end

		def each
			@hash.each do |key, value|
				yield key, value
			end
		end

		def all
			@hash.values
		end

		def all_to_hash
			hash = {}
			each do |key, value|
				hash[key] = value.value
			end
			hash
		end

		# Merges an enums values into or conditions
		def regexify
			escaped = []
			all.each do |v|
				escaped << Regexp.escape(v.value)
			end
			return escaped.join('|')
		end
	end
end

