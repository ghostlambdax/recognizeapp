# frozen_string_literal: true

class TimezoneEnforcer
  attr_reader :hour_to_run, :reference_time, :company_scope
  def initialize(hour_to_run: 0, reference_time: Time.current, company_scope: Company)
    @hour_to_run = hour_to_run
    @reference_time = reference_time
    @company_scope = company_scope
  end

  def self.run(opts={}, &block)
    raise ArgumentError, "no block given" unless block_given?
    new(opts).run_for_all_companies(&block)
  end

  def matching_timezones
    CompanySetting.distinct.pluck(:timezone).compact.select do |timezone|
      Time.use_zone(timezone) do
        time_to_run?    
      end
    end
  end

  def matching_companies
    company_scope.with_specific_timezone(matching_timezones)
  end

  # check if the hour of frozen time equals to the hour to run
  def time_to_run?
    time_in_zone.hour == hour_to_run
  end

  # convert the frozen time into time in timezone
  def time_in_zone
    reference_time.in_time_zone(Time.zone.name)
  end

  # Get uniq timezones from company settings
  # for each timezone use the timezone and also return the company_ids that have that timezone
  def run_for_all_companies
    raise ArgumentError, "no block given" unless block_given?
    CompanySetting.distinct.pluck(:timezone).compact.each do |timezone|
      Time.use_zone(timezone) do
        next unless time_to_run?
        company_ids = company_scope.with_specific_timezone(timezone).distinct.pluck(:id)
        yield(company_ids, time_in_zone)
      end
    end
  end
end
