class UidSyncer

  class CompanySyncer
    attr_reader :company

    def self.sync(company)
      new(company).sync
    end

    def initialize(company)
      @company = company
    end

    def email_uid_map(provider)
      @email_uid_map ||= {}
      @email_uid_map[provider.to_sym] ||= get_email_uid_map_for_provider(provider)
      return @email_uid_map[provider.to_sym]
    end

    def sync
      company.users.each do |user|
        UserSyncer.sync(user, self)
      end
    end

    private
    def get_email_uid_map_for_provider(provider)
      admin_sync_user = company.admin_sync_user(provider: provider)
      client = admin_sync_user.send("#{provider}_client")
      # Note: ignoring sync filters here because this class is going to be deprecated.
      provider_users = client.get_all_users
      provider_users.each{|u| u.email = "#{u.email}.not.real.tld"} if Rails.env.development?
      map = provider_users.inject({}){|hash, user| hash[user.email] = user; hash}
      return map
    end
  end

  class UserSyncer
    attr_reader :user, :company_syncer

    def self.sync(user, company_syncer = CompanySyncer.new(user.company))
      new(user, company_syncer).sync
    end

    def initialize(user, company_syncer)
      @user = user
      @company_syncer = company_syncer
    end

    # PROVIDERS = %w(yammer microsoft_graph)
    PROVIDERS = %w(yammer)
    def sync
      PROVIDERS.each do |provider|
        next if user.send("#{provider}_id").present?
        map  = @company_syncer.email_uid_map(provider)   
        if map[user.email].present?
          user.update_column("#{provider}_id", map[user.email].id) 
        end
      end
    end

  end
end