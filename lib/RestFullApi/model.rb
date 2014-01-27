class RestFullApi::Model < RestFullApi::Base
  
  def initialize model
    @model = model
    @api_attr_readable = @model.api_attr_readable
    @api_embed_readable = @model.api_embed_readable
    Rails.logger.debug "Loadded model \nLoad params"
    get_params @api_attr_readable, @api_embed_readable
    Rails.logger.debug "Loadded params"
    prepare_hash @model
    send_answer
  end

  
  def get_embed_attr_readable object
    object.api_attr_readable
  end




end
