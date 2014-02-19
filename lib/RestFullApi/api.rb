class RestFullApi::Api < ActionController::Base

  def index
    read_params
    @answer = []
    if @search_query.present?
      search(@model, @search_query, @requested_where, @requested_sort, @requested_offset, @requested_limit)
    else
      @total_count = (@model.where(@requested_where).count rescue @model.where(@requested_mongo_where))
      @records = (@model.where(@requested_where).order(@requested_sort).offset(@requested_offset).limit(@requested_limit).to_a rescue @model.where(@requested_mongo_where).order(@requeset_sort).offset(@requested_offset).limit(@requested_limit).to_a )
    end
    @records.each do |record|
      @answer.push get_record(record, @requested_fields, @requested_embed)
    end
    render_answer(@answer, 200)
  end

  def show
    record = @model.find_by_id(params[:record_id])
    create_error(:record_not_found) unless record.present?
    @answer = get_record(record, @requested_fields, @requested_embed)
    @total_count = 1
    response.headers[RestFullApi.configuration.version_option[@major][@minor][:headers][:created_at]] = record.send(RestFullApi.configuration.version_option[@major][@minor][:options][:create_timestamp]).strftime("%a, %d %b %Y %H:%M:%S %Z")
    response.headers["Last-Modified"] = record.send(RestFullApi.configuration.version_option[@major][@minor][:options][:update_timestamp]).strftime("%a, %d %b %Y %H:%M:%S %Z") 
    render_answer(@answer, 200)
  end

  def update
    record = @model.find_by_id(params[:record_id])
    @total_count = 1
    if record.present?
      response.headers[RestFullApi.configuration.version_option[@major][@minor][:headers][:created_at]] = record.send(RestFullApi.configuration.version_option[@major][@minor][:options][:create_timestamp]).strftime("%a, %d %b %Y %H:%M:%S %Z")
      response.headers["Last-Modified"] = record.send(RestFullApi.configuration.version_option[@major][@minor][:options][:update_timestamp]).strftime("%a, %d %b %Y %H:%M:%S %Z") 
      if (record.update_attributes(JSON.parse(request.body.read)) rescue false)
	render_answer(get_record(record, @requested_fields, @requested_embed), 200)
      else
	create_error(:not_updated)
      end
    else
      create_error(:record_not_found)
    end
  end

  def create
    record = @model.create(JSON.parse(request.body.read)) rescue create_error(:not_created)
    @total_count = 1
    if record.present?
      render_answer(get_record(record, @requested_fields, @requested_embed),201)
    else
      create_error(:not_created)
    end
  end

  def destroy
    record = @model.find_by_id(params[:record_id])
    if record.present?
      if record.destroy
	@answer = {status: 'destroyed'}
	render_answer(@answer, 204)
      else
	create_error(:not_destroyed)
      end
    else
      create_error(:record_not_found)
    end
  end

  def description
    @answer = RestFullApi.configuration.version_option[@major][@minor][:options][:model_description][@model.model_name.to_s.to_sym]
    render_answer(@answer, 200)
  end

  def edge
    if RestFullApi.configuration.version_option[@major][@minor][:options][:embed_accessible][@model.model_name.to_s.to_sym].include?(params[:edge].to_sym)
      @model = @model.where('rubrics.id = ?', params[:record_id]).first.send(params[:edge]) rescue create_error(:not_exist_edge)
          @api_attr_accessible = RestFullApi.configuration.version_option[@major][@minor][:options][:attributes_accessible][@model.model_name.to_s.to_sym]
          @api_embed_accessible = RestFullApi.configuration.version_option[@major][@minor][:options][:embed_accessible][@model.model_name.to_s.to_sym]
      read_params
      @answer = []
      if @search_query.present?
	search(@model, @search_query, @requested_where, @requested_sort, @requested_offset, @requested_limit)
      else
	@total_count = (@model.where(@requested_where).count rescue @model.where(@requested_mongo_where))
	@records = (@model.where(@requested_where).order(@requested_sort).offset(@requested_offset).limit(@requested_limit).to_a rescue @model.where(@requested_mongo_where).order(@requeset_sort).offset(@requested_offset).limit(@requested_limit).to_a )
      end
      @records.each do |record|
	@answer.push get_record(record, @requested_fields, @requested_embed)
      end
      render_answer(@answer, 200) 
    else
      create_error(:not_exist_edge)
    end
  end


 before_filter :before 

  def search(model, query, where, sort, offset, limit)
    #TODO: This function write for "thinking sphinx, if your use another search engine override it
    @records = @model.search(query, where: where, order: sort, offset: offset, limit: limit)
    @total_count = @records.total_entries
  end

  def authorize?(login,pass)
    true #NOTICE: For overriding
  end

  def api_key_valid?(api_key)
    true #NOTICE: For overriding
  end

  private
  
  def create_error(error_name)
    @error = {error: {code: RestFullApi.configuration.version_option[@major][@minor][:error][error_name][:code],
                      description: RestFullApi.configuration.version_option[@major][@minor][:error][error_name][:msg]}}
    if defined? @pretty
      @error = JSON.pretty_generate(@error)
    end
    render json: @error, status: RestFullApi.configuration.version_option[@major][@minor][:error][error_name][:http_code]
  end

  def render_answer(answer, code)
    if defined? @pretty
      @answer = JSON.pretty_generate(answer)
    else
      @answer = answer.to_json
    end
    response.headers[RestFullApi.configuration.version_option[@major][@minor][:headers][:limit]] = @requested_limit.to_s if @requested_limit.present?
    response.headers[RestFullApi.configuration.version_option[@major][@minor][:headers][:offset]] = @requested_offset.to_s if @requested_offset.present?
    response.headers[RestFullApi.configuration.version_option[@major][@minor][:headers][:count]] = @total_count.present? ? @total_count.to_s : '0'
    response.headers["Content-Type"] = "application/json"
    render json: @answer, status: code
  end

  def before
    read_major
    read_minor
    unless (RestFullApi.configuration.version_map[@major].include?(@minor) rescue false)
      json =  {error: {code: 0, description: RestFullApi.configuration.unknown_api_version}}
      if defined? @pretty
        json = JSON.pretty_generate(json)
      end
      render json: json, status: 400
    end
    read_api_key
    check_api_key
    authencticate
    get_model
    read_fields
    read_embeds
  end

  def read_pretty
    @pretty = (params[:pretty].present? rescue false)
  end

  def read_major
    @major = (params[:major].to_i rescue RestFullApi.configuration.default[:values][:major_version])
  end

  def read_minor
    if defined? request
      if defined? request.headers
	@minor = (request.headers[RestFullApi.configuration.default[:headers][:minor_version]].present? ? request.headers[RestFullApi.configuration.default[:headers][:minor_version]].to_i : RestFullApi.configuration.default[:values][:minor_version] rescue RestFullApi.configuration.default[:values][:minor_version])
      else
        create_error(:no_headers) #IMPOSIBLE!
      end
    else
      create_error(:no_request) #IMPOSIBLE!
    end
  end

  def read_api_key
    if RestFullApi.configuration.version_option[@major][@minor][:options][:ask_api_key]
      @api_key = (request.headers[RestFullApi.configuration.version_option[@major][@minor][:headers][:api_key]].to_s rescue create_error(:no_api_key))
    end
  end

  def check_api_key
    if RestFullApi.configuration.version_option[@major][@minor][:options][:ask_api_key]
      unless api_key_valid? @api_key
        create_error(:invalid_api_key)
      end
    end
  end

  def authencticate
    if RestFullApi.configuration.version_option[@major][@minor][:options][:authorize]
      authenticate_or_request_with_http_basic do |login, pass|
        @auth = authorize?(login, pass)
        true
      end 
      unless @auth
        create_error(:not_authorize)
      end
    end
  end

  #Get model from params model
  def get_model
    @model = nil
    if defined? params[:model].singularize.classify.constantize
      model = params[:model].singularize.classify.constantize
      if defined? model.model_name.to_s
        if  model.model_name.to_s  == params[:model].singularize.classify
          @model = model
          @api_attr_accessible = RestFullApi.configuration.version_option[@major][@minor][:options][:attributes_accessible][@model.model_name.to_s.to_sym]
          @api_embed_accessible = RestFullApi.configuration.version_option[@major][@minor][:options][:embed_accessible][@model.model_name.to_s.to_sym]
          @api_description = RestFullApi.configuration.version_option[@major][@minor][:options][:model_description][@model.model_name.to_s.to_sym]
        else
          create_error(:model_not_found) if params[:record_id].present?
        end
      else
        create_error(:model_not_found) if params[:record_id].present?
      end
    else
      create_error(:model_not_stated)
    end
  end

  def read_fields
    @requested_fields = []
    if (params['fields'].present? rescue false)
      fields = params[:fields].split(',')
      fields.each do |field|
        if @api_attr_accessible.include? field.to_sym
          @requested_fields.push field
        end
      end
    end
    @requested_fields = @api_attr_accessible if @requested_fields.empty?
  end

  def read_embeds
    @requested_embed = {}
    if (params[:embed].present? rescue false)
      embed = params[:embed].split(',')
      embed.each do |emb|
        em = emb.split('.')
        if @api_embed_accessible.include? em.first.to_sym
          @requested_embed[em.first] = [] unless @requested_embed[em.first].present?
          @requested_embed[em.shift].push(em.shift)
        end
      end
    end
  end

  def read_params
    @search_query = (params[:q].present? rescue false) ? params[:q] : nil
    
    @requested_offset = (params[:offset].to_i rescue RestFullApi.configuration.version_option[@major][@minor][:values][:offset])
    
    @requested_limit = (params[:limit].to_i rescue RestFullApi.configuration.version_option[@major][@minor][:values][:limit])
    @requested_limit = RestFullApi.configuration.version_option[@major][@minor][:values][:limit] if @requested_limit == 0

    operators = {">=" => "gte", "<=" => "lte", "<" => "lt", ">" => "gt", "!=" => "ne"}
    @requested_where = []
    @requested_mongo_where = {}
    @api_attr_accessible.each do |attr|
      if (params[attr].present? rescue false)
        complete = false
          operators.each do |string, ident|
            if (params[attr][string] rescue false)
	      @requested_where.push("#{@model.table_name}.#{attr} #{string} '#{params[attr].delete(string)}'")
	      @requested_mongo_where.merge!({"#{attr}.#{ident}".to_sym => params[attr].delete(string)})
              complete = true
            end
            break if (params[attr][string] rescue true)
          end
          unless complete
	    @requested_where.push("`#{@model.table_name}.#{attr}` = '#{params[attr]}'")
	    @requested_mongo_where.merge!(attr.to_sym => params[attr])
          end
      end
    end
        @requested_where = @requested_where.join(', ')

      @requested_sort = []
      if (params[:sort].present? rescue false)
        params['sort'].split(',').each do |sort|
	  if sort['-']
	    @requested_sort.push("#{@model.table_name}.#{sort.delete('-')} DESC") if (@api_attr_accessible.include?(sort.delete('-').to_sym) rescue false)
	  else
	    @requested_sort.push("#{@model.table_name}.#{sort} ASC") if (@api_attr_accessible.include?(sort.to_sym) rescue false)
	  end
        end
      end
      @requested_sort = @requested_sort.join(',')
  end

  #get record from model 
  def get_record(record, fields, embeds)
    result = {}
    record_attr = RestFullApi.configuration.version_option[@major][@minor][:options][:attributes_accessible][record.class.model_name.to_s.to_sym]
    record_embed = RestFullApi.configuration.version_option[@major][@minor][:options][:embed_accessible][record.class.model_name.to_s.to_sym]
    fields.each do |field|
      if record_attr.include? field.to_sym
        result[field] = (record.send(field) rescue nil)
      end
    end
    embeds.each do |embed, subembed|
      if record_embed.include? embed.to_sym
        result[embed] = []
        embed_obj = record.send(embed)
	embed_model = ((embed_obj.instance_of?(Array) ? embed_obj[0].model_name.to_s : embed_obj.model_name.to_s) rescue '')
	embed_obj_attr = RestFullApi.configuration.version_option[@major][@minor][:options][:attributes_accessible][embed_model.to_sym]

        subembed = embed_obj_attr unless subembed.present?

	embed_obj.each do |obj|
	  hash = {}
	  subembed.each do |sub|
	    if (embed_obj_attr.include?(sub.to_sym) rescue false)
	      hash[sub] = (obj.send(sub) rescue nil)
	    end
	  end
	  result[embed].push(hash)
	end

      end
    end
    return result
  end


end
