Rails.application.routes.draw do
  get '/api/doc/:major/:model' => 'rest_full_api/api#description'
  get '/api/:major/:model' => 'rest_full_api/api#index'
  post '/api/:major/:model' => 'rest_full_api/api#create'
  get '/api/:major/:model/new' => 'rest_full_api/api#new'
  get '/api/:major/:model/:id/edit' => 'rest_full_api/api#edit'
  get '/api/:major/:model/:id' => 'rest_full_api/api#show'
  put '/api/:major/:model/:id' => 'rest_full_api/api#update'
  delete '/api/:major/:model/:id' => 'rest_full_api/api#destroy'
end
