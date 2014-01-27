class RestFullApi::Request
  
  def initialize(api_attr, api_embed)
    hash = {}
    ##Get params
    if defined? params
      ##Get and validate fields
      if params[:fields].present?
        hash[:fields] = []
        params[:fields].split(',').each do |field|
          if api_attr[field].present
            hash[:fields].push field
          end
        end
      end
      ##Get major version
      hash[:major] = (params[:major].to_i rescue 0)
      ##Get search string
      hash[:search] = params[:q] if params[:q].present?
      ##Get pretty options
      hash[:pretty] = params[:pretty].present? ? true : false
      ##Get offset options
      hash[:offset] = (params[:offset].to_i rescue 0)
      ##Get limit options
      hash[:limit] = (params[:limit].to_i rescue 0)
      ##Get and validate params for embed table
      if params[:embed].present?
        hash[:embed] = []
        params[:embed].split(',').each do |embed|
          split_embed = embed.split('.')
          if api_embed[split_embed[0]].present?
            hash[:embed] = split_embed
          end
        end
      end
      ##Get and validate options for sort
      if params[:sort].present?
        hash[:sort] = []
        params[:sort].split(',').each do |sort|
          hash[:sort].push("#{sort} ASC") if api_attr[sort].present?
          hash[:sort].push("#{sort} DESC") if api_attr["-#{sort}"].present?
        end
      end
      ##Get and validate filter options
      hash[:filter] = []
      api_attr.each do |attr|
        if params[attr].present?
          chars = ['<','>','=','!']
            if chars.include? params[attr][0]
              hash[:filter].push( "#{attr} #{params[attr]}")
            else
              hash [:filter].push( "#{attr} = #{params[attr]}")
            end
        end
      end

    end
    ##GET Headers
    if defined? request.headers
      if request.headers['X-Api-Key'].present?
        hash[:api_key] = request.headers['X-Api-Key']
      end
      if request.headers['X-Api-Version'].present?
        hash[:minor] = request.headers['X-Api-Version']
      end
    end
    return hash
  end

end
