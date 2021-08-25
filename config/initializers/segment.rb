segment_creds = Recognize::Application.config.rCreds['segment']

if segment_creds && segment_creds["write_key"].present?
  Analytics = Segment::Analytics.new({
      write_key: segment_creds['write_key'],
      on_error: Proc.new { |status, msg| print msg }
  })
end
