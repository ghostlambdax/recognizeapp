if Recognize::Application.config.rCreds.dig('aws', 'elasticache')
  host = Recognize::Application.config.rCreds['aws']['elasticache']['endpoint']
else
  host = 'localhost'
end

$redis = Redis.new(:host => host, :port => 6379)
