# frozen_string_literal: true

class Api::V2::Endpoints::Rewards::Index < Api::V2::Endpoints::Rewards
  resource :rewards, desc: '' do
    # GET /rewards
    desc 'Get the list of rewards for a catalog. Each catalog is for a different currency. Each currency has a set of rewards. First get the Catalog to get the list of rewards.' do
      detail "You may only get info about current user's catalogs"
    end

    params do
      optional :catalog_id, type: String, desc: 'This is the ID of the catalog for a specific currency, such as USD.'
    end

    paginate per_page: 20, max_per_page: 100

    oauth2 'read'
    get '/' do
      catalog = if params[:catalog_id].present?
        current_user.redeemable_catalogs.detect{|c| c.recognize_hashid == params[:catalog_id]}
      else
        current_user.redeemable_catalogs.first
      end
      raise ActiveRecord::RecordNotFound, "Couldn't find a Catalog with the given ID" if catalog.nil?

      rewards = catalog.rewards.where(enabled: true)
      paged = paginate(rewards)
      present paged
    end
  end
end
