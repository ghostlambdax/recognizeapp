class Api::V2::Endpoints::Badges < Api::V2::Base
  include Api::V2::Defaults

  class Entity < Api::V2::Entities::Base
    root 'badges', 'badge'
    expose :permalink, as: :image_url, documentation: { type: 'string', desc: 'Image url'}
    expose :short_name, as: :name, documentation: { type: 'string', desc: 'Badge name'}
    expose :description, as: :description, documentation: { type: 'string', desc: 'Badge description'}
    expose :points, as: :points, documentation: { type: 'integer', desc: 'Badge points'}
    expose :is_nomination, as: :is_nomination, documentation: { type: 'boolean', desc: 'Is nomination badge'}
    expose :requires_approval, as: :requires_approval, documentation: { type: 'boolean', desc: 'Is approval badge'}
    expose :is_achievement, as: :is_achievement, documentation: { type: 'boolean', desc: 'Is achievement badge'}
    expose :is_anniversary, as: :is_anniversary, documentation: { type: 'boolean', desc: 'Is anniversary badge'}
    expose :sort_order, as: :sort_order, documentation: { type: 'integer', desc: 'Sort Order'}

    def badge
      self.object
    end

    def web_url
      return "" if badge.company_id.blank?
      company_badge_url(badge, web_url_opts.merge(network: badge.company.domain))
    end
  end

  mount Api::V2::Endpoints::Badges::Index
  mount Api::V2::Endpoints::Badges::Show

end
