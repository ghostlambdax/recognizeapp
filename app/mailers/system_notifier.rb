class SystemNotifier < ApplicationMailer
  helper :mail
  
  def reminder_simulation(csv_file)
    attachments["#{Recognize::Application.config.host.to_s.downcase.gsub('.','-')}_reminder_simulation_#{Time.now.to_formatted_s(:db)}.csv"] = csv_file
    mail(to:"peter@recognizeapp.com", subject: "#{Recognize::Application.config.host} Tomorrow's email reminders - Here's what will run")
  end
  
  def contact_email(support_email)
    @support_email = support_email
    to_address = @support_email.sales? ? 'sales@recognizeapp.com' : 'support@recognizeapp.com'
    mail(
      from: "#{@support_email.email} <donotreply@recognizeapp.com>", 
      to: to_address, 
      subject: "Recognize #{@support_email.type} Request [#{Time.now.strftime('%Y%m%d%H%I')}-#{rand(Time.now.to_i).to_s(16)}]", 
      :"reply-to" => @support_email.email
      )
  end

  def survey_response(survey)
    @survey = survey
    mail(
      from: "#{@survey.email} <donotreply@recognizeapp.com>",
      to: "support@recognizeapp.com",
      subject: @survey.data.title,
      :"reply-to" => @survey.email
    )
  end

  def points_deposit(deposit_info)
    @deposit_info = deposit_info
    mail(
      from: "#{@deposit_info.user.email} <donotreply@recognizeapp.com>",
      to: "support@recognizeapp.com",
      subject: "#{deposit_info.user.full_name} from #{deposit_info.company.name} wants to deposit points money",
      :"reply-to" => @deposit_info.user.email
    )
  end

  def low_reward_balance(account)
    @account = account
    @company = account.company
    mail(
      to: "support@recognizeapp.com",
      subject: "Rewards balance low for: #{@company.domain}",
    )
  end
  
  def signup_request(signup_request)
    @signup_request = signup_request
    mail(to: "support@recognizeapp.com", subject: "A new request to signup has been submitted!")
  end

  def new_subscription(subscription_id)
    @subscription = Subscription.find(subscription_id)
    mail(to: "support@recognizeapp.com", subject: "A new subscription has been purchased!")
  end

  def anniversary_report(results)
    @results = results
    mail(to: "support@recognizeapp.com", subject: "Anniversary Delivery Report")    
  end
end
