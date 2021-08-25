class Api::V2::Endpoints::Recognitions::Index < Api::V2::Endpoints::Recognitions
  resource :recognitions, desc: '' do
    desc 'Returns a list of recognitions' do
      # success Api::V2::Endpoints::Recognitions::Entity
    end
    params do
      optional :include_private, desc: "[true|false] Whether to include private recognitions. Token must have admin privileges to list private recognitions."
      optional :sender_or_recipient, desc: "[\"sender\"|\"recipient\"] Whether to get sent or received recognitions"
    end

    paginate per_page: 20, max_per_page: 100

    oauth2 'read'
    get '/' do
      filter_private_recognitions = -> (recognitions) do
        include_private = params[:include_private].to_s.downcase == 'true' && current_user.company_admin?
        include_private ? recognitions : recognitions.not_private 
      end
      recognitions = if params[:sender_or_recipient] == 'sender'
                       filter_private_recognitions.call(current_user.sent_recognitions.approved
                           .joins(:user_recipients, sender: :company)
                           .includes(:user_recipients, sender: :company))
                           .select { |r| r.permitted_to?(:show) }
                     elsif params[:sender_or_recipient] == 'recipient'
                       filter_private_recognitions.call(current_user.received_recognitions.approved
                           .joins(:user_recipients, sender: :company)
                           .includes(:user_recipients, sender: :company))
                           .select { |r| r.permitted_to?(:show) }
                     else
                       filter_private_recognitions.call(current_user.company.recognitions.approved)
                     end


      paged = paginate(recognitions)
      present paged
    end
  end
end
