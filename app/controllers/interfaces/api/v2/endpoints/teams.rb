class Api::V2::Endpoints::Teams < Api::V2::Base
  include Api::V2::Defaults

  class Entity < Api::V2::Entities::Base
    root 'teams', 'team'
    expose :label, documentation: { type: String, description: 'Label to use for team.'}
  end

  # mount Api::V2::Endpoints::Users::Index
  mount Api::V2::Endpoints::Teams::Show
  mount Api::V2::Endpoints::Teams::Index

end
