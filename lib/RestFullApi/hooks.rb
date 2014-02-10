module RestFullApi
  module Hooks

    def self.init
      begin; require 'mongoid'; rescue false; end
      if defined? ::Mongoid
	require 'mongoid_restfullapi'
      end
    end

  end
end
