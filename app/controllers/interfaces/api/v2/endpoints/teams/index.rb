class Api::V2::Endpoints::Teams::Index < Api::V2::Endpoints::Teams
  resource :teams, desc: '' do
    # GET /Teams
    desc 'Get teams' do
      detail 'Lists all the teams in this company.'
    end

    paginate per_page: 20, max_per_page: 100

    oauth2 'read'
    get '/' do
      set = current_user.company.teams.order("created_at desc")
      paged = paginate(set)
      present paged
    end
  end
end
