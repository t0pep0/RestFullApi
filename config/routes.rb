Rails.application.routes.draw do
  get '/api/doc/:major/:model' => 'api#description'
  get '/api/:major/:model' => 'api#index'
  post '/api/:major/:model' => 'api#create'
  get '/api/:major/:model/:id' => 'api#show'
  put '/api/:major/:model/:id' => 'api#update'
  delete '/api/:major/:model/:id' => 'api#destroy'
end
