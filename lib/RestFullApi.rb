require "RestFullApi/version"
require "RestFullApi/active_record_path"
require "RestFullApi/api"
require "RestFullApi/base"
require "RestFullApi/embed"
require "RestFullApi/model"
require "RestFullApi/record"
require "RestFullApi/request"
require "RestFullApi/response"

module RestFullApi
  class UnkonwnObjectException < Exception;  end
  class NoObjectException < Exception; end
  class AuthorizationException < Exception; end
  class NonParamsException < Exception; end
  class NonHeadersException < Exception; end
  class NonRequestException < Exception; end
  # Your code goes here...
end
