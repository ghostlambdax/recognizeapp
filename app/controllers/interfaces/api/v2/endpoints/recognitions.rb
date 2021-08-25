class Api::V2::Endpoints::Recognitions < Api::V2::Base
  include Api::V2::Defaults

  class RecipientEntity < Api::V2::Entities::Base
    root 'recipients', 'recipient'
    expose :label
    expose :avatar_thumb_url, as: :avatar_url, documentation: { type: String, description: 'Avatar url'}, if: lambda{|recipient, options|  recipient.id.present?}
  end

  class Entity < Api::V2::Entities::Base
    root 'recognitions', 'recognition'
    # expose :slug, documentation: { type: 'string', desc: 'Unique slug'}
    expose :sender, using: Api::V2::Endpoints::Users::Entity, documentation: { type: Api::V2::Endpoints::Users::Entity, desc: 'Sender of the recognition'}
    expose :message_plain, as: :message, documentation: { type: 'string', desc: 'Recognition message', required: true}
    expose :message, as: :message_html, documentation: {type: 'string', desc: 'Recognition message with full HTML', required: true}
    expose :user_recipients, using: Api::V2::Endpoints::Users::Entity, documentation: { type: Api::V2::Endpoints::Users::Entity, desc: 'User recipients of the recognition. If a team was recognized, each user is listed individually.'}
    expose :badge, using: Api::V2::Endpoints::Badges::Entity, documentation: { type: Api::V2::Endpoints::Badges::Entity, desc: 'Selected badge of the recognition'}
    expose :created_at, as: :sent_at, documentation: { type: 'string', desc: 'Datetime the recognition was sent', required: true}
    expose :permissions
    expose :is_public_to_world
    expose :is_private
    expose :comments, using: Api::V2::Endpoints::Comments::Entity, documentation: { type: Api::V2::Endpoints::Comments::Entity, desc: 'Get list of comments on the recognition'}
    expose :approvals, using: Api::V2::Endpoints::Approvals::Entity, documentation: { type: Api::V2::Endpoints::Approvals::Entity, desc: 'Get list of likes on the recognition'}
    expose :recipients, using: Api::V2::Endpoints::Recognitions::RecipientEntity
    expose :recipients_label
    expose :message_image_urls, documentation: { type: 'string', desc: 'The image urls that are present in the html message of a recognition' }
    
    def permissions
      edit = object.permitted_to?(:edit, user: current_user)
      delete = object.permitted_to?(:destroy, user: current_user)
      {edit: edit, delete: delete}
    end

  end

  mount Api::V2::Endpoints::Recognitions::Index
  mount Api::V2::Endpoints::Recognitions::Create
  mount Api::V2::Endpoints::Recognitions::Show
  mount Api::V2::Endpoints::Recognitions::Destroy

end
