class Api::V2::Endpoints::Users::Create < Api::V2::Endpoints::Users
  resource :users, desc: '' do
    desc 'Create a new user' do
      # success Entity
    end

    params do
      requires :email, type: String
      requires :first_name, type: String
      requires :last_name, type: String
      optional :send_invitation, type: Boolean, desc: "Send invitation email to user upon creation"
    end

    oauth2
    route_setting(:x_auth_email, optional: true)
    route_setting(:x_auth_network, required: false)

    post '/' do
      company = current_user.company
      do_send_invitation = params.delete(:send_invitation)
      user = company.add_external_user!(current_user, params, send_invitation: do_send_invitation)
      present user
    end

    #
    # Trusted User Create
    # Allows Slack microservice(and other trusted apps) to explictly specify which network
    # a user should belong to upon creation
    #
    desc 'Create a new user and allow explicit setting of network | Requires TRUSTED oauth scope'
    params do
      requires :email, type: String
      requires :first_name, type: String
      requires :last_name, type: String
      requires :network, type: String
    end

    oauth2 'trusted'
    route_setting(:x_auth_email, required: false)
    route_setting(:x_auth_network, required: false)

    post '/create_with_network' do
      creator = ExternalUserCreator.create(params)
      user = creator.user
      present user
    end

  end
end
