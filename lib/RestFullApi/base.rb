class RestFullApi::Base
  
  def get_params
    RestFullApi::Request.new @api_attr_readable, @api_embed_readable
  end

  def send_answer
    ResFullApi::Response.new @result, @count
  end

  def prepare_hash model
    hash = {}
    if @options[:search].present?
      @count = model.search(@options[:search], order: @options[:sort], conditions: @options[:filter]).count
      results = model.search(@options[:search], order: @options[:sort], conditions: @options[:filter],
                              limit: @options[:limit], offset: @options[:offset])
    else
      @count = model.order(@options[:sort]).where(@options[:filter]).count
      results = model.order(@options[:sort]).where(@options[:filter]).limit(@options[:limit].offset[@options[:offset]])
    end
    @result = []
    results.each do |res|
      record = []
      if @options[:fields].present?
        record.push get_column(res, @options[:fields])
      end
      if @options[:embed].present?
        @options[:embed].each do |embed|
          record.push get_embed(res, [embed])
        end
      end
      @result.push record
    end
  end

  def get_column object, *columns
    values_type = [String, Symbol]
    columns.each do |column|
      case column
      when *values_type
        {column => object.send(column)}
      when Hash
        hash = {}
        column.each do |key, value|
          hash[key] = object.send(value)
        end
        hash
      when Array
        get_column object, column
      else
        return :unknown_column_type
      end
    end
  end
  
  def get_embed object, *embeds
    if embeds.present?
      if embeds.instance_of? Array
        embeds.each do |embed|
          if embed.instance_of? Array
            if embed.length > 1
              if get_embed_attr_readable(object).include?(embed[0])
                { embed[0] => get_embed(object.send(embed.shift), embed) }
              end
            else
              if get_embed_attr_readable(object).include?(embed)
                { embed[0] => object.send(embed[0]) }
              end
            end
          else
            {embed => object.send(embed)}
          end
        end
      else
        {embeds => object.send(embeds)}
      end
    end
  end


end
