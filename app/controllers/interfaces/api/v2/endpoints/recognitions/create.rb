class Api::V2::Endpoints::Recognitions::Create < Api::V2::Endpoints::Recognitions
  resource :recognitions, desc: '' do
    desc 'Create a recognition' do
      # success Api::V2::Endpoints::Recognitions::Entity
    end
    params do
      requires :recipients, desc: "Comma seperated list of emails"
      requires :badge, desc: "Badge name or id"
      optional :message
      optional :post_to_yammer_wall, type: Boolean, desc: "Post recognition to yammer wall (requires integration)"
      optional :post_to_yammer_group_id, type: Boolean, desc: "Specify the yammer group id to post to (if post_to_yammer_wall is enabled)"
      optional :post_to_workplace, type: Boolean, desc: "Post recognition to Workplace by Facebook (requires integration)"
      optional :private, type: Boolean, desc: "Send recognition privately to recipients"
    end

    oauth2 'write'
    post '/' do
      recipients = params[:recipients].split(",")
      recognition = recognize!(recipients)
      present recognition
    end

    ########################################################################################
    desc 'Create a recognition and ensure recipients are in senders network' do
      # success Api::V2::Endpoints::Recognitions::Entity
    end
    params do
      requires :recipients, desc: "Comma seperated list of emails"
      requires :badge, desc: "Badge name or id"
      optional :message
      optional :post_to_yammer_wall, type: Boolean, desc: "Post recognition to yammer wall (requires integration)"
      optional :post_to_workplace, type: Boolean, desc: "Post recognition to Workplace by Facebook (requires integration)"
      optional :private, type: Boolean, desc: "Send recognition privately to recipients"
    end

    oauth2 'trusted'
    post '/force_network' do
      emails = params[:recipients].split(",").map(&:strip)
      recipients = emails.map{|email| ExternalUserCreator.create(email: email, network: current_user.network).user}
      recognition = recognize!(recipients)
      present recognition
    end

  end

  helpers do
    def recognize!(recipients)
      recognition_opts = {
        post_to_yammer_wall: params[:post_to_yammer_wall],
        post_to_yammer_group_id: params[:post_to_yammer_group_id],
        post_to_fb_workplace: params[:post_to_workplace],
        is_private: params[:private]
      }.merge(api_viewer_attributes)

      current_user.recognize!(recipients, params[:badge], params[:message], recognition_opts)
    end
  end
end
