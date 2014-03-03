class RestFullApi::Api < ActionController::Base

  def search(model, query, where, sort, offset, limit)
    #NOTICE: This function write for "thinking sphinx, if your use another search engine override it
    @records = @model.search(query, conditions: where, order: sort, offset: offset, limit: limit)
    @total_count = @records.total_entries
  end

  def authorize?(login,pass)
    true #NOTICE: For overriding
  end

  def api_key_valid?(api_key)
    true #NOTICE: For overriding
  end
 
	before_filter :before 
	before_filter :before_db, :except => :run_methods

  private
  
  def create_error(error_name)
    @error = {error: {code: @version_config[:error][error_name][:code],
                      description: @version_config[:error][error_name][:msg]}}
    if @pretty
      @error = JSON.pretty_generate(@error)
    end
    render json: @error, status: @version_config[:error][error_name][:http_code]
  end

  def render_answer(answer, code)
    if @pretty
      @answer = JSON.pretty_generate(answer)
    else
      @answer = answer.to_json
    end
    response.headers[@version_config[:headers][:limit]] = @requested_limit.to_s if @requested_limit.present?
    response.headers[@version_config[:headers][:offset]] = @requested_offset.to_s if @requested_offset.present?
    response.headers[@version_config[:headers][:count]] = @total_count.present? ? @total_count.to_s : '0'
    response.headers["Content-Type"] = "application/json"
    render json: @answer, status: code
  end

  def before
		@default_config = RestFullApi.configuration.default
		read_pretty
    read_major
    read_minor
		@version_config = RestFullApi.configuration.version_option[@major][@minor]
    unless (RestFullApi.configuration.version_map[@major].include?(@minor) rescue false)
      json =  {error: {code: 0, description: RestFullApi.configuration.unknown_api_version}}
      if @pretty
        json = JSON.pretty_generate(json)
      end
      render json: json, status: 400
    end
    read_api_key
    check_api_key
    authencticate
  end

	def before_db
    get_model
    read_fields
    read_embeds
	end

  def read_pretty
		@pretty = (params[:pretty] == 'true' or params[:pretty].present?) rescue false
  end

  def read_major
    @major = (params[:major].to_i rescue @default_config[:values][:major_version])
  end

  def read_minor
    if defined? request
      if defined? request.headers
	@minor = (request.headers[@default_config[:headers][:minor_version]].present? ? request.headers[@default_config[:headers][:minor_version]].to_i : @default_config[:values][:minor_version] rescue @default_config[:values][:minor_version])
      else
        create_error(:no_headers) #IMPOSIBLE!
      end
    else
      create_error(:no_request) #IMPOSIBLE!
    end
  end

  def read_api_key
    if @version_config[:options][:ask_api_key]
      @api_key = (request.headers[@version_config[:headers][:api_key]].to_s rescue create_error(:no_api_key))
    end
  end

  def check_api_key
    if @version_config[:options][:ask_api_key]
      unless api_key_valid? @api_key
        create_error(:invalid_api_key)
      end
    end
  end

  def authencticate
    if @version_config[:options][:authorize]
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
          @api_attr_accessible = @version_config[:options][:attributes_accessible][@model.model_name.to_s.to_sym]
          @api_embed_accessible = @version_config[:options][:embed_accessible][@model.model_name.to_s.to_sym]
          @api_description = @version_config[:options][:model_description][@model.model_name.to_s.to_sym]
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
    
    @requested_offset = (params[:offset].to_i rescue @version_config[:values][:offset])
    
    @requested_limit = (params[:limit].to_i rescue @version_config[:values][:limit])
    @requested_limit = @version_config[:values][:limit] if @requested_limit == 0

    operators = {">=" => "gte", "<=" => "lte", "<" => "lt", ">" => "gt", "!=" => "ne"}
    @requested_where = []
    @requested_mongo_where = {}
		@requested_sphinx_where = {}
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
	    if params[attr] == 'nil'
	      value = 'NULL'
	      mongo_value = nil
	    else
	      value = params[attr]
	      mongo_value = params[attr]
	    end
	    @requested_where.push("`#{@model.table_name}.#{attr}` = '#{value}'")
	    @requested_mongo_where.merge!(attr.to_sym => mongo_value)
			@requested_sphinx_where.merge!(attr.to_sym => mongo_value)
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
    record_attr = @version_config[:options][:attributes_accessible][record.class.model_name.to_s.to_sym]
    record_embed = @version_config[:options][:embed_accessible][record.class.model_name.to_s.to_sym]
    fields.each do |field|
      if record_attr.include? field.to_sym
        result[field] = (record.send(field) rescue nil)
      end
    end
    embeds.each do |embed, subembed|
			if record_embed.include? embed.to_sym
        result[embed] = []
        embed_obj = record.send(embed)
				embed_model = (embed_obj.instance_of?(Array) ? embed_obj.new.class.model_name.to_s : embed_obj.class.model_name.to_s)
	embed_obj_attr = @version_config[:options][:attributes_accessible][embed_model.to_sym]
        subembed = embed_obj_attr if subembed == [nil]
				unless (embed_obj.class.nil?)
					if (embed_obj.class == Array)
						unless embed_obj.length < 1
							arr = []
							embed_obj.each do |obj|
								hash = {}
								subembed.each do |sub|
									if (embed_obj_attr.include?(sub.to_sym) rescue false)
										hash[sub] = (obj.send(sub) rescue nil)
									end
								end
								arr.push(hash)
							end
							result.merge!({embed => arr})
						else
							result.merge!({embed => nil})
						end
					else
						hash = {}
						subembed.each do |sub|
							if (embed_obj_attr.include?(sub.to_sym) rescue false)
								hash[sub] = (embed_obj.send(sub) rescue nil)
							end
						end
						result.merge!({embed => hash})
					end
				else
					result.merge!({embed => nil})
				end
			end
		end
    return result
  end


end
