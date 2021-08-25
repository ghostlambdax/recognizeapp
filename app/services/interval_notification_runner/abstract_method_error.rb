module IntervalNotificationRunner
  class AbstractMethodError < StandardError
    def initialize(method_name = nil)
      method_info = %(this method#{" (:#{method_name})" if method_name})
      message = "#{method_info} should be defined by the including class"
      super(message)
    end
  end
end