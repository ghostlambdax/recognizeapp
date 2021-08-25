module UserSync

  class Yammer < Base
    attr_accessor :users_deleted, :users_created, :teams_created, :teams_deleted, :sync_groups

    def client
      @client ||= YammerClient.new(sync_initiator.yammer_token, sync_initiator)
    end

    def provider_groups
      yammer_groups
    end

    def unfiltered_provider_users
      yammer_users
    end

    def unfiltered_provider_users_to_create
      yammer_users_to_create
    end

    def unfiltered_provider_users_in_group(group)
      client.get_users_in_groups([group])
    end

    def sync
      begin
        super
      rescue ::Yammer::Error::ApiError, ActiveRecord::ActiveRecordError => e
        Rails.logger.warn(e.message)
        if e.kind_of?(YammerClient::Unauthorized)
          raise UserSync::AuthenticationError, [@sync_initiator.full_name, @sync_initiator.yammer_token, e.message, e.backtrace].flatten
        else
          # YammerClient doesn't have a base error so catch Yammer::Error::ApiError
          raise UserSync::Error, [@sync_initiator.full_name, @sync_initiator.yammer_token, e.message, e.backtrace].flatten
        end
      end
    end

    def stored_sync_groups
      company.settings.yammer_sync_groups
    end

    def update_sync_groups
      company.settings.update(yammer_sync_groups: @sync_groups)
    end

    def yammer_users
      @yammer_users ||= begin
        users = if @sync_groups.empty?
                  get_yammer_users
                else
                  get_yammer_users_in_sync_groups
                end

        users = users.map{|u| UserSync::Yammer::User.new(u) }
        users.sort_by(&:email)
      end
    end

    def yammer_groups
      @yammer_groups ||= client.get_all_groups.map{|g| UserSync::Yammer::Group.new(g) }
    end

    def get_yammer_users_in_sync_groups
      client.get_users_in_groups(@sync_groups)
    end

    def get_yammer_users
      client.get_all_users
    end

    def yammer_users_to_create
      yammer_ids = yammer_users.map{|yu| yu.id.to_s } - recognize_users.map { |u| u.yammer_id.to_s }
      yammer_users.select { |user|
        yammer_ids.include?(user.id.to_s) && 
        !@company.users.map(&:email).include?(user.email) # don't create recognize user if company already has user with this email
      }
    end

    class User < BaseUser
      def first_name
        @first_name ||= parse_name && @first_name
      end

      def last_name
        @last_name ||= parse_name && @last_name
      end

      # :job_title comes through as is from yammer
      private
      def parse_name
        @first_name, *@last_name = self.full_name.try(:split)
        @last_name = @last_name.join(" ")
      end
    end

    class Group < BaseGroup
    end
  end
end
