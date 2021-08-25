class Points::Resetter

  def self.run_scheduler
    # current time based on application settings
    TimezoneEnforcer.run do |company_ids, time|
      reset_companies(time, company_ids)  if company_ids.size > 0
    end
  end

  def self.reset_companies(time, company_ids)
    # Mondays
    reset_weekly!(company_ids) if time.wday == 1
    # First day of month
    reset_monthly!(company_ids) if time.day == 1
    # First day of quarter
    reset_quarterly!(company_ids) if time.to_date == time.beginning_of_quarter.to_date
  end

  def self.reset_timely!(interval, company_ids)
    companies = Company.where(reset_interval: interval)
    companies = companies.where(id: company_ids) if company_ids.size > 0
    new(companies).reset!
  end

  def self.reset_weekly!(company_ids=[])
    reset_timely!(Interval::WEEKLY, company_ids)
  end

  def self.reset_monthly!(company_ids=[])
    reset_timely!(Interval::MONTHLY, company_ids)
  end

  def self.reset_quarterly!(company_ids=[])
    reset_timely!(Interval::QUARTERLY, company_ids)
  end

  def self.all_company_ids
    Company.distinct.pluck(:id)
  end

  attr_reader :companies

  def initialize(companies)
    @companies = Array(companies)
  end

  def reset!
    companies.each do |company|
      reset_company(company)
    end
  end

  private
  def reset_company(company)
    company.users.each do |user|
      reset_user(user) if user.persisted?
    end

    company.teams.each do |team|
      reset_team(team) if team.persisted?
    end
  end

  def reset_user(user)
    report = Report::User.new(user, user.interval_start_date, Time.current)
    user.update_column(:interval_points, report.points)
  end

  def reset_team(team)
    report = Report::Team.new(team, team.interval_start_date, Time.current)
    team.update_column(:interval_team_points, report.team_points)
    team.update_column(:interval_member_points, report.member_points)
  end
end
