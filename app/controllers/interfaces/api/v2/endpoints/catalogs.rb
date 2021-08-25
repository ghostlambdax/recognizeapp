# frozen_string_literal: true

class Api::V2::Endpoints::Catalogs < Api::V2::Base
  include Api::V2::Defaults

  class Entity < Api::V2::Entities::Base
    include ::UsersHelper
    include MoneyRails::ActionViewExtension

    root 'catalogs', 'catalog'

    expose :currency
    expose :points_to_currency_ratio
    expose :is_enabled
    expose :id
  end

  mount Api::V2::Endpoints::Catalogs::Index
end
