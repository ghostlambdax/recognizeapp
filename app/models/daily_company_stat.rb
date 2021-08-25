# frozen_string_literal: true

class DailyCompanyStat < ActiveRecord::Base
  USER_STATS = %i[total_users pending_users active_users disabled_users].freeze
  ACTIVE_USER_COUNT_INTERVALS = %i[daily weekly monthly quarterly yearly].freeze
  ACTIVE_USER_COUNT_STATS = ACTIVE_USER_COUNT_INTERVALS.map { |a| "#{a}_active_users" }
  RES_INTERVAL = %i[monthly quarterly yearly].freeze
  RES_TYPES = %i[recipient sender].freeze
  RES_STATS = RES_INTERVAL.inject([]){|arr, interval| RES_TYPES.each{|type| arr << "#{interval}_#{type}_res".to_sym }; arr}.freeze
  STATS = (USER_STATS + ACTIVE_USER_COUNT_STATS + RES_STATS).freeze
  # Whenever adding a new stat value that affects the STATS array please make sure
  # to reflect the change in spec/factories/daily_company_stats.rb

  belongs_to :company, inverse_of: :daily_stats, optional: true
  belongs_to :team, inverse_of: :daily_stats, optional: true

  validates :company_id, :date, presence: true
  validates *STATS, presence: true

  def self.calculate(company_or_team, date: Time.current.to_date)
    company, team = company_or_team.is_a?(Company) ? [company_or_team, nil] : [company_or_team.company, company_or_team]
    stat = new(company: company, date: date, team: team)
    stat.calculate!
    stat
  end

  def self.calculate_and_save!(company_or_team, date: Time.current.to_date)
    stat = calculate(company_or_team, date: date)
    stat.save!
    stat
  end

  def calculate!
    raise "Company is not specified" unless company.present?
    raise "Date not specified" unless date.present?

    STATS.each do |stat|
      value = send("calculate_#{stat}")
      send("#{stat}=", value)
    end
  end

  def reference_object
    team.present? ? team : company
  end

  def calculate_total_users
    self.reference_object.users.size
  end

  def calculate_pending_users
    self.reference_object.users.all_pending.size
  end

  def calculate_active_users
    self.reference_object.users.active.size
  end

  def calculate_disabled_users
    self.reference_object.users.disabled.size
  end

  def res_metrics
    @res_metrics ||= ResCalculator.metrics(reference_object)
  end

  ACTIVE_USER_COUNT_INTERVALS.each do |interval|
    define_method("calculate_#{interval}_active_users") do
      start_t = case interval
      when :daily
        1.day.ago
      when :weekly
        1.week.ago
      when :monthly
        1.month.ago
      when :quarterly
        3.months.ago
      when :yearly
        1.year.ago
      end
      User.where(company_id: company.id, last_request_at: start_t..Time.current).size
    end
  end

  RES_INTERVAL.each do |interval|
    RES_TYPES.each do |type|
      define_method("calculate_#{interval}_#{type}_res") do
        res_metrics[interval]["#{type}_res".to_sym]
      end
    end
  end
end
