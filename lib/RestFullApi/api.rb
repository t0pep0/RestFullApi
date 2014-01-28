class ActionController::Api < ActionController::Base


  def apinize object
    unless defined? object
      raise RestFullApi::NoObjectException.new
    end
    case detect_type object
    when :model then
        @api_attr_readable = object.api_attr_readable
        @api_embed_readable = object.api_embed_readable
        parse_params_and_headers
        read_model(object)
    when :embed then
        @api_attr_readable = object.api_attr_readable
        @api_embed_readable = object.api_embed_readable
        parse_params_and_headers
        read_model(object)
    when :record then
        @api_attr_readable = object.class.api_attr_readable
        @api_embed_readable = object.class.api_embed_readable
        parse_params_and_headers
        read_record(object)
    else
        raise RestFullApi::UnknownObjectException.new
    end
      response.headers["X-Total-Count"] = @count
      render json: @result, status: 200
  end

  def authorizate?(login, pass)
    true
  end

  private

  def authorization
    authenticate_or_request_with_http_basic do |login, pass|
      authorizate?(login, pass) rescue raise RestFullApi::AuthorizationException.new
    end
  end

  def parse_params_and_headers
    if defined? request
      if defined? request.headers
        @api_version_minor = (request.headers['X-Api-Minor-Version'].to_i rescue 0)
        @api_key = (request.headers['X-Api-Key'].to_s rescue '')
      else
        raise RestFullApi::NonHeadersException.new
      end
    else
      raise RestFullApi::NonRequestException.new
    end

    if defined? params

      if ((params[:fields].present?) rescue false)
        @api_fields = []
        params[:fields].split(',').each do |field|
          if (@api_attr_readable[field].present rescue false)
            @api_fields.push field.to_s
          end
        end
      else
        @api_fields = @api_attr_readable
      end

      @api_version_major = (params[:major].to_i rescue 0) if (params[:major].present? rescue false)

      @api_search_query = (params[:q].to_s rescue nil) if (params[:q].present? rescue false)

      @api_pretty = (params[:pretty].present? rescue false)

      @api_offset = (params[:offest].to_i rescue 0)

      @api_limit = (params[:limit].to_s rescue 10)

      if (params[:embed].present? rescue false)
        @api_embed = []
        params[:embed].split(',').each do |embed|
          split_embed = embed.split('.')
          if (@api_embed_readable[split_embed[0]].present? rescue false)
            hash[:embed] = split_embed
          end
        end
      else
        @api_embed  = @api_embed_readable
      end

      @api_sort = {}
      if (params[:sort].present? rescue false)
        params[:sort].split(',').each do |sort|
          @api_sort.merge!({sort => :asc}) if (@api_attr_readable[sort].present? rescue false)
          @api_sort.merge!({sort => :desc}) if (@api_attr_readable["-#{sort}"].present? rescue false)
        end
      end

      operators = {'<' => :lt, '>' => :gt, '>=' => :gte, '<=' => :lte, '<>' => :not}
      @api_where_search = {}
      @api_where_raw = []
      api_attr.readable.each do |attr|
        if (params[attr].present? rescue false)
          complete = false
          operators.each do |string, ident|
            if (params[attr][string] rescue false)
              @api_where_sphinx.merge!({attr => {ident => params[attr].delete(string)}})
              @api_where_raw.push("#{attr} #{string} #{params[attr].delete(string)}")
              complete = true
            end
            break if (params[attr][string] rescue true)
          end
          unless complete
            @api_where_sphinx.merge!({attr => params[attr]})
            @api_where_raw.push("#{attr} = #{params[attr]}")
          end
        end
      end
      @api_where_raw = @api_where_raw.join(',') if (@api_where_raw.present? rescue false)

    else
      raise RestFullApi::NonParamsException.new
    end
  end


  def read_model(model)
    if (@api_search_query.present? rescue false)
        models = (model.search(@api_search_query, order: @api_sort, conditions: @api_where_search, limit: @api_limit, offset: @api_offset) rescue [])
        @count = (model.search(@api_search_query, conditions: @api_where_search))
    else
      models = model.where(@api_where_raw).order(@api_sort).limit(@api_limit).offset(@api_offset)
      @count = model.where(@api_where_raw).count
    end
    @result = []
    models.each do |res|
      record = []
      if (@api_fields.present? rescue false)
        record.push get_column(res, @api_fields)
      else
        record.push get_column(res, get_api_attr_readable(res))
      end
      if (@api_embed.present? rescue false)
        @api_embed.each do |embed|
          record.push get_embed(res, [embed])
        end
      end
      @result.push record
    end

  end

  def read_record(record)
    @result = []
    @count = 1
    if (@api_fields.present? rescue false)
      @result.push get_column(record, @api_fields)
    else
      @result.push get_column(record, @api_attr_readable)
    end

    if (@api_embed.present? rescue false)
      @result.push get_embed(record, @api_embed_readable)
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


  def detect_type object
    if defined? object.superclass
      if defined? object.class
        case object
        when Class then
          :model
        when Array then
          :embed
        else
          :unknown
        end
      else
          :unknown
      end
    else
      if defined? Object.class.superclass
        if object.class.superclass == ActiveRecord::Base
          :record
        else
          :unknown
        end
      else
          :unknown
      end
    end
  end

end
