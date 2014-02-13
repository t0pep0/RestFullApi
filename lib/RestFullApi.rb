require "RestFullApi/version"
require "RestFullApi/hooks"
require "generators/config_generator"
require "RestFullApi/api"
require "RestFullApi/configuration"

module RestFullApi
  class Engine < Rails::Engine; end
  RestFullApi.Hooks.init()
  # Your code goes here...
end
