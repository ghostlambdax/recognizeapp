# live production only
if Rails.configuration.host == "recognizeapp.com"
  Datadog.configure do |c|
    metadata = JSON.parse(Net::HTTP.get(URI(ENV['ECS_CONTAINER_METADATA_URI_V4']))) rescue nil
    service_name = metadata['Labels']["com.amazonaws.ecs.task-definition-family"] rescue 'recognize-no-service'

    c.use :rails, service_name: service_name
    c.analytics_enabled = true
    c.tracer hostname: Net::HTTP.get(URI('http://169.254.169.254/latest/meta-data/local-ipv4'))  rescue nil  
  end
end
