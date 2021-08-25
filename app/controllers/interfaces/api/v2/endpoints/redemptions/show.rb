class Api::V2::Endpoints::Redemptions::Show < Api::V2::Endpoints::Redemptions
  resource :redemptions, desc: '' do
    # GET /redemptions/:id
    desc 'Show info about a redemption, searching by id' do
      detail "You may only get info about current user's redemptions"
    end

    params do
      requires :id, type: String
    end

    oauth2 'read'
    get '/:id' do
      redemption = current_user.redemptions.find(unhash(params[:id])).first
      present redemption
    end



  end
end