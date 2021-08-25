class IpChecker::GhostInspector < IpChecker::Base
  KEY = 'gi-server-ips'

  def self.key
    KEY
  end

  def self.fetch_ips
    raw_data = RestClient.get("https://api.ghostinspector.com/v1/test-runner-ip-addresses").body
    JSON.parse(raw_data)["data"]["us-east-1"]["ips"]
  end
end
