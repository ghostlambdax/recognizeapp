class Api::V2::Endpoints::Comments::Edit < Api::V2::Endpoints::Comments
  resource :comments, desc: '' do

    # PUT /comments/:id
    desc 'Edit a comment by id' do
      detail 'You may only edit a comment you have permission to edit'
    end
    params do
      requires :id, type: String, desc: 'Comment ID'
      requires :content, type: String, desc: 'Comment content'
    end

    oauth2 'write'
    
    object { Comment.find(unhash(params[:id])).first }
    authorize { object.permitted_to?(:edit, user: current_user) }

    put '/:id' do
      comment = object
      comment.update({
        content: params[:content]
      })
      present comment
    end
  end
end
