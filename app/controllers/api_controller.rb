class ApiController < RestFullApi::Api 

  def index
    read_params
    @answer = []
    if @search_query.present?
      search(@model, @search_query, @requested_sphinx_where, @requested_sort, @requested_offset, @requested_limit)
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
    response.headers[@version_config[:headers][:created_at]] = record.send(@version_config[:options][:create_timestamp]).strftime("%a, %d %b %Y %H:%M:%S %Z")
    response.headers["Last-Modified"] = record.send(@version_config[:options][:update_timestamp]).strftime("%a, %d %b %Y %H:%M:%S %Z") 
    render_answer(@answer, 200)
  end


  def update
    record = @model.find_by_id(params[:record_id])
    @total_count = 1
    if record.present?
      response.headers[@version_config[:headers][:created_at]] = record.send(@version_config[:options][:create_timestamp]).strftime("%a, %d %b %Y %H:%M:%S %Z")
      response.headers["Last-Modified"] = record.send(@version_config[:options][:update_timestamp]).strftime("%a, %d %b %Y %H:%M:%S %Z") 
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
    @answer = @version_config[:options][:model_description][@model.model_name.to_s.to_sym]
    render_answer(@answer, 200)
  end
	
	def run_methods
		RestFullApi::Methods.init(params)
		meth = params[:method]
		if RestFullApi::Methods.method_names.include? meth
		  answer = RestFullApi::Methods.send(meth)
			unless answer.nil?
				render_answer(RestFullApi::Methods.send(meth), 200)
			else
				render_answer(nil, 404)
			end
		else
			create_error(:not_exist_method)
		end
	end


	def edge
		if @version_config[:options][:embed_accessible][@model.model_name.to_s.to_sym].include?(params[:edge].to_sym)
      @model = @model.where("#{params[:model].singularize.classify.constantize.table_name}.id = ?", params[:record_id]).first.send(params[:edge]) rescue create_error(:not_exist_edge)
			@model_name = (@model.class.model_name.to_sym rescue @model.new.class.model_name.to_sym)
      @api_attr_accessible = @version_config[:options][:attributes_accessible][@model_name]
      @api_embed_accessible = @version_config[:options][:embed_accessible][@model_name]
      read_params
      read_fields
      read_embeds
      @answer = []
			if (@model.class.to_s != @model_name.to_s)
				if @search_query.present?
					search(@model, @search_query, @requested_where, @requested_sort, @requested_offset, @requested_limit)
				else
					@total_count = (@model.where(@requested_where).count.length rescue @model.where(@requested_mongo_where).count)
					@records = (@model.where(@requested_where).order(@requested_sort).offset(@requested_offset).limit(@requested_limit).to_a rescue @model.where(@requested_mongo_where).order(@requeset_sort).offset(@requested_offset).limit(@requested_limit).to_a )
				end
				@records.each do |record|
					@answer.push get_record(record, @requested_fields, @requested_embed)
				end
			else
				@total_count = 1
				@answer = get_record(@model, @requested_fields, @requested_embed)
			end
			render_answer(@answer, 200) 
		else
      create_error(:not_exist_edge)
		end
	end

end
