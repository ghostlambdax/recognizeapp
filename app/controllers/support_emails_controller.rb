class SupportEmailsController < ApplicationController
  enable_captcha only: [:new, :sales, :create], if: Proc.new { |c| c.current_user.nil? }

  def support_thanks
  end

  def sales_thanks
    @use_marketing_manifest = true
  end

  def sales_simple
    @support_email = SupportEmail.new
    render layout: "application_chromeless"

  end

  def new
    @body = params['body'].present? ? params['body'] : nil
    @support_email = SupportEmail.new
  end

  def sales
    @use_marketing_manifest = true
    @body = params['body'].present? ? params['body'] : nil
    @support_email = SupportEmail.new
  end

  def create
    @support_email = SupportEmail.new(support_email_params)

    if verify_recaptcha(model: @support_email) && @support_email.save
      path = if @support_email.support?
               support_thanks_path
             elsif @support_email.message == "upgrade"
               sales_thanks_path
             else
               ycbm_url_with_campaign
            end

      flash[:notice] = case @support_email.message
                       when "upgrade"
                         "Thanks for your interest. We will get back to you shortly about getting started."
                       else
                         "Success! We've received your inquiry. We'll get back to you shortly."
                       end
    end

    respond_with @support_email, location: path
  end

  private

  def support_email_params
    params
      .require(:support_email)
      .permit(%w[name email phone message type])
  end

  def ycbm_url_with_campaign
    # https://ga-dev-tools.appspot.com/campaign-url-builder/
    service = params[:support_email][:service] || 'service2'
    utm_source = params[:support_email][:utm_source]
    utm_medium = params[:support_email][:utm_medium] || 'recognizeapp.com'
    utm_campaign = params[:support_email][:utm_campaign] || 'demo'
    utm_content = params[:support_email][:utm_content] || ''
    firstname = params[:support_email][:name].split(" ")[0] rescue nil
    lastname = params[:support_email][:name].split(" ")[1] rescue nil

    "https://recognize-sales.youcanbook.me/?service=#{service}&UTM_SOURCE=#{utm_source}&UTM_MEDIUM=#{utm_medium}"\
      "&UTM_CONTENT=#{utm_content}&UTM_CAMPAIGN=#{utm_campaign}&FNAME=#{firstname}&LNAME=#{lastname}"\
      "&EMAIL=#{params[:support_email][:email]}&Q9=#{params[:support_email][:phone]}"
  end
end
