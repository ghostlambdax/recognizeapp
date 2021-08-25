class Api::V2::Endpoints::Redemptions::Index < Api::V2::Endpoints::Redemptions
  resource :redemptions, desc: '' do
    # GET /redemptions
    desc 'Get redemptions' do
      detail 'Lists all the reward redemptions made by the current user'
    end

    paginate per_page: 20, max_per_page: 100

    oauth2 'read'
    get '/' do
      set = current_user.redemptions.order("created_at desc")
      paged = paginate(set)
      present paged
    end
  end
end
