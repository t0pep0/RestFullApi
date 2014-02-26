module RestFullApi::Methods	
	class <<self; end

	def self.init(params)
		@params = params
	end
#EXAMPLE: this method summing two digit
#	def self.plus
#		{:result => ((@params[:a].to_i + @params[:b].to_i) rescue 0)}
#	end

end
