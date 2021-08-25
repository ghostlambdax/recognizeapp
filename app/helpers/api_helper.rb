module ApiHelper
  def track_request
    if current_user.present?
      ::Analytics.track(
        user_id: current_user.id, 
        event: "API: /#{controller_name}/#{action_name}", 
        properties: {
          api: true,
          controller: controller_name, 
          network: current_user.network,
          admin_dashboard_enabled: current_user.company.allow_admin_dashboard,
          custom_badges: current_user.company.custom_badges_enabled?,
          has_subscription: current_user.company.subscription.present?,
          using_oauth: using_oauth?,
          user_agent: request.env["HTTP_USER_AGENT"]
        })
    end
  rescue => e
      # ExceptionNotifier.notify_exception(
      #   Exception.new("Failed tracking api request: #{controller_name}##{action_name}"), 
      #   data: {current_user: current_user.id, network: current_user.network})  
      Rails.logger.debug "Failed tracking api request (#{controller_name}##{action_name}): #{{current_user: current_user.id, network: current_user.network}.inspect}"          
  end  

  private
  def using_oauth?
    http_auth = request.env["HTTP_AUTHORIZATION"] and http_auth.match(/Bearer/)
  end
end
