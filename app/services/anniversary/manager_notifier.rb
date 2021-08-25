# Company#anniversary_notifieds returns from db the settings for who to notify: 
# - role(2[CompanyAdmin], 5[Executive]), 
# - user - don't think this is implemented
# - team_ids - I think what happens here is when "Team manager" is saved in the database, we save the team ids here and look up those managers later,
#                   - but this breaks if a team is deleted or added, so FIXME
#
module Anniversary
  class ManagerNotifier
    attr_reader :company

    def self.notify_all_anniversaries
      # current time based on application settings
      TimezoneEnforcer.run(hour_to_run: 6, company_scope: Company.program_enabled) do |company_ids|
        next if company_ids.empty?
        Company.program_enabled.where(id: company_ids).find_each do |company|
          begin
            manager_notifier = new(company)
            manager_notifier.notify_all_anniversaries
          rescue => e
            Rails.logger.debug "Anniversary::ManagerNotifier#notify_all_anniversary failed! " + manager_notifier.exception_data.inspect
            # send exception email in default timezone
            Time.use_zone(Rails.application.config.time_zone) do
              ExceptionNotifier.notify_exception(e, data: manager_notifier.exception_data)
            end
          end
        end
      end
    end

    def initialize(company)
      @company = company
    end

    def notify_all_anniversaries
      # Notifications are sent out only in weekdays.
      # Notifications that fall during weekends are accommodated in the following Monday.
      return unless work_week_day?(Date.current)

      anniversary_hash = get_todays_event_hash(:anniversary) || {}
      birthday_hash = get_todays_event_hash(:birthday) || {}
      notified_user_ids = (anniversary_hash.keys + birthday_hash.keys).uniq.compact

      notified_user_ids.each do |notified_user_id|
        user = User.find_by_id(notified_user_id)
        next unless user

        anniversary_users = anniversary_hash[notified_user_id] || []
        birthday_users = birthday_hash[notified_user_id] || []
        if anniversary_users.present? || birthday_users.present?
          AnniversaryNotifier.notify_anniversaries(user, anniversary_users, birthday_users).deliver
        end
      end
    end

    def get_todays_event_users(event_type)
      [].tap do |users|
        relevant_attribute = event_type == :anniversary ? :start_date : :birthday
        company.users.not_disabled.find_each do |user|
          relevant_date = user.send(relevant_attribute)
          if relevant_date.present? &&
             self.class.send("valid_#{event_type}?", Date.current, relevant_date) == true
            users << user
          end
        end
      end
    end

    #
    #  Returns an array of hashes with (key, value) pair of (notified_user_id, event_array).
    #
    def get_todays_event_hash(event_type)
      todays_event_users = get_todays_event_users(event_type)
      recipients_to_email = get_recipients_to_email(event_type)
      matched_role_recipients = RoleRecipientsManager.match_recipients_to_event(event_type, recipients_to_email, todays_event_users)
      matched_team_recipients = TeamRecipientsManager.match_recipients_to_event(event_type, recipients_to_email, todays_event_users)
      # The following 'merge' merges two hashes and also with the pipe '|' does
      # union of arrays(the values of the two hashes).
      matched_team_recipients.merge(matched_role_recipients){|key, a_val, b_val| a_val | b_val }
    end

    def get_recipients_to_email(event_type)
      role_recipients_to_email = RoleRecipientsManager.get_recipients_to_email(event_type, company)
      team_recipients_to_email = TeamRecipientsManager.get_recipients_to_email(event_type, company)
      role_recipients_to_email.merge(team_recipients_to_email)
    end

    # Used in Exception Notification.
    def exception_data
      {
        company: company.id,
        notified_user_ids: begin
          anniversary_hash = get_todays_event_hash(:anniversary) || {}
          birthday_hash = get_todays_event_hash(:birthday) || {}
          notified_user_ids = (anniversary_hash.keys + birthday_hash.keys).uniq
          notified_user_ids
        end
      }
    end

    class RoleRecipientsManager

      #
      # Returns hash with keys as user ids and value as an empty arrays, for users that are members of certain roles or
      # company_roles that are specified to be notified for an event_type.
      #
      def self.get_recipients_to_email(event_type, company)
        {}.tap do |recipients_to_email|
          event_notifieds = company.send("#{event_type}_notifieds")

          role_ids = event_notifieds[:role_ids]
          (role_ids || []).each do |role_id|
            user_ids = company.get_user_ids_by_role_id(role_id)
            user_ids.each do |user_id|
              recipients_to_email[user_id] = []
            end
          end

          company_role_ids = event_notifieds[:company_role_ids]
          (company_role_ids || []).each do |role_id|
            user_ids = company.get_user_ids_by_company_role_id(role_id)
            user_ids.each do |user_id|
              recipients_to_email[user_id] = []
            end
          end
        end
      end

      #
      # The passed in parameter recipients_to_email is a hash with user_ids as keys, with empty array as values.
      # The returned recipients_to_email has keys' values to be array of event users that are member of company_roles
      # or roles the user (specified by the key of the hash) is in.
      #
      def self.match_recipients_to_event(event_type, recipients_to_email, todays_event_users)
        todays_event_users.each do |todays_event_user|

          company = todays_event_user.company
          event_notifieds = company.send("#{event_type}_notifieds")

          role_ids = event_notifieds[:role_ids] || []
          role_ids.each do |role_id|
            user_ids = company.get_user_ids_by_role_id(role_id)
            # Exclude todays_event_user from user_ids so that todays_event_user doesn't get notified about its own event.
            user_ids.delete(todays_event_user.id)

            user_ids.each do |user_id|
              # managers should only get notified for their own direct reports
              next if role_id == Role.manager.id && todays_event_user.manager_id != user_id

              recipients_to_email[user_id] |= [todays_event_user]
            end
          end

          company_role_ids = event_notifieds[:company_role_ids] || []
          company_role_ids.each do |role_id|
            user_ids = company.get_user_ids_by_company_role_id(role_id)
            # Exclude todays_event_user from user_ids so that todays_event_user doesn't get notified about its own event.
            user_ids.delete(todays_event_user.id)
            user_ids.each do |user_id|
              recipients_to_email[user_id] |= [todays_event_user]
            end
          end

        end
        recipients_to_email
      end

    end

    class TeamRecipientsManager

      #
      # Returns hash with keys as manager ids and value as an empty arrays, for managers(not team members) of teams
      # that are specified to be notified for an event_type.
      #
      def self.get_recipients_to_email(event_type, company)
        {}.tap do |recipients_to_email|
          event_notifieds = company.send("#{event_type}_notifieds")
          team_ids = event_notifieds[:team_ids]
          team_ids.each do |team_id|
            team = Team.find_by_id(team_id)
            # A team might be present in {event}_notifieds for a company, but might have been deleted from the company.
            # Therefore, check for its presence, and loop accordingly.
            next unless team.present?
            team.managers.not_disabled.each do |manager|
              recipients_to_email[manager.id] = []
            end
          end
        end
      end

      #
      # The passed in parameter recipients_to_email is a hash with manager_ids as keys, with empty array as values.
      # The returned recipients_to_email has respective key's value to be array of event users that are members of the
      # team the team manager(specified by the key of hash) is in.
      #
      def self.match_recipients_to_event(event_type, recipients_to_email, todays_event_users)
        todays_event_users.each do |todays_event_user|
          team_notifieds = todays_event_user.company.send("#{event_type}_notifieds")[:team_ids] || []
          todays_event_user.teams.where(id: team_notifieds).each do |team|
            team_managers = team.managers.not_disabled.to_a
            # Exclude todays_event_user from team.managers so that todays_event_user doesn't get notified about its own event.
            team_managers.delete(todays_event_user)
            team_managers.each do |manager|
              if recipients_to_email.key?(manager.id)
                recipients_to_email[manager.id] |= [todays_event_user]
              end
            end
          end
        end

        recipients_to_email
      end
    end

    def work_week_day?(date)
      (1..5).cover? date.cwday
    end

    def self.valid_birthday?(today, birthday)
      # Apparently birthday in itself is an anniversary.
      valid_anniversary?(today, birthday)
    end

    def self.valid_anniversary?(today, start_date)
      return false if start_date >= today
      return true if today.day == start_date.day && today.month == start_date.month

      # Check for leap years' Feb 29 condition.
      #   In non-leap years, it should return true even when its Feb 28.
      start_date_is_feb_29 = start_date.month == 2 && start_date.day == 29
      today_is_feb_28 = today.month == 2 && today.day == 28
      # Checking of leap year avoids the method from firing true for start_date (2/29) at two consecutive 'todays' (2/28 and 2/29).
      current_year_is_not_leap_year = !Date.leap?(today.year)
      return true if start_date_is_feb_29 && today_is_feb_28 && current_year_is_not_leap_year

      # Accomodate anniversaries missed during weekends in the following monday.
      # The following `if` is never true during recursion calls that happen from inside the `if` logic.
      if today.friday?
        sunday = today + 2.days
        return true if valid_anniversary?(sunday, start_date)

        saturday = today + 1.day
        return true if valid_anniversary?(saturday, start_date)
      end

      false
    end

  end
end
