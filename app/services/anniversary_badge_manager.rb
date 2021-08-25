require_dependency File.join(Rails.root, 'db/anniversary_badges')

class AnniversaryBadgeManager
  attr_reader :company_id, :company, :template_id

  def initialize(company_id, template_id)
    @company_id = company_id
    @company = Company.find(@company_id)
    @template_id = template_id
  end

  def create!
    template = ANNIVERSARY_BADGES[@template_id]
    badge = self.class.template_for(@template_id, self.company)
    badge.company_id = self.company_id
    badge.image = File.open(Rails.root+"app/assets/images/badges/anniversary/#{template.image}")
    badge.save!

    return badge
  end

  def self.template_for(template_id, company)
      template = ANNIVERSARY_BADGES[template_id]

      b = Badge.new(
        name: template.name,
        short_name: template.name,
        long_name: template.name,
        points: template.points,
        anniversary_template_id: template_id,
        anniversary_message: template.message.gsub("$$company_name$$", company.name)
      )
      b.is_anniversary = true
      # b.image = File.open(Rails.root+"app/assets/images/badges/anniversary/#{template.image}")
      return b
  end

  # This gets a list of existing anniversary badges backfilled with templates
  # for those that haven't been created
  def self.company_anniversary_badges(company)
    badges = company.anniversary_badges
    templates = Badge.anniversary_templates(company)
    template_ids = templates.map(&:anniversary_template_id)
    uncreated_badge_template_ids = template_ids - badges.map(&:anniversary_template_id)
    uncreated_badge_templates = templates.select{|at|
      uncreated_badge_template_ids.include?(at.anniversary_template_id)
    }
    (badges + uncreated_badge_templates).sort_by{|b| b.anniversary_template_id}
  end

  def self.find_or_create(company, template_id)
    unless badge = company.anniversary_badges.find_by(anniversary_template_id: template_id)
      manager = new(company.id, template_id)
      badge = manager.create!
    end
    return badge
  end

  def self.update_or_create(company, params)
    badge = AnniversaryBadgeManager.find_or_create(company, params[:anniversary_template_id])
    badge.update(params)
    return badge
  end
end
