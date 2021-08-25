class Api::V2::Endpoints::Approvals < Api::V2::Base
  include Api::V2::Defaults

  class Entity < Api::V2::Entities::Base
    root 'approvals', 'approval'
    expose :giver
    expose :recognition_id

    def giver
      u = User.find(object.giver_id)
      return u
    end

    def web_url
      "https://#{Recognize::Application.config.host}/approvals"
    end

    def api_url
      "https://#{Recognize::Application.config.host}/api/v2/approvals/#{self.object.recognize_hashid}"
    end
  end

  mount Api::V2::Endpoints::Approvals::Index
  mount Api::V2::Endpoints::Approvals::Create
  mount Api::V2::Endpoints::Approvals::Show
  mount Api::V2::Endpoints::Approvals::Destroy
end
