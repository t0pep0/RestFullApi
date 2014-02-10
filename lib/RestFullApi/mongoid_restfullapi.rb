module Mongoid
  module Criteria; end
  module RestFullApi
    
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
    
      def find_by_id(id) #need for logic simplification
        self.find(id)
      end

    end

  end
end
