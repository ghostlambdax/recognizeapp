class Api::V2::Endpoints::Users::Redemptions < Api::V2::Endpoints::Redemptions
  resource :users, desc: '' do
    # GET /users/:id/redemptions
    desc 'Returns a list of user redemptions | Requires COMPANY oauth scope' do
      detail 'You may only get info about redemptions of the given user'
    end
    params do
      requires :id, type: String
    end

    paginate per_page: 20, max_per_page: 100

    oauth2 'company'
    get '/:id/redemptions' do
      user = current_user.company.users.find(unhash(params[:id])).first
      set = Redemption.includes({ reward: [:manager, :company] }, :company).where(user_id: user.id).order("created_at desc")
      paged = paginate(set)
      present paged
    end
  end
end
