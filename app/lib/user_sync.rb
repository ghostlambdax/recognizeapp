module UserSync
  PROVIDERS = {
    yammer: "Yammer",
    microsoft_graph: "Microsoft / Office 365",
    sftp: "sFTP Import"
  }.freeze

  Error = Class.new(StandardError)
  AuthenticationError = Class.new(Error)
  NoSyncInitiator = Class.new(Error)

  def self.providers_to_label_map
    PROVIDERS
  end

  def self.providers
    PROVIDERS.keys
  end

  def self.authenticable_providers
    providers - [:sftp]
  end
end
