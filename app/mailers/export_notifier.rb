# frozen_string_literal: true

class ExportNotifier < ApplicationMailer
  include MailHelper

  helper :mail
  helper :application

  def document_ready(document, for_manager)
    @user = document.requester
    @company = @user.company
    @mail_styler = company_styler(@company)
    @documents_url = documents_url(@user, for_manager)
    I18n.with_locale(@user.locale) do
      mail(to: @user.email, subject: I18n.t('notifier.export_is_ready'), track_opens: true)
    end
  end

  private

  def documents_url(requester, for_manager)
    params = { network: requester.network, type: 'downloads' }

    admin_type =  for_manager ? :manager_admin : :company_admin
    send("#{admin_type}_documents_url", params)
  end
end
