class AccountsSpreadsheetImporterNotifier < ApplicationMailer
  include MailHelper
  # layout false, only: "from_template"

  helper :mail
  helper :application

  def process_completion_email(users, import_summary = Hashie::Mash.new)
    users = Array(users)
    @company = users.first.company
    @import_summary = import_summary
    @mail_styler = company_styler(@company)
    I18n.with_locale(users.first.locale) do
      mail(to: users.map(&:email), subject: I18n.t('notifier.accounts_spreadsheet_import_processed'), track_opens: true)
    end
  end

  # For now, this will be used to handle the error case
  # whereas, the above email is handling the success case
  def spreadsheet_import_report(users, importer)
    users = Array(users)
    @company = users.first.company
    @importer = importer
    @mail_styler = company_styler(@company)
    I18n.with_locale(users.first.locale) do
      mail(to: users.map(&:email), subject: I18n.t('notifier.accounts_spreadsheet_import_report'), track_opens: true)
    end
  end
end