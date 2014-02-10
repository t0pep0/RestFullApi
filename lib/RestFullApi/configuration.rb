module RestFullApi
  class <<self; end

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.configure
    yield(configuration) if block_given?
  end

  class Configuration
    attr_accessor :default, :version_option, :version_map, :unknown_api_version

    def initialize
      default_conf
      @version_option = {0 => {1=> @default}}
      @version_map = {0 => [1]}
      @unknown_api_version = 'Unknown API version'
    end

    def default_conf
      @default = {}
      @default[:error] = {}
      @default[:options] = {}
      @default[:headers] = {}
      @default[:values] = {}
      #Options
      @default[:options][:ask_api_key] = false
      @default[:options][:authorize] = false
      @default[:options][:create_timestamp] = 'created_at'
      @default[:options][:update_timestamp] = 'updated_at'
      @default[:options][:attributes_accessible] = {model: [:field]}
      @default[:options][:embed_accessible] = {model: [:embed]}
      @default[:options][:model_description] = {model: {:attributes => {field: 'description of field'},
                                                        :embed => {embed: 'description of field'},
                                                        :description => 'model_description'}}

      #Errors
      @default[:error][:record_not_found] = {}
      @default[:error][:record_not_found][:msg] = "Record not found"
      @default[:error][:record_not_found][:code] = 400
      @default[:error][:record_not_found][:http_code] = 404

      @default[:error][:model_not_found] = {}
      @default[:error][:model_not_found][:msg] = "Table not found"
      @default[:error][:model_not_found][:code] = 401
      @default[:error][:model_not_found][:http_code] = 404

      @default[:error][:model_not_stated] = {}
      @default[:error][:model_not_stated][:msg] = "Table isn't stated"
      @default[:error][:model_not_stated][:code] = 300
      @default[:error][:model_not_stated][:http_code] = 404

      @default[:error][:no_headers] = {}
      @default[:error][:no_headers][:msg] = "Headers isn't stated"
      @default[:error][:no_headers][:code] = 301
      @default[:error][:no_headers][:http_code] = 406

      @default[:error][:no_api_key] = {}
      @default[:error][:no_api_key][:msg] = "API key isn't stated"
      @default[:error][:no_api_key][:code] = 200
      @default[:error][:no_api_key][:http_code] = 401

      @default[:error][:not_authorize] = {}
      @default[:error][:not_authorize][:msg] = "Not Authorized!"
      @default[:error][:not_authorize][:code] = 201
      @default[:error][:not_authorize][:http_code] = 401

      @default[:error][:invalid_api_key] = {}
      @default[:error][:invalid_api_key][:msg] = "Invalid API key"
      @default[:error][:invalid_api_key][:code] = 202
      @default[:error][:invalid_api_key][:http_code] = 401
      
      #Headers
      @default[:headers][:minor_version] = 'X-Api-Minor-Version'
      @default[:headers][:api_key] = 'X-Api-Key'
      @default[:headers][:count] = 'X-Total-Count'
      @default[:headers][:created_at] = 'X-Creation-Time'
      @default[:headers][:limit] = 'X-Limit'
      @default[:headers][:offset] = 'X-Offset'

      #defaults values
      @default[:values][:major_version] = 0
      @default[:values][:major_version] = 0
      @default[:values][:limit] = 10
      @default[:values][:offset] = 0
    end

  end

end
