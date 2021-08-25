class Api::V2::Endpoints::Approvals::Destroy < Api::V2::Endpoints::Approvals
  resource :approvals, desc: '' do

    # DELETE /approvals/:id
    desc 'Destroy a like by id' do
      detail 'You may only delete a like you have permission to delete'
    end
    params do
      requires :id, type: String
    end

    oauth2 'write'
    
    object { RecognitionApproval.find(unhash(params[:id])).first }
    authorize { object.permitted_to?(:destroy, user: current_user) }

    delete '/:id' do
      approval = object
      approval.destroy
      present approval
    end
  end
end
