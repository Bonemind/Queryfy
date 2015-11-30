module QueryfyExt
	def queryfy(queryparams)
		Queryfy.from_queryparams(self, queryparams)
	end
end
