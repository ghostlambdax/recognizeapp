if defined?(Rack::MiniProfiler)
  # Rack::MiniProfiler.profile_method(ActiveRecord::Querying, "all")
  Rack::MiniProfiler.config.start_hidden = true 
  Rack::MiniProfiler.config.storage = Rack::MiniProfiler::MemoryStore
  Rack::MiniProfiler.config.enabled = false
  # Rack::MiniProfiler.config.pre_authorize_cb = lambda {|env| return true}
  # Rack::MiniProfiler.config.auto_inject = true
end
class Profiler
  def self.step(label, &block)
    if defined?(Rack::MiniProfiler)
      Rack::MiniProfiler.step(label, &block)
    else
      yield
    end
  end
end
