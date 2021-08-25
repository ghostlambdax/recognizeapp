class Api::V2::Endpoints::Badges::Index < Api::V2::Endpoints::Badges
  resource :badges, desc: '' do
    desc 'Returns a list of badges' do
    end

    paginate per_page: 1000, max_per_page: 1000
    oauth2 'read'
    route_setting(:x_auth_email, optional: true)
    
    get '/' do
      set = current_user.sendable_badges.sort_by { |b| [b.sort_order, b.short_name] }
      paged = paginate(set)
      present paged
    end
  end
end
