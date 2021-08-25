class Api::V2::Endpoints::Comments::Index < Api::V2::Endpoints::Comments
  resource :comments, desc: '' do
    desc 'Returns a list of comments' do
      # success Api::V2::Endpoints::Recognitions::Entity
    end
    params do
      optional :recognition_id, type: String, desc: "Recognition ID"
    end

    paginate per_page: 20, max_per_page: 100

    helpers do
      def recognition
        @recognition ||= current_user.company.recognitions.find_from_param!(params[:recognition_id])
      end
    end

    oauth2 'read'

    authorize do
      recognition.comments.build.permitted_to?(:index, user: current_user)
    end

    get '/' do
      comments = recognition.comments
      paged = paginate(comments)
      present paged
    end
  end
end