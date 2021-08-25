module ExceptionHelper
  def set_exception_data
    return if Rails.env.test?
    if current_user.present?
      request.env["exception_notifier.exception_data"] = {user: "User:#{current_user.id}:#{current_user.email}"}    
    else
      request.env["exception_notifier.exception_data"] = {user: "none"}    
    end
  end  
end