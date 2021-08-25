class CompanySetting < ApplicationRecord
  enum authentication_field: { auth_via_email: 0, auth_via_user_principal_name: 1, auth_via_employee_id: 2}
  enum sync_frequency: { daily: 0, weekly: 1 }

  belongs_to :company, optional: true

  serialize :profile_badge_ids
  serialize :yammer_sync_groups, Array
  serialize :microsoft_graph_sync_groups, Array
  serialize :user_ids_to_notify_of_sync_report, Array
  serialize :sync_filters, Hash
  serialize :recognition_editor_settings, Hash

  before_validation :set_default_time_zone, if: -> { timezone.blank? }
  validates :company_id, presence: true, uniqueness: { case_sensitive: true }
  validates :fb_workplace_post_to_group_id, format: {with: /\A[[:alnum:]]+\z/}, allow_blank: true
  validate :sync_groups_length_valid?
  validate :default_locale_valid?
  validate :sync_filters_valid?
  validates_inclusion_of :timezone, in: ActiveSupport::TimeZone.all.map(&:name)

  VALID_SETTINGS = self.column_names.map(&:to_sym) - [:id, :company_id]

  def add_sync_group(group, provider)
    return if group.blank?
    if send("#{provider}_sync_groups").find { |sync_group| group.id == sync_group.id }.nil?
      send("#{provider}_sync_groups") << filtered_group(group, provider)
      self.save
    end
  end

  def remove_sync_group(group_id, provider)
    return if group_id.blank?

    send("#{provider}_sync_groups").delete_if { |sync_group| sync_group.id.to_s == group_id.to_s }
    self.save
  end

  def self.available_locale_info
    Recognize.available_locale_info
  end

  def self.available_locale_options
    available_locale_info.map{|key,value| [value, key]}
  end

  def self.available_locales
    Recognize.available_locales
  end

  def fb_workplace_community_id
    authoritative_fb_workplace_settings.read_attribute(:fb_workplace_community_id)
  end

  def fb_workplace_token
    authoritative_fb_workplace_settings.read_attribute(:fb_workplace_token)
  end

  def authoritative_fb_workplace_settings
    if self.company.in_family? && read_attribute(:fb_workplace_token).blank?
      family_ids = self.company.family.map(&:id)
      CompanySetting.where(company_id: family_ids).where.not(fb_workplace_token: nil).first || self
    else
      self
    end
  end

  # FIXME: There is a generic quirk with this placeholder pattern -
  #       Changes made on the DEFAULT HASH are not persisted, because it is not attached to the record
  #       The modified object should be assigned back to the attribute before saving, for it to persist
  def sync_filters
    super.presence || default_sync_filters
  end

  def recognition_editor_settings
    super.presence || {
      allow_links: true,
      allow_inserting_images: true,
      allow_uploading_images: true,
      allow_gif_selection: true
    }
  end

  def hide_disabled_users_from_recognitions?
    false
  end

  private

  def sync_groups_length_valid?
    maximum_allowed = 500
    sync_groups = [
        :yammer_sync_groups,
        :microsoft_graph_sync_groups
    ]
    sync_groups.each do |sync_group|
      if self.send("#{sync_group}").length > maximum_allowed
        errors.add sync_group, "can hold at maximum #{maximum_allowed} items"
      end
    end

  end

  def default_locale_valid?
    unless self.class.available_locales.include?(default_locale)
      errors.add :default_locale, "invalid locale"
    end
  end

  def sync_filters_valid?
    return if self.sync_filters.blank?

    self.sync_filters.values.each do |attr_filters_map| # loops over each provider
      attr_filters_map.each do |_attr, (filter, _value)| # loops over each attr
        unless filter.in?(UserSync::Base::SUPPORTED_SYNC_FILTERS)
          errors.add :sync_filters, "Unsupported filter: '#{filter}'"
        end

        # filter specific validations can go here
      end
    end
  end

  #
  # Strip unnecessary attributes coming in the `group` object.
  # Attributes to store are `id` and name.
  # For yammer sync groups, name is `full_name`.
  # For microsoft sync graph groups, name is `displayName`
  #
  def filtered_group(group, provider)
    selected_keys = ["id"]
    case provider.to_sym
      when :yammer
        selected_keys << "full_name"
      when :microsoft_graph
        selected_keys << "displayName"
    end
    filtered_attributes = group.to_h.select { |k,v| selected_keys.include? k }
    group.class.new(filtered_attributes)
  end

  def set_default_time_zone
    self.timezone = Rails.application.config.time_zone
  end

  def default_sync_filters
    {
      microsoft_graph: { accountEnabled: ['equals', true] }
    }
  end
end
