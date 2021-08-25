class Api::V2::Endpoints::Users::Show < Api::V2::Endpoints::Users
  resource :users, desc: '' do
    # GET /users/show
    desc 'Show info about a user, searching by id, email, phone, or Microsoft Graph ID' do
      detail 'You may only get info about users in your network'
    end
    params do
      optional :id, type: String
      optional :email, type: String
      optional :microsoft_graph_id, type: String
      optional :phone, type: String
      exactly_one_of :id, :email, :microsoft_graph_id, :phone
    end

    oauth2 'read'
    get '/show' do
      user = nil
      if params[:id].present?
        unhashed_id = unhash(params[:id])
        unhashed_id = unhashed_id.first if unhashed_id.kind_of?(Array) # being defensive here because I think unhash returns an array
        user = current_user.company.users.find(unhashed_id)
      elsif params[:microsoft_graph_id].present?
        user = current_user.company.users.where(microsoft_graph_id: params[:microsoft_graph_id]).first
      elsif params[:email].present? # email
        user = current_user.company.users.where(email: params[:email]).first
      elsif params[:phone].present?
        user = current_user.company.users.where(phone: Twilio::PhoneNumber.format(params[:phone])).first
      end
      raise ActiveRecord::RecordNotFound, "Could not find user" unless user
      present user
    end


    # GET /users/:id
    desc 'Show info about a user, searching by id' do
      detail 'You may only get info about users in your network'
    end
    params do
      requires :id, type: String
    end

    oauth2 'read'
    get '/:id' do
      user = current_user.company.users.find(unhash(params[:id])).first
      present user
    end



  end
end
