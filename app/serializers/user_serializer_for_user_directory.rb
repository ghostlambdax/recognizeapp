# frozen_string_literal: true

class UserSerializerForUserDirectory < BaseDatatableSerializer
  include DateTimeHelper
  include Rails.application.routes.url_helpers
  include UsersUrlConcern

  attr_reader :user_direct_report_count_map
  attributes :id, :name, :teams, :direct_reports, :badges, :department, :country

  def initialize(object, options = {})
    @user_direct_report_count_map = options.delete(:user_direct_report_count_map)
    super(object, options)
  end

  def name
    context.link_to(user.full_name, user_path(user, network: user.network))
  end

  def teams
    u_teams = user.teams
    if u_teams.present?
      u_teams.map(&:name).join(", ")
    else
      none_text
    end
  end

  def direct_reports
    dr_count = user_direct_report_count_map[user.id]
    if dr_count
      text = "#{I18n.t('dict.show')} (#{dr_count})"
      toggle_text = "#{I18n.t('dict.hide')} (#{dr_count})"
      dr_endpoint = managed_users_user_path(user, network: user.network)
      context.link_to(text, "#", class: "toggle_dr", data: {endpoint: dr_endpoint, toggle_text: toggle_text})
    else
      none_text
    end
  end

  def department
    user.department.presence || none_text
  end

  def country
    user.country.presence || none_text
  end

  def badges
    context.link_to I18n.t("dict.show"), user_path(user)
  end

  private

  def none_text
    content_tag(:span, I18n.t('dict.none'), class: "subtle-text")
  end

  def user
    @object
  end
end
