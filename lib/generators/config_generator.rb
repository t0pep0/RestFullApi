require 'rails/generators'
module RestFullApi
    class ConfigGenerator < Rails::Generators::Base
      desc 'Create config file of RestFullApi gem'
      source_root File.expand_path("../templates/", __FILE__)
      def create_initializer_file
        copy_file "restfullapi_config.rb", Rails.root.join("config", "initializers", "restfullapi_config.rb")
      end
    end

    class MethodGenerator < Rails::Generators::Base
      desc 'Create methods class file of RestFullApi gem'
      source_root File.expand_path("../templates", __FILE__)
      def create_initializer_file
        copy_file "restfullapi_methods.rb", Rails.root.join("config", "initializers", "restfullapi_methods.rb")
      end
    end

    class AuthorizeGenerator < Rails::Generators::Base
      desc 'Create authorization file for RestFullApi gem'
      source_root File.expand_path("../templates", __FILE__)
      def create_initializer_file
        copy_file "restfullapi_authorize.rb", Rails.root.join("config", "initializers", "restfullapi_authorize.rb")
      end
    end

end
