# -*- encoding : utf-8 -*-
RestFullApi.configure do |config|
  #Create a default config
  #This config a valid for all api version if parametrs not override in version config
  config.default[:options][:ask_api_key] = false #Whether to validate API key?
  config.default[:options][:authorize] = false #Requires authorization
  config.default[:options][:create_timestamp] = 'created_at' #Name of create timestamp field
  config.default[:options][:update_timestamp] = 'updated_at' #Nane of update timestamp field
  config.default[:options][:attributes_accessible] = {  #Hash of accessible models and attributes
    User:      #Accessible model name
      [:name, :id],  #Accessible attributes for model
    Post: 
      [:title, :id],
    Comment: 
      [:content]
   }
  config.default[:options][:embed_accessible] = {   #Hash of accessible embed models for models
    User:  #Model name
      [:posts, :comments],  #Accessible embed models
    Post: 
      [:user, :comments],
    Comment: 
      [:user, :post]
  }
  config.default[:options][:model_description] = { #Description for models
    User: {   #Model name
            :attributes => { #Hash of attributes
                            id: 'id of user', ##Descriptions for fields
                            name: 'User name'
                           },
            :embed => { #hash of embeds model
                             posts: 'posts where user - author', ##Descriptions for embeds
                             comments: 'comments where user - author'
                      },
            :description => 'User info'}, #Model description
    Post: {
            :attributes => {
                            title: 'Title of post',
                            id: 'id of post'
                           },
            :embed => {
                            user: 'User who write post',
                            comments: 'Comments to post'
                      },
            :description => 'The Post info'
            },
    Comment: {
              :attributes => {
                              content: 'Comment content'
                             },
              :embed => {
                              user: 'User who author of comment',
                              post: 'Post bellongs comment'
                        },
              :description => 'Comment info'
             }
  }

  #Errors
  #Message, code for json and http status code for all errors
  config.default[:error][:record_not_found][:msg] = "Record not found" 
  config.default[:error][:record_not_found][:code] = 400
  config.default[:error][:record_not_found][:http_code] = 404

  config.default[:error][:model_not_found][:msg] = "Table not found"
  config.default[:error][:model_not_found][:code] = 401
  config.default[:error][:model_not_found][:http_code] = 404

  config.default[:error][:model_not_stated][:msg] = "Table isn't stated"
  config.default[:error][:model_not_stated][:code] = 300
  config.default[:error][:model_not_stated][:http_code] = 404

  config.default[:error][:no_headers][:msg] = "Headers isn't stated"
  config.default[:error][:no_headers][:code] = 301
  config.default[:error][:no_headers][:http_code] = 406

  config.default[:error][:no_api_key][:msg] = "API key isn't stated"
  config.default[:error][:no_api_key][:code] = 200
  config.default[:error][:no_api_key][:http_code] = 401

  config.default[:error][:not_authorize][:msg] = "Not Authorized!"
  config.default[:error][:not_authorize][:code] = 201
  config.default[:error][:not_authorize][:http_code] = 401

  config.default[:error][:invalid_api_key][:msg] = "Invalid API key"
  config.default[:error][:invalid_api_key][:code] = 202
  config.default[:error][:invalid_api_key][:http_code] = 401
      
  #Headers
  config.default[:headers][:minor_version] = 'X-Api-Minor-Version' #Header name, when we recive api minor version
  config.default[:headers][:api_key] = 'X-Api-Key'  #Header name when we recieve API key if needed
  config.default[:headers][:count] = 'X-Total-Count'  #Header name whe we SEND total count of record
  config.default[:headers][:created_at] = 'X-Creation-Time' #Header name when we SEND time of creation record
  config.default[:headers][:limit] = 'X-Limit' #Header name when we SEND limit of record (current count)
  config.default[:headers][:offset] = 'X-Offset' #Header name when we SEND offset of record

  #defaults values
  #THIS PARAMETR NOT OVERRIDE IN VERSION CONFIG######################################################################
  config.default[:values][:major_version] = 0 #Set this MAJOR API version if major version invalid                 ##
  #THIS PARAMETR NOT OVERRIDE IN VERSION CONFIG######################################################################
  config.default[:values][:minor_version] = 1 #Set this MINOR API version if minor version invalid or not specified##
  ###################################################################################################################
  config.default[:values][:limit] = 10 #Defaul LIMIT if limit invalid or not specified
  config.default[:values][:offset] = 0 #Default OFFSET if offset invalid or not specified

  ###Version MAP remove in future version, but now it nesessary
  config.version_map = {
    0 => [1,2,3] # Allow version 0.1, 0.2, 0.3
  }

  @zero_dot_one = config.default #Copy default config to variable
  
  @zero_dot_three = config.default #Copy default config to variable

  config.version_option = {
    0 =>{
          1 => @zero_dot_one, #Use updated config for api version 0.1
          2 => config.default, #Use default config for api version 0.2
          3 => @zero_dot_three #Use updated config for api version 
        }
  }

end
