# frozen_string_literal: true

class UserDirectoryDatatable < Litatable
  COLUMN_SPEC =
    [
      {attribute: :name, orderable: true, title: proc { I18n.t("dict.name") }, sort_column: "CONCAT(COALESCE(first_name, ''), COALESCE(email, ''))"},
      {attribute: :department, orderable: true, sort_column: "users.department", title: proc { I18n.t("dict.department") }},
      {attribute: :country, orderable: true, sort_column: "users.country", title: proc { I18n.t("dict.country") }},
      {attribute: :teams, orderable: false, title: proc { I18n.t("dict.teams") }, if: proc { show_teams? }},
      {attribute: :badges, orderable: false, title: proc { I18n.t("dict.badges") }, if: proc { show_badges? }},
      {attribute: :direct_reports, orderable: false, title: proc { I18n.t("dict.direct_reports") }, if: proc { show_direct_reports? }}
    ].freeze

  def default_order
    "[[ 0, \"asc\" ]]"
  end

  def all_records
    all_users = company.users.not_disabled.includes(:teams)
    all_users = all_users.order(sort_columns_and_directions) if params[:order].present?
    all_users
  end

  def filtered_records
    set = all_records
    search_term = params.dig(:search, :value)
    return paginated_set(set) if search_term.blank?

    search_columns = %w[users.first_name users.last_name users.display_name users.email users.department users.country]
    set = set.references(:teams)
    set = filtered_set(set, search_term, search_columns)
    paginated_set(set)
  end

  def serializer
    UserSerializerForUserDirectory
  end

  def custom_serializer_opts
    { user_direct_report_count_map: user_direct_report_count_map }
  end

  def namespace
    'users'
  end

  def allow_export
    false
  end

  def include_all_option_in_length_menu
    false
  end

  def show_teams?
    @show_teams = Subscription.feature_permitted?(@company, nil, :teams, skip_user_check: true) && @company.allow_teams?
  end

  def show_direct_reports?
    @show_direct_reports ||= Subscription.feature_permitted?(@company, nil, :manager, skip_user_check: true)
  end

  def show_badges?
    @show_badges ||= Subscription.feature_permitted?(@company, nil, :recognition, skip_user_check: true)
  end

  # Method override!
  def colvis_options
    {}
  end

  private

  def user_direct_report_count_map
    @user_direct_report_count_map ||= @company.user_direct_report_count_map
  end
end
