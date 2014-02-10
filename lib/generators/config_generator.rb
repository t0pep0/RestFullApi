require 'rails/generators'
module RestFullApi
    class ConfigGenerator < Rails::Generators::Base
      desc 'Create config file of RestFullApi gem'
      source_root File.expand_path("../templates/", __FILE__)
      def create_initializer_file
        copy_file "restfullapi_config.rb", Rails.root.join("config", "initializers", "restfullapi_config.rb")
      end
    end
end
