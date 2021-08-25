class FbWorkplace::Logger
  def self.log(thing, opts = {})
    case thing
    when Exception
      log_exception(thing, opts)
    else
      # assume string-like thing
      log_message(thing, opts)
    end
  end

  def self.log_exception(e, opts = {})
    if e.respond_to?(:response)
      log_message(e.response, opts)
    else
      log_message(e.message, opts)
    end
    e.backtrace.map{|m| log_message(m, opts) }
  end

  def self.log_message(message, opts = {})
    prefix = "[FbWorkplace]"
    prefix << "(#{opts[:uuid]})" if opts.has_key?(:uuid)
    Rails.logger.debug "#{prefix} #{message}"
  end
end