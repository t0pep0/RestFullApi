class ApiController < RestFullApi::Api 
	include RestFullApi::Method_Extend

	def index
		read_params
		@answer = Array.new
    if @search_query.present?
     search(@model, @search_query, @requested_sphinx_where, @requested_search_sort, @requested_offset, @requested_limit)
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
    record = @model.new(params[:api]) rescue create_error(:not_created)
    @total_count = 1
    if record.save
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
    @routes = []
		@model_list = @version_config[:options][:attributes_accessible]
		@embed_list = @version_config[:options][:embed_accessible]
		@model_list.each do |model, attributes|
			route = {}
			unless @embed_list[model].nil?
				@embed_list[model].each do |embed|
					route[:request_type] = "GET"
					route[:request_path] = "api/#{@major}/#{model.to_s.constantize.table_name}/#{embed}"
					@routes.push(route)
					route[:request_type] = "POST"
					route[:request_path] = "api/#{@major}/#{model.to_s.constantize.table_name}/#{embed}"
					@routes.push(route)
				end
			end
			route[:request_type] = "GET"
			route[:request_path] = "api/#{@major}/#{model.to_s.constantize.table_name}"
			@routes.push(route)
			route[:request_type] = "POST"
			route[:request_path] = "api/#{@major}/#{model.to_s.constantize.table_name}"
			@routes.push(route)
			route[:request_type] = "GET"
			route[:request_path] = "api/#{@major}/#{model.to_s.constantize.table_name}/1"
			@routes.push(route)
			route[:request_type] = "PUT"
			route[:request_path] = "api/#{@major}/#{model.to_s.constantize.table_name}/1"
			@routes.push(route)
			route[:request_type] = "POST"
			route[:request_path] = "api/#{@major}/#{model.to_s.constantize.table_name}/1"
			@routes.push(route)

		end
	end
	
	def run_methods
		meth = params[:method]
		if self.respond_to? meth.to_sym
		  answer = self.send(meth)
			unless answer.nil?
				render_answer(answer, 200)
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

	def new_edge
		if @version_config[:options][:embed_accessible][@model.model_name.to_s.to_sym].include?(params[:edge].to_sym)
		 @model = @model.where("#{params[:model].singularize.classify.constantize.table_name}.id = ?", params[:record_id]).first.send(params[:edge]) rescue create_error(:not_exist_edge)
		 res = @model.new(params[:api]) 
		 if res.save
			 @total_count = 1
			 render_answer(res,201)
		 else
			 Rails.logger.debug res.errors.full_messages
			 create_error(:not_created)
		 end
		else
			create_error(:not_created)
		end
	end



end
