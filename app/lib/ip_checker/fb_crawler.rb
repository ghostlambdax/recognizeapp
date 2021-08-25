class IpChecker::FbCrawler < IpChecker::Base
  COMMAND = "whois -h whois.radb.net -- '-i origin AS32934' | grep ^route |awk '{print $2}'"
  KEY = 'fb-crawler-ips'

  def self.crawler_ip?(ip)
    valid_ip?(ip)
  end    

  def self.fetch_ips
    cidr_list = `#{COMMAND}`.split("\n")
    # ips = cidr_list.inject([]) do |set, cidr|
    #   Rails.logger.debug "CIDR: #{cidr}"
    #   set += IPAddr.new(cidr).to_range.map{|i| i.to_s}
    #   set
    # end
    # ips = ips.uniq
    # return ips
    return cidr_list
  end  

  def self.key
    KEY
  end
end
