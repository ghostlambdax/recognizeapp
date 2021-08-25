# frozen_string_literal: true

module CustomLabelsConcern
  def custom_labels
    CompanyCustomLabels.new(self)
  end

  class CompanyCustomLabels
    attr_reader :company
    delegate :labels, to: :company

    def initialize(company)
      @company = company
    end

    def default_email_from
      custom_label(:default_email_from)
    end

    def recognition_email_subject_label(sender_name:, badge: , with_points: false)
      translation_key = if badge.is_anniversary?
                          # force sender name in anniversary scenario to be company name
                          # this could get rendered in case of company having a recognition subject custom label and interpolate {sender_name}
                          sender_name = self.company.name
                          badge.anniversary_message.blank? ? "notifier.anniversary_recognition_fallback_email_subject" : "notifier.anniversary_recognition_email_subject"
                        else
                          with_points ? "notifier.recognized_you_with_points" : "notifier.recognized_you"
                        end
      translation_params = {name: sender_name, message: badge.anniversary_message, company: self.company.name, badge_name: badge.short_name}
      custom_label(:recognition_email_subject, default: I18n.t(translation_key, translation_params), interps: { name: sender_name })
    end

    def recognition_tags_label
      custom_label(:recognition_tags, default: I18n.t("dict.tags"))
    end

    def task_tags_label
      custom_label(:task_tags, default: I18n.t("dict.categories"))
    end

    def top_users_label
      custom_label(:top_users, default: I18n.t("reports.top_users"))
    end

    def tags_label
      default_tags_label = I18n.t("dict.tags")
      recognition_tags_label = custom_label(:recognition_tags)
      task_tags_label = custom_label(:task_tags)
      specific_labels = [recognition_tags_label, task_tags_label]

      if specific_labels.none?(&:present?) || specific_labels.all?(&:present?)
        default_tags_label
      else
        specific_labels.find(&:present?)
      end
    end

    def new_recognition_recipient_label
      recognition_label_for(:new_recognition_recipient,
                            default: I18n.t("recognition_new.recipient_search_title_html")).html_safe
    end

    def label_for_viewing_own_recognition
      recognition_label_for :view_your_recognition, default: I18n.t("recognition_notifier.view_your_recognition")
    end

    def welcome_page_tagline
      welcome_page_label_for :tagline, default: I18n.t("welcome.paid_end_user_title")
    end

    def welcome_page_description
      custom_label = welcome_page_label_for(:description)
      default = I18n.t("welcome.paid_end_user_subtitle", company: company.name)

      custom_label.present? ? custom_label.%(company: company.name) : default
    end

    def welcome_page_recognize_button_label
      welcome_page_label_for :recognize_button, default: I18n.t("dict.send_recognition")
    end

    def badges_index_welcome_label
      badges_index_label_for(:welcome, default: I18n.t("badges.welcome", name: company.name))
    end

    private

    def badges_index_label_for(key, default:)
      labels.dig(:badges_index, key) || default
    end

    def recognition_label_for(key, default:)
      labels.dig(:recognition, key) || default
    end

    def welcome_page_label_for(key, default: nil)
      labels.dig(:welcome_page, key) || default
    end

    def custom_label(key, default: "", interps: {})
      labels[key].presence.try(:%, interps) || default
    end
  end
end
