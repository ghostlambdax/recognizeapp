class Api::V2::Endpoints::Approvals::Show < Api::V2::Endpoints::Approvals
  resource :approvals, desc: '' do

    # GET /approvals/:id
    desc 'Show info about a like, searching by id' do
      detail 'You may only get info about like in your network'
    end
    params do
      requires :id, type: String
    end

    oauth2 'read'

    object { RecognitionApproval.find(unhash(params[:id])).first }
    authorize { object.permitted_to?(:show, user: current_user) }

    get '/:id' do
      present object
    end
  end
end
