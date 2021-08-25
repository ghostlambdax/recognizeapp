#
# This sets the `from` name to custom label of the company if present
# Does not modify the `from` <email>
#
# Interceptors are called before EVERY email is sent out
#
class CustomLabelEmailInterceptor
  DEFAULT_SENDERS = ['donotreply@recognizeapp.com', 'team@recognizeapp.com']

  class << self
    def delivering_email(email)
      sender_emails, recipient_emails = email.from, email.to
      return if recipient_emails.empty? || sender_emails.length != 1 # unusual cases

      sender_email = sender_emails.first
      return unless DEFAULT_SENDERS.include?(sender_email)

      # assumes all recipients are in same company in case of multiple recipients (eg. in case of spreadsheet import)
      recipient_email = recipient_emails.first
      # return if email_domain(recipient_email) == 'recognizeapp.com' # skip sales, support, admin, etc. emails coming to us

      recipient_accounts = User.where(email: recipient_email)
      # TODO (maybe): handle multiple accounts
      # currently ignoring altogether, as there is apparently no direct way of knowing which company the email was sent for
      return if recipient_accounts.length != 1

      recipient = recipient_accounts.first
      default_email_from = recipient.company.custom_labels.default_email_from
      return if default_email_from.blank?

      email.from = ["#{default_email_from} <#{sender_email}>"]
    end

    def email_domain(email)
      email.split('@').last
    end

  end

end

ActionMailer::Base.register_interceptor(CustomLabelEmailInterceptor)
