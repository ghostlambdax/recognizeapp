# frozen_string_literal: true

class RecognitionRecipientSerializer < BaseDatatableSerializer
  include DateTimeHelper
  include NominationsHelper

  attributes :DT_RowId, :DT_RowClass, :slug, :url, :html_link, :date, :badge, :points,
             :quick_nomination, :is_private, :status, :actions, :message, :skills, :timestamp, :tags, :recognized_team,
             :sender, :sender_name, :sender_email, :sender_department, :sender_country, :reference_recipient_department,
             :sender_first_name, :sender_last_name, :sender_employee_id,
             :recipient_email, :recipient_name,
             :reference_recipient_team_names, :reference_recipient_nominated_badge_ids, :reference_recipient_manager_name,
             :reference_recipient_manager_email, :reference_recipient_email, :reference_recipient_first_name,
             :reference_recipient_last_name, :reference_recipient_employee_id, :reference_recipient_full_name, :reference_recipient_country

  delegate :recognition, to: :object
  delegate :slug, :reference_activity, :reference_recognition_tags, :sender_name, :sender_email, to: :recognition
  delegate :first_name, :last_name, :employee_id, :country, :department, to: :sender, prefix: true
  delegate :email, :first_name, :last_name, :full_name, :employee_id, :country, :department, to: :reference_recipient, prefix: true, allow_nil: true

  def initialize(object, options = {})
    @is_export = options.delete(:is_export)
    super(object, options)
  end

  def DT_RowId
    "#{recognition.slug}-#{reference_recipient.id}"
  end

  def DT_RowClass
    "#{recognition.slug} recognition-recipient-row"
  end

  def html_link
    context.link_to(recognition.slug, url, target: "_blank")
  end

  def url
    context.recognition_url(recognition, host: Recognize::Application.config.host)
  end

  def quick_nomination
    context.quick_nomination_select2(recognition_recipient)
  end

  def tags
    # Note: Here recognition tags are fetched from `recognition_tags` join table without further joining `tag` table for
    # performance reasons.
    recognition_recipient.reference_recognition_tags.select(&:present?).map(&:tag_name).join(", ") if recognition_recipient.reference_recognition_tags.present?
  end

  def timestamp
    recognition.created_at.to_f
  end

  def recognition_recipient
    object
  end

  def reference_recipient
    object.user
  end

  def recipient_email
    reference_recipient.email
  end

  def recipient_name
    reference_recipient.full_name
  end

  def badge
    recognition.badge.short_name
  end

  def points
    recognition.earned_points
  end

  def is_private
    recognition.is_private? ? I18n.t('dict.true') : I18n.t('dict.false')
  end

  def sender
    recognition.is_anniversary? ? AnniversaryRecognitionSender.new : recognition.sender
  end

  def reference_recipient_manager_name
    reference_recipient&.manager&.full_name
  end

  def reference_recipient_manager_email
    reference_recipient&.manager&.email
  end

  def reference_recipient_team_names
    object.reference_recipient_teams.map(&:name).join(", ") if reference_recipient
  end

  def date
    localize_datetime(recognition.created_at, :friendly_with_time)
  end

  def skills
    recognition.skills_as_tags
  end

  def recognized_team
    recognition_recipient.team_id.present? ? Team.with_deleted.find(recognition_recipient.team_id).name : ""
  end

  def status
    context.status_label_for_datatable(recognition)
  end

  # Caution: This column is rendered as-is without escaping.
  def actions
    return unless recognition.pending_approval?

    # Use recognition off db rather than using the mocked recognition (which doesn't have id).
    original_recognition = Recognition.find(recognition.slug)
    "#{context.approve_recognition_button(original_recognition)} #{context.deny_recognition_button(original_recognition)}"
  end

  def message
    if @is_export
      # for exports, always show plain text version. This will strip out tags including images in case of html format.
      recognition.message_plain
    else
      # for datatable UI, sanitize message in case of html
      #   and then add wrapper div to allow truncation (w/ scroll)
      recognition_message = recognition.input_format_html? ? recognition.sanitized_message : recognition.message
      context.content_tag('div', class: 'message-wrapper') do
        recognition_message
      end
    end
  end

  private

  class AnniversaryRecognitionSender
    %i[first_name last_name employee_id country department].each do |dynamic_method|
      define_method(dynamic_method.to_s) { nil }
    end
  end

  # attributes to skip html escaping (used by parent class)
  def html_safe_attributes
    [:actions]
  end
end
