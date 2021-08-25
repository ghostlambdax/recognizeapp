class Api::V2::Endpoints::Comments::Destroy < Api::V2::Endpoints::Comments
  resource :comments, desc: '' do

    # DELETE /comments/:id
    desc 'Destroy a comment by id' do
      detail 'You may only delete a comment you have permission to delete'
    end
    params do
      requires :id, type: String
    end

    oauth2 'write'
    
    object { Comment.find(unhash(params[:id])).first }
    authorize { object.permitted_to?(:destroy, user: current_user) }

    delete '/:id' do
      comment = object
      comment.destroy
      present comment
    end    



  end
end
