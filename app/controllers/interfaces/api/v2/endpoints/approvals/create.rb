class Api::V2::Endpoints::Approvals::Create < Api::V2::Endpoints::Approvals
  resource :approvals, desc: '' do
    desc 'Create a like' do
      # success Api::V2::Endpoints::Approvals::Entity
    end
    params do
      requires :recognition_id, desc: "Recognition ID"
    end

    helpers do
      def recognition
        @recognition ||= Recognition.find_from_param!(params[:recognition_id])
      end

      def new_approval
        @new_approval ||= recognition.build_approval(current_user, api_viewer_attributes)
      end
    end

    authorize do
      new_approval.permitted_to?(:create, user: current_user)
    end

    oauth2 'write'

    post '/' do
      approval = new_approval
      approval.save
      present approval
    end
  end
end
