class OutlookAuthenticationsController < ActionController::Base
  include OauthConcern

  def create
    decoder = Recognize::OutlookJwtDecoder.new(params[:outlook_identity_token])
    decoder.validate
    user = User.where(network: params[:network], outlook_identity_token: decoder.unique_id).first
    if decoder.valid? && user.present?
      sign_in_user(user)
      response = {status: true, user_id: user.id}
    else
      response = {status: false, user_id: nil}
    end
    render json: response
  end
end