class AnniversaryNotifier < ApplicationMailer
  include MailHelper
  helper :mail
  helper :application

  def notify_anniversaries(user, anniversary_users, birthday_users)
    @user = user
    @anniversary_users = anniversary_users
    @weekend_anniversary_users = weekend_event_users(:anniversary, @anniversary_users)
    @birthday_users = birthday_users
    @weekend_birthday_users = weekend_event_users(:birthday, @birthday_users)
    @mail_styler = company_styler(user.company)
    I18n.with_locale(@user.locale) do
      mail(to: @user.email, subject: mail_subject, track_opens: true)
    end
  end

  private

  def weekend_event_users(event_type, event_users)
    users = {}
    if Date.current.friday? && has_weekend_event_users?(event_type, event_users)
      users = {
        sunday: event_users.select { |user| event_falls_in_day?(event_type, user, :sunday) },
        saturday: event_users.select { |user| event_falls_in_day?(event_type, user, :saturday) }
      }
    end
    users
  end

  def has_weekend_event_users?(event_type, event_users)
    event_users.detect { |user| event_falls_in_day?(event_type, user, :sunday) || event_falls_in_day?(event_type, user, :saturday) }.present?
  end

  def event_falls_in_day?(event_type, event_user, day)
    relevant_attribute = event_type == :anniversary ? :start_date : :birthday
    relevant_date = event_user.send(relevant_attribute)
    return false unless relevant_date.present?
    relevant_date_in_present = relevant_date.change(year: Time.current.year)
    # Dynamic use of Date object method 'saturday?', 'sunday?' or similar is done here.
    relevant_date_in_present.send("#{day}?")
  end

  def mail_subject
    if @anniversary_users.present? && @birthday_users.present?
      I18n.t("notifier.anniversaries_and_birthdays")
    elsif  @birthday_users.present?
      I18n.t("notifier.birthdays")
    else
      I18n.t("notifier.anniversaries")
    end
  end
end