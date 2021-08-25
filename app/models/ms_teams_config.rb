# frozen_string_literal: true

class MsTeamsConfig < ActiveRecord::Base
  belongs_to :company

  serialize :settings, Hash

  scope :for_entity, ->(entity_id) { where(entity_id: entity_id).first_or_initialize }

  validates :company_id, :entity_id, presence: true
  
  def as_json(options = {})
    options[:only] ||= [:entity_id, :settings]
    super(options)
  end

  def tab_choice(include_entity_id: false)
    if include_entity_id
      uri = Addressable::URI.parse(settings['selectedTab'])
      uri.query_values = uri.query_values.merge(entity_id: self.entity_id)
      uri.to_s
    else
      settings['selectedTab']
    end
  end

  def tab_name
    settings['suggestedDisplayName']
  end
end
