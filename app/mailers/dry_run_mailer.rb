class DryRunMailer < ApplicationMailer
  include MailHelper
  helper :mail

  def dry_run_email(report, klass, reference_time, company_ids)
    @heading = "Dry run report for #{klass}"
    subject = "#{@heading} (#{report.total_email_count})"
    @reference_time = reference_time
    @report = report
    @filtered_company_names = company_names(company_ids)

    mail(to: admins.map(&:email), subject: subject)
  end

  def forecast_email(report, klass, reference_time_range, company_ids, total_run_count)
    @heading = "Forecast report for #{klass}"
    subject = "#{@heading} (#{report.total_email_count})"
    @reference_time_range = reference_time_range
    @total_run_count = total_run_count
    @report = report
    @filtered_company_names = company_names(company_ids)

    mail(to: admins.map(&:email), subject: subject)
  end

  private

  def company_names(company_ids)
    Company.where(id: company_ids).pluck(:name) if company_ids
  end

  def admins
    @admins ||= begin
      User.admins.presence || raise('No Admin found for sending dry run email')
    end
  end
end