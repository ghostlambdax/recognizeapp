class UserNotifier < ApplicationMailer
  include MailHelper
  layout "user_mailer"
  # layout false, only: "from_template"

  helper :mail
  helper :application

  def welcome_email(user)
    @user = user
    @mail_styler = company_styler(user.company)
    I18n.with_locale(user.locale) do
      mail(to: user.email, subject: I18n.t('notifier.your_account_is_ready'), track_opens: true)
    end
  end

  def password_reset_instructions(user)
    @user = user
    @edit_password_reset_url = edit_password_reset_url(user.perishable_token)
    @mail_styler = company_styler(user.company)
    I18n.with_locale(user.locale) do
      mail(to: user.email, subject: I18n.t("notifier.instructions_for_recognize"), track_opens: true)
    end
  end

  def verification_email(user)
    user.reset_perishable_token! if user.perishable_token.blank?
    @user = user
    @mail_styler = company_styler(user.company)
    @verification_url = verify_signup_url(user.perishable_token)
    I18n.with_locale(user.locale) do
      subject = @user.from_inbound_email_id.present? ?
        I18n.t('notifier.verify_email_send_recognition') :
        I18n.t('notifier.welcome_to_recognize_verify_email')
      mail(to: user.email, subject: subject, track_opens: true)
    end
  end

  def invitation_email(user)
    @user = user
    @mail_styler = company_styler(user.company)
    @verification_url = user.company.saml_enabled_and_forced? ? sso_saml_index_url(network: user.network) : verify_signup_url(user.perishable_token)
    @inviter = user.invited_by
    @inviter_company = @inviter.company
    Rails.logger.debug "Inviting #{@user.email} from #{@inviter.full_name}(#{@inviter.email})"
    I18n.with_locale(user.locale) do
      mail(to: user.email, from: from_header_for_user(@inviter), subject: I18n.t('notifier.name_invites_you_to_recognize', name: @inviter.full_name), track_opens: true)
    end
  end

  def new_comment(recipient, comment)
    @recipient, @comment = recipient, comment
    @user = @recipient
    @mail_styler = company_styler(recipient.company)
    commenter = comment.commenter

    Rails.logger.info "STYLER"
    Rails.logger.info "recipient: #{recipient}"
    Rails.logger.info "company: #{recipient.company}"
    Rails.logger.info "styler: #{@mail_styler.interpolated_styles}"
    Rails.logger.info "STYLER"
    if @recipient.accepts_email?(:new_comment)
      I18n.with_locale(recipient.locale) do
        mail(to: @recipient.email, from: from_header_for_user(commenter), 
             subject: I18n.t("notifier.commented_on_recognition", commenter: commenter.full_name), track_opens: true)
      end
    end
  end

  def from_template(sender, recipient, subject, body)
    @user = recipient
    @sender = sender
    @body = body
    @mail_styler = company_styler(recipient.company)

    I18n.with_locale(recipient.locale) do
      mail(to: @user.email, reply_to: sender.email, from: from_header_for_user(sender), subject: subject)
    end
  end

  def manager_notifier(manager_id, recipient_id, sender_id, recognition_id)
    @manager = User.find(manager_id)
    @recipient = User.find(recipient_id)
    @user = @manager
    @mail_styler = company_styler(@manager.company)
    @sender = User.find(sender_id)
    @recognition = Recognition.find(recognition_id)
    I18n.with_locale(@manager.locale) do
      mail(to: @manager.email, subject: I18n.t("notifier.has_been_recognized", name: @recipient.full_name), track_opens: true)
    end
  end

  def resolver_notifier(recognition_id, resolver_id, recipient_ids)
    @user = User.find(resolver_id)
    @resolver = @user
    @recipients = User.where(id: recipient_ids)
    @direct_reports = @recipients.select{ |recipient| recipient.manager_id == @resolver.id }
    @non_direct_reports = @recipients - @direct_reports

    @recognition = Recognition.find(recognition_id)
    @sender = @recognition.sender
    @mail_styler = company_styler(@resolver.company)

    is_company_admin_scoped_resolution = @recognition.approval_strategy.instance_of? RecognitionConcern::ApprovalStrategy::CompanyAdmins
    is_manager_scoped_resolution = !is_company_admin_scoped_resolution

    url_opts = { network: @resolver.company.domain, status: :pending_approval }

    @resolve_url = if is_manager_scoped_resolution
      manager_admin_recognitions_url(url_opts)
    else
      company_admin_recognitions_url(url_opts)
    end

    I18n.with_locale(@resolver.locale) do
      mail(to: @resolver.email, subject: I18n.t("notifier.a_recognition_requires_your_approval"), track_opens: true)
    end
  end

  def recognition_denial_notifier(recognition_id)
    @recognition = Recognition.find(recognition_id)
    @resolver = @recognition.resolver
    @sender = @recognition.sender
    @user = @sender

    I18n.with_locale(@sender.locale) do
      mail(to: @sender.email, subject: I18n.t("notifier.recognition_denied", name: @resolver.full_name), track_opens: true)
    end
  end
end