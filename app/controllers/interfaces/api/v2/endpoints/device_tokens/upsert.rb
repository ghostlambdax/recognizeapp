class Api::V2::Endpoints::DeviceTokens::Upsert < Api::V2::Endpoints::DeviceTokens
  resource :device_tokens, desc: '' do
    # POST /device_tokens
    desc 'Update a users device token' do
      detail 'You may only update your own device token'
    end

    params do
      optional :old_token, type: String
      requires :new_token, type: String
      optional :platform, type: String
    end

    oauth2 'write'
    post '/' do
      # user = User.find(unhash(params[:id])).first
      device_token = current_user.device_tokens.find_or_initialize_by(token: params[:old_token])
      device_token.update!(token: params[:new_token], platform: params[:platform])

      # present user
    end

  end
end
