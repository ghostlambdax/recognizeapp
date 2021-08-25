File.expand_path('../../lib/microsoft_graph_client', __FILE__)

module UserSync

  class MicrosoftGraph < Base
    def self.lazy_load?
      true
    end

    def after_user_save(user)
      log "after user save callback"
      ::User.delay(queue: 'user_sync_low_priority').sync_microsoft_graph_avatar(user.id)
      ::User.delay(queue: 'user_sync_low_priority').sync_microsoft_graph_manager(user.id) if company.settings.sync_managers?
      ::User.delay(queue: 'user_sync').sync_metadata(user.id) 
      log "after the after user save callback"
    end

    def client
      @client ||= MicrosoftGraphClient.new(sync_initiator.microsoft_graph_token, sync_initiator)
    end

    def provider_groups
      @provider_groups ||= microsoft_graph_groups
    end

    def unfiltered_provider_users
      @provider_users ||= microsoft_graph_users
    end

    def unfiltered_provider_users_to_create
      @provider_users_to_create ||= microsoft_graph_users_to_create
    end

    def unfiltered_provider_users_in_group(group)
      client.get_users_in_groups([group], additional_select_attributes)
    end

    def stored_sync_groups
      company.settings.microsoft_graph_sync_groups
    end

    def update_sync_groups
      company.settings.update(microsoft_graph_sync_groups: @sync_groups)
    end

    # Excludes certain sync filters based on current value
    # 1.`accountEnabled` filter:
    #   This filter should only be applied when it is 'true',
    #   because in our application's context, the 'false' value means that disabled users should be included
    #   along WITH enabled users in the sync, not that ONLY disabled users should be synced
    def active_sync_filters
      super.dup.tap do |filters|
        filters&.delete(:accountEnabled) unless company.filter_account_enabled_users_in_microsoft_graph_sync?
      end
    end

    def sync
      client.refresh! unless Rails.env.test?# force refresh before we start
      super
    rescue RestClient::Unauthorized, ActiveRecord::ActiveRecordError => e
      Rails.logger.warn(e.message)
      # MicrosoftGraphClient doesn't have a base error so catch MicrosoftGraph::Error::ApiError
      if e.kind_of?(RestClient::Unauthorized)
        raise UserSync::AuthenticationError, [@sync_initiator.full_name, @sync_initiator.microsoft_graph_token, e.message, e.backtrace].flatten
      else
        raise UserSync::Error, [@sync_initiator.full_name, @sync_initiator.microsoft_graph_token, e.message, e.backtrace].flatten
      end
    end

    def microsoft_graph_users
      @microsoft_graph_users ||= begin
        users = if @sync_groups.empty?
                  get_microsoft_graph_users
                else
                  get_microsoft_graph_users_in_sync_groups
                end

        # `users` is a collection of MicrosoftGraphClient::MicrosoftUser objects.
        users = users.map{|u| UserSync::MicrosoftGraph::User.new(u) }
        # `users` is now a collection of UserSync::MicrosoftGraph::User objects.
        users.reject{|u| u.email.blank?}.sort_by(&:email)
      end
    end

    def microsoft_graph_groups
      @microsoft_graph_groups ||= client.groups.map{|g| UserSync::MicrosoftGraph::Group.new(g) }
    end

    def get_microsoft_graph_users_in_sync_groups
      client.get_users_in_groups(@sync_groups, additional_select_attributes)
    end

    def get_microsoft_graph_users
      client.users(additional_select_attributes)
    end

    def microsoft_graph_users_to_create
      microsoft_graph_user_ids = microsoft_graph_users.map(&:id) - recognize_users.map { |u| u.microsoft_graph_id }
      microsoft_graph_users.select { |user|
        microsoft_graph_user_ids.include?(user.id)  && 
        !@company.users.map{|u| u.email&.downcase}.include?(user.email&.downcase) # don't create recognize user if company already has user with this email
      }
    end

    # Attributes that are needed for sync filters, but not included by default by the graph API
    # @see MicrosoftGraphClient::USER_API_ATTRIBUTES for the default attributes
    def additional_select_attributes
      active_filter_keys = active_sync_filters&.keys || []
      active_filter_keys & [:accountEnabled]
    end

    class User < BaseUser
      # for some reason, there are times in the ms payload mail is nil
      # and in those cases, the email is in the userPrincipleName
      # one day, we'll look into why that is...
      def email
        self.mail || self.userPrincipalName
      end

      def first_name
        @first_name = self.givenName
      end

      def last_name
        @last_name = self.surname
      end

      def job_title
        self.jobTitle
      end

      def phone
        self.mobilePhone
      end

      def user_principal_name
        self.userPrincipalName
      end

      private
      def parse_name
        @first_name, *@last_name = self.full_name.split
      end      
    end

    class Group < BaseGroup
    end    

  end
end
