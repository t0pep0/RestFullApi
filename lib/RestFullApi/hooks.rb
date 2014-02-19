module RestFullApi
  module Hooks

    def self.init
      begin
       	require 'mongoid'
	rescue LoadError 
	  nil
      end
      if defined? ::Mongoid
	require 'RestFullApi/mongoid_restfullapi'
      end
    end

  end
end
