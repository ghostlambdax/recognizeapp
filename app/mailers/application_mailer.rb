class ApplicationMailer < ActionMailer::Base
  default from: "Recognize <donotreply@recognizeapp.com>"
  layout 'mailer'
end