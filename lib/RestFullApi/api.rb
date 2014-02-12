class RestFullApi::Api < ActionController::Base

  def index
    read_params
    @answer = []
    if @search_query.present?
      search(@model, @search_query, @requested_where, @requested_sort, @requested_offset, @requested_limit)
    else
      @total_count = @model.where(@requested_where).count
      @records = @model.where(@requested_where).order(@requested_sort).offset(@requested_offset).limit(@requested_limit)
    end
    @records.each do |record|
      @answer.push get_record(record, @requested_fields, @requested_embed)
    end
    render_answer(@answer, 200)
  end

  def show
    record = @model.find_by_id(params[:id])
    create_error(:record_not_found) unless record.present?
    @answer = get_record(record, @requested_fields, @requested_embed)
    @total_count = 1
    response.headers[RestFullApi.configuration.version_option[@major][@minor][:headers][:created_at]] = record.send(RestFullApi.configuration.version_option[@major][@minor][:options][:create_timestamp]).strftime("%a, %d %b %Y %H:%M:%S %Z")
    response.headers["Last-Modified"] = record.send(RestFullApi.configuration.version_option[@major][@minor][:options][:update_timestamp]).strftime("%a, %d %b %Y %H:%M:%S %Z") 
    render_answer(@answer, 200)
  end

  def update
    record = @model.find_by_id(params[:id])
    @total_count = 1
    response.headers[RestFullApi.configuration.version_option[@major][@minor][:headers][:created_at]] = record.send(RestFullApi.configuration.version_option[@major][@minor][:options][:create_timestamp]).strftime("%a, %d %b %Y %H:%M:%S %Z")
    response.headers["Last-Modified"] = record.send(RestFullApi.configuration.version_option[@major][@minor][:options][:update_timestamp]).strftime("%a, %d %b %Y %H:%M:%S %Z") 
    if record.update_attributes(params[@model.model_name.down_case])
      render_answer(get_record(record, @requested_fields, @requested_embed), 200)
    else
      create_error(:not_updated)
    end
  end

  def create
    record = @model.new(params[@model.model_name.down_case])
    @total_count = 1
    if record.save
      render_answer(get_record(record, @requested_fields, @requested_embed),201)
    else
      create_error(:not_created)
    end
  end

  def destroy
    record = @model.find_by_id(params[:id])
    if record.destroy
      @answer = {status: 'destroyed'}
      render_answer(@answer, 204)
    else
      create_error(:not_destroyed)
    end
  end

  def description
    @answer = RestFullApi.configuration.version_option[@major][@minor][:options][:model_description][@model.model_name.to_sym]
    render_answer(@answer, 200)
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
      if defined? model.model_name
        if  model.model_name  == params[:model].singularize.classify
          @model = model
          @api_attr_accessible = RestFullApi.configuration.version_option[@major][@minor][:options][:attributes_accessible][@model.model_name.to_sym]
          @api_embed_accessible = RestFullApi.configuration.version_option[@major][@minor][:options][:embed_accessible][@model.model_name.to_sym]
          @api_description = RestFullApi.configuration.version_option[@major][@minor][:options][:model_description][@model.model_name.to_sym]
        else
          create_error(:model_not_found) if params[:id].present?
        end
      else
        create_error(:model_not_found) if params[:id].present?
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

    operators = {">=" => :gte, "<=" => :lte, "<" => :lt, ">" => :gt, "!=" => :not}
    @requested_where = []
    @api_attr_accessible.each do |attr|
      if (params[attr].present? rescue false)
        complete = false
          operators.each do |string, ident|
            if (params[attr][string] rescue false)
              @requested_where.push("#{attr} #{string} '#{params[attr].delete(string)}'")
              complete = true
            end
            break if (params[attr][string] rescue true)
          end
          unless complete
            @requested_where.push("`#{attr}` = '#{params[attr]}'")
          end
      end
    end
        @requested_where = @requested_where.join(', ')

      @requested_sort = []
      if (params[:sort].present? rescue false)
        params['sort'].split(',').each do |sort|
	  if sort['-']
	    @requested_sort.push("#{sort.delete('-')} DESC") if (@api_attr_accessible.include?(sort.delete('-').to_sym) rescue false)
	  else
	    @requested_sort.push("#{sort} ASC") if (@api_attr_accessible.include?(sort.to_sym) rescue false)
	  end
        end
      end
      @requested_sort = @requested_sort.join(',')
  end

  #get record from model 
  def get_record(record, fields, embeds)
    result = {}
    record_attr = RestFullApi.configuration.version_option[@major][@minor][:options][:attributes_accessible][record.class.model_name.to_sym]
    record_embed = RestFullApi.configuration.version_option[@major][@minor][:options][:embed_accessible][record.class.model_name.to_sym]
    fields.each do |field|
      if record_attr.include? field.to_sym
        result[field] = (record.send(field) rescue nil)
      end
    end
    embeds.each do |embed, subembed|
      if record_embed.include? embed.to_sym
        result[embed] = []
        embed_obj = record.send(embed)
        embed_model = embed.singularize.classify.constantize
	embed_obj_attr = RestFullApi.configuration.version_option[@major][@minor][:options][:attributes_accessible][embed_model.model_name.to_sym]

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

        #subembed.each do |sub|
	#  if (embed_obj_attr.include?(sub.to_sym) rescue false)
	#    result[embed].push([sub] = (embed_obj.send(sub)) rescue nil)
        #  end
        #end
      end
    end
    return result
  end


  #TODO: CLEAR

  #def send_answer
      #unless @error.present?
        #if @result.present?
          #@json = @result.to_json
          #render json: @json, status: 200
        #else
          #render json: {error_description: 'Upon request, nothing found'}, status: 404
        #end
      #else
        #render json: {error_description: @error}, status: 500
      #end
  #end

  #def read_model(model)
    #if (@api_search_query.present? rescue false)
        #models = (model.search(@api_search_query, order: @api_sort_raw, conditions: @api_where_raw, limit: @api_limit, offset: @api_offset) rescue [])
        #@count = models.total_entries
    #else
      #models = model.where(@api_where_raw).order(@api_sort_raw).limit(@api_limit).offset(@api_offset)
      #@count = model.where(@api_where_raw).count
    #end
    #result = []
    #models.each do |record|
        #result.push read_record(record)
    #end
    #result
  #end

  #def read_record(record)
    #result = {}
    #@count = 1 unless @count.present?
    #@created_at = record.created_at if (@count == 1 and detect_type(record) == :record)
    #@updated_at = record.updated_at if (@count == 1 and detect_type(record) == :record)
    #if (@api_fields.present? rescue false)
      #result.merge! get_column(record, @api_fields)
    #else
      #result.merge! get_column(record, @api_attr_readable)
    #end

    #if (@api_embed.present? rescue false)
      #result.merge! get_embed(record, @api_embed_readable)
    #end
    #result
  #end

  #def get_column object, columns
    #values_type = [String, Symbol]
    #result = {}
    #columns.each do |col|
      #case col
      #when *values_type then
        #result.merge!({col => object.send(col.to_s)})
      #when Hash then
        #hash = {}
        #col.each do |key, value|
          #hash[key] = object.send(value)
        #end
        #result.merge!(hash)
      #when Array then
        #result.merge!(get_column(object, col))
      #else
        #@error = 'Incredible error, it was not supposed to happen, but it happened ....'
        #send_answer
      #end
    #end
    #return result
  #end
  
  #def get_embed object, embeds
    #result = {}
    
    #if embeds.instance_of? Array
      #unless embeds.empty?
        #embeds.each do |embed|
          #values_type = [String, Symbol]
          #case embed
          #when *values_type then
            #record = object.send(embed)
            #if record.instance_of? Array
              #record_save = record
              #record = {}
              #record_save.each do |rec|
              #records = []
                #record_save[0].class.api_attr_readable.each do |attr|
                  #records.push! ({attr => rec.send(attr)})
                #end
              #end
              #record = {embed => records}
            #end
            #result.merge! record
          #end
        #end
      #end
    #end
    #result
  #end


  #def detect_type object
    #if defined? object.superclass
      #if defined? object.class
        #case object
        #when Class then
          #:model
        #when Array then
          #:embed
        #else
          #:unknown
        #end
      #else
          #:unknown
      #end
    #else
      #if defined? Object.class.superclass
        #if object.class.superclass == ActiveRecord::Base
          #:record
        #else
          #:unknown
        #end
      #else
          #:unknown
      #end
    #end
  #end

end
