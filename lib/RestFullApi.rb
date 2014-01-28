require "RestFullApi/version"
require "RestFullApi/active_record_path"
require "RestFullApi/api"

module RestFullApi
  class UnkonwnObjectException < Exception;  end
  class NoObjectException < Exception; end
  class AuthorizationException < Exception; end
  class NonParamsException < Exception; end
  class NonHeadersException < Exception; end
  class NonRequestException < Exception; end
  class FantasticException < Exception; end
  # Your code goes here...
end
