# RAILS_ENV=production bundle exec rails r 'CmsManager.reset_page_caches'
require 'mechanize'
class CmsManager
  # Rudimentary way to get cms controllers. In the future, we should do a better job
  # of getting the string namespace of each relevant controller using Rails proper dsls.
  CMS_CONTROLLER_START_PATHS = Dir.glob(File.join("app","controllers","cms/*")).map{ |path| 
    "cms/"+File.basename(path, '.rb').gsub('_controller','')
  } - ["cms/base"]

  attr_reader :agent, :host, :start_path

  def self.cms_routes
    Rails.application.routes.set.anchored_routes
      .reject{|r| r.defaults[:internal] == true}
      .map{|route| 
        controller_klass = (route.defaults[:controller].to_s+"_controller").classify.constantize rescue nil
        {
        path: route.path.spec.to_s.gsub('(.:format)',''), 
        controller_path: route.defaults[:controller], 
        action: route.defaults[:action],
        controller: controller_klass
        }}
      .reject{|r| r[:controller].blank? || r[:controller].ancestors.include?(Cms::BaseController) }
      .select do |r|
        klass = r[:controller]
        klass.respond_to?(:cms_actions) && klass.cms_actions.present? && klass.cms_actions.include?(r[:action].to_sym)
      end
  end

  def self.hosts
    # this was previously used to iterate over all the instances in a cluster
    # but now that we're using EFS for the cached pages, we can run this
    # on one instance and it will take effect everywhere that uses the same EFS
    # eg, the whole cluster
    [ENV['CRAWLER_HOST'] || "https://#{Rails.configuration.host}"]
  end

  def self.reset_page_caches
    remove_page_caches
    save_page_caches
  end
  
  def self.save_page_caches
    hosts.each do |host|
      start_paths.each do |start_path|
        new(host, start_path).save_page_caches
      end
    end
  end

  def self.remove_page_caches
    hosts.each do |host|
      start_paths.each do |start_path|
        new(host, start_path).remove_page_caches
      end    
    end
  end

  def self.start_paths
    CMS_CONTROLLER_START_PATHS + cms_routes.map{|r| r[:path]}
  end

  def initialize(host, start_path)
    @host = host
    @start_path = start_path
    @agent = Mechanize.new { |agent|
      agent.user_agent = 'Recognize Cms Crawler - recognizeapp.com'
    }
  end

  def log(msg)
    Rails.logger.debug "[CmsCrawler] #{msg}"
  end

  def save_page_caches
    # For now, this isn't recursive, it will just loop over the directory
    log "Getting start page: #{host}/#{start_path}"
    agent.get("#{host}/#{start_path}") do |page|
      page.links_with(:href => %r{/cms/} ).each do |link|
        log "Visiting: #{link.uri.to_s}"
        begin
          agent.get(link.uri)
        rescue => e
          log "Could not visit page: #{e.message}"
        end
      end
    end   
  rescue Mechanize::ResponseCodeError => e
    log "Could not visit start page(#{start_path}): #{e.message}"
  end

  def remove_page_caches

    remove Dir.glob(File.join("public",start_path,"*.html"))
    remove Dir.glob(File.join("public",start_path,"*.html.gz"))
    remove File.join("public","#{start_path}.html")
    remove File.join("public","#{start_path}.html.gz")
  end
  
  def remove(file_names)
    file_names = Array(file_names)
    file_names.each do |file_name|
      log "Removing: #{file_name}"
      raise "Invalid file" unless file_name.match(/public\//)
      begin
        if File.exists?(file_name)
          FileUtils.rm(file_name)
        else
          log "Skipping #{file_name} - not present"
        end
      rescue => e
        log "Could not remove #{file_name} - #{e.message}"
      end
    end
  end
end
