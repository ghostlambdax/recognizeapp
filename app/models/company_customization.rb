class CompanyCustomization < ApplicationRecord
  belongs_to :company

  mount_uploader :primary_header_logo, LogoUploader
  mount_uploader :secondary_header_logo, LogoUploader
  mount_uploader :email_header_logo, LogoUploader
  mount_uploader :certificate_background, CertificateBackgroundUploader
  mount_uploader :end_user_guide, EndUserGuideUploader

  COLOR_COLUMNS = [:primary_bg_color, :secondary_bg_color, 
    :primary_text_color, :secondary_text_color, :action_color, :action_text_color]

  COLOR_DEFAULTS = {
    primary_bg_color: "#f3f3f5",
    secondary_bg_color: "#ffffff",
    primary_text_color: "#1568A6",
    secondary_text_color: "#333333",
    action_color: "#1568A6",
    action_text_color: "#ffffff"
  }

  FONT_FAMILY_DEFAULT = {
    font_family: "Lato, San Francisco, Helvetica Neue, Helvetica, Arial, sans-serif",
    font_url: "@import url('https://fonts.googleapis.com/css?family=Lato');"
  }

  VIDEO_DEFAULTS = {
    youtube_id: "l9k_CSBHPNY"
  }

  IMAGE_FIELDS = [:email_header_logo, :email_header_logo_cache, 
                  :certificate_background, :certificate_background_cache,
                  :end_user_guide, :end_user_guide_cache]

  IMAGE_DEFAULTS = {
    primary_header_logo: nil,
    primary_header_logo_cache: nil,
    secondary_header_logo: nil,
    secondary_header_logo_cache: nil,
    email_header_logo: nil,
    email_header_logo_cache: nil,
    email_header_logo_url: "https://recognizeapp.com/assets/chrome/logo_48x48.png",
    email_header_logo_thumb_url: "https://recognizeapp.com/assets/chrome/logo_48x48.png",
    email_header_logo_alt_text: "Sign in to Recognize",
    certificate_background: nil,
    certificate_background_cache: nil,
    end_user_guide: nil,
    end_user_guide_cache: nil
  }

  VIRTUAL_FIELDS = [:email_header_logo_url, :email_header_logo_thumb_url, :email_header_logo_alt_text]

  DEFAULTS = Hash[*[COLOR_DEFAULTS, FONT_FAMILY_DEFAULT, VIDEO_DEFAULTS, IMAGE_DEFAULTS].map(&:to_a).flatten]
  
  validates *COLOR_COLUMNS, format: {with: /#?([A-F0-9]{3}){1,2}/i, allow_blank: true }
  validate :validate_stylesheet, if: -> { stylesheet_changed? }

  def self.attributes_for_json
    self.all_columns
  end

  # ActiveRecord attributes with virtual attributes
  def all_attributes
    all = self.attributes
    all.tap do |attrs|
      VIRTUAL_FIELDS.each do |vf|
        attrs[vf] = send(vf)
      end
    end
    all
  end

  def self.all_columns
    DEFAULTS.keys
  end

  def self.color_columns
    COLOR_COLUMNS
  end

  def self.color_defaults
    COLOR_DEFAULTS
  end

  def self.defaults
    DEFAULTS 
  end

  def self.defaults_without_virtual
    @defaults_without_virtual ||= self.defaults.except(*VIRTUAL_FIELDS)
  end

  def email_header_logo_alt_text
    self.company.name
  end

  def email_header_logo_url
    self.email_header_logo.url
  end

  def email_header_logo_thumb_url
    self.email_header_logo.thumb.url
  end

  private
  def validate_stylesheet
    return true if stylesheet.blank?
    errors.add(:stylesheet, "is not properly formatted") unless CustomTheme.valid_sheet?(stylesheet)
  end
end
