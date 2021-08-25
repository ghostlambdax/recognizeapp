class RecognitionNotifier < ApplicationMailer
  include MailHelper
  layout "recognition_mailer"
  helper :mail
  helper :application

  def new_recognition_for_user(recognition, user)
    @recognition = recognition
    @badge = @recognition.badge
    @sender = @recognition.sender
    @recipient = user
    @user = @recipient
    @mail_styler = company_styler(user.company)
    if @recipient.accepts_email?(:new_recognition)
      I18n.with_locale(@recipient.locale) do
        mail(to: @recipient.email, subject: recognition_subject(user, @recognition.earned_points), track_opens: true)
      end
    end
  end

  def new_recognition_for_team(recognition, team, user)
    @recognition = recognition
    @team = team
    @badge = @recognition.badge
    @sender = @recognition.sender
    @recipient = user
    @user = @recipient
    @mail_styler = company_styler(user.company)
    if @recipient.accepts_email?(:new_recognition)
      I18n.with_locale(user.locale) do
        mail(to: @recipient.email, subject: I18n.t("notifier.team_recognized", team: @team.name, name: @recognition.sender_name), track_opens: true)
      end
    end
  end

  # def new_recognition_for_company(recognition, company)
  #   raise "not implemented!"
  #   @recognition = recognition
  #   @badge = @recognition.badge
  #   @sender = @recognition.sender
  #   @recipient = company.company_admin || company.users.first

  #   raise "company has no users to send an email to " unless @recipient.present?
  #   @user = @recipient
  #   if @recipient.accepts_email?(:new_recognition)
  #     mail(to: @recipient.email, from: @sender.formatted_email, subject: recognition_subject) do |format|
  #       format.html {render layout: "recognition_mailer"} 
  #     end
  #   end
  # end

  def invite_from_recognition_for_user(recognition, user)
    @recognition = recognition
    @badge = @recognition.badge
    @sender = @recognition.sender
    @recipient = user
    @user = @recipient
    @mail_styler = company_styler(user.company)
    @recipient.reset_perishable_token! if @recipient.perishable_token.blank?
    @verification_url = verify_signup_url(@recipient.perishable_token)
    I18n.with_locale(user.locale) do
      mail(to: @recipient.email, from: @recognition.formatted_from_email, subject: recognition_subject(user), track_opens: true)
    end
  end

  def invite_from_crosscompany_recognition_for_user(recognition, user)
    @recognition = recognition
    @badge = @recognition.badge
    @sender = @recognition.sender

    @recipient = user
    @mail_styler = company_styler(user.company)
    @user = @recipient
    @recipient.reset_perishable_token! if @recipient.perishable_token.blank?
    @verification_url = verify_signup_url(@recipient.perishable_token)
    I18n.with_locale(user.locale) do
      mail(to: @recipient.email, from: @recognition.formatted_from_email, subject: recognition_subject(user), track_opens: true)
    end
  end

  private

  def recognition_subject(user, points = 0)
    with_points = !user.company.hide_points? && points > 0
    I18n.with_locale(user.locale) do
      return user.company.custom_labels.recognition_email_subject_label(sender_name: @recognition.sender_name, badge: @badge, with_points: with_points)
    end
  end
end
