# frozen_string_literal: true

namespace :cms do
  resources :integrations, param: :slug
  resources :product_updates, param: :slug
  resources :tags
  resources :articles, param: :slug
  resources :features, param: :slug
end
