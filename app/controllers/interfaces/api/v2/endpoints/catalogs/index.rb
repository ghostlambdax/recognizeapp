# frozen_string_literal: true

class Api::V2::Endpoints::Catalogs::Index < Api::V2::Endpoints::Catalogs
  resource :catalogs, desc: '' do
    desc 'Get reward catalogs' do
      detail "Lists all the currency catalogs, such as USD or GBP, redeemable by the current user"
    end

    paginate per_page: 20, max_per_page: 100

    oauth2 'read'
    get '/' do
      set = current_user.redeemable_catalogs
      paged = paginate(set)
      present paged
    end
  end
end
