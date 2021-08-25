# frozen_string_literal: true

class DailyCompanyStatRunner
  attr_reader :company_id

  def self.run!
    TimezoneEnforcer.run(hour_to_run: 1, company_scope: Company.admin_dashboard_enabled) do |company_ids|
      company_ids.each do |company_id|
        new(company_id).run!
      end
    end
  end

  def initialize(company_id)
    @company_id = company_id
  end

  def company
    @company ||= Company.find(company_id)
  end

  def run!
    dcs = run_company!
    run_teams!
    push_metrics_to_close!(dcs)
  end

  def run_company!
    DailyCompanyStat.calculate_and_save!(company)
  end

  def run_teams!
    company.teams.each do |team|
      DailyCompanyStat.calculate_and_save!(team)
    end
  end

  CLOSE_FIELD_NAMES = ["R. Company program enabled", "R. Company dashboard enabled", "R. Users status: pending",
                       "R. Users status: active", "R. RES recipient monthly", "R. RES recipient quarterly",
                       "R. RES recipient yearly", "R. Users active: monthly", "R. Users active: quarterly"].freeze
  def push_metrics_to_close!(daily_company_stat = DailyCompanyStat.calculate(company))
    return unless Recognize::Application.closeio.live?

    field_ids = CLOSE_FIELD_NAMES.map{|f| Recognize::Application.closeio.get_custom_field_id_by_name(f) }
    company_program_enabled, company_dashboard_enabled, pending_users_field_id,
      active_users_field_id, monthly_field_id, quarterly_field_id, yearly_field_id,
      monthly_active_users_field_id, quarterly_active_users_field_id = field_ids

    payload = {
      company_program_enabled => self.company.program_enabled?,
      company_dashboard_enabled => self.company.allow_admin_dashboard?,
      pending_users_field_id => daily_company_stat.pending_users,
      active_users_field_id => daily_company_stat.active_users,
      monthly_field_id => daily_company_stat.monthly_recipient_res,
      quarterly_field_id => daily_company_stat.quarterly_recipient_res,
      yearly_field_id => daily_company_stat.yearly_recipient_res,
      monthly_active_users_field_id => daily_company_stat.monthly_active_users,
      quarterly_active_users_field_id => daily_company_stat.quarterly_active_users
    }

    if company.primary_funding_account&.persisted?
      rewards_balance_field_id = Recognize::Application.closeio.get_custom_field_id_by_name("R. Rewards Balance")
      payload[rewards_balance_field_id] = company.primary_funding_account.balance.to_f
    end

    Recognize::Application.closeio.update_lead_custom_fields(company, payload)
  end
end
