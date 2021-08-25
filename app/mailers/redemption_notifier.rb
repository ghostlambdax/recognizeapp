class RedemptionNotifier < ApplicationMailer
  include MailHelper
  helper :mail
  helper :application

  # Tell user they redeemed something and it is pending
  def notify_of_redemption(user, redemption)
    @user = user
    @admin = redemption.reward.manager_with_default
    @reward = redemption.reward
    @redemption = redemption
    @mail_styler = company_styler(user.company)
    I18n.with_locale(user.locale) do
      mail(to: @user.email, subject: t("rewards.your_redemption_is_pending", title: redemption.reward.title), track_opens: true)
    end
  end

  # Tell admins or manager they need to approve a reward.
  # In addition, this is also used to notify redemptions that are auto-approved.
  def notify_admin_of_redemption(user, redemption)
    @company = user.company
    @redemption = redemption
    @redeeming_user = user
    @reward = redemption.reward
    @reward_variant = redemption.reward_variant
    @reward_title = "#{@reward.title} (#{@reward_variant.label})"
    @mail_styler = company_styler(user.company)

    @admins, @approve_url = if @reward.manager.present?
      [[@reward.manager], manager_admin_redemptions_url(network: @company.domain)]
    else
      [@reward.company.company_admins, company_admin_redemptions_url(network: @company.domain)]
    end

    I18n.with_locale(user.locale) do
      mail(to: @admins.map(&:email), subject: t("rewards.user_has_redeemed", name: @redeeming_user.full_name), track_opens: true)
    end
  end

  # Tell an employee their reward was denied.
  def notify_status_denied(user, redemption)
    @reward = redemption.reward
    @denier = redemption.denier
    notify_redeemer_status_change(user, redemption, t("rewards.redemption_was_denied", reward_title: redemption.reward.title))
  end

  # Tell an employee their reward was approved.
  def notify_status_approved(user, redemption)
    @redemption = redemption
    @reward = redemption.reward
    @approver = redemption.approver
    @user = user
    notify_redeemer_status_change(user, redemption, t("rewards.redemption_was_approved", reward_title: redemption.reward.title))
  end

  private

  def notify_redeemer_status_change(user, redemption, title)
    @user = user
    @redemption = redemption
    @mail_styler = company_styler(user.company)
    I18n.with_locale(user.locale) do
      mail(to: @user.email, subject: title, track_opens: true)
    end
  end


end