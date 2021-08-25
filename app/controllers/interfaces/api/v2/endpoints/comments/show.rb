class Api::V2::Endpoints::Comments::Show < Api::V2::Endpoints::Comments
  resource :comments, desc: '' do

    # GET /comments/:id
    desc 'Show info about a comment, searching by id' do
      detail 'You may only get info about comment in your network'
    end
    params do
      requires :id, type: String
    end

    oauth2 'read'

    object { Comment.find(unhash(params[:id])).first }
    authorize { object.permitted_to?(:show, user: current_user) }

    get '/:id' do
      present object
    end    



  end
end
