module Credentials
  class Base
    attr_accessor :file, :required_credentials, :credentials

    def initialize(f)
      @file = f

      check_has_required_files!

      @required_credentials = YAML.load(ERB.new(File.new(f+".sample").read).result)
      @credentials = YAML.load(ERB.new(File.new(f).read).result) || Hashie::Mash.new

      # This line is problematic now that credentials.yml.sample
      # will have the world of possible credentials due to it being
      # needed across multiple environments, not all of which require
      # the same set of credentials
      # check_has_all_required_credentials! unless Rails.env.test?

      return self
    end

    def apply_credentials_to_rails
      Recognize::Application.config.rCreds = @credentials
    end

    protected
    def check_has_required_files!
      unless File.exists?(self.file+".sample")
        raise "You are missing the required sample credentials file.  Please create #{self.file}.sample which will list all the required credentials that are needed for deployment"
      end

      unless File.exists?(self.file)
        raise "You must create a credentials file.  Please copy #{self.file}.sample to #{self.file} and fill in the appropriate values"
      end
    end

    #check if all the top level credentials are there
    def check_has_all_required_credentials!
      unless (missing = (required_credentials.keys - credentials.keys)).empty?
        raise "You are missing some credentials required in order to deploy: #{missing}"
      end
    end
  end

  def self.load_credentials(rails_config)
    credentials = Base.new(Rails.root.to_s+'/config/credentials.yml')
    credentials.apply_credentials_to_rails
  end

  # Checks credentials to verify whether or not a +key+ is present, and its +nested_keys+ have values.
  # Params:
  # +key+:: +Symbol|String+ name of key accessible from the top level.
  # +nested_keys+:: +Array+ of +Symbol|String+ that are first level nested children of +key+.
  def self.credentials_present?(key, nested_keys = [])
    key = key.to_s
    nested_keys = nested_keys.map(&:to_s)
    credentials = Recognize::Application.config.rCreds
    credentials[key].present? && nested_keys.all? { |nested_key| credentials[key][nested_key].present? }
  end

end
