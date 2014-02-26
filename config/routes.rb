Rails.application.routes.draw do
	get '/api/:major/_methods/:method' => 'api#run_methods'
  get '/api/:major/:model/:record_id/:edge' => 'api#edge'
  get '/api/doc/:major/:model' => 'api#description'
  get '/api/:major/:model' => 'api#index'
  post '/api/:major/:model' => 'api#create'
  get '/api/:major/:model/:record_id' => 'api#show'
  put '/api/:major/:model/:record_id' => 'api#update'
  delete '/api/:major/:model/:record_id' => 'api#destroy'
end
