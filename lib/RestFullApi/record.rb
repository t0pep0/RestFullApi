class RestFullApi::Record

  def initialize record
    @record = record
    @api_attr_readable = @record.class.api_attr_readable
    @api_embed_readable = @record.class.api_attr_readable
    @options = get_params
    @count = 1
    prepare_hash
    send_answer
  end

  def prepare_hash
    @result = []
    if @options[:fields].present?
      @result.push get_column(@record, @options[:fields])
    end
    if @options[:embed].present?
      @result.push get_embed(@record, @oprions[:embed])
    end
  end

end
