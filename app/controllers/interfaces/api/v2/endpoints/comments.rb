class Api::V2::Endpoints::Comments < Api::V2::Base
  include Api::V2::Defaults

  class Entity < Api::V2::Entities::Base
    include ::UsersHelper

    root 'comments', 'comment'

    expose :content
    expose :author
    expose :permissions
    expose :commenter, using: Api::V2::Endpoints::Users::Entity
    expose :created_at
    expose :is_hidden

    def author
      u = User.find(object.commenter_id)

      response = {
        avatar: u.avatar,
        full_name: u.full_name
      }
    end

    def permissions
      edit = object.permitted_to?(:edit, user: current_user)
      delete = object.permitted_to?(:destroy, user: current_user)
      {edit: edit, delete: delete}
    end

  end


  mount Api::V2::Endpoints::Comments::Index
  mount Api::V2::Endpoints::Comments::Edit
  mount Api::V2::Endpoints::Comments::Create
  mount Api::V2::Endpoints::Comments::Show
  mount Api::V2::Endpoints::Comments::Destroy
end
