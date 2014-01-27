class RestFullApi::Response

  def initialize(body, count)
    response.headers['X-Total-Count'] = count
    render json: body, status: 200
  end

end
