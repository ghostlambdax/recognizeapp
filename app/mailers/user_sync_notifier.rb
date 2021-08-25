class UserSyncNotifier < ApplicationMailer
  include MailHelper
  layout "user_mailer"

  helper :mail

  def notify_company_admin_on_group_removal(admin, sync_provider_name, invalid_groups)
    @invalid_groups = invalid_groups
    @sync_provider_name = sync_provider_name
    I18n.with_locale(admin.locale) do
      mail(to: admin.email, subject: I18n.t("user_sync.notifier.removal_of_invalid_groups_subject"), track_opens: true)
    end
  end
end
