class Api::V2::Endpoints::DeviceTokens < Api::V2::Base
  include Api::V2::Defaults

  class Entity < Api::V2::Entities::Base
    root 'device_tokens', 'device_token'
  end

  mount Api::V2::Endpoints::DeviceTokens::Upsert

end
