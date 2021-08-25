class Api::V2::Endpoints::Users::Recognitions < Api::V2::Endpoints::Recognitions
  resource :users, desc: '' do
    # GET /users/:id/recognitions
    desc 'Returns a list of user recognitions' do
      detail 'You may only get info about recognitions of the given user'
    end
    params do
      requires :id, type: String
      optional :include_private, desc: "[true|false] Whether to include private recognitions. Token must have admin privileges to list private recognitions."
      optional :sender_or_recipient, desc: "[\"sender\"|\"recipient\"] Whether to get sent or received recognitions"
    end

    paginate per_page: 20, max_per_page: 100

    oauth2 'read'
    get '/:id/recognitions' do
      user = current_user.company.users.find(unhash(params[:id])).first
      sender_or_recipient = params[:sender_or_recipient]
      include_private = params[:include_private].to_s.downcase == 'true' && current_user.company_admin?

      recognitions = begin
        if sender_or_recipient == 'sender'
          user.sent_recognitions
        elsif sender_or_recipient == 'recipient'
          user.received_recognitions
        else
          user.recognitions
        end
      end

      recognitions = recognitions
        .approved
        .joins(:user_recipients, sender: :company)
        .includes(:user_recipients, sender: :company)

      recognitions = include_private ? recognitions : recognitions.not_private
      recognitions = recognitions.select { |r| r.permitted_to?(:show) }

      paged = paginate(recognitions)
      present paged
    end
  end
end
