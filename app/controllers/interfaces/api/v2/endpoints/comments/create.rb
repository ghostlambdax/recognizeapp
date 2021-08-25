class Api::V2::Endpoints::Comments::Create < Api::V2::Endpoints::Comments
  resource :comments, desc: '' do
    desc 'Create a comment' do
      # success Api::V2::Endpoints::Recognitions::Entity
    end
    params do
      requires :recognition_id, desc: "Recognition ID"
      requires :content
    end

    helpers do
      def recognition
        @recognition ||= Recognition.find_from_param!(params[:recognition_id])
      end

      def comment_params
        {
          commenter: current_user,
          content: params[:content]
        }.merge(api_viewer_attributes)
      end

      def new_comment
        @new_comment ||= recognition.comments.build(comment_params)
      end
    end

    authorize do
      new_comment.permitted_to?(:create, user: current_user)
    end

    oauth2 'write'

    post '/' do
      comment = new_comment
      comment.save!

      present comment
    end
  end
end