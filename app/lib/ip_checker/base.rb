# Subclasses must implement
# * self.fetch_ips
# * self.key (redis key namespace to hold ips)

# The main interface to cache: 
#    - IpChecker::FbCrawler.cache_ips
#    - IpChecker::GhostInspector.cache_ips
#
# To check an ip: 
#    - IpChecker::FbCrawler.valid_ip?(ip)
#    - IpChecker::GhostInspector.valid_ip?(ip)
module IpChecker
  class Base
    require 'ipaddr'

    def self.ips
      $redis.smembers(self.key)
    end

    def self.cache_ips
      $redis.del(self.key)
      $redis.sadd(self.key, fetch_ips)
    end

    def self.fetch_ips
      raise "Must be implemented by subclass"
    end

    def self.key
      raise "Must be implemented by subclass"
    end

    def self.valid_ip?(ip_to_verify)
      ips.any? do |ip|
        IPAddr.new(ip).include?(ip_to_verify)
      end
    end

  end
end
