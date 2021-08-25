class DeviceTokensController < ApplicationController
  # When browsing as super user under the hood, if the `api.pushToken` url in localStorage was for another
  # company user, then this action will redirect the request to match that domain, causing 404 error in view
  # Also Note: :only & :if args don't work together for skip action methods (https://github.com/rails/rails/issues/9703)
  skip_before_action :ensure_correct_company, if: -> { current_user&.acting_as_superuser }

  def create
    token = current_user.device_tokens.where(token: params[:device_token], platform: params[:device_platform]).first_or_create!
    render json: {token: token, url: user_device_token_url(current_user, token, network: current_user.network)}
  end

  def destroy
    token = DeviceToken.find_by(id: params[:id], user_id: params[:user_id])
    token&.destroy

    render json: {token: token}
  end
end
