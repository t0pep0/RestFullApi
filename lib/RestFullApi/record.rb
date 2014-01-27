class RestFullApi::Record < RestFullApi::Base

  def initialize record
    @record = record
    @api_attr_readable = @record.class.api_attr_readable
    @api_embed_readable = @record.class.api_attr_readable
    get_params @api_attr_readable, @api_embed_readable
    @count = 1
    prepare_hash
    send_answer
  end

  def prepare_hash
    @result = []
    if @options[:fields].present?
      @result.push get_column(@record, @options[:fields])
    else
      @result.push get_column(@record, @record.class.api_attr_readable)
    end
    if @options[:embed].present?
      @result.push get_embed(@record, @oprions[:embed])
    end
  end

end
