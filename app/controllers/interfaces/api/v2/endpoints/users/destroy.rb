# frozen_string_literal: true

class Api::V2::Endpoints::Users::Destroy < Api::V2::Endpoints::Users
  VALID_TEST_DOMAINS = ["ci.planet.io", "planet.io"]

  resource :users, desc: '' do
    desc 'Disable a new user | Requires COMPANY or TRUSTED oauth scope' do
      detail 'The api only allows disabling of user accounts (same as web interface and user sync). Hard deletes must be requested through support channel.'
    end

    params do
      optional :email, type: String, description: "Email | Either email or id must be passed"
      optional :id, type: String, description: "ID |  Either email or id must be passed"
      optional :opts, type: String, description: "Additional options for TRUSTED scope applications" # bit hacky extra param for now
    end

    oauth2 'company', 'trusted'

    object { current_user.company.users.where("id = :id OR email = :email", id: unhash(params[:id]), email: params[:email]).first }
    validate { params[:id].present? || params[:email].present? }
    authorize { object && object.permitted_to?(:destroy, user: current_user) }

    delete '/' do
      user = object
      #  ALERT: Slightly funky special hidden exception here for trusted apps (eg CI Test Harness API App)
      #     The api will normally only permit disabling for now
      #     Perhaps in the future we will permit hard delete
      #     However, we want the CI test harness to be able to hard delete user accounts
      #     so that it can execute certain "new user" scenarios
      if doorkeeper_access_token.scopes.include?("trusted") && params[:opts] == "hard_delete"
        # EXTRA SAFETY HERE: Limit to valid testing domains.
        raise Api::V2::Authorization::UnauthorizedException, "Invalid domain to hard delete. Currently only white listed domains are valid for this feature." unless VALID_TEST_DOMAINS.include?(user.network)
        user.destroy(deep_destroy: true)
      else
        user.destroy
      end
      present user, skip_current_user: true
    end
  end
end
