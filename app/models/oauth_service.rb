#wrapper for Oauth/Omniauth
#this will present a consistent interface for different providers
#TODO: the current implementation will be yammer specific
#      refactor to be more modular if/when we bring more providers on board
class OauthService
  attr_accessor :oauth, :oauth_provider, :data, :origin, :params
  delegate :provider, :uid, :except, :credentials, :extra, to: :oauth
  delegate :data, :email, :first_name, :last_name, :image, :default_image?, :user_principal_name, to: :oauth_provider
  
  def initialize(env)
    Rails.logger.info "########################"
    Rails.logger.info "OAUTH-DEBUG: "
    if env
      @oauth = env["omniauth.auth"]
      @origin = env["omniauth.origin"]      
      @params = env["omniauth.params"]
      @oauth_provider = BaseProvider.factory(@oauth)

      Rails.logger.info "OAUTH-DEBUG: #{@oauth.inspect}"
      Rails.logger.info "OAUTH-DEBUG: #{@origin.inspect}"
      Rails.logger.info "OAUTH-DEBUG: #{@strategy.inspect}"
      Rails.logger.info "OAUTH-DEBUG: #{@params.inspect}"
    else
      @oauth, @origin, @params, @data = RecognizeOpenStruct.new, RecognizeOpenStruct.new, RecognizeOpenStruct.new, RecognizeOpenStruct.new
    end
    Rails.logger.info "########################"
  end

  def marshal_dump
    # leave out strategy because it contains entire request,
    # and contains anonymous module that can't be marshalled
    # and isn't even used
    {
      "omniauth.auth" => @oauth,
      "omniauth.origin" => @origin,
      "omniauth.params" => @params
    }
  end

  def marshal_load(data)
    @oauth = data["omniauth.auth"]
    @origin = data["omniauth.origin"]      
    @params = data["omniauth.params"]
    @oauth_provider = BaseProvider.factory(@oauth)
  end
  
  def origin
    if @origin
      uri = URI.parse(@origin)
      existing_params = Rack::Utils.parse_nested_query(uri.query)
      uri.query = existing_params.merge(params).to_param
      return uri.to_s
    end
  end

  def yammer?
    @oauth.provider.to_sym == :yammer
  end
  
  def google?
    @oauth.provider.to_sym == :google_oauth2
  end

  def microsoft_graph?
    @oauth.provider.to_sym == :microsoft_graph
  end
  
  class BaseProvider
    attr_accessor :oauth, :data
    
    delegate :provider, to: :oauth
    
    def initialize(oauth)
      @oauth = oauth
    end
    
    def user_principal_name
      self.email
    end

    def self.factory(oauth)
      return BaseProvider.new(oauth) unless oauth.respond_to?(:provider)

      case oauth.provider.to_s
      when "yammer"
        YammerProvider.new(oauth)
      when "google_oauth2"
        GoogleProvider.new(oauth)
      when "microsoft_graph"
        MicrosoftGraphProvider.new(oauth)
      end
    end
  end
  
  class YammerProvider < BaseProvider
    def data
      data = oauth.extra.raw_info rescue RecognizeOpenStruct.new#oauth might be nil if user has denied authentication            
    end
    
    def email
      #there is an email that comes through in the "info" portion of the oauth structure
      #but also there is the full set of emails in the "raw_info" portion
      #For now go with the "info" portion...but if need by, you can use
      #the commented out line below to get the rest of the emails
      # data.contact.email_addresses.first{|e| e.type == "primary"}.address
      oauth.info.email
    end
  
    def first_name
      data.first_name
    end
  
    def last_name
      data.last_name
    end
  
    def image
      oauth.info.image
    end
  
    def default_image?
      self.image.match(/no_photo/)
    end    
  end
  
  class GoogleProvider < BaseProvider
    def data
      @data ||= @oauth.info rescue RecognizeOpenStruct.new#oauth might be nil if user has denied authentication            
    end
    
    def email
      #there is an email that comes through in the "info" portion of the oauth structure
      #but also there is the full set of emails in the "raw_info" portion
      #For now go with the "info" portion...but if need by, you can use
      #the commented out line below to get the rest of the emails
      # data.contact.email_addresses.first{|e| e.type == "primary"}.address
      oauth.extra.id_info.email
    end
  
    def first_name
      data.first_name
    end
  
    def last_name
      data.last_name
    end
  
    def image
      self.class.full_size_image_url(oauth.info.image)
    end
  
    def default_image?
      self.image.match(/no_photo/)
    end 
    
    def self.full_size_image_url(url)
      # https://developers.google.com/people/image-sizing
      # I think this rudimentary logic is sufficient based on the 
      # Google people api which uses this weird syntax
      url&.split("=")&.first
    end
  end

  class MicrosoftGraphProvider < BaseProvider
    def data
      data = oauth.extra.raw_info rescue RecognizeOpenStruct.new#oauth might be nil if user has denied authentication            
    end
    
    def email
      #there is an email that comes through in the "info" portion of the oauth structure
      #but also there is the full set of emails in the "raw_info" portion
      #For now go with the "info" portion...but if need by, you can use
      #the commented out line below to get the rest of the emails
      # data.contact.email_addresses.first{|e| e.type == "primary"}.address
      oauth.info.email || (oauth.extra.raw_info["userPrincipalName"].match(/\@/) && oauth.extra.raw_info["userPrincipalName"])
    end
  
    def first_name
      data.givenName
    end
  
    def last_name
      data.surname
    end
  
    def image
      nil#oauth.info.image
    end
  
    def default_image?
      true#self.image.match(/no_photo/)
    end   

    def job_title
      data.jobTitle
    end

    def user_principal_name
      data.userPrincipalName
    end   
  end
end
