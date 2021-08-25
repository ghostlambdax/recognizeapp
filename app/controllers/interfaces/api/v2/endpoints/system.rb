class Api::V2::Endpoints::System < Api::V2::Base
  include Api::V2::Defaults

  mount Api::V2::Endpoints::System::JobCounts

end
