# frozen_string_literal: true

# Resend previous anniversary and birthdays that occurred across a date range for a company
# Usage:
#   c = Company.where(domain: "example.com").first                                    # the company to check
#   anniversary_range = Time.parse("2019-07-01")..Time.parse("2019-07-02")            # tho to/from Range to search for users who have matching anniversary/birthday dates
#   opts = {send_anniversary: true, send_birthday: true}                              # what to check for/send
#   ar = Utility::AnniversaryResender.new(c, anniversary_range, opts: opts)           # create ar instance
#   ar.birthday_users.map{|u| "id=#{u.id}, email=#{u.email}"}                         # check birthdays that will be resent
#   ar.anniversary_users.map{|u| "id=#{u.id}, email=#{u.email}"}                      # check anniversaries that will be resent
#   ar.resend!                                                                        # resend recognitions
#
# Query to double check
#   c.users.not_disabled.where("birthday IS NOT NULL").map{|u| u.birthday}.sort_by{|b| "#{b.month}#{b.day.to_s.rjust(2, '0')}".to_i}.each_with_index.map{|b,i|[i,b]}
#   c.users.not_disabled.where("start_date IS NOT NULL").map{|u| u.start_date}.sort_by{|b| "#{b.month}#{b.day.to_s.rjust(2, '0')}".to_i}.each_with_index.map{|b,i|[i,b]}
#
# NOTICES
#  - there might be a discrepancy in the count of #anniversary_users or #birthday_users
#    from the actual emails that are sent out due to the fact that those methods only consider
#    whether the start_date/birthday is in range and NOT if the birthday/anniversary is turned on.
#  - we check for previously sent recognitions based off of the from.year - take caution
#    if your search (from/to) spans multiple years.

module Utility
  class AnniversaryResender
    attr_reader :company, :anniversary_range, :opts

    def initialize(company, anniversary_range, opts: {})
      @company = company
      @anniversary_range = anniversary_range
      @opts = opts
    end

    def log(msg)
      Rails.logger.debug "Utility::AnniversaryResender - #{msg}"
    end

    def resend!
      sent_users = {}
      log "Resending anniversaries..."
      sent_users[:anniversary] = self.recognize_anniversary_users! if send_anniversary?
      sent_users[:birthday] = self.recognize_birthday_users! if send_birthday?
      sent_users
    end

    def anniversary_users
      if opts[:users]
        opts[:users]
      else
        find_users_without_matching_recognition(:start_date)
      end
    end

    def birthday_users
      if opts[:users]
        opts[:users]
      else
        find_users_without_matching_recognition(:birthday)
      end
    end

    def find_users_in_range(attribute)
      company
        .users.not_disabled
        .where("(MONTH(#{attribute}) = ? AND DAYOFMONTH(#{attribute}) >= ?) OR MONTH(#{attribute}) > ?", anniversary_range.begin.month, anniversary_range.begin.day, anniversary_range.begin.month)
        .where("(MONTH(#{attribute}) = ? AND DAYOFMONTH(#{attribute}) <= ?) OR MONTH(#{attribute}) < ?", anniversary_range.end.month, anniversary_range.end.day, anniversary_range.end.month)
    end

    def find_users_without_matching_recognition(attribute)
      users_with_anniversary_in_search_range = find_users_in_range(attribute)
      users_with_anniversary_in_search_range_and_not_already_sent = users_with_anniversary_in_search_range.select do |user|
        log " -------------- "
        birthday_or_anniversary_value = user.send(attribute)
        log "Checking user: #{user.email} - #{attribute}: #{birthday_or_anniversary_value}"
        _resend_range = resend_range(user, attribute)
        log "Searching if anniversary was already sent between [#{_resend_range.begin}] and [#{_resend_range.end}]"
        conditions = {:created_at => _resend_range, badges: {is_anniversary: true}}

        birthday_template_conditions = {badges: {anniversary_template_id: Badge::BIRTHDAY_TEMPLATE_ID }}
        query = user.received_recognitions.joins(:badge).where(conditions)

        if attribute == :birthday
          recognitions = query.where(birthday_template_conditions)
        else
          recognitions = query.where.not(birthday_template_conditions)
        end

        user_can_have_recognition_resent = recognitions.blank?
        if user_can_have_recognition_resent
          log "Could not find existing recognitions, this user will be eligible to be resent"
        else
          log "Found existing recognitions for this user: #{recognitions.map(&:slug).join(", ")}"
        end
        log " -------------- "
        user_can_have_recognition_resent
      end

      service_anniversary_badges = recognizer.service_anniversary_badges

      log "Possible resendable #{attribute} users: "
      users_with_anniversary_in_search_range_and_not_already_sent.each do |u|
        if attribute == :start_date
          anniversary_year = Time.now.year - u.start_date.year
          template_id = recognizer.send(:template_id_for_years_of_service, anniversary_year)
          matching_badge = service_anniversary_badges.detect{|b| b.anniversary_template_id.to_s == template_id.to_s }
          badge_info = matching_badge.present? ? "#{matching_badge.short_name} - #{matching_badge.disabled_at.present? ? 'disabled' : 'active'}" : 'No badge'
          extra_info = "- (#{anniversary_year}) - #{badge_info}"
        else
          extra_info = ""
        end

        log "#{u.email} - #{u.send(attribute)} #{extra_info}"
      end
      users_with_anniversary_in_search_range_and_not_already_sent
    end

    def recognizer
      @recognizer ||= Anniversary::Recognizer.new(company)
    end

    def recognize_birthday_users!
      recognize_users(:birthday)
    end

    def recognize_anniversary_users!
      recognize_users(:start_date)
    end

    def recognize_users(attribute)
      sent_users = {}
      which = attribute == :birthday ? :birthday : :start_date
      users = find_users_without_matching_recognition(which)
      log "Resending (#{users.length}) #{which.to_s.humanize} users"
      users.each do |user|
        begin
          log "Resending #{which} for #{user.email} (#{user.id})"
          badges = which == :birthday ? recognizer.birthday_badge : recognizer.service_anniversary_badges
          force_private = opts[:force_private] ? true : false
          recognition = which == :birthday ? recognizer.recognize_birthday(user, badges, force_private: force_private) : recognizer.recognize_service_anniversary(user, badges, force_private: force_private)
          sent_users[user.id] = {user: user, recognition: recognition}
        rescue => e
          log "Caught exception resending for #{user.email} (#{user.id}) - #{e.message}"
          log e.backtrace.join("\n")
        end
      end
      sent_users
    end

    def send_anniversary?
      opts.key?(:send_anniversary) ? opts[:send_anniversary] : false
    end

    def send_birthday?
      opts.key?(:send_birthday) ? opts[:send_birthday] : false
    end

    def resend_range(user, attribute)
      birthday_or_anniversary_value = user.send(attribute)
      month, day = birthday_or_anniversary_value.month, birthday_or_anniversary_value.day
      # subtract two days to cover any weird boundary conditions
      # on when a birthday/anniversary was actually sent out vs the start range we calculate here
      (Time.parse("#{Time.current.year}-#{month}-#{day}") - 2.days)..Time.current
    end
  end
end
