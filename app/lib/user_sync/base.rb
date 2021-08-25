module UserSync
  class Base

    include SyncFilters
    attr_accessor :users_deleted, :users_created, :teams_created, :teams_deleted
    attr_reader :sync_initiator, :company

    def self.sync(company:, sync_initiator:, client: nil)
      self.new(
          company: company,
          sync_initiator: sync_initiator,
          client: client
      ).sync
    end

    def self.factory(provider_string)
      raise ArgumentError, 'Unknown provider' unless UserSync.providers.include?(provider_string.to_sym)

      "UserSync::#{provider_string.camelcase}".constantize
    end

    def self.lazy_load?
      false
    end

    def initialize(company:, sync_initiator:, client: nil)
      @company = company
      @sync_initiator = sync_initiator
      @sync_teams = company.sync_teams
      @client = client# || YammerClient.new(sync_initiator.yammer_token, sync_initiator)
      @sync_groups = valid_sync_groups
    end


    # stub to be overwritten by subclasses
    def after_user_save(user)
      log "UserSync::Base - after user sync"
    end

    def client
      raise "Must be implemented by subclasses"
    end

    def create_recognize_team(sync_group)
      log "Creating team: #{sync_group}"
      team = company.teams.where(name: sync_group.name).first_or_initialize
      team.send("#{provider_uid_method}=", sync_group.id)
      team.save!
      return team
    end

    def log(msg)
      Rails.logger.debug "[UserSync][#{company.id}][#{company.domain}][#{caller[0].gsub("#{Rails.root}", '')}] #{msg}"
    end

    def sync_phone_data?(company, provider_user)
      company.settings.sync_phone_data? && provider_user.respond_to?(:phone)
    end

    def sync_display_name?(company)
      company.settings.sync_display_name? && provider.to_sym == :microsoft_graph
    end

    def sync_department?(company)
      company.settings.sync_department? && provider.to_sym == :microsoft_graph
    end

    def sync_country?(company)
      company.settings.sync_country? && provider.to_sym == :microsoft_graph
    end

    def create_recognize_user(provider_user)
      log "Attempting to create user: #{provider_user.id}-#{provider_user.email}"
      # first make sure we can't use a disabled user
      disabled_or_deleted_user_map = recognize_users_disabled_or_deleted_map
      log "trying to find user"
      if (found_user = disabled_or_deleted_user_map[provider_user.id])
        log "found user about to update"
        user = update_recognize_user(found_user) do |u|
          log "Reactivating deleted or disabled user: #{u.id}-#{u.email}"
          u.deleted_at = nil
        end
      else
        log "Didn't find user - need to create"
        email_to_use = company.settings.sync_email_with_upn? ? provider_user.user_principal_name : provider_user.email
        user = company.users.build(
            "#{provider_uid_method}": provider_user.id,
            first_name: provider_user.first_name,
            last_name: provider_user.last_name,
            email: email_to_use,
            user_principal_name: provider_user.user_principal_name,
            network: company.domain,
            synced_at: Time.now
        )
        user.job_title = provider_user.job_title if company.settings.sync_job_title?
        user.phone = provider_user.phone if sync_phone_data?(company, provider_user)
        user.display_name = provider_user.displayName if sync_display_name?(company)
        user.department = provider_user.department if sync_department?(company)
        user.country = provider_user.country if sync_country?(company)

        log "before adding user without invite"
        @sync_initiator.add_user_without_invite!(user, company: company, save_without_session_maintenance: true)
        after_user_save(user)
      end
      return user
    end

    def update_recognize_user(user)
      log "Updating user in sync: #{user.id}-#{user.email}"
      provider_user = provider_users.detect{|pu| pu.id.to_s == user.send("#{provider_uid_method}").to_s}
      provider_user ||= provider_users.detect{|pu| pu.email&.downcase == user.email&.downcase }

      log "before tap"
      email_to_use = company.settings.sync_email_with_upn? ? provider_user.user_principal_name : provider_user.email      
      user.tap do |u| 
        u.first_name = provider_user.first_name
        u.last_name = provider_user.last_name
        u.email = email_to_use
        u.user_principal_name = provider_user.user_principal_name
        u.job_title = provider_user.job_title if company.settings.sync_job_title?
        u.phone = provider_user.phone if sync_phone_data?(company, provider_user)
        u.display_name = provider_user.displayName if sync_display_name?(company)
        u.department = provider_user.department if sync_department?(company)
        u.country = provider_user.country if sync_country?(company)
        u.synced_at = Time.now
        if u.status == 'disabled'
          u.status = u.last_non_disabled_status
        end
        u.disabled_at = nil if u.disabled_at.present?
      end

      yield user if block_given?

      user.save!(validate: false)
      after_user_save(user)

      return user
    end

    def delete_recognize_user(user)
      log "Deleting user in sync: #{user.id}-#{user.email}"
      User.delay(queue: 'user_sync_low_priority').destroy(user.id)
    end

    def delete_recognize_team(team)
      log "Deleting team: #{team}"
      team.destroy
    end

    def provider
      @provider ||= self.class.to_s.demodulize.underscore.to_sym
    end

    def provider_uid_method
      @provider_uid_method ||= "#{provider}_id"
    end

    def provider_groups
      raise "Must be implemented by subclasses"
    end

    def provider_user(user)
      raise "Must be implemented by subclasses"
    end

    def unfiltered_provider_users
      raise "Must be implemented by subclasses"
    end

    def unfiltered_provider_users_to_create
      raise "Must be implemented by subclasses"
    end

    def unfiltered_provider_users_in_group(_group)
      raise "Must be implemented by subclasses"
    end

    def provider_users
      @_provider_users ||= filtered_users(unfiltered_provider_users)
    end

    def provider_users_to_create
      @_provider_users_to_create ||= filtered_users(unfiltered_provider_users_to_create)
    end

    def pair_recognize_user_to_provider_user(unpaired_recognize_user)
      match = provider_users.detect{|pu| pu&.email&.downcase == unpaired_recognize_user&.email&.downcase } #match on email
      log "pairing #{unpaired_recognize_user.id}-#{unpaired_recognize_user.email}"
      log "match: #{match}"
      unpaired_recognize_user.update_column(provider_uid_method, match.id) if match
    end

    def recognize_users
      @recognize_users ||= User.not_disabled.where(company_id: company.id)#company.users(reload=true).not_disabled
    end

    def recognize_users_with_disabled_and_deleted
      @recognize_users_with_disabled_and_deleted ||= User.with_deleted.where(company_id: company.id).where.not(unique_key: nil)
    end

    def recognize_users_disabled_or_deleted_map
      @recognize_users_disabled_or_deleted_map ||= User.with_deleted
        .where("deleted_at IS NOT NULL or status = 'disabled'")
        .where(company_id: company.id).inject({}){|hash, user| 
        # index both the id and provider uid to the user
        # if there is overlap, it shouldn't matter, i think...
        hash[user.id] = user
        hash[user.send(provider_uid_method)] = user
        hash
      }
    end

    def recognize_users_to_update
      @recognize_users_to_update ||= begin
        provider_ids = provider_users.map{|pu| pu.id.to_s}
        provider_emails = provider_users.map{|pu| pu.email&.downcase }

        recognize_users_emails_with_multiple_accounts = User.with_deleted.where(company_id: company.id).group(:email).having("count_email > 1").count(:email).keys

        # NOTE: use cases
        #       1. user is in recognize but doesn't have provider id
        #       2. user is in recognize and has provider id
        recognize_users_with_disabled_and_deleted.select { |u| 
          # handle case when there could be more than 1 account per email(1 deleted and 1 active)
          if recognize_users_emails_with_multiple_accounts.include?(u.email)

            # trying to make this really robust, even if at the expense of performance
            users = User.with_deleted.where(email: u.email).where.not(unique_key: nil)
            chosen_user = nil
            chosen_user ||= users.detect{|user| user.active? }
            chosen_user ||= users.detect{|user| user.send(provider_uid_method) == u.send(provider_uid_method)}
            chosen_user ||= users.detect{|user| user.disabled? }

            if chosen_user.blank?
              log "WTH - stupid user sync: #{users.inspect}"
              log "WTH - stupid user sync: choosing user: #{users.last.inspect}"
            end

            chosen_user ||= users.last

            u == chosen_user && (provider_ids.include?(u.send(provider_uid_method).to_s) || provider_emails.include?(u.email))
          else
            provider_ids.include?(u.send(provider_uid_method).to_s) ||
            provider_emails.include?(u.email&.downcase)

          end

        }
      end
    end

    def recognize_users_to_delete
      @recognize_users_to_delete ||= begin
        provider_user_emails = provider_users.map {|u| u.email&.downcase }
        provider_ids_in_recognize = recognize_users.map {|u| u.send(provider_uid_method).to_s}
        provider_ids_at_provider_end = provider_users.map {|pu| pu.id.to_s}

        provider_ids_not_found_remotely = provider_ids_in_recognize - provider_ids_at_provider_end
        recognize_users.select { |user|
          provider_ids_not_found_remotely.include?(user.send(provider_uid_method).to_s) &&
            !provider_user_emails.include?(user.email&.downcase) # don't delete recognize user if recognize user's email is in provider
        }.reject(&:company_admin?)
      end
    end

    def recognize_users_without_uid
      @recognize_users_without_uid ||= recognize_users.select{|ru| ru.send(provider_uid_method).blank? }
    end

    def sync
      log "Starting sync"

      # if there are inaccessible groups, remove them from the settings
      if sync_groups_have_invalid_groups?
        handle_invalid_sync_groups
        # return early if the provided groups are all invalid
        if valid_sync_groups.blank?
          return
        end
      end

      set_progress(0)
      # Record that we've started a sync so that if a company tries to change
      # their sync provider after a sync has begun at least once, 
      # we block and tell them to contact us
      company.touch(:last_synced_at)

      @users_deleted = []
      @users_created = []
      @users_updated = []
      @teams_created = []
      @teams_deleted = []
      @errors = []

      if @sync_teams
        log "Sync teams is turned on: #{teams_to_create.size} to create, #{teams_to_delete.size} to delete"
        teams_to_create.each_with_index do |sync_group, index|
          log "Teams to create: #{index}/#{teams_to_create.size}"
          team = create_recognize_team(sync_group)
          team.log_sync
          @teams_created.push(team)
        end

        teams_to_delete.each_with_index do |team, index|
          log "Teams to delete: #{index}/#{teams_to_delete.size}"
          team.log_sync
          delete_recognize_team(team)
          @teams_deleted.push(team)
        end
      end

      set_progress(15)
      log "Recognize users without uid: #{recognize_users_without_uid.size}"
      recognize_users_without_uid.each_with_index do |user, index|
        begin
          log "recognize user without uid: #{index}/#{recognize_users_without_uid.size}"
          pair_recognize_user_to_provider_user(user)
        rescue => e
          @errors << {e: e, user: user, action: :recognize_users_without_uid}
        end
      end

      # this should include disabled and deleted users
      # we should resurrect those accounts and activate them
      # if they are found. Two use cases:
      # 1. Existing user in recognize has matching provider id
      # 2. Existing user in recognize matches email
      set_progress(25)
      log "Recognize users to update: #{recognize_users_to_update.size}"
      recognize_users_to_update.each_with_index do |user, index|
        begin
          log "Updating recognize user(#{index}/#{recognize_users_to_update.size}): #{user.id}-#{user.email}"
          update_recognize_user(user)
          user.log_sync
          log "Before adding users to set"
          @users_updated.push(user)
          log "After adding users to set"
        rescue => e
          @errors << {e: e, user: user, action: :recognize_users_to_update}
        end
      end

      set_progress(55)
      log "Provider users to update: #{provider_users_to_create.size}"
      provider_users_to_create.each_with_index do |provider_user, index|
        begin
          log "Creating provider user(#{index}/#{provider_users_to_create.size}): #{provider_user.id}-#{provider_user.email}"
          user = create_recognize_user(provider_user)
          user.log_sync
          log "Before adding users to set"
          @users_created.push(user)
          log "After adding users to set"
        rescue => e
          @errors << {e: e, user: provider_user, action: :provider_users_to_create}
        end
      end

      set_progress(75)
      log "Recognize users to delete: #{recognize_users_to_delete.size}"
      recognize_users_to_delete.each_with_index do |user, index|
        begin
          log "Deleting recognize user(#{index}/#{recognize_users_to_delete.size}): #{user.id}-#{user.email}"
          user.log_sync
          delete_recognize_user(user)
          @users_deleted.push(user)
        rescue => e
          @errors << {e: e, user: provider_user, action: :recognize_users_to_delete}
        end
      end

      if @sync_teams
        company.reload
        log "Updating team memberships"
        company.teams.includes(:users).find_each.each_with_index do |team, index|
          log "Updating team(#{index}/#{company.teams.size}) - #{team.id} - #{team.name}"
          update_team_memberships(team)
        end
        set_progress(85)
      end

      if @errors.present?
        log "Found errors: #{@errors.size}"
        begin
          @errors.each_with_index do |data, index|
            log "Error(#{index}/#{@errors.size}) - #{data}"
            ExceptionNotifier.notify_exception(data[:e], data: {user: data[:user], action: data[:action]})
          end
        # be super cautious
        rescue => e
          ExceptionNotifier.notify_exception(e)
        end
      end

      set_progress(100)
      SafeDelayer.delay(queue: 'caching').run(Company, company.id, :refresh_cached_users!)
      # company.delay(queue: 'caching').refresh_cached_users!
    end

    def set_progress(progress)
      log "Progress is now: #{progress}%"
      @progress = progress
    end

    def stored_sync_groups
      raise "Must be implemented by subclasses"      
    end

    def sync_provider_name
      provider.to_s.titleize
    end

    def update_sync_groups
      raise "Must be implemented by subclasses"
    end

    def sync_groups_have_invalid_groups?
      invalid_sync_groups.any?
    end

    def invalid_sync_groups
      @invalid_sync_groups ||= begin
        if stored_sync_groups.empty?
          []
        else
          invalid_sync_group_ids = begin
            stored_sync_groups.map { |group| group.id.to_s } - provider_groups.map { |group| group.id.to_s }
          end
          stored_sync_groups.select { |group| invalid_sync_group_ids.include?(group.id.to_s) }
        end
      end
    end

    def valid_sync_groups
      @valid_sync_groups ||= stored_sync_groups - invalid_sync_groups
    end

    def handle_invalid_sync_groups
      update_sync_groups
      notify_company_admins_on_invalid_sync_groups_removal
    end

    def notify_company_admins_on_invalid_sync_groups_removal
      company.company_admins.each do |admin|
        UserSyncNotifier
          .delay(queue: "priority")
          .notify_company_admin_on_group_removal(admin, sync_provider_name, invalid_sync_groups)
      end
    end

    def teams_to_create
      group_ids = @sync_groups.map{|g| g.id.to_s} - company.teams.map { |t| t.send(provider_uid_method).to_s }
      @sync_groups.select { |group| group_ids.include?(group.id.to_s) }
    end

    # TODO: how do we handle teams that were created manually and have no provider_uid.
    # # Do we delete these teams or just leave them alone?
    def teams_to_delete
      group_ids = company.teams.map { |t| t.send(provider_uid_method).to_s } - @sync_groups.map{|g| g.id.to_s}
      company.teams.where("#{provider_uid_method} in (?)", group_ids).to_a
    end

    def update_team_memberships(team)
      team.users.clear
      group = @sync_groups.find { |g| team.send(provider_uid_method).to_s == g.id.to_s }
      return if group.nil?

      group_members = filtered_users(unfiltered_provider_users_in_group(group))
      company.users.where("#{provider_uid_method} in (?)", group_members.map(&:id)).each do |user|
        team.add_member(user)
      end
    end

    class BaseUser < Hashie::Mash
      def uid
        self.id
      end

      def email
        if Rails.env.development?
          super+".not.real.tld"
        else
          super
        end
      end

      def user_principal_name
      end
    end

    class BaseGroup < Hashie::Mash
      def uid
        self.id
      end
    end
  end
end
