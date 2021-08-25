module Anniversary
  class Recognizer
    attr_reader :company

    def self.send_recognitions!
      Rails.logger.debug "Anniversary::Recognizer#send_recognitions - starting up"
      results = {success: [], fail: []}      

      TimezoneEnforcer.run(hour_to_run: 6, company_scope: Company.program_enabled) do |company_ids|
        next if company_ids.empty?
        Rails.logger.debug "Anniversary::Recognizer#send_recognitions - company ids: #{company_ids}"

        Company.program_enabled.where(id: company_ids).find_each do |company|
          begin
            ar = new(company)
            ar.send_recognitions!
            users_with_service_anniversaries = ar.send(:users_who_have_service_anniversaries_today)
            users_with_birthdays = ar.send(:users_who_have_birthdays_today)

            if users_with_service_anniversaries.length > 0 || users_with_birthdays.length > 0
              results[:success] << {
                company: company, 
                sa_users: users_with_service_anniversaries,
                b_users: users_with_birthdays
              }
            end
          rescue => e
            Rails.logger.debug "Anniversary::Recognizer#send_recognitions - failed for #{company.id}: #{e.message}"
            ExceptionNotifier.notify_exception(e, {data: {company_id: company.id, domain: company.domain}})
            result = {company: company}
            result[:sa_users] = ar.send(:users_who_have_service_anniversaries_today) rescue []
            result[:b_users] = ar.send(:users_who_have_birthdays_today) rescue []
            result[:exception] = e.message
            results[:fail] << result
          end
        end

      end
      Rails.logger.debug "Anniversary::Recognizer#send_recognitions - finished up, will send report if need be"
      handle_results(results) if results[:success].present? || results[:fail].present?
    end

    def self.handle_results(results)
      Rails.logger.debug "Anniversary::Recognizer#send_recognitions - about to deliver report: #{results}"      
      SystemNotifier.anniversary_report(results).deliver if results[:fail].present? 

      begin
        slack_body = ApplicationController.render(template: "system_notifier/anniversary_report", formats: "md", assigns: {results: results})
        channel = results[:fail].present? ? "#support-alerts" : "#system-notifications"
        ::Recognizebot.say(text: slack_body, channel: channel)
      rescue => e
        ExceptionNotifier.notify_exception(e, {data: results.inspect})
      end
    end

    def initialize(company)
      @company = company
    end

    def send_recognitions!
      Rails.logger.debug "Anniversary::Recognizer#send_recognitions - running for #{company.domain}(#{company.id})"
      
      if service_anniversary_badges.present?
        service_anniversary_users = users_who_have_service_anniversaries_today
        Rails.logger.debug "Anniversary::Recognizer#send_recognitions - service anniversary users: #{service_anniversary_users}"
        service_anniversary_users.each do |user|
          recognize_service_anniversary(user, service_anniversary_badges)
        end
      end
      if birthday_badge.present?
        birthday_users = users_who_have_birthdays_today
        Rails.logger.debug "Anniversary::Recognizer#send_recognitions - birthday users: #{birthday_users}"
        birthday_users.each do |user|
          recognize_birthday(user, birthday_badge)
        end
      end
    end

    def service_anniversary_badges
      @_service_anniversary_badges ||= begin
        active_anniversary_badges.reject(&:birthday?)
      end
    end

    def birthday_badge
      @_birthday_badge ||= begin
        active_anniversary_badges.detect(&:birthday?)
      end
    end

    def recognize_service_anniversary(user, service_anniversary_badges, force_private: false)
      badge = detect_service_anniversary_badge(service_anniversary_badges, user.start_date)

      if badge.present?
        opts = {}
        opts[:is_private] = true if user.receive_anniversary_recognitions_privately? || force_private
        send_anniversary_recognition(user, badge, opts)
      end
    end

    def detect_service_anniversary_badge(badges, start_date, reference_time: Time.current)
      years_of_service = reference_time.year - start_date.year

      # if the start date is later in the year than now
      # then its really one less year
      # This should only be encountered when resending anniversary recognitions
      if start_date_later_in_year?(start_date)
        years_of_service -= 1
      end

      months_of_service = difference_in_months(today, start_date)
      weeks_of_service = difference_in_weeks(today, start_date)

      badges.each do |badge|
        template_id = badge.anniversary_template_id
        return badge if template_id == template_id_for_years_of_service(years_of_service)

        if matching_day_of_month?(start_date)
          return badge if template_id == template_id_for_months_of_service(months_of_service)
        end

        if matching_day_of_week?(start_date)
          return badge if template_id == template_id_for_weeks_of_service(weeks_of_service)
        end
      end

      return nil
    end

    def detect_upcoming_service_anniversary_badge(badges, start_date)
      detect_service_anniversary_badge(badges, start_date, reference_time: Time.current + 1.year)
    end

    def recognize_birthday(user, birthday_badge, force_private: false)
      if birthday_badge.present?
        opts = {}
        opts[:is_private] = true if user.receive_birthday_recognitions_privately? || force_private
        send_anniversary_recognition(user, birthday_badge, opts)
      end
    end

    private

    def users_who_have_service_anniversaries_today
      company.users.not_disabled.select do |user|
        service_anniversary?(user.start_date) && (user.start_date < Date.current)
      end
    end

    def users_who_have_birthdays_today
      company.users.not_disabled.select do |user|
        birthday_anniversary?(user.birthday)
      end
    end

    def birthday_anniversary?(date)
      date.present? && yearly_anniversary?(date)
    end

    def service_anniversary?(date)
      date.present? && (yearly_anniversary?(date) || non_yearly_anniversary?(date))
    end

    def yearly_anniversary?(anniversary_date)
      if(today.day == anniversary_date.day && today.month == anniversary_date.month)
        return true
      end

      if(anniversary_date.month == 2 && anniversary_date.day == 29 && today.month == 2 && today.day == 28)
        return true
      end

      return false
    end

    def non_yearly_anniversary?(anniversary_date)
      template_ids_for_active_non_yearly_service_badges.each do |template_id|
        # interval count comes first for all non yearly anniversary templates, eg '01week', '1month', etc.
        anniversary_interval_count = template_id.to_i
        case template_id
        when /month/
          return true if matching_day_of_month?(anniversary_date) &&
                         difference_in_months(today, anniversary_date) == anniversary_interval_count
        when /week/
          return true if today - anniversary_date == anniversary_interval_count * 7
        end
      end

      false
    end

    def send_anniversary_recognition(user, badge, opts = {})
      User.system_user.recognize!(user, badge, badge.anniversary_message, opts)
    end

    def active_anniversary_badges
      @_active_anniversary_badges ||= company.anniversary_badges.not_disabled
    end

    def template_ids_for_active_non_yearly_service_badges
      @_template_ids_for_active_non_yearly_service_badges ||= begin
        non_yearly_template_ids = ANNIVERSARY_BADGES.keys.reject {|t| t.match(/^year|birthday$/)}
        active_anniversary_badges
          .select{|b| non_yearly_template_ids.include?(b.anniversary_template_id) }
          .map(&:anniversary_template_id)
      end
    end

    def start_date_later_in_year?(start_date)
      current_date = Date.current

      # return early for the usual case of scheduled anniversaries
      return false if start_date.month == current_date.month && start_date.day == current_date.day

      start_date_is_in_leap_year = start_date.leap?
      current_date_is_in_leap_year = current_date.leap?

      # Adjust for leap year
      # When only a single date is leap, then there is a disconnect between the two ydays after feb 28
      # because of feb 29 being present only in the leap year. So decrement that date for appropriate comparison.
      # Note: This does not mutate the original date objects
      if start_date_is_in_leap_year && !current_date_is_in_leap_year
        if start_date.yday > (31 + 28) # start date is after feb 28
          start_date -= 1
        end
      elsif current_date_is_in_leap_year && !start_date_is_in_leap_year
        if current_date.yday > (31 + 28) # current date is after feb 28
          current_date -= 1
        end
      end

      return start_date.yday > current_date.yday
    end

    # https://stackoverflow.com/a/9428676
    def difference_in_months(later_date, earlier_date)
      ((later_date.year * 12) + later_date.month) - ((earlier_date.year * 12) + earlier_date.month)
    end

    def difference_in_weeks(later_date, earlier_date)
      ((later_date - earlier_date) / 7).to_i
    end

    def template_id_for_years_of_service(years)
      "year_#{format_template_index(years)}"
    end

    def template_id_for_months_of_service(months)
      "#{months}#{'month'.pluralize(months)}"
    end

    def template_id_for_weeks_of_service(weeks)
      "#{format_template_index(weeks)}week"
    end

    def format_template_index(index)
      index.to_s.rjust(2, '0')
    end

    # here the second part is the edge case where the anniversary date is later in month than today
    # but today is end of this month. So they are considered a match.
    def matching_day_of_month?(anniversary_date)
      today.mday == anniversary_date.mday || (today == today.end_of_month && anniversary_date.mday > today.mday)
    end

    def matching_day_of_week?(anniversary_date)
      today.wday == anniversary_date.wday
    end

    def today
      @_today ||= Date.current
    end
  end
end
