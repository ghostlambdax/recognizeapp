class EmailSetting < ApplicationRecord
  acts_as_paranoid

  MANAGER_DIRECT_REPORT_SETTINGS = [
    :receive_direct_report_peer_recognition_notifications,
    :receive_direct_report_anniversary_notifications,
    :receive_direct_report_birthday_notifications
  ]

  SETTINGS = [
    :new_recognition,
    :new_comment,
    :daily_updates,
    :weekly_updates,
    :monthly_updates,
    :activity_reminders,
    :allow_recognition_sms_notifications,
    :allow_admin_report_mailer,
    :allow_manager_report_mailer
  ]

  # this used to work on create too, but stopped when upgraded to v4.1.10
  # try to check again later
  validates :user_id, presence: true, on: :update 
  validates *([:global_unsubscribe]+SETTINGS+[inclusion: {in: [true, false]}])
  validates *(MANAGER_DIRECT_REPORT_SETTINGS+[inclusion: {in: [true, false]}, allow_nil: true])
  
  belongs_to :user, inverse_of: :email_setting

  delegate :company, to: :user, allow_nil: true
  delegate :settings, to: :company, prefix: :company, allow_nil: true
  
  def self.settings
    return SETTINGS
  end

  MANAGER_DIRECT_REPORT_SETTINGS.each do |email_setting|
    define_method email_setting do
      setting = super()
      setting.nil? ? company_settings.send("default_#{email_setting}") : setting
    end
  end

  def unsubscribe!
    update_attribute(:global_unsubscribe, true)
  end
end
