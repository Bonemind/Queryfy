require 'queryfy/queryfy_ext'
class ActiveRecord::Base
	def self.acts_as_queryfy
		puts 'acts_as_queryfy'
		def self.queryfy(queryparams)
			Queryfy.from_queryparams(self, queryparams)
		end
	end
end
