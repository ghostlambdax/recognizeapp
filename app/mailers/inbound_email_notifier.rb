class InboundEmailNotifier < ApplicationMailer
  include MailHelper
  include RecognitionsHelper

  helper :mail
  helper :application
  helper :recognitions

  def missing_recipients(inbound_email)
    @inbound_email = inbound_email
    subject = "Your recognition via email is missing recipients"
    mail(to: inbound_email.sender_email, subject: subject)
  end

  def confirmation(recognition)
    @recognition = recognition
    @sender = @recognition.sender
    @badge = @recognition.badge
    @recipients_label = recipients_label(@recognition, exclude_link: true)
    subject = @recognition.recipients.size < 3 ? 
      "Your recognition to #{@recipients_label} has been delivered" : 
      "Your recognition has been delivered"
    mail(to: recognition.sender_email, subject: subject, track_opens: true) 
  end  
end
