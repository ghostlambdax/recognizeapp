class Api::V2::Endpoints::Teams::Show < Api::V2::Endpoints::Teams
  resource :teams, desc: '' do
    # GET /teams/:id
    desc 'Show info about a team, searching by id' do
      detail "You may only get info about a team"
    end

    params do
      requires :id, type: String
    end

    oauth2 'read'
    get '/:id' do
      team = current_user.company.teams.find(unhash(params[:id])).first
      present team
    end



  end
end
